[🇬🇧 English](../en/Troubleshooting.md) · 🇩🇪 Deutsch

# Fehlerbehebung

| Was du siehst | Was tun |
|---|---|
| Das Widget fehlt in der Auswahl | Ordner nicht auf der SD-Karte unter `scripts/` oder Lua-Speicher voll. Ordner prüfen, neu starten, selten gebrauchte Skripte entfernen. |
| «nur im Vollbild» | Das Feld ist kleiner als die Kompaktansicht. «Vollbild» oder das Layout mit Kopf- und Fussleiste wählen. |
| Überall Striche, «KEINE DATEN» | Keine Telemetrie oder keine Sensoren. Empfänger an? Modell › Telemetrie › Sensoren suchen, dann «Suchen» im Widget. |
| Ein Feld zeigt einen Strich | Sensor zugewiesen, aber ohne Wert. In Ethos unter Telemetrie prüfen. |
| Falscher Sensor nach der Suche | Oben im Menü stehen die Felder, auf die mehrere Sensoren passten. Von Hand wählen. |
| «Zellenzahl im Menü wählen» | Reiner Spannungssensor ohne Zellenzahl: «Akku n Zellen» einstellen. |
| Dauernde Zellwarnung bei LiFe oder NiMH | «Akku n Art» richtig einstellen, die Grenzen folgen. |
| Keine Ansagen | «Ansagen» an? Stumm-Schalter aus? Lautstärke? Ordner `audio/` mitkopiert? |
| Ein Alarm kommt bei Motor aus nicht | «Alarm auch bei Motor aus» ist für diesen Wert ausgeschaltet (Menü oder Lua-Studio). |
| Kein Flug in der Liste | Motorschalter nicht zugewiesen oder «Stellung Aus» falsch. |
| Kleiner roter Fehlertext unten links | Ein Skriptfehler. Bildschirmfoto machen und mit dem Log (FrSky Suite › Debug-Log) als GitHub-Issue melden. |

## Lua-Speicher («too much RAM»)
Alle Lua-Skripte auf dem Sender teilen sich einen Lua-Speicher (rund 2048 KB auf der X18RS). Meldet Ethos «too much RAM» bzw. «Zu wenig Lua-Speicher», **den Sender aus- und wieder einschalten**. Seit ECU 1.8.1 / Vergaser 0.8.1 gibt das Widget seinen Speicher nach dem Wechsel auf ein Modell ohne dieses Widget frei (rund 4 KB bleiben statt rund 127 KB, im Simulator gemessen).

---
[← Start](../Home.md) | [Zurück](FAQ.md) | [Weiter →](Versionen.md)

### Studio-Layout erscheint nicht?
1. Datei nach `scripts/studio/` auf der SD-Karte oder im Funkenspeicher kopieren (gesucht wird in `SCRIPTS:/studio/`, `SD:/scripts/studio/` und `RADIO:/scripts/studio/`).
2. **Ein Layout für alle Modelle:** die Lua-Studio-Datei als `Standard.gas_ecu.lua` / `Standard.gas_carb.lua` speichern. Reihenfolge: Wahl im Widget-Menü › Datei des Modells (`<Modell>.gas_ecu.lua`) › `Standard`-Datei › eingebaute Anzeige. Im Menü steht «Standard (alle Modelle)»; Änderungen am Sender bleiben pro Modell (`<Modell>.gas_ecu.funke.lua`). Heisst ein Modell «Standard», gilt die Datei als seine Modelldatei.
3. Passt der Dateiname nicht zum Modellnamen: Widget-Menü › **Studio-Layout** › Datei wählen (Ort in Klammern). «automatisch (Modellname)» nimmt `<Modell>.gas_ecu.lua` / `<Modell>.gas_carb.lua`.
3. Andere Fenstergrösse (z. B. mit Kopf- und Fussleiste 784 × 316 oder kleinere Funke): Das Widget rechnet die ähnlichste Ansicht um und zeigt 5 s lang «Studio: Ansicht 800x480 angepasst». Zu kleine Plätze werden Zahl oder fallen weg.
4. Eine Zeile unten «Studio: Datei fehlerhaft (…)» oder «Studio: keine passende Ansicht» nennt den Grund für die Standardanzeige. Datei im Lua-Studio neu exportieren.
5. Die Info-Datei `SCRIPTS:/studio/<Modell>.<lua>.info.json` zeigt `studioQuelle`, `studioWahl`, `ansichtGenutzt`, `angepasst` und `hinweis`; Lua-Studio liest sie.
