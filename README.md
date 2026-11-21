# Gas Engine ECU / Carb – telemetry widgets for gas engines (FrSky Ethos)

**English** · [Deutsch](README.de.md) · Documentation: [Wiki (English)](wiki/en/ECU.md) · [Wiki (Deutsch)](wiki/de/ECU.md)

> **Configure on your PC with [Lua-Studio](https://github.com/Raffi1202/lua-studio)** – arrange the screen, choose values, alarms and symbols, then transfer to the radio. Download: [latest release](https://github.com/Raffi1202/lua-studio/releases/latest) · [Wiki](https://github.com/Raffi1202/lua-studio/tree/main/wiki)

Two full-screen widgets for FrSky radios running **Ethos 26.1 or newer**. They show the telemetry of a gas engine on
three pages (engine, electrics, summary with flight list) or in a compact view, and warn with colour, voice and
vibration. Display, menu and voice in German and English.

| Widget | For | Version | Folder on the SD card |
|---|---|---|---|
| **Gas Engine ECU** | Fuel-injected engines with an ECU (RPM, cylinders, fuel pressure, ECU voltage) | 1.10.0 | `SD:/scripts/gas_ecu/` |
| **Gas Engine Carb** | Carburettor engines, e.g. with FrSky AES / AES II | 0.10.0 | `SD:/scripts/gas_carb/` |

![Gas Engine ECU page 1 (English, Ethos simulator)](docs/bilder-simulator/Gas%20Engine%20ECU%20-%20Sim%20800x480%2012%20Englisch%20Seite%201%20Alarm.png)

**Status:** public pre-release (public beta). Gas Engine ECU 1.10.0 / Carb 0.10.0 are tested in the Ethos simulator; the
transmitter test on the X18RS follows. Use at your own risk. License: GPL-3.0, see below.

**New in Gas Engine ECU 1.10.0 / Carb 0.10.0 (renamed from Motoren ECU / Vergaser):** «Alarm also with motor off» per limit (menu and Lua-Studio, on by default);
a Lua-Studio limit without a number keeps the factory limit; memory is freed on model change.

## Quick start

1. Download `Gas-Engine-ECU-1.10.0.zip` or `Gas-Engine-Carb-0.10.0.zip` from the latest **release**.
2. Connect the radio by USB, choose **Ethos Suite** on the radio and open **FrSky Suite** on the computer.
3. Suite › **Lua library** › **Install from local ZIP** › choose the ZIP (do not unzip it). Restart the radio.
4. Model › **DISP** › new screen with layout **full screen** › choose the widget.
5. Long-press the widget › **Configure widget** › **Search**. Then set engine switch, throttle channel, cylinders, tank and batteries.

Without the Suite: copy the folder from the ZIP to `SD:/scripts/`. The X18RS with Ethos 26.2 loads scripts from the
SD card only. Updating keeps settings, tank, flights and assignments.
**Upgrading from Motoren ECU / Vergaser (breaking):** choose the widget again on each model and search the sensors
again, see [Wiki › Installation](wiki/en/Installation.md#upgrading-from-motoren-ecu--vergaser).

## Documentation and testing

| What | File |
|---|---|
| Wiki | [English](wiki/en/ECU.md) · [Deutsch](wiki/de/ECU.md) |
| Manual ECU (PDF) | [English](docs/Gas%20Engine%20ECU%20-%20Manual.pdf) · [German](docs/Gas%20Engine%20ECU%20-%20Anleitung.pdf) |
| Manual Carb (PDF) | [English](docs/Gas%20Engine%20Carb%20-%20Manual.pdf) · [German](docs/Gas%20Engine%20Carb%20-%20Anleitung.pdf) |
| Test guide (German, checklist) | [TESTLEITFADEN.md](TESTLEITFADEN.md) |
| Voice texts (DE/EN) | [docs/Sprachansagen.md](docs/Sprachansagen.md) |
| Bugs and wishes | GitHub › Issues › New issue |
| Versions | [CHANGELOG.md](CHANGELOG.md) |

## Radios and test status

| Radio | Display | Status |
|---|---|---|
| X18RS / X18S / X18 | 480×320 | tested on the radio (X18RS, Ethos 26.2.0) |
| X20 / X20S / X20RS / X20 Pro | 800×480 | Ethos simulator only |
| X14 / X14S | 640×360 | not tested |
| X10 / Twin X Lite | 480×272 | not tested |

Tested on a real X18RS (with a telemetry simulator, 48 sensors, receiver SR10 Plus): sensor search, power switch alarm,
batteries, battery type, language, switch name field, the Lua-Studio file. **Never flown yet.** Not yet tested on the
radio: everything new in 1.10.0 / 0.10.0, every single menu item, announcements in flight, other radios.
Questions, «Refuelled» and the flight list need touch; the rotary encoder only changes pages.

## Lua-Studio

With the PC app Lua-Studio you design every box yourself (value, number, ring, bar, graph, status, colours, limits).
Lua-Studio writes one file per model to `SCRIPTS:/studio/`; the widget reads it on model change. Without the file
everything works as before. What the widgets offer is described in
[studio/gas_ecu/beschreibung.json](studio/gas_ecu/beschreibung.json) and
[studio/gas_carb/beschreibung.json](studio/gas_carb/beschreibung.json).

## Repository layout

| Content | Location |
|---|---|
| Widget ECU (as on the SD card, voice files in `audio/de` and `audio/en`) | `src/gas_ecu/` |
| Widget Carb | `src/gas_carb/` |
| Manuals (HTML source, PDF next to it) | `docs/anleitung/`, `docs/*.pdf` |
| Simulator screenshots | `docs/bilder-simulator/` |
| Tests, explained in [test/LIESMICH.md](test/LIESMICH.md) (German) | `test/` |

## Development

Not needed for testers. The Mac tests run with Lua 5.4 from the repo folder:

```sh
lua test/motor_aus_test.lua
lua test/suche_test.lua
lua test/update_test.lua <felder.lua of the previous version> src/gas_ecu/felder.lua
```

The simulator flows in `test/` are meant for a driver based on the Ethos WASM simulator («ethos-tools» plugin); that
driver, the random test and the PDF/package scripts belong to the author's build kit and are not part of this repo
(folder in the environment variable `ETHOS_LUA_TOOLS`). Version only in `src/<folder>/main.lua`; two widgets with
their own version numbers, so two tag series `gas-ecu-vX.Y.Z` and `gas-carb-vX.Y.Z`.

## Related projects

| Project | What it does |
|---|---|
| [Electric](https://github.com/Raffi1202/electric-lua) | Ethos widget for electric models |
| [Heli](https://github.com/Raffi1202/heli-lua) | Ethos widget for helicopters (Rotorflight) |
| [Jet](https://github.com/Raffi1202/jet-lua) | Ethos widget for turbines (several ECU brands) |
| [Glider](https://github.com/Raffi1202/glider-lua) | Ethos widget for gliders (vario, thermals) |
| [Lua-Studio](https://github.com/Raffi1202/lua-studio) | PC app to set up the widgets (Mac/Windows) |
| [Telemetry simulator](https://github.com/Raffi1202/telemetrie-simulator) | ESP32-S3 that simulates FrSky telemetry sensors |
| [Ethos model converter](https://github.com/Raffi1202/ethos-modell-konverter) | Move models between Ethos radios |
| [Ethos sensor IDs](https://github.com/Raffi1202/ethos-sensor-ids) | Which sensor Ethos creates for each AppID |

## License

GPL-3.0, see [LICENSE](LICENSE).
