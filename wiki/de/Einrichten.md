[🇬🇧 English](../en/Setup.md) · 🇩🇪 Deutsch

# Einrichten

## Bildschirm
1. Modell wählen, **DISP** drücken und einen neuen Bildschirm im Layout **Vollbild** anlegen.
2. Die leere Fläche antippen und **Gas Engine ECU** oder **Gas Engine Carb** wählen. Ohne Sensoren stehen überall Striche, das ist richtig.
3. Im Layout mit Kopf- und Fussleiste (ein Widget) zeigt das Widget von selbst die **Kompaktansicht**. In einem noch kleineren Feld steht «nur im Vollbild».

## Sensoren
1. Zuerst Ethos die Sensoren finden lassen: Modell › Telemetrie › **Sensoren suchen**.
2. Widget lange drücken › **Widget konfigurieren** › **Suchen** neben «Sensoren automatisch suchen». Die Suche läuft einige Sekunden und füllt nur leere Felder.
3. Menü schliessen. Das Widget zeigt kurz «n Sensoren neu zugewiesen».
4. Passen mehrere Sensoren auf ein Feld, steht oben im Menü «Mehrere Sensoren passen, bitte prüfen:». Diese Felder prüfen und bei Bedarf von Hand wählen.

Die Suche erkennt Sensoren an ihrer FrSky-ID (Application-ID) und an bekannten Namen. Ein gelöschter Sensor («---») gilt als leer und wird neu gefüllt.

## Von Hand
- **Motorschalter (3 Stufen)** mit «Stellung Aus (Kill)» und «Stellung Choke»: Aus → Zündung beginnt einen Flug, Zündung → Aus fragt «Flug beendet?».
- **Gas (Kanal)**, **Stumm (Schalter)** und die zwei Schalter der Statusleiste (Name höchstens 12 Zeichen, «umkehren», wenn die Pille verkehrt leuchtet).
- **Gas umkehren** (direkt unter «Gas (Kanal)»): einschalten, wenn du Gas Reverse fliegst (Vollgas = Knüppel hinten). Ab Werk aus.
- **Anzahl Zylinder**, **Tankinhalt**, **ml pro Impuls** des Durchflusssensors (0,100 ml für das FrSky-Flowmeter).
- Je Akku: **Rolle** (Empfänger, Zündung, Anlasser, ECU, Akku), **Zellen** (nötig bei reinem Spannungssensor) und **Art** (LiPo, LiFe, NiMH; ein Wechsel setzt die zwei Zellgrenzen).

## Menügruppen
Motor · Motor: Grenzwerte (0 = aus) · Motor: Skalen der Anzeige · Kraftstoff · Flug und Empfang · Akkus (Zellen- oder Spannungssensor) · Stromweiche (RB, falls vorhanden) · Empfänger · Schalter in der Statusleiste · Anzeige (Sprache) · Warnungen · Alarm auch bei Motor aus.

Sensoren, Kanäle und Schalter speichert das Modell, alle übrigen Werte die Datei `daten/<Modellname>.txt` im Skriptordner. Jede Einstellung mit Standard und Bereich steht in Kapitel 8 der Anleitung.

---
[← Start](../Home.md) | [Zurück](Installation.md) | [Weiter →](Anzeige.md)
