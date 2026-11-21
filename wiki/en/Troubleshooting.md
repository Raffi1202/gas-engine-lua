🇬🇧 English · [🇩🇪 Deutsch](../de/Fehlerbehebung.md)

# Troubleshooting

| What you see | What to do |
|---|---|
| The widget is not in the list | Folder not on the SD card under `scripts/`, or Lua memory full. Check the folder, restart, remove rarely used scripts. |
| «full screen only» | The area is smaller than the compact view. Choose «full screen» or the layout with top and bottom bar. |
| Dashes everywhere, «NO DATA» | No telemetry or no sensors. Receiver on? Model › Telemetry › Discover sensors, then «Search» in the widget. |
| One field shows a dash | The sensor is assigned but has no value. Check it in Ethos under Telemetry. |
| Wrong sensor after the search | The top of the menu lists fields where several sensors matched. Choose by hand. |
| «Set cell count in menu» | Plain voltage sensor without cell count: set «Battery n cells». |
| Constant cell warning with LiFe or NiMH | Set «Battery n type» correctly, the limits follow. |
| No announcements | «Announcements» on? Mute switch off? Radio volume? `audio/` folder copied? |
| An alarm does not come with the motor off | «Alarm also with motor off» is cleared for this value (menu or Lua-Studio). |
| No flight in the list | Engine switch not assigned or «Position off» wrong. |
| Small red error text bottom left | A script error. Take a screenshot and report it as a GitHub issue with the log (FrSky Suite › Debug log). |

## Lua memory («too much RAM»)
All Lua scripts on the radio share one Lua memory (about 2048 KB on the X18RS). If Ethos reports «too much RAM» or not enough Lua memory, **switch the radio off and on again**. Since ECU 1.8.1 / Vergaser 0.8.1 the widget frees its memory after a change to a model without it (about 4 KB stay instead of about 127 KB, measured in the simulator).

---
[← Home](../Home.md) | [Previous](FAQ.md) | [Next →](Changelog.md)

### Studio layout not showing?
1. Copy the file to `scripts/studio/` on the SD card or in the radio memory (`SCRIPTS:/studio/`, `SD:/scripts/studio/` and `RADIO:/scripts/studio/` are all searched).
2. If the file name does not match the model name: widget menu › **Studio layout** › pick the file (place in brackets). «automatic (model name)» uses `<model>.gas_ecu.lua` / `<model>.gas_carb.lua`.
3. Other window size (e.g. with top and bottom bar, 784 × 316, or a smaller radio): the widget scales the closest view and shows «Studio: view 800x480 adapted» for 5 s. Boxes too small for their type become numbers or are left out.
4. A line at the bottom «Studio: file faulty (…)» or «Studio: no matching view» tells why the default display is shown. Export the file again from Lua-Studio.
5. The info file `SCRIPTS:/studio/<model>.<lua>.info.json` shows `studioQuelle`, `studioWahl`, `ansichtGenutzt`, `angepasst` and `hinweis`; Lua-Studio reads it.
