"""Validate review coverage and apply only individually validated text changes.

Run from any directory. --require-complete fails while unchecked entries remain.
The baseline is the working tree at review start, including pre-existing edits.
"""
import argparse
import collections
import json
from pathlib import Path
import re
from removal_state import load_manifest, prune, remap

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
LANGUAGES = ('it', 'en', 'es', 'fr')

def flatten(value, path=''):
    if isinstance(value, str):
        yield path, value
    elif isinstance(value, dict):
        for key, child in value.items():
            yield from flatten(child, path + '/' + key)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from flatten(child, path + '/' + str(index))

def set_text(document, pointer, text):
    parts = pointer.split('/')[1:]
    node = document
    for part in parts[:-1]:
        node = node[int(part)] if isinstance(node, list) else node[part]
    key = int(parts[-1]) if isinstance(node, list) else parts[-1]
    node[key] = text

def non_text_structure(value):
    if isinstance(value, str):
        return None
    if isinstance(value, dict):
        return {key: non_text_structure(child) for key, child in value.items()}
    if isinstance(value, list):
        return [non_text_structure(child) for child in value]
    return value

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--require-complete', action='store_true')
    parser.add_argument('--require-applied', action='store_true', help='Require databases to contain every validated revision already')
    parser.add_argument('--allow-pending-second-pass', action='store_true')
    args = parser.parse_args()
    rows = json.loads((HERE / 'review.json').read_text())
    baseline = json.loads((HERE / 'baseline.json').read_text())
    exceptions = json.loads((HERE / 'invariant_restorations.json').read_text())
    ids = [row['id'] for row in rows]
    assert len(ids) == len(set(ids)), 'Duplicate review IDs'
    expected_ids = set(dict(flatten(baseline['it'])))
    assert set(ids) == expected_ids, 'Missing or extra review IDs'
    removals = load_manifest()
    targets = removals['targets'] if removals else []
    removed_ids = set(removals['removed_ids']) if removals else set()
    active_rows = [row for row in rows if row['id'] not in removed_ids]
    assert removed_ids <= set(ids)
    changes = collections.Counter()
    states = {}
    pending = []
    output = {}
    for language in LANGUAGES:
        current_path = ROOT / 'Data/Resources' / f'backupActions_{language}.json'
        current = json.loads(current_path.read_text())
        active_baseline = prune(baseline[language], targets) if targets else baseline[language]
        assert non_text_structure(current) == non_text_structure(active_baseline), (language, 'non-text data changed')
        old_flat = dict(flatten(baseline[language]))
        current_flat = dict(flatten(current))
        assert set(current_flat) == set(dict(flatten(active_baseline))), language
        states[language] = collections.Counter()
        for row in active_rows:
            source_pointer = row['id']
            pointer = remap(source_pointer, targets) if targets else source_pointer
            original = row['original'][language]
            assert original == old_flat[source_pointer]
            status = row['status'][language]
            assert status in ('NOT_CHECKED', 'CHECKED_UNCHANGED', 'CHECKED_MODIFIED', 'VALIDATED')
            states[language][status] += 1
            if status == 'NOT_CHECKED':
                pending.append((pointer, language))
            if language in row['changes']:
                if status == 'CHECKED_MODIFIED' and args.allow_pending_second_pass:
                    assert current_flat[pointer] == original, (pointer, language, 'pending change already applied')
                    pending.append((pointer, language))
                    continue
                assert status == 'VALIDATED', (pointer, language, 'second pass required')
                revised = row['changes'][language]['text']
                assert original != revised, (pointer, language, 'no-op change')
                for pattern in (r'\d+', r'\{[^{}]+\}', r'\[[^\[\]]+\]'):
                    before = re.findall(pattern, original)
                    after = re.findall(pattern, revised)
                    if before != after:
                        permitted = [e for e in exceptions if e['id'] == source_pointer and e['language'] == language and e['pattern'] == pattern]
                        assert len(permitted) == 1, (pointer, language, pattern)
                        assert permitted[0]['before'] == before and permitted[0]['after'] == after, (pointer, language, 'restoration mismatch')
                allowed_current = (original, revised, *row['changes'][language].get('previous_validated_texts', []))
                assert current_flat[pointer] in allowed_current, (pointer, language, 'concurrent edit')
                if args.require_applied:
                    assert current_flat[pointer] == revised, (pointer, language, 'validated change not applied')
                set_text(current, pointer, revised)
                changes[language] += 1
            else:
                assert status in ('NOT_CHECKED', 'CHECKED_UNCHANGED')
                assert current_flat[pointer] == original, (pointer, language, 'unexpected edit')
        output[current_path] = current
    summary = {
        'complete': not pending,
        'total_entries': len(active_rows),
        'total_texts': len(active_rows) * len(LANGUAGES),
        'checked_entries': sum(all(s != 'NOT_CHECKED' for s in r['status'].values()) for r in active_rows),
        'checked_texts': len(active_rows) * len(LANGUAGES) - len(pending),
        'modified_entries': sum(bool(r['changes']) for r in active_rows),
        'checked_unchanged_entries': sum(not r['changes'] and all(s != 'NOT_CHECKED' for s in r['status'].values()) for r in active_rows),
        'modified_texts_by_language': dict(changes),
        'corrected_translations': sum(changes[l] for l in LANGUAGES if l != 'it'),
        'remaining_entries': sum(any(s == 'NOT_CHECKED' for s in r['status'].values()) for r in active_rows),
        'states_by_language': states,
    }
    if removals:
        summary['removed_entries'] = len(removed_ids)
        summary['historical_total_entries'] = len(rows)
    if args.apply:
        for path, document in output.items():
            path.write_text(json.dumps(document, ensure_ascii=False, indent=2) + '\n')
        (HERE / 'summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    if args.require_complete and pending:
        raise SystemExit('INCOMPLETE: unchecked records remain')

if __name__ == '__main__':
    main()
