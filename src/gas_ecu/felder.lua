-- Gas Engine ECU: Liste aller Einstellungen (für Menü und Speicher). Wird nur bei Bedarf geladen und wieder freigegeben.
-- Art: q = Quelle (Sensor, Kanal, Schalter), z = Zahl, b = Ja/Nein, w = Auswahl.
-- z: { name, "z", Text, Werkwert, min, max, Kommastellen, Einheit, Schritt }. Zahlen mit Kommastellen sind als ganze
-- Zahl gespeichert (Kommastellen 1: 110 bedeutet 11,0). 0 = aus. Ab Werk (seit ECU 1.3.0 / Vergaser 0.3.0)
-- gesetzt: Zylinder, Zellen, Zellenunterschied, Kraftstoffdruck; die übrigen Grenzwerte stehen auf 0. Ältere Modelle
-- behalten ihre gespeicherten Werte, auch eine 0 (die Datei unterscheidet nicht zwischen «nie gesetzt» und «aus»).
-- Ausnahmen mit Werkwert: Skalen (nur Anzeige), Wiederholpause, Startsperre, Zellenbalken 3,00..4,20 V,
-- ml pro Impuls 0,100 (Angabe der FrSky-Anleitung zum Flowmeter).
local M = {}

local POS = { { "oben", 1 }, { "Mitte", 2 }, { "unten", 3 } }
local ZYL = { { "1", 1 }, { "2", 2 }, { "3", 3 }, { "4", 4 } }
-- Rolle eines Akkus: bestimmt Name und Ansage (Empfänger mehrfach möglich, dann mit Nummer)
local ROLLE = { { "Empfänger", 1 }, { "Zündung", 2 }, { "Anlasser", 3 }, { "ECU", 4 }, { "Akku", 5 } }
M.ROLLE = ROLLE
-- Akkuart: bestimmt die Werkgrenzen je Zelle (Warnung, Alarm) und die Skala der Zellenbalken (leer, voll), in 0,01 V.
-- Wechselt man im Menü die Art, setzt das Menü die Grenzen dieses Akkus auf die Werte der Art.
local ART = { { "LiPo", 1 }, { "LiFe", 2 }, { "NiMH", 3 } }
M.ART_GRENZE = { { 350, 330, 300, 420 }, { 310, 290, 280, 360 }, { 115, 105, 100, 145 } }
local ZELLEN = { { "automatisch", 0 }, { "1S", 1 }, { "2S", 2 }, { "3S", 3 }, { "4S", 4 }, { "5S", 5 }, { "6S", 6 } }

M.gruppen = {
  { "Motor", {
    { "zylAnz", "w", "Anzahl Zylinder", 2, ZYL },
    { "cht1", "q", "Zylinder 1 Temp." },
    { "cht2", "q", "Zylinder 2 Temp." },
    { "cht3", "q", "Zylinder 3 Temp." },
    { "cht4", "q", "Zylinder 4 Temp." },
    { "rpm", "q", "Drehzahl" },
    { "druck", "q", "Kraftstoffdruck" },
    { "ecuV", "q", "ECU-Spannung" },
    { "gas", "q", "Gas (Kanal)" },
    { "motorSw", "q", "Motorschalter (3 Stufen)" },
    { "swAus", "w", "Stellung Aus (Kill)", 1, POS },
    { "swChoke", "w", "Stellung Choke", 3, POS },
  } },
  { "Motor: Grenzwerte (0 = aus)", {
    { "laeuftAb", "z", "Motor läuft ab", 0, 0, 5000, 0, " U/min", 50 },
    { "chtKalt", "z", "Zylinder kalt unter", 0, 0, 600, 0, "°" },
    { "chtWarn", "z", "Zylinder Warnung über", 200, 0, 600, 0, "°" },
    { "chtAlarm", "z", "Zylinder Alarm über", 230, 0, 600, 0, "°" },
    { "chtDiff", "z", "Zyl.-Unterschied über", 40, 0, 300, 0, "°" },
    { "rpmWarn", "z", "Drehzahl Warnung über", 0, 0, 30000, 0, " U/min", 100 },
    { "rpmAlarm", "z", "Drehzahl Alarm über", 0, 0, 30000, 0, " U/min", 100 },
    { "druckVon", "z", "Druck Sollbereich von", 15, 0, 9999, 1 },
    { "druckBis", "z", "Druck Sollbereich bis", 0, 0, 9999, 1 },
    { "druckAlarm", "z", "Druck Alarm unter", 10, 0, 9999, 1 },
    { "ecuWarn", "z", "ECU Warnung unter", 0, 0, 300, 1, " V" },
    { "ecuAlarm", "z", "ECU Alarm unter", 0, 0, 300, 1, " V" },
    { "chokeTemp", "z", "Choke-Warnung ab Zyl.", 0, 0, 600, 0, "°" },
    { "chokeGas", "z", "Choke-Warnung ab Gas", 0, 0, 100, 0, " %" },
  } },
  { "Motor: Skalen der Anzeige", {
    { "chtVon", "z", "Zylinder von", 0, 0, 600, 0, "°", 10 },
    { "chtBis", "z", "Zylinder bis", 250, 10, 600, 0, "°", 10 },
    { "rpmSkala", "z", "Drehzahl bis", 9000, 1000, 30000, 0, " U/min", 500 },
    { "druckSkala", "z", "Druck bis", 50, 1, 9999, 1 },
  } },
  { "Kraftstoff", {
    { "impulse", "q", "Impulszähler (Flowsensor)" },
    { "mlImp", "z", "ml pro Impuls", 100, 1, 10000, 3, " ml" },
    { "fluss", "q", "Durchfluss (ml/min)" },
    { "tank", "z", "Tankinhalt", 0, 0, 20000, 0, " ml", 50 },
    { "tankRes", "z", "Reserve unter", 0, 0, 100, 0, " %" },
    { "tankLeer", "z", "Alarm unter", 0, 0, 100, 0, " %" },
    { "tankMin", "z", "Alarm Restzeit unter", 0, 0, 120, 0, " min" },
  } },
  { "Flug und Empfang", {
    { "hoehe", "q", "Höhe" },
    { "vario", "q", "Steigen" },
    { "speed", "q", "Geschwindigkeit" },
    { "rssi", "q", "Empfang (Statusleiste)" },
  } },
  { "Akkus (Zellen- oder Spannungssensor)", {
    { "lipo1", "q", "Akku 1 Sensor" },
    { "a1Rolle", "w", "Akku 1 ist", 1, ROLLE },
    { "a1S", "w", "Akku 1 Zellen", 0, ZELLEN },
    { "a1Typ", "w", "Akku 1 Art", 1, ART, art = 1 },
    { "z1Warn", "z", "Akku 1 Zelle Warnung unter", 350, 0, 500, 2, " V" },
    { "z1Alarm", "z", "Akku 1 Zelle Alarm unter", 330, 0, 500, 2, " V" },
    { "lipo2", "q", "Akku 2 Sensor" },
    { "a2Rolle", "w", "Akku 2 ist", 1, ROLLE },
    { "a2S", "w", "Akku 2 Zellen", 0, ZELLEN },
    { "a2Typ", "w", "Akku 2 Art", 1, ART, art = 2 },
    { "z2Warn", "z", "Akku 2 Zelle Warnung unter", 350, 0, 500, 2, " V" },
    { "z2Alarm", "z", "Akku 2 Zelle Alarm unter", 330, 0, 500, 2, " V" },
    { "lipo3", "q", "Akku 3 Sensor" },
    { "a3Rolle", "w", "Akku 3 ist", 3, ROLLE },
    { "a3S", "w", "Akku 3 Zellen", 0, ZELLEN },
    { "a3Typ", "w", "Akku 3 Art", 1, ART, art = 3 },
    { "z3Warn", "z", "Akku 3 Zelle Warnung unter", 350, 0, 500, 2, " V" },
    { "z3Alarm", "z", "Akku 3 Zelle Alarm unter", 330, 0, 500, 2, " V" },
    { "zDiff", "z", "Zellenunterschied über", 15, 0, 200, 2, " V" },
    { "zLeer", "z", "Zellenbalken leer bei", 300, 0, 500, 2, " V" },
    { "zVoll", "z", "Zellenbalken voll bei", 420, 0, 500, 2, " V" },
    { "zuendAkku", "q", "Zündakku (alt)", versteckt = true },   -- frühere Fassungen; wird in einen freien Akku übernommen
  } },
  { "Stromweiche (RB, falls vorhanden)", {
    { "bat1V", "q", "Akku 1 Spannung" },
    { "bat1A", "q", "Akku 1 Strom" },
    { "bat2V", "q", "Akku 2 Spannung" },
    { "bat2A", "q", "Akku 2 Strom" },
    { "rbState", "q", "Zustand Empfänger (RB State)" },
    { "rbChState", "q", "Zustand Kanäle (RB Ch. State)" },
    { "rbK1", "q", "Strom Kanal 1" },
    { "rbK2", "q", "Strom Kanal 2" },
    { "rbK3", "q", "Strom Kanal 3" },
    { "rbK4", "q", "Strom Kanal 4" },
    { "rbK5", "q", "Strom Kanal 5" },
    { "rbK6", "q", "Strom Kanal 6" },
    { "rbK7", "q", "Strom Kanal 7" },
    { "rbK8", "q", "Strom Kanal 8" },
    { "kWarn", "z", "Kanalstrom Warnung über", 0, 0, 500, 1, " A" },
    { "kAlarm", "z", "Kanalstrom Alarm über", 0, 0, 500, 1, " A" },
  } },
  { "Empfänger", {
    { "rxBatt", "q", "Empfängerspannung (RxBatt)" },
    { "rx1R24", "q", "RX1 RSSI 2,4 GHz" },
    { "rx1R900", "q", "RX1 RSSI 900 MHz" },
    { "rx1Vfr", "q", "RX1 VFR" },
    { "rx2R24", "q", "RX2 RSSI 2,4 GHz" },
    { "rx2R900", "q", "RX2 RSSI 900 MHz" },
    { "rx2Vfr", "q", "RX2 VFR" },
    { "rssiWarn", "z", "RSSI Warnung unter", 0, 0, 100, 0 },
    { "rssiAlarm", "z", "RSSI Alarm unter", 0, 0, 100, 0 },
  } },
  { "Schalter in der Statusleiste", {
    { "winde", "q", "Schalter 1" },
    { "sw1Name", "t", "Schalter 1 Name", "SCHALTER 1" },
    { "windeInv", "b", "Schalter 1 umkehren", false },
    { "bremse", "q", "Schalter 2" },
    { "sw2Name", "t", "Schalter 2 Name", "SCHALTER 2" },
    { "bremseInv", "b", "Schalter 2 umkehren", false },
  } },
  { "Anzeige", {
    { "sprache", "w", "Sprache / Language", 0, { { "wie Sender", 0 }, { "Deutsch", 1 }, { "English", 2 } } },
  } },
  { "Warnungen", {
    { "ansage", "b", "Ansagen", true },
    { "zahl", "b", "Wert mit ansagen", true },
    { "vibration", "b", "Vibration bei Alarm", true },
    { "pause", "z", "Wiederholung alle", 30, 5, 600, 0, " s", 5 },
    { "sperre", "z", "Startsperre", 10, 0, 120, 0, " s" },
    { "stumm", "q", "Stumm (Schalter)" },
  } },
  -- Je Grenzwert-Alarm: kommt er auch, wenn der Motorschalter auf Aus steht? Standard ja (Lua-Studio-Format 2 §3.5,
  -- 21.11.2026). Aus = Ton, Ansage und Vibration dieses Alarms schweigen nur, solange der Schalter auf Aus steht; die
  -- Anzeige bleibt farbig. «alle» ist kein eigener Wert (nicht in M.folge), er setzt nur die Haken darunter.
  { "Alarm auch bei Motor aus", {
    { "maAlle", "b", "alle", true, alle = true },
    { "maChtMax", "b", "Zylinder heiss / warm", true, studio = "cht_max" },
    { "maChtDiff", "b", "Zylinder ungleich", true, studio = "cht_diff" },
    { "maRpm", "b", "Drehzahl hoch", true, studio = "rpm" },
    { "maDruck", "b", "Spritdruck tief", true, studio = "druck" },
    { "maEcuV", "b", "ECU-Spannung tief", true, studio = "ecu_v" },
    { "maTankProz", "b", "Tank % (Reserve, leer)", true, studio = "tank_proz" },
    { "maRestzeit", "b", "Tank-Restzeit", true, studio = "restzeit" },
    { "maAkku1", "b", "Akku 1 tief", true, studio = "akku1_zelle" },
    { "maAkku2", "b", "Akku 2 tief", true, studio = "akku2_zelle" },
    { "maAkku3", "b", "Akku 3 tief", true, studio = "akku3_zelle" },
    { "maAkkuDiff", "b", "Zellen ungleich", true, studio = "akku_diff" },
    { "maKanal", "b", "Servostrom hoch", true, studio = "kanalstrom_max" },
    { "maRssi", "b", "Empfang schwach", true, studio = "rx1_rssi" },
  } },
}

-- Reihenfolge im Speicher. Ethos speichert nach Reihenfolge, nicht nach Namen:
-- neue Einstellungen kommen immer ANS ENDE dieser Liste, nie dazwischen.
M.folge = {
  "cht1", "cht2", "rpm", "druck", "ecuV", "gas", "motorSw", "swAus", "swChoke",
  "laeuftAb", "chtKalt", "chtWarn", "chtAlarm", "chtDiff", "rpmWarn", "rpmAlarm", "druckVon", "druckBis", "druckAlarm",
  "ecuWarn", "ecuAlarm", "chokeTemp", "chokeGas",
  "chtVon", "chtBis", "rpmSkala", "druckSkala",
  "impulse", "mlImp", "fluss", "tank", "tankRes", "tankLeer", "tankMin",
  "hoehe", "vario", "speed", "rssi",
  "lipo1", "lipo2", "lipo3", "z1Warn", "z1Alarm", "z2Warn", "z2Alarm", "z3Warn", "z3Alarm", "zDiff", "zLeer", "zVoll",
  "zuendAkku",
  "bat1V", "bat1A", "bat2V", "bat2A", "rbState", "rbK1", "rbK2", "rbK3", "rbK4", "rbK5", "rbK6", "rbK7", "rbK8",
  "kWarn", "kAlarm",
  "rx1R24", "rx1R900", "rx1Vfr", "rx2R24", "rx2R900", "rx2Vfr", "rssiWarn", "rssiAlarm",
  "winde", "windeInv", "bremse", "bremseInv",
  "ansage", "zahl", "vibration", "pause", "sperre", "stumm",
  -- ab 1.2.0 (nur ans Ende)
  "zylAnz", "cht3", "cht4", "rxBatt", "a1Rolle", "a2Rolle", "a3Rolle", "a1S", "a2S", "a3S", "sw1Name", "sw2Name",
  -- ab 1.4.0 (nur ans Ende; keine Quelle, darum bleibt FORMAT 4)
  "sprache",
  "a1Typ", "a2Typ", "a3Typ",
  -- ab 1.4.1: Quelle, darum FORMAT 5
  "rbChState",
  -- ab 1.9.0: «Alarm auch bei Motor aus» (Ja/Nein, stehen mit Namen in der Datei), FORMAT 6
  "maChtMax", "maChtDiff", "maRpm", "maDruck", "maEcuV", "maTankProz", "maRestzeit", "maAkku1", "maAkku2", "maAkku3", "maAkkuDiff", "maKanal", "maRssi",
}

-- Feld zu einem Namen (Verzeichnis einmal aufbauen: Ethos begrenzt die Befehle je Aufruf).
local INDEX = nil
function M.feld(name)
  if INDEX == nil then
    INDEX = {}
    for _, g in ipairs(M.gruppen) do
      for _, f in ipairs(g[2]) do INDEX[f[1]] = f end
    end
  end
  return INDEX[name]
end

function M.standard()
  local c = {}
  for _, g in ipairs(M.gruppen) do
    for _, f in ipairs(g[2]) do
      if f[2] ~= "q" then c[f[1]] = f[4] end
    end
  end
  return c
end

local function istQuelle(v)
  local t = type(v)
  return t == "userdata" or (t == "table" and type(v.value) == "function")
end
M.istQuelle = istQuelle

-- Freitext (Schalternamen): nur Buchstaben, Ziffern, Leerzeichen, Punkt, Bindestrich, Umlaute; höchstens 12 Zeichen.
function M.text(v)
  if type(v) ~= "string" then return nil end
  v = v:gsub("[^%w %.%-\128-\255]", ""):gsub("^%s+", ""):gsub("%s+$", "")
  if utf8 and utf8.offset then
    local okp, p = pcall(utf8.offset, v, 13)
    if okp and p then v = v:sub(1, p - 1) elseif not okp then v = v:sub(1, 12) end
  else
    v = v:sub(1, 12)
  end
  if v == "" then return nil end
  return v
end

-- Gespeicherten Wert prüfen; passt er nicht, gilt der Wert ab Werk.
local function pruefe(f, v)
  local art = f[2]
  if art == "q" then
    if istQuelle(v) then return v end
    return nil
  elseif art == "b" then
    if type(v) == "boolean" then return v end
  elseif art == "z" then
    if type(v) == "number" and v == v and v >= f[5] and v <= f[6] then return math.floor(v) end
  elseif art == "t" then
    return M.text(v) or f[4]
  elseif art == "w" then
    if type(v) == "number" then
      for _, a in ipairs(f[5]) do
        if a[2] == v then return v end
      end
    end
  end
  return f[4]
end

-- Speicher, gemessen im Simulator 26.1.2: der Widget-Speicher von Ethos fasst nur rund 256 Byte
-- (51 Zahlen oder 51 Quellen, danach «Max size reached»). Darum:
-- * Widget-Speicher: nur die Quellen (Sensoren, Kanäle, Schalter), in der Reihenfolge von M.folge, mit Rahmen.
-- * Datei daten/<Modell>.txt im Skriptordner: alle Zahlen, Ja/Nein, Auswahlen und die dauerhaften Werte
--   (Verbrauch seit «Vollgetankt»), als «name=wert», also nach Namen und nicht nach Reihenfolge.
-- Ethos liest den Widget-Speicher nach Reihenfolge der Aufrufe, nicht nach Namen. Kommen Quellen dazu, braucht es
-- ein neues FORMAT, sonst landet die alte Endmarke in einem neuen Feld und alles gilt als unlesbar.
-- FORMAT 3 (bis 1.1.x): Quellen bis «stumm». FORMAT 4 (1.2.0–1.4.0): dazu cht3, cht4, rxBatt.
-- FORMAT 5 (ab 1.4.1): dazu rbChState. ENDE nennt je älterem Format die letzte Quelle.
-- FORMAT 6 (ab 1.9.0): Quellen unverändert; neu sind die Ja/Nein-Werte «Alarm auch bei Motor aus» (Datei, nach Namen).
M.FORMAT = 6
local ENDE = { [3] = "stumm", [4] = "rxBatt", [5] = "rbChState" }

-- Quellen in Speicher-Reihenfolge; mit bis = Name nur die Quellen bis und mit diesem Feld (ältere Formate).
local function quellen(bis)
  local r = {}
  for _, name in ipairs(M.folge) do
    local f = M.feld(name)
    if f and f[2] == "q" then r[#r + 1] = name end
    if bis and name == bis then break end
  end
  return r
end

-- Dateiname zum aktuellen Modell (Ordner und Name, nur Buchstaben, Ziffern, _ und -).
function M.datei()
  local ok, p = pcall(model.path)
  if not ok or type(p) ~= "string" or p == "" then
    local ok2, n = pcall(model.name)
    p = (ok2 and type(n) == "string" and n ~= "") and n or "modell"
  end
  p = p:gsub("%.bin$", ""):gsub("[^%w%-]", "_")
  return "daten/" .. p .. ".txt"
end

-- Datei ganz lesen (Ethos liest nur in Stücken), höchstens 8 KB.
local function liesDatei(pfad)
  local ok, f = pcall(io.open, pfad, "r")
  if not ok or not f then return nil end
  local teile, n = {}, 0
  while n < 8192 do
    local ok2, s = pcall(f.read, f, 512)
    if not ok2 or type(s) ~= "string" or s == "" then break end
    teile[#teile + 1] = s
    n = n + #s
  end
  pcall(f.close, f)
  return table.concat(teile)
end

-- Zusatzwerte je Flug in der Datei, Reihenfolge fest (neue nur ans Ende):
-- Sinken, max. Durchfluss, Motorlaufzeit s, heissester Zylinder, tiefste Zelle, max. Drehzahl, tiefste ECU-Spannung
M.SZUSATZ = { "sink", "fl", "t", "cht", "zel", "rpm", "ecu" }

function M.lies(w)
  local c = M.standard()
  w.cfg = c
  local gefunden = false
  -- Quellen aus dem Widget-Speicher
  if storage and storage.read then
    local function hol(name)
      local ok, v = pcall(storage.read, name)
      if ok then return v end
      return nil
    end
    local fmt = hol("fmt")
    local q = ENDE[fmt] and quellen(ENDE[fmt]) or quellen()
    if fmt == M.FORMAT or ENDE[fmt] then
      local werte = {}
      for i = 1, #q do werte[i] = hol("q" .. i) end
      if hol("ende") == fmt then
        gefunden = true
        for i, name in ipairs(q) do c[name] = istQuelle(werte[i]) and werte[i] or nil end
      else
        print("Gas Engine ECU: gespeicherte Sensoren unlesbar, bitte neu zuweisen")
      end
    end
  end
  -- Zahlen und dauerhafte Werte aus der Datei
  local text = liesDatei(M.datei())
  if text == nil then   -- Übergang: Daten der Vorversion (Ordner motoren_ecu) nur lesen; gespeichert wird im neuen Ordner
    text = liesDatei("SCRIPTS:/motoren_ecu/" .. M.datei())
    if text then print("Gas Engine ECU: settings taken over from motoren_ecu") end
  end
  if text then
    gefunden = true
    w.ue, w.schlepps, w.sl, w.nSchlepp = {}, {}, nil, 0      -- ein zweites Lesen darf nichts doppelt anhängen
    for zeile in text:gmatch("[^\r\n]+") do
      local k, v = zeile:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
      if k == "verbr" then
        local x = tonumber(v)
        if x and x == x and x >= 0 and x < 1e6 then w.tk.verbr = x end
      elseif k and k:sub(1, 3) == "ue_" then
        local x = tonumber(v)
        if x and x == x and x > -1e7 and x < 1e7 then w.ue[k:sub(4)] = x end
      elseif k == "s" or k == "sl" then
        -- Flug: nr,ml,h,steig (abgeschlossen) bzw. ml,h,steig,pause (laufend); leere Felder = kein Wert
        local f, i = {}, 0
        for teil in (v .. ","):gmatch("([^,]*),") do
          i = i + 1
          f[i] = tonumber(teil)                  -- leeres Feld bleibt nil, die Stellen verrutschen nicht
        end
        local function ok(x) return x and x == x and x > -1e7 and x < 1e7 end
        -- ab Stelle 5 die Zusatzwerte je Flug; ältere Dateien haben sie nicht, dann bleiben sie leer
        local function zusatz(t) for j, n in ipairs(M.SZUSATZ) do if ok(f[4 + j]) then t[n] = f[4 + j] end end return t end
        if k == "s" and ok(f[1]) and ok(f[2]) and #w.schlepps < 50 then
          w.schlepps[#w.schlepps + 1] = zusatz({ nr = math.floor(f[1]), ml = f[2], h = ok(f[3]) and f[3] or nil, steig = ok(f[4]) and f[4] or nil })
        elseif k == "sl" and ok(f[1]) then
          w.sl = zusatz({ ml = f[1], h = ok(f[2]) and f[2] or nil, steig = ok(f[3]) and f[3] or nil, pause = f[4] == 1 })
        end
      elseif k == "nschlepp" then
        local x = tonumber(v)
        if x and x >= 0 and x < 1e6 then w.nSchlepp = math.floor(x) end
      elseif k then
        local f = M.feld(k)
        if f and f[2] == "b" then
          c[k] = pruefe(f, v == "1")
        elseif f and (f[2] == "z" or f[2] == "w") then
          c[k] = pruefe(f, tonumber(v))
        elseif f and f[2] == "t" then
          c[k] = pruefe(f, v)
        end
      end
    end
  end
  return gefunden
end

-- Quellen in den Widget-Speicher (Ethos ruft das beim Speichern des Modells auf).
function M.schreibe(w)
  if not (storage and storage.write) then return end
  local c = w.cfg
  local q = quellen()
  pcall(storage.write, "fmt", M.FORMAT)
  for i, name in ipairs(q) do
    local v = c[name]
    pcall(storage.write, "q" .. i, istQuelle(v) and v or 0)
  end
  pcall(storage.write, "ende", M.FORMAT)
end

-- Zahlen und dauerhafte Werte in die Datei. Gibt true zurück, wenn geschrieben.
function M.schreibeDatei(w)
  local c = w.cfg
  local z = { "# Gas Engine ECU Widget, Einstellungen und Tankstand dieses Modells" }
  for _, name in ipairs(M.folge) do
    local f = M.feld(name)
    local v = c[name]
    if f[2] == "b" then
      z[#z + 1] = name .. "=" .. (v and "1" or "0")
    elseif f[2] == "t" then
      local t = M.text(v)
      if t then z[#z + 1] = name .. "=" .. t end
    elseif f[2] ~= "q" and type(v) == "number" then
      z[#z + 1] = name .. "=" .. string.format("%d", math.floor(v))
    end
  end
  z[#z + 1] = "verbr=" .. string.format("%.1f", w.tk.verbr or 0)
  -- Übersicht und Flüge
  local function zahl(x) return x and string.format("%.2f", x) or "" end
  local function zusatz(s)
    local r = ""
    for _, n in ipairs(M.SZUSATZ) do r = r .. "," .. zahl(s[n]) end
    return r
  end
  for k, x in pairs(w.ue or {}) do
    if type(x) == "number" then z[#z + 1] = "ue_" .. k .. "=" .. zahl(x) end
  end
  z[#z + 1] = "nschlepp=" .. tostring(w.nSchlepp or 0)
  for _, s in ipairs(w.schlepps or {}) do
    z[#z + 1] = "s=" .. tostring(s.nr or 0) .. "," .. zahl(s.ml) .. "," .. zahl(s.h) .. "," .. zahl(s.steig) .. zusatz(s)
  end
  if w.sl then
    z[#z + 1] = "sl=" .. zahl(w.sl.ml or 0) .. "," .. zahl(w.sl.h) .. "," .. zahl(w.sl.steig) .. "," .. (w.sl.pause and "1" or "0") .. zusatz(w.sl)
  end
  if os and os.mkdir then pcall(os.mkdir, "daten") end
  local pfad = M.datei()
  local ok, f = pcall(io.open, pfad, "w")
  if not ok or not f then return false end
  local okw = pcall(f.write, f, table.concat(z, "\n") .. "\n")
  pcall(f.close, f)
  return okw
end

M.anzahlQuellen = function() return #quellen() end

return M
