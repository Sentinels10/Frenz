"""Add-only, resumable multilingual expansion. Never rewrite existing cards."""
import collections
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import sys
import unicodedata

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
LANGS = ('it', 'en', 'es', 'fr')
POOLS = ('party', 'darkRoom', 'redRoom', 'coppie')
PATHS = {l: ROOT/'Data'/'Resources'/f'backupActions_{l}.json' for l in LANGS}
def read(name): return json.loads((HERE/name).read_text())
def save(name, x): (HERE/name).write_text(json.dumps(x, ensure_ascii=False, indent=2)+'\n')
def now(): return datetime.now(timezone.utc).isoformat()
def hashes(): return {l: hashlib.sha256(p.read_bytes()).hexdigest() for l,p in PATHS.items()}
def flat(x):
    if isinstance(x,str): yield x
    elif isinstance(x,dict):
        for v in x.values(): yield from flat(v)
    elif isinstance(x,list):
        for v in x: yield from flat(v)
def norm(t): return ' '.join(re.findall(r'\w+',unicodedata.normalize('NFKC',t).casefold()))
def bundle(pool):
    candidates = read(f'candidates_{pool}.json')
    review = read(f'review_{pool}.json')
    translations = read(f'translations_{pool}.json')
    assert len(candidates)==50 and all(t.strip() for t in candidates)
    assert review['second_pass'] is True and review['reviewed_candidates']==50
    ids = {str(i) for i in range(1,51)}
    rejected = review['rejected']
    assert set(rejected)<=ids and all(rejected.values())
    assert set(translations)==ids-set(rejected)
    result=[]
    for i,it in enumerate(candidates,1):
        key=str(i)
        if key in rejected: continue
        assert set(translations[key])==set(LANGS)-{'it'}
        texts={'it':it,**translations[key]}
        for lang,text in texts.items():
            assert isinstance(text,str) and text.strip()
            assert re.findall(r'\d+',text)==re.findall(r'\d+',it),(pool,i,lang,'numbers')
            assert re.findall(r'\{[^}]+\}|\[[^\]]+\]',text)==re.findall(r'\{[^}]+\}|\[[^\]]+\]',it)
        result.append({'id':f'{pool}-{i:02}','texts':texts})
    return result,rejected
def build(state):
    docs=read('baseline.json'); manifest=[]
    seen={l:{norm(t) for t in flat(d)} for l,d in docs.items()}
    for pool in state['applied_pools']:
        items,_=bundle(pool)
        for item in items:
            for l,t in item['texts'].items():
                assert norm(t) not in seen[l],(item['id'],l,'duplicate')
                seen[l].add(norm(t));docs[l][pool].append({'text':t})
            manifest.append({'pool':pool,**item})
    return docs,manifest
def stats(state):
    info={}
    for p in POOLS:
        generated=len(read(f'candidates_{p}.json')) if (HERE/f'candidates_{p}.json').exists() else 0
        review=read(f'review_{p}.json') if (HERE/f'review_{p}.json').exists() else {}
        info[p]={'generated':generated,'reviewed':review.get('reviewed_candidates',0),
                 'rejected':len(review.get('rejected',{})),
                 'translated':len(read(f'translations_{p}.json')) if (HERE/f'translations_{p}.json').exists() else 0,
                 'applied':p in state['applied_pools']}
    state.update(updated_at=now(),pools=info,next_pool=next((p for p in POOLS if p not in state['applied_pools']),None))
    state.update(generated_candidates=sum(v['generated'] for v in info.values()),
                 reviewed_candidates=sum(v['reviewed'] for v in info.values()),
                 rejected_candidates=sum(v['rejected'] for v in info.values()),
                 active_records_per_language=state['original_records']+state.get('added_records',0))
    return state
def verify(state):
    docs,manifest=build(state);base=read('baseline.json')
    assert state['phase'] is None and hashes()==state['last_applied_sha256']
    for l,p in PATHS.items():
        actual=json.loads(p.read_text());assert actual==docs[l]
        assert actual.keys()==base[l].keys()
        for k in base[l]:
            if k in POOLS: assert actual[k][:len(base[l][k])]==base[l][k]
            else: assert actual[k]==base[l][k]
    counts={l:len(list(flat(d))) for l,d in docs.items()}
    assert len(set(counts.values()))==1
    return {'result':'PASS','checked_at':now(),'original_records':state['original_records'],
            'added':len(manifest),'active_records_per_language':counts,
            'per_pool':{p:len(docs['it'][p])-len(base['it'][p]) for p in POOLS},
            'existing_content_unchanged':True,'sha256':hashes()}
def main():
    cmd=sys.argv[1]
    if cmd=='init':
        assert not (HERE/'baseline.json').exists()
        docs={l:json.loads(p.read_text()) for l,p in PATHS.items()};save('baseline.json',docs)
        save('progress.json',stats({'status':'IN_PROGRESS','phase':None,'languages':list(LANGS),
             'original_records':len(list(flat(docs['it']))),'target_candidates':200,'applied_pools':[],
             'last_applied_sha256':hashes(),'problematic_ids':[]}))
    elif cmd=='status':
        state=stats(read('progress.json'));save('progress.json',state);print(json.dumps(state,ensure_ascii=False))
    elif cmd=='similar':
        pool=sys.argv[2];assert pool in POOLS
        stop=set('penalità penalita oppure ricevi paga distribuisci secondi tutti hai una uno che con come per alla alle della delle dalla nel del dei gli chi tuo tua tuoi tue suo sua più meno fare fatto passi finisci senza scegli giocatore gruppo devi deve puoi avere solo anche non sul così fai se si di da il lo le la i e o a un al in ti te fa ogni una quello quella cui questo mentre durante entro prima dopo'.split())
        old=list(flat(read('baseline.json')['it'])); tokens=lambda s:set(re.findall(r'\w+',s.lower()))-stop
        sets=[tokens(t) for t in old]
        for i,t in enumerate(read(f'candidates_{pool}.json'),1):
            ts=tokens(t); ranked=sorted(range(len(old)),key=lambda j:len(ts&sets[j])/max(1,len(ts|sets[j])),reverse=True)[:2]
            print(i,t)
            for j in ranked: print('  ~',old[j])
    elif cmd=='apply':
        pool=sys.argv[2];assert pool in POOLS
        state=read('progress.json');assert pool not in state['applied_pools']
        assert hashes()==state['last_applied_sha256'] and state['phase'] is None
        state['applied_pools'].append(pool);docs,manifest=build(state)
        state.update(phase='APPLYING',current_pool=pool,updated_at=now());save('progress.json',state)
        for l,p in PATHS.items():p.write_text(json.dumps(docs[l],ensure_ascii=False,indent=2)+'\n')
        state.update(phase=None,current_pool=None,last_applied_sha256=hashes(),added_records=len(manifest))
        state=stats(state);save('progress.json',state);save('added_manifest.json',manifest)
        save('validation.json',verify(state));print(json.dumps(state['pools'],ensure_ascii=False))
    elif cmd in ('verify','complete'):
        state=read('progress.json');report=verify(state)
        if cmd=='complete':
            assert set(state['applied_pools'])==set(POOLS)
            assert sum(len(read(f'candidates_{p}.json')) for p in POOLS)==200
            assert read('added_manifest.json')==build(state)[1]
            state=stats(state);state.update(status='COMPLETED',completed_at=now())
            save('validation.json',report);save('progress.json',state)
        print(json.dumps(report,ensure_ascii=False,indent=2))
    else: raise SystemExit('Unknown command')
if __name__=='__main__':main()
