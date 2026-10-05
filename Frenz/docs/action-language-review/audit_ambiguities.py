"""Record explicitly inspected canonical ambiguities without inventing mechanics."""
import json
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent

def main():
    assert not (HERE / 'removal_manifest.json').exists(), 'Ambiguities have been removed; keep their historical dispositions'
    rows = json.loads((HERE / 'review.json').read_text())
    issues = json.loads((HERE / 'unresolved.json').read_text())
    additions = json.loads((HERE / 'additional_ambiguities.json').read_text())
    for index, explanation in additions:
        row = rows[index]
        existing = next((issue for issue in issues if issue['id'] == row['id']), None)
        if existing is None:
            issues.append(dict(id=row['id'], index=index, issue=explanation,
                               original=row['original']['it']))
    timestamp = datetime.now(timezone.utc).isoformat()
    for issue in issues:
        row = rows[issue['index']]
        assert row['id'] == issue['id']
        assert all(s in ('VALIDATED', 'CHECKED_UNCHANGED') for s in row['status'].values()), issue['id']
        issue.update(disposition='PRESERVED_CANONICAL_AMBIGUITY',
                     second_pass_reviewed=True, reviewed_at=timestamp,
                     resolution='Controllati tutti i testi. Correggere soltanto errori linguistici certi; non risolvere questa ambiguità senza una decisione sul contenuto/meccanica.')
    (HERE / 'unresolved.json').write_text(json.dumps(issues, ensure_ascii=False, indent=2) + '\n')
    print(f'{len(issues)} ambiguità canoniche controllate e preservate.')

if __name__ == '__main__':
    main()
