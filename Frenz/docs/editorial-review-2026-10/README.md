# Revisione editoriale selettiva, 15 ottobre 2026

Richiesta: aggiungere le 45 proposte approvate e tradurle in IT/EN/ES/FR; ricontrollare tutte le azioni esistenti per chiarezza, divertimento e coerenza con la stanza. Non riscrivere le azioni valide. Questa è una nuova revisione editoriale, successiva alla revisione linguistica di ottobre 5 e alla rimozione autorizzata di 43 ambiguità. Non ripristinare contenuti rimossi.

Il baseline di questa fase contiene esattamente il database trovato il 15 ottobre; records.json conserva gli indici immutabili e i quattro originali. Il checkpoint progress.json registra ogni batch effettivamente letto, anche se lasciato invariato. Le decisioni motivano ogni modifica o rimozione. removed_actions.json rende recuperabili le rimozioni; nessun file storico precedente va sovrascritto per far quadrare gli indici.

Mood: Chilling/party leggero e sociale; Dark Room confessioni, drama, segreti; Red Room piccante, provocante e consensuale; Partner complicità e pepe; Clash sfide. Roulette usa già il mix party/redRoom/darkRoom: le nove proposte approvate per Roulette vengono assegnate a queste raccolte, senza duplicarle né creare una nuova chiave.

Metodo: leggere ogni azione italiana nel suo contesto di stanza/minigioco. Conservare se comprensibile e giocabile, anche se non del proprio gusto; correggere solo problemi concreti. Rimuovere elementi irrecuperabili, meccaniche poco sensate, rischi sproporzionati per un party game, contenuti fuori mood o veri doppioni. Non eliminare in massa per parole chiave. Se si modifica un'azione, confrontare tutti e quattro i testi originali e fornire le quattro versioni, poi fare il secondo controllo. Numeri, ruoli, condizioni e segnaposto vanno conservati salvo ragione esplicita della riparazione editoriale. Testi di interfaccia e regole strutturali vanno mantenuti se funzionano.

Decisioni: {"start":0,"end":100,"second_pass":true,"changes":[{"index":5,"action":"edit","reason":"Problema concreto","texts":{"it":"…","en":"…","es":"…","fr":"…"}},{"index":12,"action":"remove","reason":"Problema concreto"}]}. Gli altri record del batch letto sono KEEP. Non segnare second_pass prima del confronto. I lavoratori scrivono soltanto file di decisioni separati; solo root applica e aggiorna i database.

Comandi dalla radice Frenz:

    python3 docs/editorial-review-2026-10/review_tools.py show START END
    python3 docs/editorial-review-2026-10/review_tools.py show START END --all
    python3 docs/editorial-review-2026-10/review_tools.py apply FILE.json
    python3 docs/editorial-review-2026-10/review_tools.py verify

Con indici non contigui lavorati in parallelo, next_unchecked_index è sempre il primo buco reale. Non ripartire dall'inizio. I database sono ricostruiti dal baseline e dalle decisioni cumulative, eliminando elementi dagli array in ordine decrescente e aggiungendo le nuove azioni alla fine; così gli ID dei batch non slittano. Verifica anti-modifiche concorrenti tramite checksum prima di ogni salvataggio. Se phase=APPLYING, confrontare i file con build(state) e con last_applied_sha256 prima di recuperare: non sovrascrivere modifiche estranee.

Proposte escluse: CHILLING-06, DARK-05, RED-01, RED-07, ROULETTE-05. approved_additions.json mantiene stanza richiesta e numerazione originaria delle altre 45. Non modificarne l'italiano approvato per gusto stilistico.

COMPLETED solo dopo 4.294 record originali controllati, 45 aggiunte, tutti i batch ricontrollati e verifica finale riuscita. La precedente cartella action-language-review resta uno storico del database prima di questa fase, e il suo vecchio comando di validazione non descrive più il database aggiornato.

Secondo controllo conclusivo: final_recheck.json conserva anche azioni inizialmente candidate alla rimozione quando il motivo non è sufficientemente netto. Le decisioni con action=keep sono ammesse solo nei batch recheck_only e annullano la precedente decisione sul medesimo indice; non modificare retroattivamente batch già applicati. Il record2477 è stato conservato prima dell'applicazione perché la confessione senza obbligo di nominare la persona non è identica alla versione con tale obbligo.

Verifica ripetibile (sola lettura, salvo --save che salva il report):

    python3 docs/editorial-review-2026-10/final_audit.py
    python3 docs/editorial-review-2026-10/review_tools.py complete

Il comando complete esegue anche l'audit: copertura, testi KEEP identici nelle quattro lingue, numeri e segnaposto delle modifiche, esattamente45ID approvati, esclusione dei5rifiutati, schema e raccolte non vuote, backup delle rimozioni. final_audit.json fotografa i conteggi e i checksum effettivi. L'assenza di duplicati esatti delle aggiunte è verificata automaticamente; il controllo delle affinità lessicali con le azioni precedenti è stato letto manualmente e non ha trovato equivalenti della stessa scena e meccanica.

Ambito linguistico di questa fase: revisione editoriale di ogni testo italiano nel contesto della stanza; confronto delle quattro lingue per ogni modifica, traduzione e secondo controllo delle45 aggiunte nelle quattro lingue. Non è una nuova dichiarazione di rilettura integrale di tutte le traduzioni lasciate invariate, già oggetto della precedente revisione linguistica.
