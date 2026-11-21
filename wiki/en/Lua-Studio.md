🇬🇧 English · [🇩🇪 Deutsch](../de/Lua-Studio.md)

# Lua-Studio

> **Configure on your PC with [Lua-Studio](https://github.com/Raffi1202/lua-studio)** – arrange the screen, choose values, alarms and symbols, then transfer to the radio. Download: [latest release](https://github.com/Raffi1202/lua-studio/releases/latest) · [Wiki](https://github.com/Raffi1202/lua-studio/tree/main/wiki)

Lua-Studio creates one file per model: `SD:/scripts/studio/<model>.gas_ecu.lua` or `<model>.gas_carb.lua` (special characters and umlauts in the name become «_»). Settings, limits and the boxes of the compact view or page 1 then come from this file, and the menu shows «Studio file loaded». Without the file everything works as before.

- Changes made in the widget menu afterwards are stored in `<model>.gas_ecu.funke.lua` (or `.gas_carb.funke.lua`).
- **Back to Studio state** discards them after a question. Without a Studio file the button is called **Back to defaults** and resets all settings; sensors stay.
- A broken or too new file shows a note at the bottom for 8 s, then a «!» top right; the widget works as without Studio.
- «Alarm also with motor off» is the field `beiMotorAus` per limit. A limit entry without a number never changes the factory limit; only «off» switches an alarm off completely.

What each widget offers to Lua-Studio is described in [`studio/gas_ecu/beschreibung.json`](../../studio/gas_ecu/beschreibung.json) and [`studio/gas_carb/beschreibung.json`](../../studio/gas_carb/beschreibung.json). The widgets currently use Lua-Studio format 1 plus the format 2 setting `beiMotorAus`.

---
[← Home](../Home.md) | [Previous](Alarms.md) | [Next →](FAQ.md)
