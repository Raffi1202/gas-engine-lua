🇬🇧 English · [🇩🇪 Deutsch](../de/Alarme.md)

# Alarms

> **Pre-release:** Gas Engine ECU 1.10.0 / Carb 0.10.0 are tested in the Ethos simulator; the transmitter test on the X18RS follows. Use at your own risk.

Every monitored value has **two thresholds**: **warning** (orange, announcement) and **alarm** (red, announcement and, if switched on, vibration). The announcement repeats every «Repeat every» seconds (default 30 s) while the condition lasts and stops when the value is good again. The mute switch silences all announcements; the colours stay. A 0 switches a limit off.

## Messages that always come
These are never silenced by the motor switch or by «Alarm also with motor off»:

| Message | When | Level |
|---|---|---|
| TELEMETRY LOST | No telemetry («Telemetry recovered» when it returns) | Warning |
| ENGINE OFF | Engine stopped although the engine switch is on ignition (after the start delay) | Alarm |
| CHOKE OFF! | Choke on, engine running and warm or throttle high | Warning |
| POWER SWITCH FAULT | The power switch reports failsafe, lost receiver, no signal, overload or a faulty channel | Alarm |

## Limits
Cylinder too hot / overheating, cylinder temperatures uneven, RPM too high, fuel pressure low / critical (ECU, only while the engine runs), ECU voltage (ECU), fuel on reserve, tank almost empty (percent always; time left only while the engine runs), battery voltage low / almost empty, cells unbalanced, servo current too high, weak signal. «Cylinder temperatures uneven» also comes with the engine stopped and after shutdown, only not during the start lock after starting.

## Alarm also with motor off
Factory setting: all warnings and alarms also come with the motor switch at Off. In the menu group **Alarm also with motor off** you can clear the tick per limit; the switch **all** sets every tick at once. Without the tick, only tone, announcement and vibration of that value are silent while the motor switch is at Off; the display stays orange or red. Back at ignition, the announcement comes again. Without an assigned motor switch the setting has no effect.

In Lua-Studio the setting is called «also with motor off» (field `beiMotorAus`).

## Completely silent only with «off»
A limit is only switched off completely with 0 in the menu or «off» in Lua-Studio. A Lua-Studio limit entry without a number never changes the factory limit.

---
[← Home](../Home.md) | [Previous](Display.md) | [Next →](Lua-Studio.md)
