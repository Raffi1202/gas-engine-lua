🇬🇧 English · [🇩🇪 Deutsch](../de/FAQ.md)

# FAQ

**ECU or Carb?** Gas Engine ECU for fuel-injected engines with an ECU (fuel pressure, ECU voltage), Gas Engine Carb for carburettor engines (e.g. FrSky AES). Both can be installed at the same time.

**Does the motor switch mute alarms?** No. By default every warning and alarm also comes with the motor switch at Off. You can silence single limits in «Alarm also with motor off»; the display keeps its colour.

**Can I use it without touch?** Yes, the rotary encoder changes pages. Questions, REFUELLED and the flight list need touch in this version.

**Where are my settings?** Sensors, channels and switches in the model; all other values in `daten/<model name>.txt` in the script folder. They stay when you update.

**Which language?** Setting «Sprache / Language»: as radio, Deutsch or English. Display, menu and announcements follow it.

**Why is there no time left with the engine stopped?** A stopped engine uses no fuel. The percent limit of the tank always applies.

**Which radios?** Tested on a real X18RS (Ethos 26.2.0). X20 family only in the simulator (scripts may be in the internal memory `SCRIPTS:`); X14 and X10 / Twin X Lite not tested.

---
[← Home](../Home.md) | [Previous](Lua-Studio.md) | [Next →](Troubleshooting.md)
