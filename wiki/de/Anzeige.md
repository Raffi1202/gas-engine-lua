[🇬🇧 English](../en/Display.md) · 🇩🇪 Deutsch

# Anzeige

Drei Seiten. Weiter: nach links wischen oder Drehrad nach rechts; zurück: nach rechts wischen oder Drehrad nach links.

## Seite 1 Motor
| Teil | Was es zeigt |
|---|---|
| Statusleiste | Zustand (LÄUFT, WARMLAUF, KEINE DATEN, WARNUNG, ALARM), Zündung, Choke, die zwei Schalter, Modellname, ECU-Spannung (nur ECU), Empfang, Seite |
| Meldezeile | Alle aktiven Warnungen (orange) und Alarme (rot) als Text |
| Zylinder | Je Zylinder ein Balken mit Temperatur, Trendpfeil, Differenz und Maximum |
| Drehzahl | Bogen mit Drehzahl und Maximum, darunter der Gasbalken in Prozent |
| Kraftstoff | Druckbalken (nur ECU), Tank in % und ml, Verbrauch, Durchfluss, Restzeit, Knopf VOLLGETANKT |
| Fussleiste | Höhe, Steigen, Geschwindigkeit |

## Seite 2 Elektrik
![Seite 2 Elektrik mit drei Akkus (Simulator)](../../docs/bilder-simulator/Gas%20Engine%20ECU%20-%20Sim%20800x480%2007%20Seite%202%20Elektrik%203%20Akkus.png)

Bis zu drei Akkus. Mit Zellensensor je Zelle ein Balken und Δ = Differenz; mit reinem Spannungssensor ein Balken der mittleren Zelle («Ø … V je Zelle»). Stromweiche (nur wenn Sensoren zugewiesen sind): Status, Akkuspannungen und -ströme, Kanalströme. Empfang von Empfänger 1 und 2 und RXBATT.

## Seite 3 Übersicht
![Seite 3 Flug-Details (Simulator)](../../docs/bilder-simulator/Gas%20Engine%20ECU%20-%20Sim%20800x480%2009%20Seite%203%20Flug-Details.png)

Links die Höchst- und Tiefstwerte seit dem letzten Zurücksetzen, rechts die Flüge. Einen Flug antippen zeigt seine Werte; **FLUG n LÖSCHEN** löscht ihn einzeln (die Nummern rücken nach). **ÜBERSICHT ZURÜCKSETZEN** löscht nach Rückfrage die Höchstwerte und die Flugliste; der Tank bleibt.

## Kompaktansicht
![Kompaktansicht (Simulator)](../../docs/bilder-simulator/Gas%20Engine%20ECU%20-%20Sim%20784x316%2014%20Kompakt%20Alarm.png)

Oben Motorlaufzeit, Zustand, Zündung, Choke und Empfang; vier Ringe (Drehzahl, heissester Zylinder, Tank mit Restzeit, erster Akku) und acht Felder. Keine Seiten; Akku-Details und Flugliste im Vollbild.

## Bedienung
| | |
|---|---|
| Flug beginnen | Motorschalter Aus → Zündung. Ein pausierter Flug läuft weiter. |
| Flug beenden | Motorschalter → Aus, Rückfrage «Flug beendet?»: JA speichert, NEIN lässt ihn als Pause offen. |
| Vollgetankt | VOLLGETANKT auf Seite 1, dann JA: Verbrauch 0, Tank 100 %. |
| Ohne Berührung | Das Drehrad blättert die Seiten. Rückfragen, VOLLGETANKT und die Flugliste brauchen Berührung. |

---
[← Start](../Home.md) | [Zurück](Einrichten.md) | [Weiter →](Alarme.md)
