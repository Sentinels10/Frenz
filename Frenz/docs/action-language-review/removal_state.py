"""Map historical review IDs after explicitly authorized array-record removals."""
import copy
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent

def load_manifest():
    path = HERE / 'removal_manifest.json'
    if not path.exists():
        return None
    manifest = json.loads(path.read_text())
    assert manifest['status'] == 'APPLIED', 'Removal is incomplete; recover it before reviewing'
    return manifest

def prune(document, targets):
    result = copy.deepcopy(document)
    # All authorized targets are array elements. Descending indices avoid shifts.
    groups = {}
    for pointer in targets:
        parent, index = pointer.rsplit('/', 1)
        groups.setdefault(parent, []).append(int(index))
    for parent, indices in groups.items():
        node = result
        for part in parent.split('/')[1:]:
            node = node[int(part)] if isinstance(node, list) else node[part]
        assert isinstance(node, list)
        for index in sorted(indices, reverse=True):
            node.pop(index)
    return result

def remap(pointer, targets):
    parts = pointer.split('/')[1:]
    translated = []
    for depth, part in enumerate(parts):
        parent = '/' + '/'.join(parts[:depth])
        removed = [int(t.rsplit('/', 1)[1]) for t in targets if t.rsplit('/', 1)[0] == parent]
        translated.append(str(int(part) - sum(i < int(part) for i in removed)) if removed else part)
    return '/' + '/'.join(translated)
