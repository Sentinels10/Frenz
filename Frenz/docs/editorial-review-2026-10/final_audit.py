"""Read-only checks; --save writes only the audit report, never the databases."""
import collections
import json
import re
import sys
import review_tools as t


def audit():
    state = t.read('progress.json')
    docs, covered, changes, removed, additions = t.build(state)
    rows = t.read('records.json')
    assert covered == set(range(len(rows)))
    assert state['phase'] is None and state['remaining_records'] == 0
    assert state['problematic_ids'] == [] and state['current_batch'] is None
    assert state['last_processed_index'] == len(rows) - 1
    assert state['languages'] == list(t.LANGS)
    assert state['last_applied_sha256'] == {l: t.sha(p) for l, p in t.PATHS.items()}
    for lang, path in t.PATHS.items():
        assert json.loads(path.read_text()) == docs[lang]

    # Independently map original paths to current array positions after deletions.
    groups = collections.defaultdict(list)
    for target in removed:
        parent, index = target.rsplit('/', 1)
        groups[parent].append(int(index))

    def final_path(path):
        for parent, indices in groups.items():
            if path.startswith(parent + '/'):
                tail = path[len(parent) + 1:]
                index, slash, rest = tail.partition('/')
                original = int(index)
                assert original not in indices
                current = original - sum(i < original for i in indices)
                return parent + '/' + str(current) + (slash + rest if slash else '')
        return path

    kept = edited = 0
    for row in rows:
        change = changes.get(row['index'])
        if change and change['action'] == 'remove':
            continue
        expected = change['texts'] if change else row['texts']
        for lang in t.LANGS:
            assert t.locate(docs[lang], final_path(row['id'])) == expected[lang]
        if change:
            edited += 1
            for lang in t.LANGS:
                before, after = row['texts'][lang], expected[lang]
                # No edited record in this phase is intended to change quantities or tokens.
                assert re.findall(r'\d+', before) == re.findall(r'\d+', after)
                pattern = r'\{[^}]+\}|\[[^\]]+\]'
                assert re.findall(pattern, before) == re.findall(pattern, after)
        else:
            kept += 1

    # Exactly the approved proposal IDs, including intentional numbering gaps.
    wanted = {
        **{f'CHILLING-{i:02}': 'party' for i in range(1, 11) if i != 6},
        **{f'DARK-{i:02}': 'darkRoom' for i in range(1, 11) if i != 5},
        **{f'RED-{i:02}': 'redRoom' for i in range(1, 11) if i not in (1, 7)},
        **{f'PARTNER-{i:02}': 'coppie' for i in range(1, 11)},
        **{f'ROULETTE-{i:02}': ('darkRoom' if i == 2 else 'redRoom' if i == 7 else 'party')
           for i in range(1, 11) if i != 5},
    }
    assert len(additions) == 45
    assert {a['proposal_id']: a['room'] for a in additions} == wanted
    for a in additions:
        nums = re.findall(r'\d+', a['texts']['it'])
        for lang in t.LANGS:
            assert a['texts'][lang].strip()
            assert re.findall(r'\d+', a['texts'][lang]) == nums
            assert sum(x['text'] == a['texts'][lang] for x in docs[lang][a['room']]) == 1
            assert a['texts'][lang] not in {r['texts'][lang] for r in rows}

    # Every former pool still exists and remains usable; no structural keys removed.
    baseline = t.read('baseline.json')
    def schema_check(before, after):
        assert type(before) is type(after)
        if isinstance(before, dict):
            assert before.keys() == after.keys()
            for key in before:
                schema_check(before[key], after[key])
        elif isinstance(before, list):
            assert not before or after
            if before:
                for item in after:
                    schema_check(before[0], item)
    for lang in t.LANGS:
        schema_check(baseline[lang], docs[lang])

    counts = {l: len(list(t.flatten(d))) for l, d in docs.items()}
    active = len(rows) - len(removed) + len(additions)
    assert all(n == active for n in counts.values())
    assert len(covered) == state['checked_records'] == len(rows)
    assert kept == state['kept_records']
    assert edited == state['edited_records']
    assert len(removed) == state['removed_records']
    assert active == state['active_records']
    manifest = t.read('removed_actions.json')
    assert {x['index'] for x in manifest} == set(removed.values())
    for item in manifest:
        assert item['texts'] == rows[item['index']]['texts']
    return {
        'checked_at': t.now(), 'result': 'PASS',
        'review_scope': 'Every original Italian record reviewed for editorial fit; all four originals compared for edits. All 45 additions reviewed in four languages.',
        'source_records': len(rows), 'checked_records': len(covered),
        'unchanged_records': kept, 'edited_records': edited,
        'removed_records': len(removed), 'added_records': len(additions),
        'active_records_per_language': counts,
        'added_by_pool': dict(collections.Counter(a['room'] for a in additions)),
        'main_pool_counts': {k: len(docs['it'][k]) for k in ('party','darkRoom','redRoom','coppie','clash')},
        'unresolved_ids': [], 'databases_sha256': state['last_applied_sha256'],
        'checks': ['complete_disjoint_batch_coverage', 'runtime_matches_decisions',
                   'unchanged_texts_preserved_in_four_languages', 'edited_numbers_and_placeholders_preserved',
                   'approved_ids_and_rooms_exact', 'rejected_proposals_absent',
                   '45_additions_each_present_once_per_language', 'no_exact_addition_duplicates_in_baseline',
                   'same_numeric_tokens_for_added_translations', 'schema_and_nonempty_pools_preserved',
                   'all_removals_recoverable_with_four_originals'],
    }


if __name__ == '__main__':
    report = audit()
    if '--save' in sys.argv:
        t.save('final_audit.json', report)
    print(json.dumps(report, ensure_ascii=False, indent=2))
