[🇬🇧 English](../en/Installation.md) · 🇩🇪 Deutsch

# Installation

Für beide Widgets gleich; Datei- und Ordnernamen entsprechend ersetzen (`Gas-Engine-ECU-1.13.1.zip` / `gas_ecu` oder `Gas-Engine-Carb-0.13.1.zip` / `gas_carb`).

## Mit der FrSky Suite (empfohlen)
1. Die Paket-ZIP aus dem neusten **Release** auf GitHub laden. Nicht entpacken.
2. Sender per USB an den Computer anschliessen und am Sender **Ethos Suite** wählen.
3. FrSky Suite › **Lua-Bibliothek** › **Von lokaler ZIP installieren** › die ZIP wählen.
4. Sender trennen und neu starten.

## Ohne Suite, über die SD-Karte
1. Die Datei am Computer entpacken. Darin liegt der Ordner `gas_ecu` bzw. `gas_carb`.
2. Den ganzen Ordner nach `SD:/scripts/` auf dem Sender kopieren.
3. Am Mac danach `dot_clean -m` auf den Ordner ausführen, sonst stören versteckte Dateien.
4. Sender neu starten.

> Die X18RS mit Ethos 26.2 lädt Skripte **nur von der SD-Karte**. Liegt der Ordner im internen Speicher (RADIO), fehlt das Widget in der Auswahl.

## Aktualisieren und entfernen
- **Aktualisieren:** die neue ZIP genauso installieren. Einstellungen, Tank, Flüge und Zuweisungen bleiben erhalten, auch über mehrere Versionen.
- **Entfernen:** in der FrSky Suite unter Lua-Bibliothek löschen oder den Ordner `SD:/scripts/gas_ecu/` (bzw. `gas_carb/`) löschen; die gespeicherten Daten im Unterordner `daten/` sind dann ebenfalls weg.

## Umstieg von Motoren ECU / Vergaser
Bis ECU 1.9.0 / Vergaser 0.9.0 hiessen die Widgets **Motoren ECU** (Ordner `motoren_ecu`) und **Motoren Vergaser** (Ordner `motoren_vergaser`). Neu heissen sie **Gas Engine ECU** (`gas_ecu`) und **Gas Engine Carb** (`gas_carb`). Der Wechsel ist **nicht rückwärtskompatibel**:
1. Das neue Paket wie oben installieren.
2. In jedem Modell das Widget im Bildschirm **neu wählen** (Ethos erkennt das Widget an seinem Schlüssel, und der ist neu).
3. Sensoren mit **Suchen** zuweisen, Motorschalter, Zylinder, Tank und Akkus neu einstellen. Einstellungen, Tank und Flüge der alten Version werden nicht übernommen.
4. Lua-Studio: Eine Datei mit dem alten Namen (`<Modell>.motoren_ecu.lua` / `.motoren_vergaser.lua`) wird noch gelesen; im Log steht «old studio file found, please re-transfer». Bitte aus Lua-Studio neu übertragen.
5. Den alten Ordner `SD:/scripts/motoren_ecu/` bzw. `motoren_vergaser/` löschen.

> Einstellungen, Tank und Flüge liegen in `daten/<Modell>.txt` im Skriptordner. Das neue Widget versucht, die alte Datei einmal zu lesen; sicherer ist es, `SD:/scripts/motoren_ecu/daten/` nach `SD:/scripts/gas_ecu/daten/` (bzw. `motoren_vergaser/daten/` nach `gas_carb/daten/`) zu kopieren, bevor der alte Ordner gelöscht wird.

---
[← Start](../Home.md) | [Zurück](Carb.md) | [Weiter →](Einrichten.md)

**X20 / X20 Pro:** Die Skripte können dort im internen Speicher liegen (`SCRIPTS:/gas_ecu/`, `SCRIPTS:/gas_carb/`) statt auf der SD-Karte. Widgets und Studio-Dateien funktionieren an beiden Orten (`SCRIPTS:/studio/` wird zuerst durchsucht).
