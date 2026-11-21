# Gas Engine Lua – Sprachansagen

Stand 19.11.2026: «Schlepp» durch «Flug» ersetzt (beide Widgets nutzen flug_beendet/pause/weiter). Davor 16.11.2026 (Nacht: «Nummer» bei Zylindern, Empfängerakkus und Empfängern ergänzt, damit «zwei» nicht als Anzahl verstanden wird). Diese Texte braucht das Widget als Sprachdateien. Sprechweise (Wunsch des Users, 16.11.2026 Nacht): natürlich, nicht abgelesen; nach «Nummer eins/zwei» bzw. vor dem Zustand eine kurze Pause (im Text als Komma), Alarme beginnen mit «Achtung!». «ECU» und «RB» sind durch «Motorsteuerung» und «Stromweiche» ersetzt, damit die Aussprache sicher stimmt.

Zahlen mit Einheit (z. B. «205 Grad», «3,4 Volt», «18 Prozent») sagt Ethos selbst an (`system.playNumber`); dafür braucht es keine Dateien. Das Widget spielt erst den Text, dann bei Bedarf die Zahl.

Dateiname = Name der WAV-Datei ohne Endung (klein, ohne Umlaute, ohne Leerzeichen). Ablage auf dem Sender im Skriptordner des Widgets: `scripts/gas_ecu/audio/de/` und `…/audio/en/` bzw. `scripts/gas_carb/audio/de/` und `…/en/` (im Repo unter `src/…/audio/`). Ab ECU 1.4.0 / Vergaser 0.4.0 haben beide Widgets dieselben 58 Dateien je Sprache; Englisch mit en-US-Wavenet-F, Tempo 1.0. Erzeugt mit Google TTS de-DE-Wavenet-E, Tempo 1.1, WAV A-law mono 16 kHz (wie die FrSky-Originale).

Die folgenden Ansagen (insgesamt 58 je Sprache, mit den Akku-Rollen weiter unten) gelten für **Gas Engine ECU**; der Vergaser nutzt sie ebenfalls (ab 0.3.0 auch die Rollen-Ansagen `empf1_…`, `empf2_…`, `anlass_…`).

## Motor
| Dateiname | Text | English | Wann |
|---|---|---|---|
| zyl1_heiss | Zylinder Nummer eins, zu heiss | Cylinder one, too hot | Warnung Temperatur Zylinder 1 |
| zyl2_heiss | Zylinder Nummer zwei, zu heiss | Cylinder two, too hot | Warnung Temperatur Zylinder 2 |
| zyl1_alarm | Achtung! Zylinder Nummer eins, viel zu heiss | Warning! Cylinder one, overheating | Alarm Temperatur Zylinder 1 |
| zyl2_alarm | Achtung! Zylinder Nummer zwei, viel zu heiss | Warning! Cylinder two, overheating | Alarm Temperatur Zylinder 2 |
| zyl_ungleich | Zylinder ungleich warm | Cylinder temperatures uneven | Unterschied Z1/Z2 zu gross |
| drehzahl_hoch | Drehzahl zu hoch | RPM too high | Drehzahl über Grenze |
| motor_aus | Achtung! Motor ist aus | Warning! Engine stopped | Motor stoppt, obwohl der Motorschalter auf Ein steht |
| choke_aus | Bitte Choke ausschalten | Please turn the choke off | Choke noch an, Motor warm oder Gas hoch |
| spritdruck_tief | Spritdruck tief | Fuel pressure low | Warnung Kraftstoffdruck |
| spritdruck_alarm | Achtung! Spritdruck viel zu tief | Warning! Fuel pressure critical | Alarm Kraftstoffdruck |

## Kraftstoff
| Dateiname | Text | English | Wann |
|---|---|---|---|
| tank_reserve | Tank auf Reserve | Fuel on reserve | Tank unter Reserve-Grenze |
| tank_leer | Achtung! Tank fast leer | Warning! Fuel tank almost empty | Tank unter Alarm-Grenze |
| tank_voll | Tank auf voll gesetzt | Fuel tank set to full | Bestätigung nach «Ja, vollgetankt» |

## Akkus und Elektrik
| Dateiname | Text | English | Wann |
|---|---|---|---|
| empf1_tief | Empfängerakku Nummer eins, Spannung tief | Receiver battery one, voltage low | Warnung tiefste Zelle, Rolle Empfänger 1 |
| empf2_tief | Empfängerakku Nummer zwei, Spannung tief | Receiver battery two, voltage low | Warnung tiefste Zelle, Rolle Empfänger 2 |
| anlass_tief | Anlasserakku, Spannung tief | Starter battery, voltage low | Warnung tiefste Zelle, Rolle Anlasser |
| empf1_alarm | Achtung! Empfängerakku Nummer eins, fast leer | Warning! Receiver battery one, almost empty | Alarm tiefste Zelle, Rolle Empfänger 1 |
| empf2_alarm | Achtung! Empfängerakku Nummer zwei, fast leer | Warning! Receiver battery two, almost empty | Alarm tiefste Zelle, Rolle Empfänger 2 |
| anlass_alarm | Achtung! Anlasserakku, fast leer | Warning! Starter battery, almost empty | Alarm tiefste Zelle, Rolle Anlasser |
| empf1_ungleich | Empfängerakku Nummer eins, Zellen ungleich | Receiver battery one, cells unbalanced | Zellenunterschied, Rolle Empfänger 1 |
| empf2_ungleich | Empfängerakku Nummer zwei, Zellen ungleich | Receiver battery two, cells unbalanced | Zellenunterschied, Rolle Empfänger 2 |
| anlass_ungleich | Anlasserakku, Zellen ungleich | Starter battery, cells unbalanced | Zellenunterschied, Rolle Anlasser |
| ecu_tief | Spannung der Motorsteuerung tief | ECU voltage low | Warnung ECU-Spannung |
| ecu_alarm | Achtung! Spannung der Motorsteuerung viel zu tief | Warning! ECU voltage critical | Alarm ECU-Spannung |
| servostrom_hoch | Servostrom zu hoch | Servo current too high | Strom eines Stromweichen-Kanals über Grenze |
| rb_fehler | Achtung! Fehler an der Stromweiche | Warning! Power switch fault | Stromweiche meldet einen Fehlerzustand |

## Empfang und Telemetrie
| Dateiname | Text | English | Wann |
|---|---|---|---|
| rx1_schwach | Empfänger Nummer eins, Empfang schwach | Receiver one, weak signal | RSSI Empfänger 1 unter Grenze |
| rx2_schwach | Empfänger Nummer zwei, Empfang schwach | Receiver two, weak signal | RSSI Empfänger 2 unter Grenze |
| telemetrie_weg | Achtung! Telemetrie verloren | Warning! Telemetry lost | keine Telemetrie mehr |
| telemetrie_da | Telemetrie wieder da | Telemetry recovered | Telemetrie zurück |

## Flüge und Übersicht
| Dateiname | Text | English | Wann |
|---|---|---|---|
| flug_beendet | Flug gespeichert | Flight saved | nach «Ja, beendet» (danach optional Verbrauch als Zahl) |
| flug_pause | Flug pausiert | Flight paused | nach «Nein, nur Pause» |
| flug_weiter | Flug geht weiter | Flight resumed | Motorschalter nach einer Pause wieder auf Ein |
| uebersicht_geloescht | Übersicht zurückgesetzt | Summary reset | nach «Ja, zurücksetzen» |

## Allgemein
| Dateiname | Text | English | Wann |
|---|---|---|---|
| ansagen_aus | Ansagen aus | Announcements off | Stumm-Schalter ein |
| ansagen_ein | Ansagen ein | Announcements on | Stumm-Schalter aus |

## Zum Einfügen im Sprach-Tab (Dateiname = Text)
```
zyl1_heiss = Zylinder Nummer eins, zu heiss
zyl2_heiss = Zylinder Nummer zwei, zu heiss
zyl1_alarm = Achtung! Zylinder Nummer eins, viel zu heiss
zyl2_alarm = Achtung! Zylinder Nummer zwei, viel zu heiss
zyl_ungleich = Zylinder ungleich warm
drehzahl_hoch = Drehzahl zu hoch
motor_aus = Achtung! Motor ist aus
choke_aus = Bitte Choke ausschalten
spritdruck_tief = Spritdruck tief
spritdruck_alarm = Achtung! Spritdruck viel zu tief
tank_reserve = Tank auf Reserve
tank_leer = Achtung! Tank fast leer
tank_voll = Tank auf voll gesetzt
empf1_tief = Empfängerakku Nummer eins, Spannung tief
empf2_tief = Empfängerakku Nummer zwei, Spannung tief
anlass_tief = Anlasserakku, Spannung tief
empf1_alarm = Achtung! Empfängerakku Nummer eins, fast leer
empf2_alarm = Achtung! Empfängerakku Nummer zwei, fast leer
anlass_alarm = Achtung! Anlasserakku, fast leer
empf1_ungleich = Empfängerakku Nummer eins, Zellen ungleich
empf2_ungleich = Empfängerakku Nummer zwei, Zellen ungleich
anlass_ungleich = Anlasserakku, Zellen ungleich
ecu_tief = Spannung der Motorsteuerung tief
ecu_alarm = Achtung! Spannung der Motorsteuerung viel zu tief
servostrom_hoch = Servostrom zu hoch
rb_fehler = Achtung! Fehler an der Stromweiche
rx1_schwach = Empfänger Nummer eins, Empfang schwach
rx2_schwach = Empfänger Nummer zwei, Empfang schwach
telemetrie_weg = Achtung! Telemetrie verloren
telemetrie_da = Telemetrie wieder da
flug_beendet = Flug gespeichert
flug_pause = Flug pausiert
flug_weiter = Flug geht weiter
uebersicht_geloescht = Übersicht zurückgesetzt
ansagen_aus = Ansagen aus
ansagen_ein = Ansagen ein
```

## Akkus nach Rolle (Gas Engine ECU ab 1.2.0, Gas Engine Carb ab 0.3.0)
Jeder der bis zu 3 Akkus hat im Menü eine Rolle: Empfänger, Zündung, Anlasser, ECU oder Akku. Die Ansage richtet sich nach der Rolle (Dateien `empf1_…`, `empf2_…`, `anlass_…`). Für die Rolle «Akku» und für Rollen ohne eigene Datei kommt die allgemeine Ansage «Akku Nummer n» (`akku1_…` bis `akku3_…`, gleiche Dateien wie beim Vergaser). Ausserdem nutzt die ECU ab 1.2.0 `zyl3_…` und `zyl4_…` des Vergasers.

**Seit ECU 1.4.0 / Vergaser 0.4.0 vorhanden** (vorher kam die allgemeine Ansage):
| Dateiname | Text DE | Text EN |
|---|---|---|
| empf3_tief | Empfängerakku Nummer drei, Spannung tief | Receiver battery three, voltage low |
| empf3_alarm | Achtung! Empfängerakku Nummer drei, fast leer | Warning! Receiver battery three, almost empty |
| empf3_ungleich | Empfängerakku Nummer drei, Zellen ungleich | Receiver battery three, cells unbalanced |
| zuend_tief | Zündakku, Spannung tief | Ignition battery, voltage low |
| zuend_alarm | Achtung! Zündakku, fast leer | Warning! Ignition battery, almost empty |
| zuend_ungleich | Zündakku, Zellen ungleich | Ignition battery, cells unbalanced |
| ecuakku_tief | Akku der Motorsteuerung, Spannung tief | ECU battery, voltage low |
| ecuakku_alarm | Achtung! Akku der Motorsteuerung, fast leer | Warning! ECU battery, almost empty |
| ecuakku_ungleich | Akku der Motorsteuerung, Zellen ungleich | ECU battery, cells unbalanced |

Eingetragen in `WAV_DA` in beiden `kern.lua`.

## Nur Gas Engine Carb (zusätzlich bzw. ersetzt, 17.11.2026)
Die Akku-Ansagen sind beim Vergaser allgemein formuliert («Akku» statt «Empfängerakku»/«Anlasserakku») und ersetzen dort die gleichnamigen Dateien. «Zylinder» ist als «Zilinder» geschrieben, damit die Stimme es richtig ausspricht.
```
zyl3_heiss = Zilinder Nummer drei, zu heiss
zyl3_alarm = Achtung! Zilinder Nummer drei, viel zu heiss
zyl4_heiss = Zilinder Nummer vier, zu heiss
zyl4_alarm = Achtung! Zilinder Nummer vier, viel zu heiss
akku1_tief = Akku Nummer eins, Spannung tief
akku2_tief = Akku Nummer zwei, Spannung tief
akku3_tief = Akku Nummer drei, Spannung tief
akku1_alarm = Achtung! Akku Nummer eins, fast leer
akku2_alarm = Achtung! Akku Nummer zwei, fast leer
akku3_alarm = Achtung! Akku Nummer drei, fast leer
akku1_ungleich = Akku Nummer eins, Zellen ungleich
akku2_ungleich = Akku Nummer zwei, Zellen ungleich
akku3_ungleich = Akku Nummer drei, Zellen ungleich
```

Englisch dazu:
```
zyl3_heiss = Cylinder three, too hot
zyl4_heiss = Cylinder four, too hot
zyl3_alarm = Warning! Cylinder three, overheating
zyl4_alarm = Warning! Cylinder four, overheating
akku1_tief = Battery one, voltage low
akku2_tief = Battery two, voltage low
akku3_tief = Battery three, voltage low
akku1_alarm = Warning! Battery one, almost empty
akku2_alarm = Warning! Battery two, almost empty
akku3_alarm = Warning! Battery three, almost empty
akku1_ungleich = Battery one, cells unbalanced
akku2_ungleich = Battery two, cells unbalanced
akku3_ungleich = Battery three, cells unbalanced
```
