🇬🇧 English · [🇩🇪 Deutsch](../de/Einrichten.md)

# Setup

## Screen
1. Select the model, press **DISP** and add a new screen with the layout **full screen**.
2. Tap the empty area and choose **Gas Engine ECU** or **Gas Engine Carb**. Without sensors there are dashes everywhere, which is correct.
3. In the layout with top and bottom bar (one widget) the widget shows a **compact view** by itself. In an even smaller area it shows «full screen only».

## Sensors
1. Let Ethos find the sensors first: Model › Telemetry › **Discover sensors**.
2. Long-press the widget › **Configure widget** › **Search** next to «Find sensors automatically». The search runs a few seconds and only fills empty fields.
3. Close the menu. The widget briefly shows «n sensors newly assigned».
4. If several sensors match a field, the top of the menu shows «Several sensors match, please check:». Check these fields and choose by hand if needed.

The search recognises sensors by their FrSky ID (application ID) and by known names. A deleted sensor («---») counts as empty and is filled again.

## By hand
- **Engine switch (3 positions)** with «Position off (kill)» and «Position choke»: off → ignition starts a flight, ignition → off asks «Flight finished?».
- **Throttle (channel)**, **Mute (switch)** and the two status bar switches (name max. 12 characters, «reverse» if the pill lights the wrong way round).
- **Reverse throttle** (directly below «Throttle (channel)»): switch on if you fly throttle reverse (full throttle = stick back). Off by default.
- **Number of cylinders**, **Tank capacity**, **ml per pulse** of the flow sensor (0.100 ml for the FrSky flow meter).
- For each battery: **role** (receiver, ignition, starter, ECU, battery), **cells** (needed for a plain voltage sensor) and **type** (LiPo, LiFe, NiMH; changing it sets the two cell limits).

## Menu groups
Engine · Engine: limits (0 = off) · Engine: display scales · Fuel · Flight and reception · Batteries · Power switch (RB, if present) · Receiver · Switches in the status bar · Display (language) · Warnings · Alarm also with motor off.

Sensors, channels and switches are stored in the model, all other values in `daten/<model name>.txt` in the script folder. Every setting with default and range is listed in chapter 8 of the manual.

---
[← Home](../Home.md) | [Previous](Installation.md) | [Next →](Display.md)
