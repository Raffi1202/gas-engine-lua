🇬🇧 English · [🇩🇪 Deutsch](../de/Installation.md)

# Installation

The steps are the same for both widgets; replace the file and folder name (`Gas-Engine-ECU-1.11.0.zip` / `gas_ecu` or `Gas-Engine-Carb-0.11.0.zip` / `gas_carb`).

## With FrSky Suite (recommended)
1. Download the package ZIP from the latest **release** on GitHub. Do not unzip it.
2. Connect the radio to the computer by USB and choose **Ethos Suite** on the radio.
3. Open FrSky Suite › **Lua library** › **Install from local ZIP** › choose the ZIP.
4. Disconnect the radio and restart it.

## Without Suite, via the SD card
1. Unzip the file on the computer. It contains the folder `gas_ecu` or `gas_carb`.
2. Copy the whole folder to `SD:/scripts/` on the radio.
3. On a Mac, run `dot_clean -m` on the folder afterwards, otherwise hidden files get in the way.
4. Restart the radio.

> The X18RS with Ethos 26.2 loads scripts from the **SD card only**. If the folder is in the internal memory (RADIO), the widget does not appear in the list.

## Update and remove
- **Update:** install the new ZIP the same way. Settings, tank, flights and assignments stay, across several versions.
- **Remove:** delete it in FrSky Suite under Lua library, or delete the folder `SD:/scripts/gas_ecu/` (or `gas_carb/`); the saved data in its `daten/` subfolder goes with it.

## Upgrading from Motoren ECU / Vergaser
Up to ECU 1.9.0 / Vergaser 0.9.0 the widgets were called **Motoren ECU** (folder `motoren_ecu`) and **Motoren Vergaser** (folder `motoren_vergaser`). The new names are **Gas Engine ECU** (`gas_ecu`) and **Gas Engine Carb** (`gas_carb`). This change is **breaking**:
1. Install the new package as above.
2. On each model, choose the widget **again** on its screen (Ethos knows the widget by its key, which has changed).
3. Assign the sensors with **Search** and set engine switch, cylinders, tank and batteries again. Settings, tank and flights of the old version are not taken over.
4. Lua-Studio: a file with the old name (`<model>.motoren_ecu.lua` / `.motoren_vergaser.lua`) is still read; the log says «old studio file found, please re-transfer». Re-transfer it from Lua-Studio.
5. Delete the old folder `SD:/scripts/motoren_ecu/` or `motoren_vergaser/`.

> Settings, tank and flights are stored in `daten/<model>.txt` in the script folder. The new widget tries to read the old file once; to be safe, copy `SD:/scripts/motoren_ecu/daten/` to `SD:/scripts/gas_ecu/daten/` (or `motoren_vergaser/daten/` to `gas_carb/daten/`) before you delete the old folder.

---
[← Home](../Home.md) | [Previous](Carb.md) | [Next →](Setup.md)
