-- Gas Engine Lua: englische Texte. Gilt gleich für Gas Engine ECU und Gas Engine Carb.
-- Die Anzeige ist auf Deutsch geschrieben; bei Sprache English übersetzt Z.tr jeden Text vor dem Zeichnen:
-- 1. ganzer Text (SATZ), 2. Muster mit Zahlen (MUSTER), 3. Wort für Wort (WORT), unbekannte Wörter bleiben.
-- Wird nur bei Englisch geladen. Meldungen im Protokoll (print) bleiben deutsch.

local SATZ = {
  -- «Alarm auch bei Motor aus» (1.9.0 / 0.9.0)
  ["Alarm auch bei Motor aus"] = "Alarm also with motor off", alle = "all",
  ["Zylinder heiss / warm"] = "Cylinder hot / warm", ["Zylinder ungleich"] = "Cylinders uneven",
  ["Drehzahl hoch"] = "RPM high", ["Spritdruck tief"] = "Fuel pressure low", ["ECU-Spannung tief"] = "ECU voltage low",
  ["Tank % (Reserve, leer)"] = "Tank % (reserve, empty)", ["Tank-Restzeit"] = "Tank time left",
  ["Akku 1 tief"] = "Battery 1 low", ["Akku 2 tief"] = "Battery 2 low", ["Akku 3 tief"] = "Battery 3 low",
  ["Zellen ungleich"] = "Cells uneven", ["Servostrom hoch"] = "Servo current high", ["Empfang schwach"] = "Reception weak",
  -- Statusleiste und Zustand
  ["KEINE DATEN"] = "NO DATA", ["LÄUFT"] = "RUNNING", ["WARMLAUF"] = "WARM-UP", ["MOTOR AUS"] = "ENGINE OFF",
  ["ZÜND. EIN"] = "IGN. ON", ["ZÜND. AUS"] = "IGN. OFF", ["ZÜNDUNG EIN"] = "IGNITION ON", ["ZÜNDUNG AUS"] = "IGNITION OFF",
  ["CHOKE AUS!"] = "CHOKE OFF!", ["nur im Vollbild"] = "full screen only",
  -- Meldungen
  ["TELEMETRIE WEG"] = "TELEMETRY LOST", ["DREHZAHL HOCH"] = "RPM HIGH", ["SPRITDRUCK TIEF"] = "FUEL PRESSURE LOW",
  ["ECU-SPANNUNG TIEF"] = "ECU VOLTAGE LOW", ["SERVOSTROM HOCH"] = "SERVO CURRENT HIGH", ["TANK FAST LEER"] = "TANK ALMOST EMPTY",
  ["TANK RESERVE"] = "TANK RESERVE", ["ZYL UNGLEICH"] = "CYL UNEVEN", ["STROMWEICHE FEHLER"] = "POWER SWITCH FAULT",
  ["Tank auf voll gesetzt"] = "Tank set to full", ["Übersicht zurückgesetzt"] = "Summary reset",
  ["Fehler bei der Suche"] = "Search failed", ["Suche läuft"] = "Searching", ["füllt nur leere Felder"] = "fills empty fields only",
  -- Seite 1
  ["U/min"] = "rpm", ["2,4 GHz"] = "2.4 GHz", ["im Menü setzen"] = "set in menu", ["Tankinhalt fehlt"] = "No tank capacity", ["Studio-Datei geladen"] = "Studio file loaded", ["Studio-Layout"] = "Studio layout", ["automatisch (Modellname)"] = "automatic (model name)", ["Einstellungen"] = "Settings",
  ["Zurück auf Studio-Stand"] = "Back to Studio state", ["Zurück auf Studio-Stand?"] = "Back to Studio state?", ["Zurück auf Standard?"] = "Back to defaults?",
  ["Änderungen an der Funke werden verworfen."] = "Changes made on the radio will be discarded.",
  ["Alle Einstellungen gehen auf den Werkwert. Sensoren bleiben."] = "All settings return to their defaults. Sensors stay.", ["Zurück auf Standard"] = "Back to defaults",
  ["Studio-Datei kaputt – Standard"] = "Studio file broken – defaults", ["Studio-Datei zu neu – Lua aktualisieren"] = "Studio file too new – update the Lua",
  ["Änderungen an der Funke verworfen"] = "Changes on the radio discarded", ["Änderung nicht gespeichert"] = "Change not saved", ["Zylinder max"] = "Cylinder max", ["Durchfluss"] = "Flow", ["Zyl.-Diff"] = "Cyl. diff", ["Tank"] = "Tank", ["Zellenzahl im Menü wählen"] = "Set cell count in menu", ["Restzeit"] = "Time left", ["Steigen"] = "Climb", ["Höhe"] = "Altitude",
  -- Seite 2
  ["Keine Akkus gewählt"] = "No batteries selected", ["Keine Empfangssensoren gewählt"] = "No receiver sensors selected",
  ["Keine Kanalströme gewählt"] = "No channel currents selected", ["Keine Sensoren gewählt"] = "No sensors selected",
  ["STROMWEICHE (KANALSTRÖME)"] = "POWER SWITCH (CHANNEL CURRENTS)", ["ZÜNDAKKU"] = "IGN. BATTERY",
  -- Seite 3
  ["Höchst- und Tiefstwerte und Flüge seit dem letzten Zurücksetzen"] = "Highest and lowest values and flights since the last reset",
  ["antippen = Werte"] = "tap = values", ["Kein Flug"] = "No flight", ["Noch kein Flug"] = "No flight yet",
  ["Keine Werte"] = "No values", ["Laufender Flug"] = "Current flight", ["Flug (Pause)"] = "Flight (paused)",
  ["Verbrauch gesamt"] = "Total fuel used", ["Max. Durchfluss"] = "Max. flow", ["Mittl. Durchfluss"] = "Avg. flow",
  ["Max. Fluss"] = "Max. flow", ["Mittl. Fluss"] = "Avg. flow", ["Max. Drehzahl"] = "Max. RPM", ["Max. Höhe"] = "Max. altitude",
  ["Max. Sinken"] = "Max. sink", ["Max. Steigen"] = "Max. climb", ["Max. Zylinder"] = "Max. cylinder",
  ["Tiefste Zelle"] = "Lowest cell", ["Tiefste ECU-Spannung"] = "Lowest ECU voltage", ["Tiefste ECU"] = "Lowest ECU",
  ["Motorlaufzeit"] = "Engine run time",
  -- Rückfragen
  ["Wirklich vollgetankt?"] = "Really refuelled?", ["JA, VOLLGETANKT"] = "YES, REFUELLED",
  ["Der Verbrauch wird auf 0 gesetzt."] = "Fuel used will be set to 0.",
  ["Flug beendet?"] = "Flight finished?", ["JA, BEENDET"] = "YES, FINISHED", ["NEIN, NUR PAUSE"] = "NO, ONLY A PAUSE",
  ["Übersicht zurücksetzen?"] = "Reset summary?", ["JA, ZURÜCKSETZEN"] = "YES, RESET",
  ["Höchstwerte und Flugliste werden gelöscht. Der Tank bleibt."] = "Highest values and flight list will be deleted. The tank stays.",
  ["ÜBERSICHT ZURÜCKSETZEN"] = "RESET SUMMARY", ["Eintrag löschen?"] = "Delete entry?",
  ["Tank und Gesamtwerte bleiben."] = "Tank and totals stay.", ["JA, LÖSCHEN"] = "YES, DELETE",
  ["ABBRECHEN"] = "CANCEL", ["SCHLIESSEN"] = "CLOSE", ["NEIN"] = "NO",
  -- Menü: Kopf, Gruppen, Auswahlen
  ["Sensoren automatisch suchen"] = "Find sensors automatically", ["Suchen"] = "Search",
  ["Motor: Grenzwerte (0 = aus)"] = "Engine: limits (0 = off)", ["Motor: Skalen der Anzeige"] = "Engine: display scales",
  ["Flug und Empfang"] = "Flight and reception", ["Akkus (Zellen- oder Spannungssensor)"] = "Batteries (cell or voltage sensor)",
  ["Stromweiche (RB, falls vorhanden)"] = "Power switch (RB, if present)", ["Schalter in der Statusleiste"] = "Switches in the status bar",
  ["Anzeige"] = "Display", ["Sprache / Language"] = "Sprache / Language", ["wie Sender"] = "as radio",
  ["oben"] = "up", ["Mitte"] = "middle", ["unten"] = "down", ["keine"] = "none", ["automatisch"] = "automatic",
  -- Menü: Felder
  ["Anzahl Zylinder"] = "Number of cylinders", ["Gas (Kanal)"] = "Throttle (channel)",
  ["Motorschalter (3 Stufen)"] = "Engine switch (3 positions)", ["Stellung Aus (Kill)"] = "Position off (kill)",
  ["Stellung Choke"] = "Position choke", ["Motor läuft ab"] = "Engine running from", ["Zylinder kalt unter"] = "Cylinder cold below",
  ["Zylinder Warnung über"] = "Cylinder warning above", ["Zylinder Alarm über"] = "Cylinder alarm above",
  ["Zyl.-Unterschied über"] = "Cyl. difference above", ["Drehzahl Warnung über"] = "RPM warning above",
  ["Drehzahl Alarm über"] = "RPM alarm above", ["Choke-Warnung ab Zyl."] = "Choke warning from cyl.",
  ["Choke-Warnung ab Gas"] = "Choke warning from throttle", ["Druck Sollbereich von"] = "Pressure range from",
  ["Druck Sollbereich bis"] = "Pressure range to", ["Druck Alarm unter"] = "Pressure alarm below",
  ["ECU Warnung unter"] = "ECU warning below", ["ECU Alarm unter"] = "ECU alarm below",
  ["Zylinder von"] = "Cylinder from", ["Zylinder bis"] = "Cylinder to", ["Drehzahl bis"] = "RPM to", ["Druck bis"] = "Pressure to",
  ["Impulszähler"] = "Pulse counter", ["Impulszähler (Flowsensor)"] = "Pulse counter (flow sensor)",
  ["ml pro Impuls"] = "ml per pulse", ["Durchfluss (ml/min)"] = "Flow (ml/min)", ["Tankinhalt"] = "Tank capacity",
  ["Reserve unter"] = "Reserve below", ["Alarm unter"] = "Alarm below", ["Alarm Restzeit unter"] = "Alarm time left below",
  ["Geschwindigkeit"] = "Speed", ["Empfang (Statusleiste)"] = "Reception (status bar)",
  ["Zellenunterschied über"] = "Cell difference above", ["Zellenbalken leer bei"] = "Cell bar empty at",
  ["Zellenbalken voll bei"] = "Cell bar full at", ["Zündakku (alt)"] = "Ignition battery (old)",
  ["Empfängerspannung (RxBatt)"] = "Receiver voltage (RxBatt)", ["Kanalstrom Warnung über"] = "Channel current warning above",
  ["Zustand Empfänger (RB State)"] = "Receiver status (RB State)", ["Zustand Kanäle (RB Ch. State)"] = "Channel status (RB Ch. State)",
  ["Kanalstrom Alarm über"] = "Channel current alarm above", ["RSSI Warnung unter"] = "RSSI warning below",
  ["RSSI Alarm unter"] = "RSSI alarm below", ["Ansagen"] = "Announcements", ["Wert mit ansagen"] = "Announce value",
  ["Vibration bei Alarm"] = "Vibration on alarm", ["Wiederholung alle"] = "Repeat every", ["Startsperre"] = "Start delay",
  ["Stumm (Schalter)"] = "Mute (switch)", ["Kraftstoffdruck"] = "Fuel pressure", ["ECU-Spannung"] = "ECU voltage",
}

-- Texte mit Zahlen: { Muster, Ersatz } in dieser Reihenfolge
local MUSTER = {
  { "^Flug (%d+) löschen%?$", "Delete flight %1?" },
  { "^Der Tank wird auf 100 %% %((%d+) ml%) gesetzt%.$", "The tank will be set to 100 %% (%1 ml)." },
  { "^Dieser Flug: (.*) ml Sprit$", "This flight: %1 ml fuel" },
  { "^(%d+) neu zugewiesen$", "%1 newly assigned" },
  { "^(%d+) Sensoren automatisch zugewiesen$", "%1 sensors assigned automatically" },
  { "^(%d+) Sensoren neu zugewiesen$", "%1 sensors newly assigned" },
  { "^1 Sensor automatisch zugewiesen$", "1 sensor assigned automatically" },
  { "^1 Sensor neu zugewiesen$", "1 sensor newly assigned" },
  { "^Strom Kanal (%d)$", "Channel %1 current" },
  { "^Studio%-Datei: (%d+) Fehler$", "Studio file: %1 errors" },
  { "^FLUG (%d+) LÖSCHEN$", "DELETE FLIGHT %1" },
  { "^Z(%d)$", "C%1" },
  { "^Ø (.*) ml pro Flug$", "Ø %1 ml per flight" },
  { "^(.*)2,4 GHz$", "%12.4 GHz" },                    -- Zylinder 1..4 über den Balken
  { "^(.*) U/min$", "%1 rpm" },
}

-- Einzelne Wörter (gross und klein getrennt)
local WORT = {
  -- gross (Anzeige)
  AKKU = "BATTERY", ["EMPFÄNGER"] = "RECEIVER", ["ZÜNDUNG"] = "IGNITION", ANLASSER = "STARTER BATT.", ["ECU-AKKU"] = "ECU BATTERY",
  SPRITDRUCK = "FUEL PRESSURE", ["ECU-SPANNUNG"] = "ECU VOLTAGE", TIEF = "LOW", HEISS = "HOT", WARM = "WARM", SCHWACH = "WEAK", ZELLEN = "CELLS", UNGLEICH = "UNBALANCED",
  ZYL = "CYL", ZYLINDER = "CYLINDERS", DREHZAHL = "RPM", KRAFTSTOFF = "FUEL", EMPFANG = "RECEPTION",
  STROMWEICHE = "POWER SWITCH", ["FLÜGE"] = "FLIGHTS", GESAMT = "TOTAL", FLUG = "FLIGHT", VOLLGETANKT = "REFUELLED",
  WARNUNG = "WARNING", FEHLER = "FAULT", ["LÖSCHEN"] = "DELETE", AUS = "OFF", EIN = "ON", SCHALTER = "SWITCH",
  -- klein (Anzeige und Menü)
  Motor = "Engine", Elektrik = "Electrics", ["Übersicht"] = "Summary", Empfang = "Reception", Flug = "Flight",
  Pause = "paused", ["läuft"] = "running", Zustand = "Status", Verbrauch = "Fuel used", ["Verbr."] = "Used",
  Fluss = "Flow", Sprit = "Fuel", Gas = "Thr.", Drehzahl = "RPM", Kraftstoff = "Fuel", Druck = "Pressure",
  ["ca."] = "approx.", je = "per", Zelle = "cell", Diff = "Diff", Warnungen = "Warnings", Rolle = "Role",
  Akku = "Battery", ["ECU-Akku"] = "ECU battery", RxBatt = "RxBatt", Art = "type", Sensor = "sensor", Spannung = "voltage", Strom = "current", Zellen = "cells", ist = "is",
  Zellenzahl = "cells", Kanal = "channel", Temp = "temp", ["Temp."] = "temp.", Zylinder = "Cylinder",
  Schalter = "Switch", Name = "name", umkehren = "reverse", Warnung = "warning", Alarm = "alarm", unter = "below",
  ["über"] = "above", ["Zündung"] = "Ignition", Anlasser = "Starter", ["Empfänger"] = "Receiver",
}

local cache, n = {}, 0
-- Übersetzt einen Text der Anzeige ins Englische.
return function(t)
  if type(t) ~= "string" or t == "" then return t end
  local r = cache[t]
  if r then return r end
  r = SATZ[t]
  if r == nil then
    for _, m in ipairs(MUSTER) do
      if t:find(m[1]) then r = t:gsub(m[1], m[2]); break end
    end
  end
  if r == nil then
    r = t:gsub("[%a\128-\255][%a\128-\255%.%-]*", function(wd)
      local e = WORT[wd]
      if e == nil and wd:sub(-1) == "." then e = WORT[wd:sub(1, -2)]; if e then e = e .. "." end end
      return e
    end)
  end
  if n > 300 then cache, n = {}, 0 end    -- Texte mit wechselnden Zahlen nicht endlos sammeln
  cache[t], n = r, n + 1
  return r
end
