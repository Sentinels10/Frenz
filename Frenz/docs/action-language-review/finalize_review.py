"""Finalize only a fully reviewed, validated and applied language review.

Canonical content ambiguities remain documented, never resolved by invention.
Run after all workers finish: python3 docs/action-language-review/finalize_review.py
"""
import collections
import hashlib
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess
import sys
from removal_state import load_manifest

HERE = Path(__file__).resolve().parent

def read(name):
    return json.loads((HERE / name).read_text())

def main():
    result = subprocess.run(
        [sys.executable, str(HERE / 'check_and_apply.py'),
         '--require-complete', '--require-applied'],
        check=True, text=True, capture_output=True)
    summary = json.loads(result.stdout)
    rows = read('review.json')
    historical_rows = rows
    removals = load_manifest()
    removed_ids = set(removals['removed_ids']) if removals else set()
    rows = [r for r in rows if r['id'] not in removed_ids]
    assert summary['complete'] and summary['remaining_entries'] == 0
    assert summary['checked_entries'] == len(rows) == summary['total_entries']
    assert all(all(s in ('VALIDATED', 'CHECKED_UNCHANGED')
                   for s in r['status'].values()) for r in rows)
    progress = read('language_review_progress.json')
    assert progress['current_batch'] is None
    for batch in progress['completed_batches']:
        assert read(batch['decisions'])['second_pass'] is True
    by_id = {row['id']: row for row in historical_rows}
    issues = read('unresolved.json')
    for issue in issues:
        assert issue['id'] in by_id
        assert all(s in ('VALIDATED', 'CHECKED_UNCHANGED')
                   for s in by_id[issue['id']]['status'].values())
        expected_disposition = 'REMOVED_FROM_DATABASE' if issue['id'] in removed_ids else 'PRESERVED_CANONICAL_AMBIGUITY'
        assert issue.get('disposition') == expected_disposition, issue['id']
        assert issue.get('second_pass_reviewed') is True, issue['id']
    timestamp = datetime.now(timezone.utc).isoformat()
    audit = dict(
        completed_at=timestamp,
        status='COMPLETED',
        summary=summary,
        database_sha256={language: hashlib.sha256((HERE.parent.parent / 'Data' / 'Resources' / f'backupActions_{language}.json').read_bytes()).hexdigest()
                         for language in ('it', 'en', 'es', 'fr')},
        checks={
            'all_records_and_languages_reviewed': True,
            'no_missing_or_duplicate_ids': True,
            'all_validated_revisions_applied': True,
            'originals_preserved_in_report': True,
            'non_text_structure_unchanged': True,
            'numbers_and_placeholders_preserved_or_explicitly_restored': True,
            'all_resume_batches_second_pass_reviewed': True,
            'canonical_ambiguities_reviewed_and_preserved': True,
        },
        content_ambiguities_preserved=[issue['id'] for issue in issues if issue['id'] not in removed_ids],
        note='Revisione linguistica completa. Le ambiguità del contenuto canonico restano documentate: risolverle richiede una decisione sulle meccaniche, fuori dallo scopo della revisione.')
    if removals:
        audit['checks'].pop('non_text_structure_unchanged')
        audit['checks'].pop('canonical_ambiguities_reviewed_and_preserved')
        audit['checks'].update(non_text_structure_unchanged_except_authorized_record_removals=True,
                               canonical_ambiguities_reviewed_and_removed=True)
        audit.update(content_ambiguities_removed=removals['removed_ids'],
            removal_manifest='removal_manifest.json',
            note='Revisione completa. Tutti i record ambigui elencati in unresolved.json sono stati eliminati dai quattro database su richiesta dell’utente; copie recuperabili conservate.')
    (HERE / 'final_audit.json').write_text(json.dumps(audit, ensure_ascii=False, indent=2) + '\n')
    (HERE / 'summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n')
    progress.update(updated_at=timestamp, completed_at=timestamp,
        status='COMPLETED', remaining_records=0, checked_records=len(rows),
        validated_and_applied_records=len(rows), last_checked_index=len(rows)-1,
        last_checked_id=rows[-1]['id'], next_unchecked_index=len(rows), next_unchecked_id=None,
        problematic_ids=[issue['id'] for issue in issues if issue['id'] not in removed_ids],
        modified_records=summary['modified_entries'],
        modified_texts_by_language=summary['modified_texts_by_language'],
        final_audit='final_audit.json',
        resume='Revisione completata: nessun record da riprendere. Consultare final_audit.json e unresolved.json per le sole ambiguità canoniche preservate.')
    if removals:
        progress.update(total_records=len(rows), historical_total_records=len(historical_rows),
            removed_records=len(removed_ids), removed_texts=len(removed_ids)*4,
            index_space='Retained-record count; review.json keeps historical IDs and indices. Use removal_manifest.json retained_id_mapping for current database paths.',
            last_checked_index=len(historical_rows)-1, next_unchecked_index=len(historical_rows),
            resume=f'COMPLETED: nessun record da riprendere. I {len(removed_ids)} record ambigui sono stati eliminati su richiesta; storico e copie conservati in removal_manifest.json e removed_ambiguous_actions.json.')
    (HERE / 'language_review_progress.json').write_text(json.dumps(progress, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(audit, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()
