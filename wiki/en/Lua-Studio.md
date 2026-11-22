🇬🇧 English · [🇩🇪 Deutsch](../de/Lua-Studio.md)

# Lua-Studio

> **Configure on your PC with [Lua-Studio](https://github.com/Raffi1202/lua-studio)** – arrange the screen, choose values, alarms and colours, then transfer to the radio. Download: [latest release](https://github.com/Raffi1202/lua-studio/releases/latest) · [Wiki](https://github.com/Raffi1202/lua-studio/tree/main/wiki)

Lua-Studio creates one file per model: `SD:/scripts/studio/<model>.gas_ecu.lua` or `<model>.gas_carb.lua` (special characters and umlauts in the name become «_»). Settings, limits and the boxes of the compact view or page 1 then come from this file, and the menu shows «Studio file loaded». Without the file everything works as before.

- Changes made in the widget menu afterwards are stored in `<model>.gas_ecu.funke.lua` (or `.gas_carb.funke.lua`).
- **Back to Studio state** discards them after a question. Without a Studio file the button is called **Back to defaults** and resets all settings; sensors stay.
- A broken or too new file shows a note at the bottom for 8 s, then a «!» top right; the widget works as without Studio.
- «Alarm also with motor off» is the field `beiMotorAus` per limit. A limit entry without a number never changes the factory limit; only «off» switches an alarm off completely.

What each widget offers to Lua-Studio is described in [`studio/gas_ecu/beschreibung.json`](../../studio/gas_ecu/beschreibung.json) and [`studio/gas_carb/beschreibung.json`](../../studio/gas_carb/beschreibung.json). The widgets currently use Lua-Studio format 1 plus the format 2 setting `beiMotorAus`.

---
[← Home](../Home.md) | [Previous](Alarms.md) | [Next →](FAQ.md)

## Cylinders and tank in your own layout (from ECU 1.11.0 / Carb 0.11.0)

Two display types draw a whole group of page 1 inside one box of your layout:

| `darstellung` | `w` | Minimum size (at 800 px width) | Shows |
|---|---|---|---|
| `zylinder` | `lua:cht_max` | 160 × 220 | All cylinder columns with temperature, trend arrow, peak mark, «Diff» and «max»; colours and limits from the cylinder settings |
| `tank` | `lua:tank_proz` | 160 × 220 | Tank column with %, ml, used, flow, time left and the button REFUELLED (with confirmation, same as page 1) |

- Each type at most once per view; a second one, a wrong `w` or an unknown type shows as a number and the «!» note.
- The content scales with the box; in small boxes «max» and «Flow» are left out (as on small screens).
- Only `titel` can be changed; colours, `min`/`max`, `zusatz` and `stufen` have no effect here.
- Older widget versions show such a box as a plain number. Older Lua-Studio versions do not offer the types.

### Studio layout not showing?
1. Copy the file to `scripts/studio/` on the SD card or in the radio memory (`SCRIPTS:/studio/`, `SD:/scripts/studio/` and `RADIO:/scripts/studio/` are all searched).
2. **One layout for all models:** save the Lua-Studio file as `Standard.gas_ecu.lua` / `Standard.gas_carb.lua`. Order: choice in the widget menu › file of the model (`<model>.gas_ecu.lua`) › `Standard` file › built-in display. The menu shows «Default (all models)»; changes made on the radio stay per model (`<model>.gas_ecu.funke.lua`). A model named «Standard» uses the file as its own model file.
3. If the file name does not match the model name: widget menu › **Studio layout** › pick the file (place in brackets). «automatic (model name)» uses `<model>.gas_ecu.lua` / `<model>.gas_carb.lua`.
3. Other window size (e.g. with top and bottom bar, 784 × 316, or a smaller radio): the widget scales the closest view and shows «Studio: view 800x480 adapted» for 5 s. Boxes too small for their type become numbers or are left out.
4. A line at the bottom «Studio: file faulty (…)» or «Studio: no matching view» tells why the default display is shown. Export the file again from Lua-Studio.
5. The info file `SCRIPTS:/studio/<model>.<lua>.info.json` shows `studioQuelle`, `studioWahl`, `ansichtGenutzt`, `angepasst` and `hinweis`; Lua-Studio reads it.
