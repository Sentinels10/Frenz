"""Remove only unresolved records authorized by the user; save recoverable copies."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import sys

from removal_state import prune, remap
from check_and_apply import flatten

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
LANGUAGES = ('it', 'en', 'es', 'fr')

def save(name, data):
    (HERE / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')

def get(document, pointer):
    node = document
    for part in pointer.split('/')[1:]:
        node = node[int(part)] if isinstance(node, list) else node[part]
    return node

def main():
    assert not (HERE / 'removal_manifest.json').exists(), 'Already removed or removal interrupted: inspect manifest first'
    subprocess.run([sys.executable, str(HERE / 'check_and_apply.py'), '--require-complete', '--require-applied'], check=True, capture_output=True)
    issues = json.loads((HERE / 'unresolved.json').read_text())
    ids = [issue['id'] for issue in issues]
    assert len(ids) == len(set(ids)) and ids
    targets = [p[:-5] if p.endswith('/text') else p for p in ids]
    assert len(set(targets)) == len(ids)
    paths = {l: ROOT / 'Data' / 'Resources' / f'backupActions_{l}.json' for l in LANGUAGES}
    before = {l: json.loads(p.read_text()) for l, p in paths.items()}
    records = []
    for issue, target in zip(issues, targets):
        parent, index = target.rsplit('/', 1)
        for l in LANGUAGES:
            assert isinstance(get(before[l], parent), list)
            assert isinstance(get(before[l], issue['id']), str)
            assert len(list(flatten(get(before[l], target)))) == 1, (target, 'would remove extra text')
        records.append(dict(historical_id=issue['id'], historical_index=issue['index'],
                            target=target, issue=issue['issue'],
                            records_by_language={l: get(before[l], target) for l in LANGUAGES}))
    after = {l: prune(document, targets) for l, document in before.items()}
    retained_mapping = {}
    for l in LANGUAGES:
        old = dict(flatten(before[l]))
        expected = {remap(p, targets): text for p, text in old.items() if p not in ids}
        assert dict(flatten(after[l])) == expected, (l, 'retained text changed')
        assert len(old) - len(expected) == len(ids)
        retained_mapping = {p: remap(p, targets) for p in old if p not in ids}
    serialized = {l: json.dumps(after[l], ensure_ascii=False, indent=2) + '\n' for l in LANGUAGES}
    timestamp = datetime.now(timezone.utc).isoformat()
    manifest = dict(status='PREPARED', created_at=timestamp,
        authorization='User requested deletion of every entry listed in unresolved.json.',
        removed_record_count=len(ids), removed_text_count=len(ids)*len(LANGUAGES),
        removed_ids=ids, targets=targets, retained_id_mapping=retained_mapping,
        remaining_records=len(retained_mapping), backup='removed_ambiguous_actions.json',
        before_sha256={l: hashlib.sha256(paths[l].read_bytes()).hexdigest() for l in LANGUAGES},
        after_sha256={l: hashlib.sha256(serialized[l].encode()).hexdigest() for l in LANGUAGES})
    save('removed_ambiguous_actions.json', dict(created_at=timestamp, records=records,
         recovery='Insert each saved record back into its parent array in ascending historical index order, in each language. Original paths and complete records are preserved here.'))
    save('removal_manifest.json', manifest)
    for l in LANGUAGES:
        paths[l].write_text(serialized[l])
    for issue in issues:
        issue.update(disposition='REMOVED_FROM_DATABASE', removed_at=timestamp,
                     resolution='Record eliminato in tutte le lingue su richiesta esplicita dell’utente. Copia in removed_ambiguous_actions.json.')
    save('unresolved.json', issues)
    manifest.update(status='APPLIED', applied_at=datetime.now(timezone.utc).isoformat())
    save('removal_manifest.json', manifest)
    print(f'Removed {len(ids)} records in all four languages; {len(retained_mapping)} retained, unchanged.')

if __name__ == '__main__':
    main()
