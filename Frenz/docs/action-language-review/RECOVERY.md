Recovery del 5 ottobre 2026

I quattro database effettivamente caricati dall'app sono Data/Resources/backupActions_{it,en,es,fr}.json. I record sono identificati tramite JSON pointer; gli indici del report partono da zero. Sono 4.337 record, 17.348 testi. Localizable.strings contiene testi UI, non il database delle azioni.

La revisione precedente non era persa: baseline.json fotografa il working tree all'inizio, comprese modifiche preesistenti. review.json conserva originali, motivazioni e stati per ogni lingua, incluse frasi controllate e lasciate invariate. Nessun commit recente documenta questa revisione: report e modifiche erano non committati.

Alla ripresa, summary.json e database erano aggiornati fino all'indice 1769 (1.770 record); review.json, salvato tre minuti dopo, era arrivato all'indice 1899. Gli indici 1770–1899 contenevano 211 correzioni in CHECKED_MODIFIED, ancora da ricontrollare/applicare. Il primo NOT_CHECKED era 1900, /wouldYouRather/redRoom/75/text. Questo batch sospeso è stato completato prima di passare ai nuovi record.

Fonte dello stato attuale: language_review_progress.json e review.json. I file batch_*.json documentano le decisioni della ripresa. Nessuno stato NOT_CHECKED può essere convertito in controllato senza leggere tutte le lingue. Gli elementi problematici sono in unresolved.json: preservare ambiguità del canonico senza inventare nuove meccaniche.

Comandi da eseguire dalla cartella del progetto:

    python3 docs/action-language-review/batch_tools.py show START END
    python3 docs/action-language-review/batch_tools.py finish batch_START_END.json
    python3 docs/action-language-review/check_and_apply.py

END è esclusivo. Il comando finish aggiorna il checkpoint prima dell'applicazione e dopo il batch. Se l'applicazione fallisce, current_batch segnala il lavoro da recuperare e i database non sono riscritti prima che la validazione globale passi. Le decisioni prefix conservano automaticamente le istruzioni di voto originali; text indica la frase intera. Usare replace solo con coppie di testo esplicitamente controllate. Ogni decisione deve avere un problema concreto e second_pass=true solo dopo confronto originale/correzione.

Gli invarianti controllano numeri e segnaposto. invariant_restorations.json contiene eccezioni individuali motivate per traduzioni già corrotte, con destinatari e quantità recuperati dal canonico. previous_validated_texts conserva versioni applicate poi corrette al secondo controllo e permette di riconoscerle senza accettare modifiche esterne arbitrarie.

Non modificare i file Swift e il progetto Xcode già presenti nel dirty worktree: erano estranei alla revisione. Non usare git restore/reset. Non impostare COMPLETED finché esistono testi non controllati o correzioni senza secondo controllo.

Completamento della ripresa

Su autorizzazione dell'utente, tre agenti hanno revisionato intervalli separati. Solo l'agente principale ha applicato i batch ai database e aggiornato il checkpoint; ogni file agent_*.json documenta i limiti e il secondo controllo. Gli intervalli fuori ordine non implicano record saltati: next_unchecked_index indica sempre il primo vero record mancante.

Il comando finish resta IN_PROGRESS durante la revisione e diventa AWAITING_FINAL_AUDIT quando termina la copertura. COMPLETED viene impostato esclusivamente da finalize_review.py dopo tutti i controlli.

    python3 docs/action-language-review/audit_ambiguities.py
    python3 docs/action-language-review/check_and_apply.py --require-complete --require-applied

Controllo prima del commit

I sette ritocchi tardivi del secondo controllo Dark Room sono stati verificati e integrati tramite batch_precommit_final_recheck.json, mantenendo le battute e distinguendo sentirsi più interessante da rendersi più interessante. I database ridotti possono ricevere soltanto decisioni sparse recheck_only, con gli ID storici del report: il verificatore le applica ai percorsi attuali usando removal_manifest.json. È vietato rielaborare vecchi batch completi o modificare record già rimossi. Audit e checkpoint sono stati rigenerati dopo questo controllo.
    python3 docs/action-language-review/finalize_review.py

final_audit.json documenta il controllo finale. unresolved.json non è una coda di record non letti: contiene ambiguità originali ricontrollate, conservate senza inventare meccaniche o numeri, con disposition e second_pass_reviewed. additional_ambiguities.json registra quelle emerse durante la ripresa. Per modificarne il significato serve una decisione esplicita sul contenuto, non una semplice revisione linguistica.

Le piccole decisioni recheck_only ricontrollano soltanto gli indici indicati in edits/corrections, già revisionati; non rielaborano l'intero intervallo. I segnaposto localizzati della nuova regola sono riconosciuti da ActionTextRenderer, dunque non sono stati uniformati senza necessità.

Eliminazione dei record ambigui, autorizzata dall'utente il 5 ottobre 2026

Tutti i 43 record elencati in unresolved.json sono stati rimossi integralmente dai quattro database (172 testi). Rimangono 4.294 record, già tutti revisionati. Nessun testo conservato è stato modificato da questa operazione. removed_ambiguous_actions.json conserva copie complete dei record rimossi in ogni lingua; removal_manifest.json registra bersagli, checksum e corrispondenza degli ID storici con i percorsi attuali dopo lo spostamento degli indici negli array.

review.json e baseline.json restano lo storico originale, non vengono rinumerati. check_and_apply.py riconosce le rimozioni autorizzate e verifica i record conservati usando la mappa; finalize_review.py aggiorna audit e checkpoint per i 4.294 record attivi. unresolved.json conserva le motivazioni storiche con disposition REMOVED_FROM_DATABASE, non contiene una coda ancora da risolvere. Non rieseguire audit_ambiguities.py o vecchi batch dopo la rimozione.

Verifica attuale:

    python3 docs/action-language-review/check_and_apply.py --require-complete --require-applied
