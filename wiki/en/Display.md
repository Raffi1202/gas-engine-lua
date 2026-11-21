🇬🇧 English · [🇩🇪 Deutsch](../de/Anzeige.md)

# Display

Three pages. Next: swipe left or turn the rotary encoder right; back: swipe right or turn it left.

## Page 1 Engine
| Part | What it shows |
|---|---|
| Status bar | State (RUNNING, WARM-UP, NO DATA, WARNING, ALARM), ignition, choke, the two switches, model name, ECU voltage (ECU only), reception, page |
| Message line | All active warnings (orange) and alarms (red) as text |
| Cylinders | One bar per cylinder with temperature, trend arrow, difference and maximum |
| RPM | Arc with RPM and maximum, below it the throttle bar in percent |
| Fuel | Pressure bar (ECU only), tank in % and ml, fuel used, flow, time left, button REFUELLED |
| Bottom row | Altitude, climb, speed |

## Page 2 Electrics
![Page 2 Electrics (English, simulator)](../../docs/bilder-simulator/Gas%20Engine%20ECU%20-%20Sim%20800x480%2013%20Englisch%20Seite%202%20Elektrik.png)

Up to three batteries. With a cell sensor one bar per cell and Δ = difference; with a plain voltage sensor one bar of the average cell («Ø … V per cell»). Power switch (only if sensors are assigned): status, battery voltages and currents, channel currents. Reception of receivers 1 and 2 and RXBATT.

## Page 3 Summary
![Page 3 flight details (English, simulator)](../../docs/bilder-simulator/Gas%20Engine%20Carb%20-%20Sim%20800x480%2012%20Englisch%20Seite%203%20Flug-Details.png)

Left the highest and lowest values since the last reset, right the flights. Tap a flight to see its values; **DELETE FLIGHT n** deletes it on its own (the numbers move up). **RESET SUMMARY** deletes the highest values and the flight list after a question; the tank stays.

## Compact view
![Compact view (English, simulator)](../../docs/bilder-simulator/Gas%20Engine%20Carb%20-%20Sim%20630x258%2015%20Kompakt%20Englisch.png)

Engine run time, state, ignition, choke and reception at the top; four rings (RPM, hottest cylinder, tank with time left, first battery) and eight fields. No pages; use full screen for battery details and the flight list.

## Operation
| | |
|---|---|
| Start a flight | Engine switch off → ignition. A paused flight continues. |
| End a flight | Engine switch → off, question «Flight finished?»: YES saves, NO keeps it open as a pause. |
| Refuelled | REFUELLED on page 1, then YES: fuel used 0, tank 100 %. |
| Without touch | The rotary encoder changes pages. Questions, REFUELLED and the flight list need touch. |

---
[← Home](../Home.md) | [Previous](Setup.md) | [Next →](Alarms.md)
