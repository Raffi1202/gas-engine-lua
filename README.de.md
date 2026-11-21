# Gas Engine ECU / Carb – Telemetrie für Verbrennungsmotoren (FrSky Ethos)

[English](README.md) · **Deutsch** · Dokumentation: [Wiki (English)](wiki/en/ECU.md) · [Wiki (Deutsch)](wiki/de/ECU.md)

> **Am PC einrichten mit [Lua-Studio](https://github.com/Raffi1202/lua-studio)**: Bildschirm einteilen, Werte, Alarme und Symbole wählen, auf die Funke übertragen.

Zwei Vollbild-Widgets für FrSky-Sender mit **Ethos 26.1 oder neuer**. Sie zeigen die Telemetrie eines
Verbrennungsmotors auf drei Seiten (Motor, Elektrik, Übersicht mit Flugliste) oder in der Kompaktansicht und warnen mit
Farbe, Ansage und Vibration. Anzeige, Menü und Ansagen deutsch und englisch.

| Widget | Für | Version | Ordner auf der SD-Karte |
|---|---|---|---|
| **Gas Engine ECU** | Einspritzmotoren mit ECU (Drehzahl, Zylinder, Kraftstoffdruck, ECU-Spannung) | 1.11.0 | `SD:/scripts/gas_ecu/` |
| **Gas Engine Carb** | Vergasermotoren, z. B. mit FrSky AES / AES II | 0.11.0 | `SD:/scripts/gas_carb/` |

![Seite 1 der Gas Engine ECU im Simulator](docs/bilder-simulator/Gas%20Engine%20ECU%20-%20Sim%20800x480%2001%20Seite%201%20Normal.png)

**Stand:** öffentliche Vorabversion (public beta). Gas Engine ECU 1.11.0 / Carb 0.11.0 sind im Ethos-Simulator getestet; der
Sendertest an der X18RS folgt. Benutzung auf eigene Gefahr. Lizenz: GPL-3.0, siehe unten.

**Neu in Gas Engine ECU 1.12.0 / Carb 0.12.0:** das Studio-Layout wird immer gefunden: Suche in `SCRIPTS:/studio/`, `SD:/scripts/studio/` und `RADIO:/scripts/studio/`, Menüeintrag **«Studio-Layout»** für eine Datei, deren Name nicht zum Modell passt, Umrechnen auf andere Fenstergrössen und eine Hinweiszeile, wenn die Standardanzeige erscheint. Siehe [Studio-Layout erscheint nicht?](#studio-layout-erscheint-nicht).

**Neu in Gas Engine ECU 1.11.0 / Carb 0.11.0:** zwei neue Lua-Studio-Darstellungen: **`zylinder`** (alle Zylinder-Säulen wie Seite 1, `w = "lua:cht_max"`) und **`tank`** (Tank-Säule mit %, ml, Verbrauch, Fluss, Restzeit und Knopf VOLLGETANKT, `w = "lua:tank_proz"`); Zylinder und Tank lassen sich damit im eigenen Layout frei platzieren. Braucht eine Lua-Studio-Version, die sie anbietet; ältere Lua-Studio-Versionen bieten sie einfach nicht an.

**Neu in Gas Engine ECU 1.10.0 / Carb 0.10.0 (bisher Motoren ECU / Vergaser):** «Alarm auch bei Motor aus» je Grenze (Menü und Lua-Studio, ab Werk an); eine
Lua-Studio-Grenze ohne Zahl behält die Werkgrenze; Speicher wird beim Modellwechsel frei.

## Schnellstart

1. Aus dem neusten **Release** `Gas-Engine-ECU-1.11.0.zip` oder `Gas-Engine-Carb-0.11.0.zip` laden.
2. Sender per USB anschliessen, am Sender **Ethos Suite** wählen, am Computer die **FrSky Suite** öffnen.
3. Suite › **Lua-Bibliothek** › **Von lokaler ZIP installieren** › die ZIP wählen (nicht entpacken). Sender neu starten.
4. Modell › **DISP** › neuer Bildschirm im Layout **Vollbild** › Widget wählen.
5. Widget lange drücken › **Widget konfigurieren** › **Suchen**. Dann Motorschalter, Gaskanal, Zylinder, Tank und Akkus einstellen.

Ohne Suite: den Ordner aus der ZIP nach `SD:/scripts/` kopieren. Die X18RS mit Ethos 26.2 lädt Skripte nur von der
SD-Karte. Beim Aktualisieren bleiben Einstellungen, Tank, Flüge und Zuweisungen erhalten. Umstieg von Motoren ECU / Vergaser: siehe [Wiki › Installation](wiki/de/Installation.md#umstieg-von-motoren-ecu--vergaser).

## Anleitungen und Test

| Was | Datei |
|---|---|
| Wiki | [English](wiki/en/ECU.md) · [Deutsch](wiki/de/ECU.md) |
| Anleitung ECU (PDF) | [Deutsch](docs/Gas%20Engine%20ECU%20-%20Anleitung.pdf) · [Englisch](docs/Gas%20Engine%20ECU%20-%20Manual.pdf) |
| Anleitung Carb (PDF) | [Deutsch](docs/Gas%20Engine%20Carb%20-%20Anleitung.pdf) · [Englisch](docs/Gas%20Engine%20Carb%20-%20Manual.pdf) |
| Testleitfaden zum Abhaken | [TESTLEITFADEN.md](TESTLEITFADEN.md) |
| Ansagetexte (DE/EN) | [docs/Sprachansagen.md](docs/Sprachansagen.md) |
| Fehler und Wünsche | GitHub › Issues › New issue |
| Versionen | [CHANGELOG.md](CHANGELOG.md) |

## Sender und Stand der Erprobung

| Sender | Display | Stand |
|---|---|---|
| X18RS / X18S / X18 | 480×320 | am Sender getestet (X18RS, Ethos 26.2.0) |
| X20 / X20S / X20RS / X20 Pro | 800×480 | nur im Ethos-Simulator |
| X14 / X14S | 640×360 | nicht getestet |
| X10 / Twin X Lite | 480×272 | nicht getestet |

Am echten X18RS getestet (mit Telemetrie-Simulator, 48 Sensoren, Empfänger SR10 Plus): Sensorsuche,
Stromweichen-Alarm, Akkus, Akkuart, Sprache, Textfeld für Schalternamen, die Lua-Studio-Datei. **Noch nie im echten
Flug.** Noch nicht am Sender getestet: alles Neue in 1.11.0 / 0.11.0, jeder Menüpunkt einzeln, Ansagen im Flug, andere
Sender. Rückfragen, «Vollgetankt» und die Flugliste brauchen Berührung; das Drehrad blättert nur die Seiten.

## Lua-Studio

Mit dem PC-Programm Lua-Studio gestaltest du jedes Kästchen selbst (Wert, Zahl, Ring, Balken, Verlauf, Status, Farben,
Grenzen). Lua-Studio legt je Modell eine Datei nach `SCRIPTS:/studio/`; das Widget liest sie beim Modellwechsel.
Ohne Datei bleibt alles wie bisher. Was die Widgets anbieten, steht in
[studio/gas_ecu/beschreibung.json](studio/gas_ecu/beschreibung.json) und
[studio/gas_carb/beschreibung.json](studio/gas_carb/beschreibung.json).


### Studio-Layout erscheint nicht?
1. Datei nach `scripts/studio/` auf der SD-Karte oder im Funkenspeicher kopieren (gesucht wird in `SCRIPTS:/studio/`, `SD:/scripts/studio/` und `RADIO:/scripts/studio/`).
2. Passt der Dateiname nicht zum Modellnamen: Widget-Menü › **Studio-Layout** › Datei wählen (Ort in Klammern). «automatisch (Modellname)» nimmt `<Modell>.gas_ecu.lua` / `<Modell>.gas_carb.lua`.
3. Andere Fenstergrösse (z. B. mit Kopf- und Fussleiste 784 × 316 oder kleinere Funke): Das Widget rechnet die ähnlichste Ansicht um und zeigt 5 s lang «Studio: Ansicht 800x480 angepasst». Zu kleine Plätze werden Zahl oder fallen weg.
4. Eine Zeile unten «Studio: Datei fehlerhaft (…)» oder «Studio: keine passende Ansicht» nennt den Grund für die Standardanzeige. Datei im Lua-Studio neu exportieren.
5. Die Info-Datei `SCRIPTS:/studio/<Modell>.<lua>.info.json` zeigt `studioQuelle`, `studioWahl`, `ansichtGenutzt`, `angepasst` und `hinweis`; Lua-Studio liest sie.

## Wo liegt was

| Inhalt | Ort |
|---|---|
| Widget ECU (so auf die SD-Karte, Ansagen in `audio/de` und `audio/en`) | `src/gas_ecu/` |
| Widget Carb | `src/gas_carb/` |
| Anleitungen (Quelle HTML, PDF daneben) | `docs/anleitung/`, `docs/*.pdf` |
| Bildschirmfotos aus dem Simulator | `docs/bilder-simulator/` |
| Tests, Erklärung in [test/LIESMICH.md](test/LIESMICH.md) | `test/` |

## Entwicklung

Für Tester nicht nötig. Die Mac-Tests laufen mit Lua 5.4 aus dem Repo-Ordner (Befehle siehe [README.md](README.md#development)).
Simulator-Treiber, Zufallstest und Paket-Skripte gehören zum Baukasten des Autors und liegen nicht in diesem Repo
(Ordner in der Umgebungsvariable `ETHOS_LUA_TOOLS`). Zwei Widgets mit eigener Versionsnummer, darum zwei Tag-Reihen
`gas-ecu-vX.Y.Z` und `gas-carb-vX.Y.Z`.

## Weitere Projekte

| Projekt | Wozu |
|---|---|
| [Electric](https://github.com/Raffi1202/electric-lua) | Ethos-Widget für Elektromodelle |
| [Heli](https://github.com/Raffi1202/heli-lua) | Ethos-Widget für Helis mit Telemetrie (jedes Flybarless-System) |
| [Jet](https://github.com/Raffi1202/jet-lua) | Ethos-Widget für Turbinen (mehrere ECU-Hersteller) |
| [Glider](https://github.com/Raffi1202/glider-lua) | Ethos-Widget für Segler (Vario, Thermik) |
| [Lua-Studio](https://github.com/Raffi1202/lua-studio) | PC-Programm zum Einrichten der Widgets (Mac/Windows) |

## Lizenz

GPL-3.0, siehe [LICENSE](LICENSE).
