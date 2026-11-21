[🇬🇧 English](../en/Lua-Studio.md) · 🇩🇪 Deutsch

# Lua-Studio

> **Am PC einrichten mit [Lua-Studio](https://github.com/Raffi1202/lua-studio)**: Bildschirm einteilen, Werte, Alarme und Symbole wählen, auf die Funke übertragen.

Lua-Studio legt je Modell eine Datei an: `SD:/scripts/studio/<Modell>.gas_ecu.lua` bzw. `<Modell>.gas_carb.lua` (Sonderzeichen und Umlaute im Namen werden zu «_»). Einstellungen, Grenzen und die Kästchen der Kompaktansicht oder von Seite 1 kommen dann aus dieser Datei, und das Menü zeigt «Studio-Datei geladen». Ohne Datei bleibt alles wie bisher.

- Spätere Änderungen im Widget-Menü landen in `<Modell>.gas_ecu.funke.lua` (bzw. `.gas_carb.funke.lua`).
- **Zurück auf Studio-Stand** verwirft sie nach einer Rückfrage. Ohne Studio-Datei heisst der Knopf **Zurück auf Standard** und setzt alle Einstellungen zurück; Sensoren bleiben.
- Eine kaputte oder zu neue Datei zeigt unten 8 s lang einen Hinweis, danach ein «!» oben rechts; das Widget arbeitet wie ohne Studio.
- «Alarm auch bei Motor aus» ist je Grenze das Feld `beiMotorAus`. Ein Grenzeintrag ohne Zahl ändert die Werkgrenze nie; nur «aus» schaltet einen Alarm ganz aus.

Was jedes Widget Lua-Studio anbietet, steht in [`studio/gas_ecu/beschreibung.json`](../../studio/gas_ecu/beschreibung.json) und [`studio/gas_carb/beschreibung.json`](../../studio/gas_carb/beschreibung.json). Die Widgets nutzen derzeit Lua-Studio-Format 1 plus die Format-2-Einstellung `beiMotorAus`.

---
[← Start](../Home.md) | [Zurück](Alarme.md) | [Weiter →](FAQ.md)
