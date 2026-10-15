# Nuove azioni — 15 ottobre 2026

Richiesta: 50 candidate nuove per Chilling, Dark, Red e Partner (nessuna raccolta Roulette dedicata). Interazioni individuali, a coppie e di gruppo. Partner più malizioso e orientato alla seduzione, con contatto solo concordato, senza penalizzare il rifiuto del contatto. Secondo controllo selettivo: scartare candidate deboli o già presenti, non riempire una quota a tutti i costi.

`baseline.json` fotografa i quattro database prima delle aggiunte. Non modificare né rieseguire i vecchi strumenti di revisione per applicare questa fase: ricostruirebbero il database precedente.

Per ogni pool, `candidates_POOL.json` contiene esattamente50 testi italiani, con ID stabile dato dalla posizione1–50. `review_POOL.json` contiene scarti motivati e conferma del secondo controllo. `translations_POOL.json` contiene EN/ES/FR solo per le candidate approvate. L'italiano non viene copiato a mano nelle traduzioni.

Comandi dalla radice del progetto:

    python3 docs/action-expansion-2026-10-15/manage.py status
    python3 docs/action-expansion-2026-10-15/manage.py similar party
    python3 docs/action-expansion-2026-10-15/manage.py apply party
    python3 docs/action-expansion-2026-10-15/manage.py verify
    python3 docs/action-expansion-2026-10-15/manage.py complete

Applicare un pool solo dopo lettura delle50 candidate, confronto con le più simili nel DB, controllo del mood e secondo confronto delle traduzioni. Ogni apply salva e verifica i quattro database e aggiorna progress.json. Non modificare i file approvati dopo l'applicazione senza analizzare lo stato. In caso di interruzione, leggere progress.json, i file del pool in corso e i checksum; non ripartire da zero. `phase=APPLYING` richiede confrontare runtime/baseline/ricostruzione prima di recuperare un salvataggio interrotto.

Le nuove carte party/darkRoom/redRoom saranno naturalmente disponibili anche al mix Roulette esistente; non vengono generate carte extra per Roulette né modificata la logica dell'app.
