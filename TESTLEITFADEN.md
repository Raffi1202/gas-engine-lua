# Testleitfaden Gas Engine ECU und Gas Engine Carb / Test guide

Danke fürs Testen. Geh die Fälle der Reihe nach durch und hake ab, was stimmt. Stimmt etwas nicht, melde es als
Issue (unten steht wie). Ein Fall dauert meist eine Minute. Alles geht am Boden, ohne Flug.

*Thank you for testing. Work through the cases in order and tick what is correct. If something is wrong, open an
issue (see the end). Everything can be done on the ground, no flight needed.*

Gilt für Gas Engine ECU **1.8.1** und Gas Engine Carb **0.8.1**. Wo sich die beiden unterscheiden, steht es dabei.

## Was du brauchst / What you need

- [ ] FrSky-Sender mit Ethos 26.1 oder neuer und Farbdisplay. Notiere Sender und Ethos-Version (System › Info).
- [ ] FrSky Suite auf dem Computer oder Zugriff auf die SD-Karte des Senders.
- [ ] Die ZIP zum Teilen aus dem GitHub-Release, entpackt (Anleitung als PDF und Paket für die Suite).
- [ ] Ein Modell mit Telemetrie. Ideal: Motor mit Drehzahl- und Temperatursensor. Ohne Motor reicht ein Empfänger mit RxBatt und RSSI; dann gehen die Fälle zu Motor und Tank nur teilweise.
- [ ] Ein freier Dreistufenschalter (für Aus / Zündung / Choke) und ein freier Zweistufenschalter (für «Stumm»).

## A Installation

| Nr | Schritt | Erwartet | ✓ |
|---|---|---|---|
| A1 | Paket mit der FrSky Suite installieren (Lua-Bibliothek › Von lokaler ZIP installieren), Sender neu starten. | Keine Fehlermeldung. Auf der SD-Karte liegt `scripts/gas_ecu/` bzw. `scripts/gas_carb/` mit `main.lua` und `audio/`. | ☐ |
| A2 | Im Modell mit **DISP** einen Bildschirm im Layout **Vollbild** anlegen, Widget wählen. | Das Widget steht in der Auswahl. Seite 1 erscheint, oben rechts «Motor 1/3». | ☐ |
| A3 | Einen zweiten Bildschirm mit dem Layout **mit Kopf- und Fussleiste** (ein Widget) anlegen und das Widget wählen. | Kompaktansicht: oben eine schmale Leiste (Motorlaufzeit, Zustand, Zündung, Empfang), darunter 4 Ringe (Drehzahl, Zylinder max, Tank, Akku) und 8 Felder. Nichts überlappt, kein Fehlertext. | ☐ |
| A4 | In der Kompaktansicht eine Warnung auslösen (z. B. wie D1). | Die Warnung ersetzt oben die Pillen, der betroffene Ring wird orange bzw. rot. | ☐ |
| A5 | Das Widget in ein noch kleineres Feld setzen (Layout mit mehreren Feldern). | «nur im Vollbild», kein Fehler. | ☐ |

## B Sensoren / Sensors

| Nr | Schritt | Erwartet | ✓ |
|---|---|---|---|
| B1 | Modell › Telemetrie › **Sensoren suchen**, warten, bis alle Sensoren da sind. | Ethos zeigt die Sensoren. | ☐ |
| B2 | Widget lange drücken › **Widget konfigurieren** › **Suchen**. Ein paar Sekunden warten, Menü schliessen. | Auf dem Bildschirm kurz der Hinweis, wie viele Sensoren zugewiesen wurden. Kein Absturz, kein Fehlertext unten links. | ☐ |
| B3 | Menü wieder öffnen. | Passten für ein Feld mehrere Sensoren, steht oben die Zeile «Mehrere Sensoren passen, bitte prüfen:», darunter je Feld Name, Anzahl und «gewählt: …». Nichts überlappt. | ☐ |
| B4 | In den Gruppen nachsehen, ob die Sensoren stimmen (Drehzahl, Zylinder, Akkus, Empfang). Falsche von Hand ändern. | Die Zuweisung lässt sich ändern und bleibt nach Menü schliessen und Sender neu starten. | ☐ |
| B5 | Einen zugewiesenen Sensor in Ethos löschen (Telemetrie), dann im Widget-Menü **Suchen**. | Das Feld wird neu gefüllt oder bleibt leer, es steht nicht mehr «---». | ☐ |

## C Anzeige / Display

| Nr | Schritt | Erwartet | ✓ |
|---|---|---|---|
| C1 | Telemetrie an (Empfänger an). Seite 1 ansehen. | Oben links der Zustand (z. B. «LÄUFT», «WARMLAUF», «KEINE DATEN»), rechts Modellname, Empfang und Seite. Werte statt Striche, wo Sensoren zugewiesen sind. | ☐ |
| C2 | Drehrad nach rechts drehen (oder nach links wischen). | Seite 2 «Elektrik 2/3», dann Seite 3 «Übersicht 3/3». Drehrad links zurück. Der erste Drehrad-Schritt nach dem Laden darf in Ethos das Widget auswählen. | ☐ |
| C3 | Seite 2 mit einem Zellensensor (FLVS) ansehen. | Ein Balken je Zelle mit Wert, unten Δ. Bei 5 oder 6 Zellen zwei Reihen. | ☐ |
| C4 | Seite 2 mit einem reinen Spannungssensor (z. B. RxBatt als Akku 1), «Akku 1 Zellen» auf **automatisch**. | Gesamtspannung, leerer Balken, «Zellenzahl im Menü wählen». | ☐ |
| C5 | «Akku 1 Zellen» auf die richtige Zahl stellen. | Balken der mittleren Zelle, darunter «Ø x,xx V je Zelle». | ☐ |
| C6 | «Akku 1 Art» von LiPo auf LiFe stellen. | Im Menü stehen sofort die LiFe-Grenzen (3,10 / 2,90 V), der Balken passt die Skala an. | ☐ |
| C7 | Empfänger aus. | Nach kurzer Zeit «TELEMETRIE WEG» und Ansage «Achtung! Telemetrie verloren». Empfänger an: «Telemetrie wieder da». | ☐ |

## D Warnungen und Ansagen / Warnings and voice

| Nr | Schritt | Erwartet | ✓ |
|---|---|---|---|
| D1 | Eine Grenze so stellen, dass sie sicher anspricht, z. B. «Akku 1 Zelle Warnung unter» über die aktuelle Zellspannung. | Akku orange, Meldezeile orange, Ansage «… Spannung tief», danach der Wert. Wiederholung nach «Wiederholung alle». | ☐ |
| D2 | Ebenso «… Alarm unter» über die Zellspannung. | Rot, Ansage «Achtung! … fast leer», Vibration (wenn «Vibration bei Alarm» an). | ☐ |
| D3 | Grenzen zurückstellen. | Farbe und Ansagen hören auf. | ☐ |
| D4 | «Stumm (Schalter)» zuweisen und umlegen. | «Ansagen aus», danach keine Ansagen, Farben bleiben. Zurück: «Ansagen ein». | ☐ |
| D5 | Menü › Anzeige › «Sprache / Language» auf **English**. | Anzeige, Menü (nach neu Öffnen) und Ansagen englisch, Zahlen mit Punkt. Zurück auf «wie Sender». | ☐ |
| D6 | Mit Stromweiche (RB): «Zustand Empfänger (RB State)» und «Zustand Kanäle (RB Ch. State)» zuweisen, einen Empfänger an der RB abziehen. | Alarm «STROMWEICHE FEHLER», Ansage. Wieder anstecken: Alarm weg. | ☐ |

## E Motor, Tank und Flüge / Engine, tank and flights

| Nr | Schritt | Erwartet | ✓ |
|---|---|---|---|
| E1 | «Motorschalter (3 Stufen)», «Stellung Aus (Kill)» und «Stellung Choke» einstellen. Schalter durchschalten. | Oben «ZÜNDUNG EIN» bzw. «CHOKE», bei Aus nichts. | ☐ |
| E2 | Motorschalter von Aus auf Zündung. | Ein Flug beginnt (Seite 3 rechts «Flug n läuft»). | ☐ |
| E3 | Motorschalter auf Aus. | Rückfrage «Flug beendet?». **JA, BEENDET**: Ansage «Flug gespeichert», Flug in der Liste. Nochmals mit **NEIN, NUR PAUSE**: «Flug pausiert». | ☐ |
| E4 | Seite 3: einen Flug antippen. | Fenster mit den Werten des Flugs. **FLUG n LÖSCHEN** löscht nach Rückfrage nur diesen Flug, die Nummern rücken nach. | ☐ |
| E5 | **ÜBERSICHT ZURÜCKSETZEN** › Ja. | Ansage «Übersicht zurückgesetzt», Liste und Höchstwerte leer, Tank unverändert. | ☐ |
| E6 | «Tankinhalt» setzen, auf Seite 1 **VOLLGETANKT** › **JA, VOLLGETANKT**. | Ansage «Tank auf voll gesetzt», Tank 100 %, Verbrauch 0. | ☐ |
| E7 | Mit laufendem Motor (falls möglich): Drehzahl, Zylinder, Durchfluss beobachten. | Werte plausibel, Restzeit erscheint nach etwa 30 s Motorlauf. | ☐ |
| E8 | Sender aus und wieder an. | Einstellungen, Tank und Flugliste sind noch da. | ☐ |
| E9 | Motor läuft (nach der Startsperre). Zylinderunterschied über «Unterschied ab» bringen (z. B. Grenze tief stellen). Dann Motor über den Motorschalter **aus** (Kill). | Mit Motor ein: «ZYL UNGLEICH» samt Ansage. Nach dem Kill bleibt «ZYL UNGLEICH», solange der Unterschied da ist. In den ersten Sekunden nach dem nächsten Anlassen (Startsperre) kommt es nicht. | ☐ |
| E10 | «Alarm Restzeit unter» so hoch stellen, dass er bei laufendem Motor anspricht. Dann Motorschalter **aus**. | Motor ein: «TANK FAST LEER». Motor aus: Restzeit verschwindet, der Alarm geht. Liegt der Tank unter «Alarm unter» (%), kommt «TANK FAST LEER» auch mit Motor aus. | ☐ |
| E11 | Motorschalter auf **Choke**, Motor warm oder Gas über «Choke-Warnung ab Gas». Dann Motor abstellen. | Motor läuft: «CHOKE AUS!». Motor steht: keine Choke-Warnung. | ☐ |
| E12 | Eine Grenze, die sicher anspricht (z. B. wie D1), mit Motorschalter **ein** und **aus**. | Warnung und Ansage kommen in beiden Stellungen. Der Motorschalter schaltet keinen Alarm stumm. | ☐ |
| E13 | Menü › «Alarm auch bei Motor aus»: Haken «Zylinder heiss / warm» **ein**, Motorschalter **aus**, Zylinder über «Alarm über». | Alarm rot, Ansage und Vibration kommen. | ☐ |
| E14 | Wie E13, Haken **aus**, Motorschalter **aus**. | Feld und Meldezeile rot, aber keine Ansage, kein Ton, keine Vibration. | ☐ |
| E15 | Wie E14 (Haken aus), Motorschalter **ein** (Zündung). | Ansage und Vibration kommen wieder. | ☐ |
| E16 | Schalter «alle» aus und wieder ein. | Alle Haken der Gruppe folgen. Nach Modellwechsel bleiben die Haken. | ☐ |
| E17 | Umstieg: alte Version (Motoren ECU / Vergaser) im Modell, neues Paket installieren, Widget im Bildschirm neu wählen. | Das Widget heisst «Gas Engine ECU» bzw. «Gas Engine Carb», Ordner `gas_ecu` / `gas_carb`; «Suchen» weist die Sensoren zu. | ☐ |
| E18 | Nur eine alte Studio-Datei `<Modell>.motoren_ecu.lua` (bzw. `.motoren_vergaser.lua`) auf der SD-Karte, Modell laden. | Die Studio-Ansicht erscheint, im Log steht «old studio file found, please re-transfer». | ☐ |

## F Nur Gas Engine ECU

| Nr | Schritt | Erwartet | ✓ |
|---|---|---|---|
| F1 | Kraftstoffdruck und ECU-Spannung zugewiesen? | Druckbalken auf Seite 1, «ECU x,x V» oben. Druck unter 1,5 bar bei laufendem Motor: Warnung «Spritdruck tief». Motor über den Motorschalter **aus**: keine Spritdruck-Warnung. | ☐ |

## G Lua-Studio (nur wenn du das Lua-Studio hast)

| Nr | Schritt | Erwartet | ✓ |
|---|---|---|---|
| G1 | Im Lua-Studio für das Modell eine Kompaktansicht gestalten, übertragen, Modell neu laden. | Die Kästchen erscheinen wie im Studio, oben bleibt die schmale Leiste. Kein Hinweis unten. | ☐ |
| G2 | Eine Grenze im Studio setzen (z. B. Zylinder max Warnung unter die aktuelle Temperatur). | Kästchen orange, Ansage wie bei der Einstellung. | ☐ |
| G3 | Im Widget-Menü eine Einstellung ändern, Modell neu laden. | Die Änderung bleibt (steht in `….funke.lua`). | ☐ |
| G4 | Menü › **Zurück auf Studio-Stand** › Ja, Modell neu laden. | Wieder der Stand aus dem Studio. | ☐ |
| G5 | Die Studio-Datei auf der SD-Karte mit einem Texteditor kaputt machen (z. B. eine Zeile löschen), Modell neu laden. | Unten 8 s der Hinweis «Studio-Datei kaputt – Standard», danach ein «!» oben rechts; das Widget zeigt die eingebaute Ansicht. | ☐ |

## Fehler melden / Report a problem

1. Auf GitHub im Repo **Issues › New issue › Fehler melden** wählen und das Formular ausfüllen.
2. Immer angeben: Sender, Ethos-Version, Widget und Version (steht oben im Widget-Menü), Nummer des Testfalls, was du getan hast, was du erwartet hast, was passiert ist.
3. **Bildschirmfoto:** In Ethos einem Schalter die Spezialfunktion «Screenshot» geben; das Bild liegt danach auf der SD-Karte im Ordner `screenshots/`. Ein Handyfoto geht auch.
4. **Log:** Sender per USB an die FrSky Suite, dort das **Debug-Log** öffnen und den Text kopieren. Meldungen des Widgets beginnen mit «Gas Engine ECU:» bzw. «Gas Engine Carb:».
5. Ein kleiner roter Text unten links im Widget ist ein Skriptfehler: bitte genau abschreiben oder fotografieren.

Wünsche bitte als **Issues › New issue › Wunsch**.
