# Tests für Gas Engine Lua

Hier liegen nur Skripte und Ablaufdateien. Ergebnisse und Bilder entstehen ausserhalb (Scratchpad oder `docs/bilder-simulator/`).

| Datei | Zweck |
|---|---|
| `lauf.py` | Ein Simulator-Ablauf für ein Widget: Vollbild öffnen, auf die gewünschte Seite wischen, warten, optional ein Bild speichern. |
| `haken_einspritzer.lua`, `haken_vergaser.lua` | Testhaken: werden nur im Simulator an `kern.lua` angehängt, liefern künstliche Sensorwerte je Szenario und schreiben `TEST`-Zeilen. |
| (nicht im Repo) | Testmodell für den Simulator X18RS mit eingerichtetem Vollbild-Widget: Pfad in `MOTOREN_TESTMODELL`. Es enthält Daten einer echten Funke und gehört darum nie ins Repo. `lauf.py` arbeitet mit einer Kopie. |
| `update_test.lua` | Update-Test des Widget-Speichers: Vorversion schreibt, aktuelle Fassung liest. |
| `zuschnitt.py` | Vergrössert einen Ausschnitt eines Simulatorbildes zur Kontrolle von Schrift und Umlauten. |

Voraussetzungen: Ethos-Lua-Baukasten des Autors (nicht im Repo) mit `sim.cjs`, `simulator.cjs` und `zufallstest.lua`, Ordner in der Umgebungsvariable `ETHOS_LUA_TOOLS`, Node.js, Lua 5.4 (`/opt/homebrew/opt/lua@5.4/bin/lua`).

## Zufallstest (ohne Simulator)

Aus dem Projektordner:

```sh
for w in gas_ecu gas_carb; do
  /opt/homebrew/opt/lua@5.4/bin/lua $ETHOS_LUA_TOOLS/zufallstest.lua src/$w 5000 1
done
```

Erwartet wird je Widget die Zeile `ERGEBNIS: kein Fehler`.

## Update-Test (Widget-Speicher, ohne Simulator)

Ethos liest den Widget-Speicher nach Reihenfolge, nicht nach Namen. Vor jeder Version mit neuen Quellen (Art «q») prüfen,
dass die Vorversion noch gelesen wird:

```sh
git show <tag-der-vorversion>:src/gas_ecu/felder.lua > /tmp/felder_alt.lua
/opt/homebrew/opt/lua@5.4/bin/lua test/update_test.lua /tmp/felder_alt.lua src/gas_ecu/felder.lua
```

Erwartet: «0 fehlen» und «ERGEBNIS: kein Fehler». Neue Quellen nur ans Ende von `M.folge` und dazu `M.FORMAT` erhöhen,
das alte Format im Lesen weiter unterstützen.

## Simulator

```sh
python3 test/lauf.py <einspritzer|vergaser> <szenario> <bild.png|-> [sekunden=8] [gross=1|2] [seite=1]
```

- Szenarien Einspritzer: `normal`, `alarm`, `motoraus`, `chokewarn`, `kalt`, `tank`, `teil`, `unsinn`, `schleppx`, `schleppy`, `schleppz`, `teleweg`, `dreh`, `akkus`, `alt`, `altvoll`, `spannung`, `zyl3`, `zyl4`
- Szenarien Vergaser: `ein1` (Einzylinder), `aes2`, `aes4` (FrSky AES mit 2 bzw. 4 Zylindern), `fluege`, `flugdetail`, `teleweg`, `dreh`, ab 0.3.0 `akkus` (3×6S mit Rollen, Schalternamen), `alt` (separater Zündakku wird übernommen), `spannung` (6S nur Gesamtspannung), `zyl3`, `langname` (langer Modellname in der Statusleiste), `m3`, `m4` (3 Akkus je 3S/4S), `rbfs` (Stromweiche: Kanal gestört und Failsafe), `rbok` (nur verlorene Pakete, kein Alarm), `arten` (LiPo, LiFe, NiMH), `gesamt` (nur Gesamtspannung, mit und ohne Zellenzahl), `rbtext`/`rbtextok` (Zustand der Stromweiche als Text wie unter Ethos 26.2). Jedes Szenario mit angehängtem `_en` (z. B. `akkus_en`) zeigt die Anzeige auf Englisch
- `akkus` (ECU): 3 Akkus à 6S mit Rollen, Schalternamen, RxBatt; `alt`: früherer Zündakku wird in Akku 3 übernommen; `altvoll`: alle Akkus belegt, Zündakku bleibt als Karte, Stromweiche ohne Empfang; `spannung`: reiner Spannungssensor mit 6S; `zyl3`/`zyl4`: 3 bzw. 4 Zylinder
- `dreh` (beide): Drehrad rechts/links, prüft Seitenwechsel und Rückgabe
- `teleweg` (beide): Telemetrie 3 s da, 4 s weg, dann wieder da; «Telemetrie da» muss genau einmal kommen
- `echt` startet das Widget ohne Testhaken (keine künstlichen Werte).
- `-` statt eines Bildnamens: nur die Textausgabe (`TEST`- und Fehlerzeilen).
- `seite` 1 bis 3 wählt die Seite (Motor, Elektrik, Übersicht).
- Mit `ABBILD=1` davor läuft der Simulator mit dem Speicherabbild der Funke (Speicherbedarf).

Beispiel: `python3 test/lauf.py einspritzer alarm /tmp/alarm.png 8 1 1`

## Alarme bei Motor aus (ab ECU 1.8.1 / Vergaser 0.8.1)

- `/opt/homebrew/opt/lua@5.4/bin/lua test/motor_aus_test.lua`: ZYL UNGLEICH, Spritdruck (ECU), Tank-Restzeit/Prozent, CHOKE AUS! je mit Motor ein und Motor aus (Kill über den Motorschalter), dazu: der Motorschalter schaltet keinen Grenzwert-Alarm stumm. Beide Widgets, ohne Simulator. Erwartet «ERGEBNIS: kein Fehler».
- `python3 test/lauf.py einspritzer motoraus - 16`: dasselbe im Simulator. Erwartet bei «Motor ein» `zyl_ungleich`, `spritdruck_alarm`, `tank_leer`, `choke_aus`, bei «Motor aus» `zyl_ungleich` und `tank_reserve`.

## Sensorzuordnung (ab ECU 1.6.0 / Vergaser 0.6.0)

- `/opt/homebrew/opt/lua@5.4/bin/lua test/suche_test.lua`: feste Fälle (a)–(g) der Vorgaben Sensorzuordnung für beide Widgets, ohne Simulator; misst dazu die Lua-Befehle je Aufruf (Ziel deutlich unter 10 000).
- `cd test && node $ETHOS_LUA_TOOLS/simulator.cjs suche_ablauf.json --port <eigener Port>`: dieselbe Suche auf Ethos 26.2 mit per Lua angelegten Sensoren (`suche_makro.lua`). Fall (c) mischt der Simulator, er steht nur im Mac-Test.
