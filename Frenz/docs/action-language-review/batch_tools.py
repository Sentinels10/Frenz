"""Display compact review batches and apply explicitly reviewed batch decisions.

Usage: batch_tools.py show START END; batch_tools.py finish DECISIONS.json
Decisions contain start/end, edits by index/language, and second_pass=true.
Only the explicitly inspected range is marked; all changes retain originals.
"""
import json
import sys
import re
from datetime import datetime, timezone
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
def read(name):
    return json.loads((HERE / name).read_text())

rows = read('review.json')
if sys.argv[1] == 'show':
    for i in range(int(sys.argv[2]), int(sys.argv[3])):
        row = rows[i]
        print(i, row['id'])
        for lang, original in row['original'].items():
            # Remove only repeated voting instructions from the display.
            def compact(text):
                for suffix in (' Votate tutti contemporaneamente', ' Everyone votes at the same time', ' Voten todos al mismo tiempo', ' Votez tous en même temps'):
                    text = text.split(suffix)[0]
                return text
            revised = row['changes'].get(lang, {}).get('text')
            print(lang, compact(original), (' => ' + compact(revised)) if revised else '')
elif sys.argv[1] == 'finish':
    decisions = read(sys.argv[2])
    from removal_state import load_manifest
    removals = load_manifest()
    removed_ids = set(removals['removed_ids']) if removals else set()
    if removals and not decisions.get('recheck_only'):
        raise SystemExit('After removals only sparse recheck_only decisions with historical IDs are allowed.')
    if 'corrections' in decisions:
        decisions['edits'] = {}
        for correction in decisions['corrections']:
            index, lang, revised = correction[:3]
            reason = correction[3] if len(correction)>3 else 'Errore concreto di sintassi, grammatica o traduzione nel confronto con il canonico; correzione minima.'
            decisions['edits'].setdefault(str(index), {})[lang] = {'text': revised, 'reason': reason}
    # Resolve replacements before literal repairs and invariant exceptions.
    for index, edits in decisions.get('edits', {}).items():
        for lang, edit in edits.items():
            if edit and 'replace' in edit:
                revised = rows[int(index)]['changes'].get(lang, {}).get('text', rows[int(index)]['original'][lang])
                for before, after in edit.pop('replace'):
                    assert before in revised, (index, lang, before)
                    revised = revised.replace(before, after)
                edit['text'] = revised
    for lang, before, after, reason in decisions.get('literal_repairs', []):
        for i in range(decisions['start'], decisions['end']):
            original = rows[i]['original'][lang]
            if re.search(r'\b' + re.escape(before) + r'\b', original) and lang not in decisions.get('edits', {}).get(str(i), {}):
                decisions.setdefault('edits', {}).setdefault(str(i), {})[lang] = {'text':original,'reason':reason}
            edit = decisions.get('edits', {}).get(str(i), {}).get(lang)
            if edit and 'text' in edit:
                edit['text'] = re.sub(r'\b' + re.escape(before) + r'\b', lambda _: after, edit['text'])
    exceptions = read('invariant_restorations.json')
    import re
    for index, lang, reason in decisions.get('restorations', []):
        edit = decisions['edits'][str(index)][lang]
        original = rows[index]['original'][lang]
        for pattern in (r'\d+', r'\{[^{}]+\}', r'\[[^\[\]]+\]'):
            before, after = re.findall(pattern, original), re.findall(pattern, edit['text'])
            if before != after:
                existing = [e for e in exceptions if e['id']==rows[index]['id'] and e['language']==lang and e['pattern']==pattern]
                if existing:
                    assert len(existing) == 1 and existing[0]['before'] == before and existing[0]['after'] == after, (index, lang, 'restoration changed')
                else:
                    exceptions.append(dict(id=rows[index]['id'],language=lang,pattern=pattern,before=before,after=after,reason=reason))
    if decisions.get('restorations'):
        (HERE / 'invariant_restorations.json').write_text(json.dumps(exceptions,ensure_ascii=False,indent=2)+'\n')
    assert decisions['second_pass'] is True
    start, end = decisions['start'], decisions['end']
    for index, edits in decisions.get('edits', {}).items():
        i = int(index)
        assert start <= i < end
        assert rows[i]['id'] not in removed_ids, (i, 'record was removed')
        for lang, edit in edits.items():
            if edit is None:
                rows[i]['changes'].pop(lang, None)
            else:
                if 'previous_prefix' in edit:
                    original = rows[i]['original'][lang]
                    suffix = {'it': ' Votate tutti contemporaneamente', 'en': ' Everyone votes at the same time', 'es': ' Voten todos al mismo tiempo', 'fr': ' Votez tous en même temps'}[lang]
                    previous = edit.pop('previous_prefix') + (suffix + original.split(suffix, 1)[1] if suffix in original else '')
                    edit['previous_validated_texts'] = [previous]
                if 'replace' in edit:
                    revised = rows[i]['changes'].get(lang, {}).get('text', rows[i]['original'][lang])
                    for before, after in edit.pop('replace'):
                        assert before in revised, (i, lang, before)
                        revised = revised.replace(before, after)
                    edit['text'] = revised
                if 'prefix' in edit:
                    original = rows[i]['original'][lang]
                    suffix = {'it': ' Votate tutti contemporaneamente', 'en': ' Everyone votes at the same time', 'es': ' Voten todos al mismo tiempo', 'fr': ' Votez tous en même temps'}[lang]
                    edit['text'] = edit.pop('prefix') + (suffix + original.split(suffix, 1)[1] if suffix in original else '')
                previous = rows[i]['changes'].get(lang)
                if edit['text'] == rows[i]['original'][lang]:
                    assert previous is None or previous['text'] == edit['text'], (i, lang, 'cannot discard an applied revision')
                    rows[i]['changes'].pop(lang, None)
                    continue
                if previous and previous['text'] != edit['text']:
                    edit['previous_validated_texts'] = list(dict.fromkeys(edit.get('previous_validated_texts', []) + previous.get('previous_validated_texts', []) + [previous['text']]))
                rows[i]['changes'][lang] = edit
    inspected = ([rows[int(i)] for i in decisions.get('edits', {})]
                 if decisions.get('recheck_only') else rows[start:end])
    if decisions.get('recheck_only'):
        assert all('NOT_CHECKED' not in r['status'].values() for r in inspected)
    for row in inspected:
        for lang in list(row['changes']):
            if row['changes'][lang]['text'] == row['original'][lang]:
                row['changes'].pop(lang)
        for lang in row['original']:
            row['status'][lang] = 'VALIDATED' if lang in row['changes'] else 'CHECKED_UNCHANGED'
    progress = read('language_review_progress.json')
    progress.update(updated_at=datetime.now(timezone.utc).isoformat(), current_batch={'start':start,'end_exclusive':end,'phase':'VALIDATION_AND_APPLY','decisions':sys.argv[2]})
    (HERE / 'language_review_progress.json').write_text(json.dumps(progress, ensure_ascii=False, indent=2) + '\n')
    (HERE / 'review.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2) + '\n')
    subprocess.run([sys.executable, str(HERE / 'check_and_apply.py'), '--apply', '--allow-pending-second-pass'], check=True)
    summary = read('summary.json')
    progress = read('language_review_progress.json')
    first = next((i for i, r in enumerate(rows) if 'NOT_CHECKED' in r['status'].values()), len(rows))
    progress.update(updated_at=datetime.now(timezone.utc).isoformat(),
        checked_records=summary['checked_entries'], modified_records=summary['modified_entries'],
        validated_and_applied_records=sum(all(s in ('VALIDATED','CHECKED_UNCHANGED') for s in r['status'].values()) for r in rows if r['id'] not in removed_ids),
        last_checked_index=first-1, last_checked_id=rows[first-1]['id'],
        last_applied_index=max(end-1, progress.get('last_applied_index', -1)), next_unchecked_index=first,
        current_batch=None, status='AWAITING_FINAL_AUDIT' if summary['complete'] else 'IN_PROGRESS',
        remaining_records=summary['remaining_entries'])
    progress['next_unchecked_id'] = rows[first]['id'] if first < len(rows) else None
    progress['problematic_ids'] = [r['id'] for r in read('unresolved.json') if r['id'] not in removed_ids]
    progress['modified_texts_by_language'] = summary['modified_texts_by_language']
    progress['resume'] = 'Read this checkpoint and review.json. Resume current_batch if present; otherwise start at next_unchecked_index. Use batch_tools.py show START END; save individually inspected decisions; finish with batch_tools.py finish DECISIONS.json. Preserve original text and unchanged good wording. Run check_and_apply.py --require-complete only after all NOT_CHECKED and CHECKED_MODIFIED states are resolved. Resolve linguistic issues in unresolved.json without inventing mechanics.'
    progress.setdefault('completed_batches', []).append({'start': start, 'end_exclusive': end, 'decisions': sys.argv[2]})
    (HERE / 'language_review_progress.json').write_text(json.dumps(progress, ensure_ascii=False, indent=2) + '\n')
