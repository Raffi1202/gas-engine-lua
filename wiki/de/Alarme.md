[🇬🇧 English](../en/Alarms.md) · 🇩🇪 Deutsch

# Alarme

> **Vorabversion:** Gas Engine ECU 1.11.0 / Carb 0.11.0 sind im Ethos-Simulator getestet; der Sendertest an der X18RS folgt. Benutzung auf eigene Gefahr.

Jeder überwachte Wert hat **zwei Schwellen**: **Warnung** (orange, Ansage) und **Alarm** (rot, Ansage und, wenn eingeschaltet, Vibration). Die Ansage wiederholt sich alle «Wiederholung alle» Sekunden (Standard 30 s), solange der Zustand dauert, und hört auf, sobald der Wert wieder gut ist. Der Stumm-Schalter schaltet alle Ansagen stumm; die Farben bleiben. Eine 0 schaltet eine Grenze aus.

## Meldungen, die immer kommen
Diese schaltet weder der Motorschalter noch «Alarm auch bei Motor aus» stumm:

| Meldung | Wann | Stufe |
|---|---|---|
| TELEMETRIE WEG | Keine Telemetrie («Telemetrie wieder da», wenn sie zurückkommt) | Warnung |
| MOTOR AUS | Motor steht, obwohl der Motorschalter auf Zündung steht (nach der Startsperre) | Alarm |
| CHOKE AUS! | Choke an, Motor läuft und ist warm oder Gas hoch | Warnung |
| STROMWEICHE FEHLER | Die Stromweiche meldet Failsafe, verlorenen Empfänger, kein Signal, Überlast oder einen fehlerhaften Kanal | Alarm |

## Grenzen
Zylinder zu heiss / überhitzt, Zylindertemperaturen ungleich, Drehzahl zu hoch, Spritdruck tief / kritisch (ECU, nur bei laufendem Motor), ECU-Spannung (ECU), Sprit auf Reserve, Tank fast leer (Prozent immer; Restzeit nur bei laufendem Motor), Akkuspannung tief / fast leer, Zellen ungleich, Servostrom zu hoch, schwaches Signal. «Zylindertemperaturen ungleich» kommt auch bei stehendem Motor und nach dem Abstellen, nur nicht während der Startsperre nach dem Anlassen.

## Alarm auch bei Motor aus
Werkseinstellung: Alle Warnungen und Alarme kommen auch mit dem Motorschalter auf Aus. In der Menügruppe **Alarm auch bei Motor aus** lässt sich der Haken je Grenze entfernen; der Schalter **alle** setzt alle Haken auf einmal. Ohne Haken sind bei Motorschalter auf Aus nur Ton, Ansage und Vibration dieses Werts still; die Anzeige bleibt orange oder rot. Zurück auf Zündung kommt die Ansage wieder. Ohne zugewiesenen Motorschalter hat die Einstellung keine Wirkung.

In Lua-Studio heisst die Einstellung «auch bei Motor aus» (Feld `beiMotorAus`).

## Ganz still nur mit «aus»
Ganz ausgeschaltet ist eine Grenze nur mit 0 im Menü oder «aus» in Lua-Studio. Ein Lua-Studio-Grenzeintrag ohne Zahl ändert die Werkgrenze nie.

---
[← Start](../Home.md) | [Zurück](Anzeige.md) | [Weiter →](Lua-Studio.md)
