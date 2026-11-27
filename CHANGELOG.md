# Changelog

Older entries (before ECU 1.9.0 / Vergaser 0.9.0) in German.

## Gas Engine ECU 1.14.0 / Gas Engine Carb 0.14.0 – 27.11.2026 (pre-release)
- **Up to 5 cylinders:** «Number of cylinders» 1 to 5, new sensor field **«Cylinder 5 temp.»** (DE «Zylinder 5 Temp.») directly below «Cylinder 4 temp.». Cylinder 5 works like the others: warning and alarm with voice announcements (`zyl5_heiss`, `zyl5_alarm`, German and English), «Diff | max», cylinder difference, choke warning, cold display, trend arrow, overview and flight list, sensor search, Lua-Studio value `cht5`.
- Page 1 draws 5 bars as before (narrower). Temperature and trend arrow get a font that fits the column; on very narrow columns (e.g. 480×272) the «°» is left out so the numbers do not touch.
- Storage: the new source is stored at the end, storage FORMAT +1 (ECU 8, Carb 7). Updating from 1.13.1 / 0.13.1 keeps every sensor, setting and the Studio layout choice; «Number of cylinders» stays as stored.
- Fewer Lua commands per picture on page 1: the font size of the temperatures is measured once per window size, numbers without letters (e.g. «128°») skip the translator, and with 4 or 5 cylinders the bars are drawn as plain rectangles. Fixes paint above the limit with 4 cylinders assigned (up to 10,531 before, Mac count).
- Command counts (Mac, 3 seeds × 20,000 calls, page 1 fixed to 4 resp. 5 cylinders): ECU paint at most 8,956 (4) / 9,615 (5), Carb at most 8,924 (4) / 9,680 (5); wakeup at most 4,736.
- Fixed: page 2 could stop drawing when it was painted before the first reading (cell count still empty); found by the random test.
- German announcements for cylinders 1 and 2 are now pronounced like those for cylinders 3 to 5.

## Gas Engine ECU 1.13.1 / Gas Engine Carb 0.13.1 – 24.11.2026 (pre-release)
- New setting **«Reverse throttle»** (DE «Gas umkehren»), yes/no, off by default, in the menu directly below «Throttle (channel)». For pilots who fly throttle reverse (full throttle = stick back): throttle % = 100 − channel %. Applies everywhere the throttle is used: throttle bar, compact view, the choke warning «from throttle» and the Lua-Studio value `lua:gas`. Lua-Studio key `gas_inv`.
- Stored by name in the settings file; no new source, storage FORMAT unchanged. Updating from 1.13.0 / 0.13.0 keeps every setting, «Reverse throttle» is off afterwards.
- Command counts (Mac, random test, 3 seeds × 20,000 calls): ECU wakeup at most 4,204, paint at most 8,611. Carb wakeup at most 4,147, paint at most 8,495 in two seeds.
- Known (the code path is older than «Reverse throttle»; the changed random sequence now hit it): in one Carb random-test seed one paint reached 10,210 Lua commands (limit 10,000). Path: English display, page 2 with the tow question open, first picture right after switching the language, when every text is translated once. Not seen on the radio; to be fixed in a later version.

## Gas Engine ECU 1.13.0 / Gas Engine Carb 0.13.0 – 22.11.2026 (pre-release)
- One layout for all models: a Lua-Studio file named `Standard.gas_ecu.lua` / `Standard.gas_carb.lua` (same three places as before) is used by every model without its own file. Order: choice in the widget menu › file of the model › `Standard` file › built-in display.
- Widget menu «Studio layout»: entry «Default (all models)» (DE «Standard (alle Modelle)»); «automatic» shows «(default)» when the Standard file is in use.
- Changes made on the radio stay per model (`<model>.gas_ecu.funke.lua`), also with the Standard layout. Info file: `studioWahl` = `"standard"`, `studioQuelle` = path of the Standard file.
- A model named «Standard» uses the file as its own model file. No new storage field, no FORMAT change; update without loss.
- README and wiki: versions, test status (radio: ECU 1.11 / 1.12.3, Carb 0.12.5), X18RS is 800×480, X20 scripts may be in the internal memory, no more «symbols» in Lua-Studio.
- Command limits: wakeup at most 4,096, paint at most 9,151 (Mac count, 3 seeds × 20,000 calls).

## Gas Engine ECU 1.12.5 / Gas Engine Carb 0.12.5 – 22.11.2026 (pre-release)
- After the settings are read (start, model change, update), the widget searches the sensors once by itself as soon as telemetry is running, 5 s after reading. It fills only empty or invalid fields (e.g. «---» after an update or a sensor rediscovery); assigned sensors stay untouched. If sensors were assigned it shows «n sensors newly assigned» and marks the model as changed; otherwise nothing is shown.
- Sensor list in the menu: the sensor ID is shown only for whole-number IDs (a non-integer value caused a caught error in the menu; seen in the random test only).
- Command limits unchanged: wakeup at most 4,379, paint at most 9,151 (Mac count, 3 seeds × 20,000 calls).

## Gas Engine ECU 1.12.4 / Gas Engine Carb 0.12.4 – 22.11.2026 (pre-release)
- Full screen: the Studio note now appears in the header line in place of the model name (orange) instead of a band over the field titles. In the compact view it stays in the widget's own top bar.

## Gas Engine ECU 1.12.3 / Gas Engine Carb 0.12.3 – 22.11.2026 (pre-release)
Findings from the transmitter test (X18RS):
- The info file now lists the telemetry sensors on the transmitter: the sensor list is read with `system.getSources(CATEGORY_TELEMETRY_SENSOR)` (number form). The table form returned an empty list on the X18RS, so Lua-Studio's quick test reported «keineSensoren». The same fix applies to sensors chosen in a Studio file.
- The info file is updated again once the widget has been drawn in a new window size (`fenster` no longer stays empty).
- A newly added widget writes the info file without reloading the model.
- Command limits: while a sensor search or the Studio steps after a model change run (a few calls), reading and warnings pause for that call; every wakeup stays below 5,000 (Mac count: at most 4,280), every paint below 10,000 (at most 9,011).

## Gas Engine ECU 1.12.2 / Gas Engine Carb 0.12.2 – 22.11.2026 (pre-release)
- Command limits: every wakeup now stays below 5,000 Lua commands, every paint below 10,000 (Mac count with the random test, 3 seeds × 5,000 calls; before: wakeup up to 9,274 ECU / 10,166 Carb).
  - Writing the settings file runs in two calls of its own (load and index, then write); these calls do nothing else.
  - The info file for Lua-Studio collects 10 sensors per call (was 20).
  - During a sensor-search step (a few calls) reading values and warnings pause for that call.
- Removed the «Known» note about command counts from 1.12.1.

## Gas Engine ECU 1.12.1 / Gas Engine Carb 0.12.1 – 22.11.2026 (pre-release)
- The Studio note («Studio: view 800x480 adjusted», «Studio: file faulty …») now appears in the widget's own status/message line at the top instead of a band at the bottom, so it never covers values.
- A tank place (`lua:tank_proz`, `lua:tank_ml`, `lua:restzeit`) without a tank capacity shows «No tank capacity» instead of an empty bar. With a Studio file, settings such as the tank capacity come from the Studio file only.
- Grammar: «1 sensor newly assigned» / «n sensors …» (German and English).

## Gas Engine ECU 1.12.0 / Gas Engine Carb 0.12.0 – 22.11.2026 (pre-release)
- **Studio layout is always found** (Lua-Studio issue #1):
  - The widget looks for the studio file in `SCRIPTS:/studio/`, then `SD:/scripts/studio/`, then `RADIO:/scripts/studio/` (the same folder under two names counts once). Changes made on the radio (`.funke.lua`) and the info file stay in `SCRIPTS:/studio/`.
  - New menu entry **«Studio layout»**: lists every `*.gas_ecu.lua` / `*.gas_carb.lua` of the three places (without `.funke.lua`) with the place in brackets, plus «automatic (model name)». Use it when the file name does not match the model name. An explicit choice wins over the file with the model name. The choice is stored at the end of the widget storage (format +1); updating from the previous version keeps all sensors, the choice starts at «automatic».
  - **Window size:** if no view matches the window exactly, the view with the closest aspect ratio (on a tie the larger one) is scaled to the free area below the widget's own header. Boxes that get too small for their display type are drawn as a number, boxes too small even for that are left out and counted in the note. Scaling is done once per window size.
  - **Feedback:** if the default display is shown although a file was found or chosen, a line at the bottom tells why («Studio: file faulty (…)», «Studio: no matching view»). A scaled view shows «Studio: view 800x480 adapted» for 5 s.
  - Info file: new fields at the end `studioQuelle`, `studioWahl`, `ansichtGenutzt`, `angepasst`, `hinweis`.
  - A newly added widget (nothing stored yet) now loads its studio file right away; before it waited for the next model load.
- **Fix:** closing the widget menu could log «Error in menue: true» and show the red error mark (since 1.11.0 / 0.11.0 seen in the simulator); a source field now only receives real sources.
- Unchanged: studio file formats 1/2, «no switch-off without `aus`», `beiMotorAus`, freeing memory, announcements and alarms.

## Gas Engine ECU 1.11.0 / Gas Engine Carb 0.11.0 – 21.11.2026 (pre-release)
- **Cylinders and tank in your own layout:** two new Lua-Studio display types for a box of a view.
  - `darstellung = "zylinder"` with `w = "lua:cht_max"`: all cylinder columns as on page 1 (temperature, trend arrow, peak mark, «Diff», «max»), same colours and limits. Minimum size 160 × 220 at 800 px width.
  - `darstellung = "tank"` with `w = "lua:tank_proz"`: tank column with %, ml, used, flow, time left and the button REFUELLED (same confirmation and function as page 1). Minimum size 160 × 220.
  - Both reuse the drawing code of page 1 and scale with the box (small boxes leave out «max» and «Flow»). Each type at most once per view; a second one or a non-matching `w` falls back to a number with the «!» note.
  - Also in the compact view (the confirmation of REFUELLED is now drawn there too).
- `studio/*/beschreibung.json`: `zylinder` / `tank` added to the `darstellungen` of `cht_max` / `tank_proz`; new top-level field `darstellungenExtra` with names, descriptions and minimum sizes (`min.b`, `min.h`).
- Backward compatible: studio files without the new types behave as before; older widget versions show such a box as a number. Alarm rules (no switch-off without `aus`, `beiMotorAus`) unchanged.

## Gas Engine ECU 1.10.0 / Gas Engine Carb 0.10.0 – 21.11.2026 (pre-release)
- **Renamed from Motoren ECU / Motoren Vergaser – breaking: old models must re-add the widget; Studio files must be renamed or re-transferred.**
  - New names: **Gas Engine ECU** (folder `SD:/scripts/gas_ecu/`, widget key `gasecu`) and **Gas Engine Carb** (folder `SD:/scripts/gas_carb/`, widget key `gascarb`). Repository: `gas-engine-lua`.
  - Ethos stores a widget by its key, so after installing the new version choose the widget again on the model's screen. Settings, tank and flight list of the old version are not taken over (they stay in the old folder `motoren_ecu/daten/` or `motoren_vergaser/daten/`); assign the sensors again with «Search».
  - Settings, tank and flight list live in `daten/<model>.txt` in the script folder. On first start the new widget reads `SCRIPTS:/motoren_ecu/daten/…` or `SCRIPTS:/motoren_vergaser/daten/…` if its own file is missing (read only, the old folder is never changed); to be safe, copy the folder `daten/` from the old to the new script folder before the change.
  - Lua-Studio files: `<model>.gas_ecu.lua` / `<model>.gas_carb.lua`. If only an old file (`<model>.motoren_ecu.lua` / `<model>.motoren_vergaser.lua`) exists, the widget reads it and writes «old studio file found, please re-transfer» to the log. Menu changes then go to the new `.funke.lua`.
  - Packages: `Gas-Engine-ECU-1.10.0.zip`, `Gas-Engine-Carb-0.10.0.zip`; share ZIPs `…-share.zip`. Remove the old folders `motoren_ecu` / `motoren_vergaser` after the change.
- Contains everything from ECU 1.9.0 / Vergaser 0.9.0 below (not released separately).

## Motoren ECU 1.9.0 / Motoren Vergaser 0.9.0 – 21.11.2026 (not released separately)
- **Alarm also with motor off** (Lua-Studio format 2 §3.5, `beiMotorAus`): new menu group «Alarm also with motor off» with a switch «all» and one tick per limit alarm (default on). Without the tick, only tone, announcement and vibration of that alarm are silent while the motor switch is at Off; the display keeps its colour. ENGINE OFF, POWER SWITCH FAULT, TELEMETRY LOST and CHOKE OFF! always come. Read from the studio file (`beiMotorAus = false`) and from `.funke.lua` (`true` overrides a `false` of the studio file); menu changes go into `.funke.lua` as `beiMotorAus` of the limit entry.
- **Fix (critical finding from the Heli review):** a studio limit entry without a numeric level (e.g. only `beiMotorAus = false`, only `ansage = false`, or `warnung = false` plus `alarm = false`) switched the alarm off. Now the factory limit applies; an alarm is only silent completely with `aus = true`.
- `beschreibung.json` and the info file carry `"beiMotorAus": true`; the status value `zustand` is marked `"immerAlarm": true`.
- Widget storage FORMAT 6 (ECU) / 5 (Vergaser): sources unchanged, the new yes/no values are stored by name in the data file. Update from 1.8.0 / 0.8.0 keeps all assignments (update test).
- Includes the unreleased 1.8.1 / 0.8.1 changes below. Manual DE/EN: time-left limit only while the engine runs (percent limit always), «ZYL UNGLEICH» also after shutdown.
- Known point: «ZYL UNGLEICH» also comes with the engine stopped and after shutdown, as in 1.8.1 / 0.8.1.
- Vergaser: fuel pressure and ECU voltage limits (set only via a Lua-Studio file, no menu fields) have no «also with motor off» tick and always sound.
- Tests: `test/motor_aus_test.lua` 90 cases (tick on/off × switch off/on, always-alarms, studio entries without level, `.funke.lua`).

## Motoren ECU 1.8.1 – 21.11.2026 (Entwicklungsstand, nicht released)
- Alarme bei stehendem Motor:
  - «ZYL UNGLEICH» kommt jetzt auch bei stehendem Motor, also auch nach dem Abstellen über den Motorschalter. Die Startsperre gilt nur noch in den ersten Sekunden nach dem Anlassen.
  - «SPRITDRUCK TIEF» kommt weiter nur bei laufendem Motor (nach der Startsperre); bei stehendem Motor ist der Druck fachlich tief.
  - Die Tank-Restzeit fällt bei stehendem Motor sofort weg (Anzeige und Grenze «Alarm Restzeit unter»). Die Prozent-Grenze «Tank unter X %» bleibt immer aktiv.
  - «CHOKE AUS!» kommt weiter nur bei laufendem Motor (geprüft, unverändert).
  - Geprüft: Der Motorschalter schaltet keinen Grenzwert-Alarm und keine Ansage stumm.
- Speicher: Ist nach einem Modellwechsel kein Widget dieses Luas mehr da, gibt es Kern, Zeichnen, Seiten, Studio-Teile und Übersetzung frei (über `__gc` am Widget-Objekt, Ethos meldet Widgets kein «close»). Im Simulator 26.2.0 bleiben danach rund 4 KB statt rund 127 KB belegt. Die Studio-Ansicht wird beim Modellwechsel freigegeben und nur bei Bedarf neu geladen.
- Tests: neuer Mac-Test `test/motor_aus_test.lua` (je Meldung Motor ein und Motor aus, beide Widgets), neues Simulator-Szenario `motoraus` (ECU).

## Motoren Vergaser 0.8.1 – 21.11.2026 (Entwicklungsstand, nicht released)
- Alarme bei stehendem Motor:
  - «ZYL UNGLEICH» kommt jetzt auch bei stehendem Motor, also auch nach dem Abstellen über den Motorschalter. Die Startsperre gilt nur noch in den ersten Sekunden nach dem Anlassen.
  - Die Tank-Restzeit fällt bei stehendem Motor sofort weg (Anzeige und Grenze «Alarm Restzeit unter»). Die Prozent-Grenze «Tank unter X %» bleibt immer aktiv.
  - «CHOKE AUS!» kommt weiter nur bei laufendem Motor (geprüft, unverändert).
  - Geprüft: Der Motorschalter schaltet keinen Grenzwert-Alarm und keine Ansage stumm.
- Speicher: Ist nach einem Modellwechsel kein Widget dieses Luas mehr da, gibt es Kern, Zeichnen, Seiten, Studio-Teile und Übersetzung frei (über `__gc` am Widget-Objekt, Ethos meldet Widgets kein «close»). Im Simulator 26.2.0 bleiben danach rund 4 KB statt rund 127 KB belegt. Die Studio-Ansicht wird beim Modellwechsel freigegeben und nur bei Bedarf neu geladen.
- Tests: neuer Mac-Test `test/motor_aus_test.lua` (je Meldung Motor ein und Motor aus, beide Widgets), neues Simulator-Szenario `motoraus` (ECU).

## Motoren ECU 1.8.0 – 20.11.2026
- Neu: **Lua-Studio-Format v1.** Liegt auf der SD-Karte eine Studio-Datei `SCRIPTS:/studio/<Kennung>.<lua>.lua` (Kennung = Modellname, Sonderzeichen als `_`), zeichnet das Widget die Plätze daraus: je Platz Wert, Darstellung (Zahl, Ring, Balken waagrecht/senkrecht, Verlauf, Status), Titel, Bereich, Farben, Farbstufen und Zusatzzeile (min/max/Mittel). In der Kompaktansicht ersetzt sie die eingebaute Belegung (die Leiste oben bleibt), im Vollbild die Seite 1; Seiten 2 und 3 bleiben. Einstellungen, Wert-Anpassungen (Faktor, Versatz, Einheit) und Grenzen je Wert kommen aus der Datei; Grenzen auf eigene Sensoren und Kanäle warnen mit Farbe und Vibration.
- Laden mit der Referenzfunktion `studioLaden` (wörtlich, Fassung vom 20.11. 12:33 mit den Grenzen 16 KB, 1200 Elemente, 240 Tabellen), Prüfung und Sensorsuche in Schritten unter der Befehlsgrenze (gemessen am Mac mit den Testdateien und einer vollen Datei: Laden höchstens rund 1'900, Prüfschritt höchstens rund 3'000 Befehle je Aufruf). Höchstens 24 Grenzen auf eigene Sensoren und Kanäle. Kaputte, zu neue oder fehlerhafte Dateien ergeben den Standard mit Hinweis unten im Widget, nie einen Absturz. Fehlt für einen Lua-Wert eine Grenze, gilt die Werkgrenze; abschalten nur mit `aus = true`. Eine Richtung, die nicht zum Lua-Wert passt, wird abgewiesen (Werkgrenze). Die Grenze von «RX1 Empfang» gilt für beide Empfänger.
- Änderungen im Widget-Menü gehen bei Modellen mit Studio-Datei in `<Kennung>.<lua>.funke.lua` (sicher über `.funke.neu`, zurücklesen, umbenennen). Bei einer geänderten Grenze schreibt das Widget den ganzen Eintrag (Warnung, Alarm, `aus`) in der angezeigten Einheit, damit kein Alarm still verloren geht. Verglichen wird immer mit dem Stand der Studio-Datei, frühere Änderungen an der Funke bleiben darum bei weiteren Änderungen erhalten. Neu im Menü: «Zurück auf Studio-Stand» bzw. «Zurück auf Standard», mit Rückfrage.
- Das Widget schreibt nach jedem Modellwechsel `<Kennung>.<lua>.info.json` für das Studio (Modell, Fenstergrössen, Sensorliste).
- Beschreibung für das Studio: `studio/<lua>/beschreibung.json` (Werte, Einstellungen, Werkgrenzen, Standardbelegung, reservierte Statusleiste).
- Ohne Studio-Datei arbeitet das Widget wie 1.7.0 / 0.7.0.
- Sendertest X18RS (20.11.): Studio-Ansicht mit Live-Werten, kaputte Datei, Info-Datei, Menü-Änderungen in `.funke.lua` (ganzer Grenzeintrag, Einstellungen und Grenzen zusammen), «Zurück auf Studio-Stand»; Speicher-Spitze der grössten erlaubten Studio-Datei 126 KB bei rund 460 KB frei. Danach behoben (nur am Mac geprüft): eine unterbrochene Ladefolge beginnt neu (Log-Meldung `studio.lua:188`), nach «Zurück auf Studio-Stand» wird keine offene Menü-Änderung mehr nachgeschrieben.

## Motoren Vergaser 0.8.0 – 20.11.2026
- Neu: **Lua-Studio-Format v1.** Liegt auf der SD-Karte eine Studio-Datei `SCRIPTS:/studio/<Kennung>.<lua>.lua` (Kennung = Modellname, Sonderzeichen als `_`), zeichnet das Widget die Plätze daraus: je Platz Wert, Darstellung (Zahl, Ring, Balken waagrecht/senkrecht, Verlauf, Status), Titel, Bereich, Farben, Farbstufen und Zusatzzeile (min/max/Mittel). In der Kompaktansicht ersetzt sie die eingebaute Belegung (die Leiste oben bleibt), im Vollbild die Seite 1; Seiten 2 und 3 bleiben. Einstellungen, Wert-Anpassungen (Faktor, Versatz, Einheit) und Grenzen je Wert kommen aus der Datei; Grenzen auf eigene Sensoren und Kanäle warnen mit Farbe und Vibration.
- Laden mit der Referenzfunktion `studioLaden` (wörtlich, Fassung vom 20.11. 12:33 mit den Grenzen 16 KB, 1200 Elemente, 240 Tabellen), Prüfung und Sensorsuche in Schritten unter der Befehlsgrenze (gemessen am Mac mit den Testdateien und einer vollen Datei: Laden höchstens rund 1'900, Prüfschritt höchstens rund 3'000 Befehle je Aufruf). Höchstens 24 Grenzen auf eigene Sensoren und Kanäle. Kaputte, zu neue oder fehlerhafte Dateien ergeben den Standard mit Hinweis unten im Widget, nie einen Absturz. Fehlt für einen Lua-Wert eine Grenze, gilt die Werkgrenze; abschalten nur mit `aus = true`. Eine Richtung, die nicht zum Lua-Wert passt, wird abgewiesen (Werkgrenze). Die Grenze von «RX1 Empfang» gilt für beide Empfänger.
- Änderungen im Widget-Menü gehen bei Modellen mit Studio-Datei in `<Kennung>.<lua>.funke.lua` (sicher über `.funke.neu`, zurücklesen, umbenennen). Bei einer geänderten Grenze schreibt das Widget den ganzen Eintrag (Warnung, Alarm, `aus`) in der angezeigten Einheit, damit kein Alarm still verloren geht. Verglichen wird immer mit dem Stand der Studio-Datei, frühere Änderungen an der Funke bleiben darum bei weiteren Änderungen erhalten. Neu im Menü: «Zurück auf Studio-Stand» bzw. «Zurück auf Standard», mit Rückfrage.
- Das Widget schreibt nach jedem Modellwechsel `<Kennung>.<lua>.info.json` für das Studio (Modell, Fenstergrössen, Sensorliste).
- Beschreibung für das Studio: `studio/<lua>/beschreibung.json` (Werte, Einstellungen, Werkgrenzen, Standardbelegung, reservierte Statusleiste).
- Ohne Studio-Datei arbeitet das Widget wie 1.7.0 / 0.7.0.
- Sendertest X18RS (20.11.): Studio-Ansicht mit Live-Werten, kaputte Datei, Info-Datei, Menü-Änderungen in `.funke.lua` (ganzer Grenzeintrag, Einstellungen und Grenzen zusammen), «Zurück auf Studio-Stand»; Speicher-Spitze der grössten erlaubten Studio-Datei 126 KB bei rund 460 KB frei. Danach behoben (nur am Mac geprüft): eine unterbrochene Ladefolge beginnt neu (Log-Meldung `studio.lua:188`), nach «Zurück auf Studio-Stand» wird keine offene Menü-Änderung mehr nachgeschrieben.

## Motoren ECU 1.7.0 – 20.11.2026
- Neu: Kompaktansicht für das Ethos-Layout mit Kopf- und Fussleiste (gemessen 784×316 bei X20/X18RS, 630×258 bei X14, 472×210 bei X18 und Twin X Lite). Das Widget erkennt die Fenstergrösse selbst (flacher als 1:2), kein Menüpunkt. Oben eine schmale Leiste mit Motorlaufzeit des Flugs, Zustand, Zündung, Choke und Empfang (Warnungen ersetzen die Pillen), darunter 4 Ringe (Drehzahl, heissester Zylinder, Tank, erster Akku) und 8 Felder (ECU: Druck, ECU-Spannung, Zylinderunterschied, Durchfluss, Verbrauch, Gas, Höhe, Steigen; Vergaser: Zylinderunterschied, Durchfluss, Verbrauch, Gas, Höhe, Steigen, Speed, RxBatt). Im Vollbild alles wie bisher. «nur im Vollbild» erscheint nur noch in sehr kleinen Feldern.
- Sendertest X18RS (20.11.): Kompaktansicht und Warnung in beiden Widgets bestanden. Danach behoben: Titel einheitlich geschrieben («Empfänger 1», «RxBatt» statt Grossbuchstaben); der Akku-Ring nimmt den ersten Akku mit Wert, sonst die Empfängerspannung (blieb vorher leer, wenn Akku 1 keinen Wert hatte); zu lange Warnzeilen in der Leiste werden gekürzt.
- In der Kompaktansicht lädt das Widget nur kompakt.lua, die drei Seiten werden freigegeben (Lua-Speicher im Simulator wie im Vollbild).

## Motoren Vergaser 0.7.0 – 20.11.2026
- Neu: Kompaktansicht für das Ethos-Layout mit Kopf- und Fussleiste (gemessen 784×316 bei X20/X18RS, 630×258 bei X14, 472×210 bei X18 und Twin X Lite). Das Widget erkennt die Fenstergrösse selbst (flacher als 1:2), kein Menüpunkt. Oben eine schmale Leiste mit Motorlaufzeit des Flugs, Zustand, Zündung, Choke und Empfang (Warnungen ersetzen die Pillen), darunter 4 Ringe (Drehzahl, heissester Zylinder, Tank, erster Akku) und 8 Felder (ECU: Druck, ECU-Spannung, Zylinderunterschied, Durchfluss, Verbrauch, Gas, Höhe, Steigen; Vergaser: Zylinderunterschied, Durchfluss, Verbrauch, Gas, Höhe, Steigen, Speed, RxBatt). Im Vollbild alles wie bisher. «nur im Vollbild» erscheint nur noch in sehr kleinen Feldern.
- Sendertest X18RS (20.11.): Kompaktansicht und Warnung in beiden Widgets bestanden. Danach behoben: Titel einheitlich geschrieben («Empfänger 1», «RxBatt» statt Grossbuchstaben); der Akku-Ring nimmt den ersten Akku mit Wert, sonst die Empfängerspannung (blieb vorher leer, wenn Akku 1 keinen Wert hatte); zu lange Warnzeilen in der Leiste werden gekürzt.
- In der Kompaktansicht lädt das Widget nur kompakt.lua, die drei Seiten werden freigegeben (Lua-Speicher im Simulator wie im Vollbild).

## Motoren ECU 1.6.2 – 20.11.2026
Erste Fassung für Tester.
- Behoben: Im Widget-Menü überlappte der Hinweis «ECU-Spannung: 2 Sensoren passen» mit «bitte prüfen» (X18RS). Jetzt eine Kopfzeile «Mehrere Sensoren passen, bitte prüfen:» und je Feld eine kurze Zeile mit Feldname und Anzahl, darunter der gewählte Sensor. Am Sender (X18RS) liefen Suche und Menü ohne Fehler; die neue Hinweis-Darstellung selbst ist dort noch nicht gesehen, nur mit Testdaten am Mac geprüft.
- Ansagen: 18 deutsche Dateien (Zylinder 1–4 heiss/Alarm, Zylinder ungleich, Akku 1–3 tief/Alarm/ungleich) neu nach der Ansagenliste erzeugt; Text und Pausen jetzt einheitlich.
- Neu: Anleitungen als PDF (deutsch und englisch), TESTLEITFADEN.md, Vorlagen für Fehler- und Wunschmeldungen, README mit englischer Zusammenfassung und ehrlichen Grenzen.


## Motoren Vergaser 0.6.2 – 20.11.2026
Erste Fassung für Tester.
- Behoben: Im Widget-Menü überlappte der Hinweis «ECU-Spannung: 2 Sensoren passen» mit «bitte prüfen» (X18RS). Jetzt eine Kopfzeile «Mehrere Sensoren passen, bitte prüfen:» und je Feld eine kurze Zeile mit Feldname und Anzahl, darunter der gewählte Sensor. Am Sender (X18RS) liefen Suche und Menü ohne Fehler; die neue Hinweis-Darstellung selbst ist dort noch nicht gesehen, nur mit Testdaten am Mac geprüft.
- Ansagen: 18 deutsche Dateien (Zylinder 1–4 heiss/Alarm, Zylinder ungleich, Akku 1–3 tief/Alarm/ungleich) neu nach der Ansagenliste erzeugt; Text und Pausen jetzt einheitlich.
- Neu: Anleitungen als PDF (deutsch und englisch), TESTLEITFADEN.md, Vorlagen für Fehler- und Wunschmeldungen, README mit englischer Zusammenfassung und ehrlichen Grenzen.

## Motoren ECU 1.6.1 und Motoren Vergaser 0.6.1 – 20.11.2026
- Behoben (kritisch, X18RS): «Suchen» brach mit «Max instructions count reached» ab, nichts wurde zugeordnet (37 Sensoren). Die Suche verglich jeden Sensor mit allen 141 Einträgen der Kennung in einem einzigen Aufruf (gemessen rund 21 500 Lua-Befehle bei 37 Sensoren, 56 500 bei 100).
- Kennung jetzt als Index nach AppID-Bereich (16 Instanzen je Bereich, D-Hub und ab 0xF000 einzeln); `kennung.lua` bleibt unverändert.
- Die Suche läuft in Schritten über mehrere Aufrufe (laden, ordnen, je 10 Sensoren, zuordnen, Namens-Rückfall je 10). Ergebnis als Hinweis auf dem Bildschirm, mehrdeutige Treffer im Menü auf zwei Zeilen. Je Schlüssel nur die besten 4 Kandidaten, sortiert beim Einfügen.
- Gemessen (Mac, Zählhaken): höchstens rund 2 840 Befehle je Aufruf bei 100 Sensoren, 17 Aufrufe. Zuordnung gleich wie 1.6.0.

## Motoren ECU 1.6.0 und Motoren Vergaser 0.6.0 – 20.11.2026
- Automatische Sensorzuordnung neu nach der gemeinsamen Sensorkennung («Vorgaben Sensorzuordnung»): Merkmal ist AppID + Teilwert (`kennung.lua`, nur während der Suche geladen), nicht mehr der Name. Je Feld eine Rangfolge; von Hand gesetzte Felder bleiben.
- ECU: Drehzahl 0x0500 (JetCat), Zylinder/EGT aus Temp. 1, ECU-Spannung aus 0x0900 (SportECU/Hornet). Liegt 0x0900 oder 0x0910 vor, gilt 0x0410 als ECU-Status und kommt nicht in einen Zylinder.
- Vergaser: Gas Suite (0x0D00–0x0D70) und AES II (0x0D80–0x0E20) vor Temp. 1, Temp. 2 und Drehzahl 0x0500.
- Zylinder-Temperaturen nur so viele, wie «Anzahl Zylinder» vorgibt. Zellensensoren (0x0300) auf Akku 1–3; eine reine Gesamtspannung wird nicht als Akku eingetragen (Anzeige wie bisher).
- Mehrere passende Sensoren: Wahl nach gültigem Wert, niedrigster Instanz, Standard-Physical-ID; Hinweis «n Sensoren passen, gewählt: … – bitte prüfen» als Meldung nach «Suchen» und im Menü. Jeder zugewiesene Telemetriesensor zeigt im Menü [Physical ID/AppID].
- Fehlt der Teilwert (per Lua angelegte Sensoren), entscheidet bei gepackten AppIDs die Einheit (Volt/Ampere).
- Skriptordner der ECU heisst neu `motoren_ecu` (Ethos kürzt auf 16 Zeichen). Widget-Schlüssel und Suite-Paketschlüssel bleiben; beim Umstieg `daten/` aus `scripts/motoren_einspritzer/` übernehmen (README).
- Speicherformat unverändert (keine neuen Felder); Update-Test von 1.5.0 / 0.5.0 bestanden. Neue Tests: `test/suche_test.lua` (feste Fälle a–g), `test/suche_makro.lua` + `suche_ablauf.json` (Simulator 26.2).

## Motoren ECU 1.5.0 und Motoren Vergaser 0.5.0 – 19.11.2026
- Akku nur mit Gesamtspannung (kein Zellensensor, automatisch erkannt): ein Balken mit der mittleren Zelle (Gesamtspannung / Zellenzahl aus dem Menü), darunter «Ø x,xx V je Zelle». Grenzen, Alarme und Ansagen gelten für die mittlere Zelle (wie bisher), ohne Zellendifferenz. Ohne Zellenzahl im Menü der Hinweis «Zellenzahl im Menü wählen». Mit Zellensensor bleiben die Zellbalken.

## Motoren ECU 1.4.3 und Motoren Vergaser 0.4.3 – 19.11.2026
- Übersicht und Flüge: «Tiefste Zelle» übernimmt nur Werte ab 0,5 V. Beim Umstecken oder Einschalten meldete ein Sensor kurz 0,02 V, das blieb als Tiefstwert stehen. Warnungen und Alarme wirken weiter auf jeden Wert.

## Motoren ECU 1.4.2 und Motoren Vergaser 0.4.2 – 19.11.2026
- Behoben: Nach einem Neuladen der Skripte ruft Ethos die Widgets kurz ohne Widget-Objekt auf; das gab tausende Fehlermeldungen bis zum Abbruch wegen Lua-Speicher. Alle Aufrufe tun dann nichts.
- Auswertung des Stromweichen-Zustands ohne Neuzuweisung der Schleifenvariable (lädt auch unter Lua 5.5).

## Motoren ECU 1.4.1 und Motoren Vergaser 0.4.1 – 19.11.2026
- Behoben: Der Alarm «Stromweiche Fehler» kam an der X18RS nie. Ethos 26.2 liefert den Zustand der Stromweiche als Text («RX1 Failsafe+RX1 Lost Frame», «+K3 KO») und teilt ihn auf zwei Sensoren auf. Neu zwei Felder: «Zustand Empfänger (RB State)» und «Zustand Kanäle (RB Ch. State)», beide von der Suche erkannt. Fehler ist alles ausser «OK»; einzelne verlorene Pakete («Lost Frame») nicht. Liefert eine Ethos-Fassung eine Zahl, gilt weiter die Bitauswertung.
- Speicherformat: ECU 5 (liest 3 und 4), Vergaser 4 (liest 3). Update-Test aller Vorversionen bestanden.

## Motoren ECU 1.4.0 und Motoren Vergaser 0.4.0 – 19.11.2026
- Zweisprachig Deutsch/Englisch: Einstellung «Sprache / Language» (wie Sender, Deutsch, English) in der neuen Menügruppe «Anzeige». Anzeige, Menü, Rückfragen und Hinweise übersetzt (`texte.lua`), englisch mit Dezimalpunkt und Tausender-Komma.
- Akkuart je Akku (LiPo, LiFe, NiMH): Wahl der Art setzt die Zellgrenzen dieses Akkus (LiPo 3,50/3,30 V, LiFe 3,10/2,90 V, NiMH 1,15/1,05 V) und die Skala der Zellenbalken. Ältere Stände gelten als LiPo, ihre Grenzen bleiben.
- Ansagen in `audio/de/` und `audio/en/` (je 58). Neu auch die Rollen-Ansagen Empfänger 3, Zündakku und ECU-Akku (bisher Rückfall auf «Akku Nummer n»).
- Seite 2: Die Zahl «100» beim Empfang überlappt den Balken nicht mehr.
- Sensorsuche: Eine ungültige Zuweisung (Sensor gelöscht, Ethos zeigt «---») gilt als leer und wird neu gefüllt.
- Speicher: neue Einstellung nur in der Datei, Speicherformat unverändert; Update-Test von allen Vorversionen bestanden (ausser der zurückgezogenen ECU 1.2.0, siehe 1.2.1). Auf Englisch braucht das Widget im Simulator rund 35 KB mehr Lua-Speicher.

## Motoren ECU 1.3.0 und Motoren Vergaser 0.3.0 – 19.11.2026
Beide Widgets (nach den Testbildern):
- Seite 2: Akkus wieder als Spalten nebeneinander, je Zelle ein senkrechter Balken mit Wert darunter; bis 4 Zellen in einer Reihe, 5 und 6 Zellen in zwei Reihen zu 3. Zellenwerte stehen unter dem Balken (besser lesbar als auf hellem Balken).
- Grenzwerte ab Werk gesetzt (im Menü änderbar, 0 = aus): Zylinder Warnung 200 °C, Alarm 230 °C, Unterschied 40 °C; Zelle Warnung 3,50 V, Alarm 3,30 V; Zellenunterschied 0,15 V; ECU zusätzlich Kraftstoffdruck Warnung unter 1,5 bar, Alarm unter 1,0 bar. Modelle aus älteren Versionen behalten ihre gespeicherten Werte, auch eine 0, weil die Datei nicht zwischen «nie gesetzt» und «bewusst aus» unterscheidet.
- Stromweiche: Der Zustand (RB State) wird ausgewertet. Gestörter Kanal, Failsafe, verlorener Empfänger, kein Signal oder Überlast geben den Alarm «Stromweiche Fehler» mit Ansage; einzelne verlorene Pakete nicht. Auf Seite 2 «Zustand OK/FEHLER» statt der Rohzahl. Bitbelegung nach EdgeTX (frsky_sport.cpp), an der Funke noch zu bestätigen.

Nur Motoren Vergaser 0.3.0 (gleicher Umfang wie Motoren ECU 1.2.x):
- Zylinder: 1 bis 4 im Menü (neu auch 3).
- Akkus: bis 3, je Sensor, Rolle (Empfänger, Zündung, Anlasser, Akku) und Zellenzahl (automatisch oder 1S–6S); reiner Spannungssensor mit Zellenzahl zeigt und überwacht den Mittelwert je Zelle. Ansagen je Rolle, sonst «Akku Nummer n».
- Seite 2: Stromweiche nur, wenn Sensoren gewählt sind; Empfang nur mit Empfangssensor; Empfängerspannung als eigene Karte.
- Statusleiste: zwei Schalter mit frei wählbarem Namen (bisher fest «Winde»/«Bremsen»). Lange Modellnamen werden nach verfügbarem Platz gekürzt statt fest nach 16 Zeichen.
- Sensorsuche: ohne eigenen Statusleisten-Sensor wird RSSI von Empfänger 1 genommen.
- Verträglichkeit: Speicherformat unverändert (keine neuen Quellen), Update-Test von 0.1.0, 0.1.1, 0.2.0 und 0.2.1 bestanden. Akkus behalten ab Werk die Rolle «Akku» und heissen wie bisher «AKKU 1–3»; ein separat gewählter Zündakku wird in den ersten freien Akku mit Rolle «Zündung» übernommen, sonst bleibt er als eigene Karte.

## Motoren ECU 1.2.1 – 19.11.2026
- Behoben (wichtig): Beim Update von 1.0.x/1.1.x auf 1.2.0 gingen alle gespeicherten Sensor-Zuweisungen verloren («gespeicherte Sensoren unlesbar»). Ethos liest den Widget-Speicher nach Reihenfolge; 1.2.0 hatte drei Quellen mehr bei gleichem Format. Jetzt Speicherformat 4; das alte Format 3 wird mit seinen 39 Quellen gelesen, die neuen bleiben leer.
- Neuer Test `test/update_test.lua`: schreibt den Speicher mit einer Vorversion und liest ihn mit der aktuellen.

## Motoren ECU 1.2.0 – 19.11.2026
- Zylinder: 1 bis 4 im Menü wählbar (bisher fest 2), mit Warnung je Zylinder und Unterschied heissester/kältester.
- Akkus: bis 3, als Reihen übereinander mit 1–6 Zellen als kleine Balken. Je Akku im Menü Sensor, Rolle (Empfänger, Zündung, Anlasser, ECU, Akku) und Zellenzahl (automatisch oder 1S–6S). Bei einem reinen Spannungssensor mit Zellenzahl wird der Mittelwert je Zelle angezeigt und überwacht.
- Ansagen je Rolle (empf1/empf2/anlass, sonst «Akku Nummer n»); fehlende Rollen-Ansagen siehe docs/Sprachansagen.md.
- Seite 2 allgemein: Stromweiche nur, wenn Sensoren gewählt sind (jede RB, Akku 1/2 mit Spannung und Strom), Empfängerspannung (RxBatt) als eigenes Feld.
- Statusleiste: zwei Schalter mit frei wählbarem Namen (bisher fest «Winde»/«Bremse»).
- Verträglichkeit: Einstellungen und Daten älterer Fassungen bleiben; Akku 1/2 gelten als Empfänger, Akku 3 als Anlasser wie bisher; ein früher separat gewählter Zündakku wird in den ersten freien Akku übernommen; sind alle drei belegt, bleibt er als eigene Karte «Zündakku» auf Seite 2 und im Menü sichtbar.
- Seite 2: Feld «Empfang» nur, wenn ein Empfangssensor gewählt ist.

## Motoren ECU 1.1.1 – 19.11.2026
Befunde aus dem Abnahmetest an der X18RS (Ethos 26.2.0):
- Drehrad blättert: rechts nächste Seite, links vorige Seite (auch für Sender ohne Touch). Bisher tat rechts nichts und links verliess das Widget.
- Seite 2: Feld «Empfang» und «Kanalströme» zeigen ohne gewählte Sensoren einen Hinweis statt einer leeren Fläche; Titel nur noch «EMPFANG».
- Sensorsuche erkennt auch die Ethos-Standardnamen «RSSI» und «VFR» eines Empfängers; ohne eigenen Statusleisten-Sensor wird RSSI von Empfänger 1 genommen.

## Motoren Vergaser 0.2.1 – 19.11.2026
- Drehrad blättert wie bei Motoren ECU 1.1.1.
- Feld «Empfang» zeigt ohne gewählte Sensoren einen Hinweis.

## Motoren ECU 1.1.0 – 19.11.2026
Das Widget heisst jetzt «Motoren ECU» (bisher «Motoren Einspritzer»). Skriptordner `scripts/motoren_einspritzer/` und Widget-Schlüssel bleiben, darum bleiben Einstellungen und Daten auf der Funke erhalten.
- Allgemein für Flüge statt nur für Schlepps: Seite 3 «Flüge», Rückfrage «Flug beendet?», Ansagen «Flug gespeichert / pausiert / geht weiter». Linke Spalte heisst «Gesamt» (Werte seit dem letzten Zurücksetzen).
- Gespeicherte Daten älterer Fassungen werden weiter gelesen; frühere Schlepps erscheinen als Flüge.
- Keine Hersteller- oder Personennamen mehr in Texten und Unterlagen.

## Motoren Vergaser 0.2.0 – 19.11.2026
- Nur noch «Flug»: die Menüwahl «Einträge heissen Flug/Schlepp» entfällt, ebenso die Schlepp-Ansagen. Linke Spalte der Übersicht heisst «Gesamt».
- Gespeicherte Daten älterer Fassungen werden weiter gelesen; frühere Einträge erscheinen als Flüge.

## Motoren Einspritzer 1.0.1 – 19.11.2026
- Behoben: Kam die Telemetrie nach einem Ausfall zurück, wurde «Telemetrie da» bis zu 10-mal pro Sekunde angesagt, solange die Meldung «Telemetrie weg» noch stand. Jetzt genau einmal.
- Paketangaben (Name, Beschreibung, Suite-Schlüssel) stehen oben in `main.lua`; Pakete entstehen mit einem zentralen Paketskript, `tools/paket.py` entfällt.
- Tests im Repo (`test/`): Simulator-Ablauf, Testhaken, neues Szenario `teleweg`. Simulatorbilder einheitlich benannt.
- Geprüft im Simulator 26.1.2 (alle Szenarien) und Laden unter Ethos 26.2.0.

## Motoren Vergaser 0.1.1 – 19.11.2026
- Behoben: «Telemetrie da» wurde nach einem Ausfall mehrfach angesagt (wie Einspritzer 1.0.1).
- Paketangaben oben in `main.lua`, zentrales `paket.py`, Tests und Bildnamen wie beim Einspritzer.

## Motoren Vergaser 0.1.0 – 17.11.2026
Erste Fassung, abgeleitet vom Einspritzer.
- Gleiche Bedienung und Robustheit wie der Einspritzer, Modellname oben.
- Seite 1: 1, 2 oder 4 Zylinder (Menü), jede Temperatur frei zuweisbar, Unterschied heissester/kältester, eine Drehzahl, Tank/Durchfluss/Restzeit, Choke nur über eine optionale Schalterstellung (ab Werk keine).
- Seite 2: beliebige Akkus mit Zellen oder nur Spannung, RxBatt, RB-Kanäle nur wenn eine RB zugewiesen ist, 1 oder 2 Empfänger mit 1 oder 2 Bändern und VFR.
- Seite 3: wie Einspritzer; Einträge heissen «Flug» (Werk) oder «Schlepp» (Menü); einzeln löschbar.
- Automatische Sensorsuche über die FrSky-Standardbereiche der Application ID (Temperatur 0x0400–0x041F, Drehzahl 0x0500–0x050F, Durchfluss 0x0D50–0x0D5F, Impulse 0x5102, Zellen 0x0300–0x030F, Höhe, Vario, GPS-Speed, RSSI, RxBatt) und über Namen.
- 43 Ansagen, davon 16 neu (Flug, Zylinder 3/4, allgemeine Akkus).
- Noch nicht: mehrere Drehzahlen, AES-II-Temperaturen 6/7 und AD-Eingänge. Nicht an einer echten AES geprüft.

## Motoren Einspritzer 1.0.0 – 17.11.2026
Erste veröffentlichte Fassung (vorher interne Vorabversion). Der Widget-Schlüssel bleibt unverändert.
- Vollbild-Widget mit drei Seiten, Wischen blättert; Modellname oben in der Statusleiste.
- Seite 1 Motor: Zylinder 1 und 2 mit Trendpfeil, Drehzahlbogen mit Höchstwert, Gas, Spritdruck mit Sollbereich, Tank mit Restzeit, «Vollgetankt» mit Rückfrage, Fussleiste Höhe/Steigen/Speed.
- Seite 2 Elektrik: bis 3 Akkus mit Zellen (FLVS) oder nur Spannung, RB35-Kanalströme, Empfang RX1/RX2 (2,4 GHz/900 MHz, VFR), Zündakku.
- Seite 3 Übersicht: Eckwerte «Dieser Flug»; Schlepp-Liste über den Motorschalter mit Rückfrage «Schlepp beendet?»; antippen zeigt die Werte des Schlepps; einzelne Schlepps löschen; Übersicht zurücksetzen mit Rückfrage.
- Tank führt das Widget selbst (Impulszähler, sonst Durchfluss); dauerhaft gespeichert, zurück nur über «Vollgetankt».
- Warnungen und Alarme mit 36 Ansagen (FrSky-Stimme de-DE-Wavenet-E); alle Grenzwerte im Widget-Menü, 0 = aus.
- Sensoren automatisch zuweisen (nur leere Felder), von Hand änderbar; absturzsicher.
- Behoben: reiner Spannungssensor erschien als «8S» mit falschen Zellen.
