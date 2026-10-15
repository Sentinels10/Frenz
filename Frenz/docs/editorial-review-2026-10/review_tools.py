"""Resumable selective editorial review. Historical indices never shift.

init: freeze current four databases and record inventory.
show START END: read source Italian for a batch (all four with --all).
apply FILE.json: record a personally inspected batch, reconstruct and validate.
additions: apply the 45 approved new multilingual actions.
verify: verify current databases against decisions and additions, without writing.

Decisions: {start,end,second_pass:true,changes:[{index,action:'edit'|'remove'|'keep',
reason,texts:{it,en,es,fr}}]}. All other inspected records in this batch are kept.
Only root applies. Workers save disjoint decisions files and send their paths.
"""
import collections
import copy
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
LANGS = ('it','en','es','fr')
PATHS = {l: ROOT/'Data'/'Resources'/f'backupActions_{l}.json' for l in LANGS}

def read(name): return json.loads((HERE/name).read_text())
def save(name, obj): (HERE/name).write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n')
def now(): return datetime.now(timezone.utc).isoformat()
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def flatten(x, path=''):
    if isinstance(x,str): yield path,x
    elif isinstance(x,dict):
        for k,v in x.items(): yield from flatten(v,path+'/'+k)
    elif isinstance(x,list):
        for i,v in enumerate(x): yield from flatten(v,path+'/'+str(i))
def locate(doc, path):
    node=doc
    for part in path.split('/')[1:]: node=node[int(part)] if isinstance(node,list) else node[part]
    return node
def set_text(doc, path, text):
    parent,key=path.rsplit('/',1); node=locate(doc,parent)
    node[int(key) if isinstance(node,list) else key]=text

def build(state):
    documents=read('baseline.json'); rows=read('records.json')
    covered=set(); changes={}
    for filename in state['applied_batches']:
        batch=read(filename)
        assert batch['second_pass'] is True
        start,end=batch['start'],batch['end']
        assert 0<=start<end<=len(rows)
        indices=set(range(start,end))
        if batch.get('recheck_only'): indices={c['index'] for c in batch['changes']}
        else: assert not covered & indices, (filename,'overlapping batch')
        covered.update(indices)
        for change in batch['changes']:
            i=change['index']; assert i in indices and change['reason'].strip()
            assert change['action'] in ('edit','remove','keep')
            if change['action']=='keep':
                assert batch.get('recheck_only'), 'Keep overrides require explicit recheck'
                changes.pop(i,None)
                continue
            if change['action']=='edit':
                assert set(change['texts'])==set(LANGS)
                assert any(change['texts'][l]!=rows[i]['texts'][l] for l in LANGS)
                assert all(isinstance(t,str) and t.strip() for t in change['texts'].values())
            changes[i]=change
    targets={}
    for i,change in changes.items():
        row=rows[i]; path=row['id']
        if change['action']=='edit':
            for l in LANGS: set_text(documents[l],path,change['texts'][l])
        else:
            target=path[:-5] if path.endswith('/text') else path
            parent,index=target.rsplit('/',1)
            for l in LANGS:
                assert isinstance(locate(documents[l],parent),list), (path,'not an array action')
                assert len(list(flatten(locate(documents[l],target))))==1
            assert target not in targets
            targets[target]=i
    groups=collections.defaultdict(list)
    for target in targets:
        parent,index=target.rsplit('/',1); groups[parent].append(int(index))
    for l in LANGS:
        for parent,indices in groups.items():
            for i in sorted(indices,reverse=True): locate(documents[l],parent).pop(i)
    additions=read('approved_additions.json') if state['additions_applied'] else []
    assert len({a['proposal_id'] for a in additions})==len(additions)
    for addition in additions:
        assert set(addition['texts'])==set(LANGS)
        assert addition['room'] in ('party','darkRoom','redRoom','coppie')
        for l in LANGS:
            assert addition['texts'][l] not in dict(flatten(documents[l])).values(), addition['proposal_id']
            documents[l][addition['room']].append({'text':addition['texts'][l]})
    paths=[set(dict(flatten(documents[l]))) for l in LANGS]
    assert all(p==paths[0] for p in paths)
    assert len(paths[0])==len(rows)-len(targets)+len(additions)
    return documents,covered,changes,targets,additions

def persist(state):
    documents,covered,changes,targets,additions=build(state)
    # Detect any unrelated concurrent database edits before writing anything.
    assert {l:sha(p) for l,p in PATHS.items()}==state['last_applied_sha256'], 'Concurrent database edit'
    state.update(updated_at=now(),phase='APPLYING')
    save('progress.json',state)
    for l,p in PATHS.items():p.write_text(json.dumps(documents[l],ensure_ascii=False,indent=2)+'\n')
    rows=read('records.json'); remaining=sorted(set(range(len(rows)))-covered)
    state.update(updated_at=now(),phase=None,
        status='AWAITING_FINAL_AUDIT' if not remaining else 'IN_PROGRESS',
        checked_records=len(covered),remaining_records=len(remaining),
        edited_records=sum(c['action']=='edit' for c in changes.values()),
        removed_records=len(targets),kept_records=len(covered)-len(changes),
        active_records=len(rows)-len(targets)+len(additions),added_records=len(additions),
        next_unchecked_index=remaining[0] if remaining else None,
        last_processed_index=max(covered) if covered else None,
        last_processed_id=rows[max(covered)]['id'] if covered else None,
        current_batch=None,problematic_ids=[],
        last_applied_sha256={l:sha(p) for l,p in PATHS.items()})
    save('progress.json',state)
    save('removed_actions.json',[dict(index=i,id=rows[i]['id'],reason=changes[i]['reason'],texts=rows[i]['texts']) for i in targets.values()])
    print(json.dumps({k:state[k] for k in ('status','checked_records','remaining_records','edited_records','removed_records','kept_records','added_records','active_records','next_unchecked_index')},ensure_ascii=False))

def main():
    command=sys.argv[1]
    if command=='init':
        assert not (HERE/'baseline.json').exists()
        documents={l:json.loads(p.read_text()) for l,p in PATHS.items()}
        flats={l:dict(flatten(d)) for l,d in documents.items()}
        assert all(set(f)==set(flats['it']) for f in flats.values())
        rows=[{'index':i,'id':path,'texts':{l:flats[l][path] for l in LANGS}} for i,path in enumerate(flats['it'])]
        save('baseline.json',documents);save('records.json',rows)
        save('progress.json',dict(updated_at=now(),status='IN_PROGRESS',phase=None,
            original_total_records=len(rows),languages=list(LANGS),checked_records=0,
            remaining_records=len(rows),edited_records=0,removed_records=0,kept_records=0,
            active_records=len(rows),added_records=0,additions_applied=False,
            applied_batches=[],next_unchecked_index=0,last_applied_sha256={l:sha(p) for l,p in PATHS.items()},
            resume='Read README.md and progress.json; records.json indices are immutable. Never infer coverage from diffs. Apply only personally read batches.'))
        print(len(rows))
    elif command=='show':
        for r in read('records.json')[int(sys.argv[2]):int(sys.argv[3])]:
            print(r['index'],r['id'],r['texts']['it'])
            if '--all' in sys.argv:
                for l in LANGS[1:]:print(l,r['texts'][l])
    elif command=='apply':
        state=read('progress.json');filename=sys.argv[2]
        assert filename not in state['applied_batches']
        state['applied_batches'].append(filename);persist(state)
    elif command=='additions':
        state=read('progress.json');assert not state['additions_applied']
        assert len(read('approved_additions.json'))==45
        state['additions_applied']=True;persist(state)
    elif command in ('verify','complete'):
        state=read('progress.json');documents,covered,changes,targets,additions=build(state)
        assert state['phase'] is None
        for l,p in PATHS.items():assert json.loads(p.read_text())==documents[l]
        assert state['checked_records']==len(covered)
        assert state['last_applied_sha256']=={l:sha(p) for l,p in PATHS.items()}
        if command=='complete':
            assert len(covered)==state['original_total_records'] and len(additions)==45
            from final_audit import audit
            save('final_audit.json',audit())
            state.update(status='COMPLETED',updated_at=now(),completed_at=now())
            save('progress.json',state)
        print('Valid:',state['status'],state['checked_records'],'reviewed;',state['remaining_records'],'remaining')
    else:raise SystemExit('Unknown command')

if __name__=='__main__':main()
