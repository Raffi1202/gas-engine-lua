-- Test «Alarme bei Motor aus» (Entscheide User 21.11.2026), ohne Simulator, für beide Widgets.
-- Je geänderter Meldung ein Fall mit Motor ein und einer mit Motor aus (Kill über den Motorschalter, Drehzahl 0),
-- dazu: der Motorschalter schaltet keinen Grenzwert-Alarm stumm.
-- Aufruf aus dem Projektordner:  /opt/homebrew/opt/lua@5.4/bin/lua test/motor_aus_test.lua
-- Ergebnis: je Fall eine Zeile «ok»/«FEHLER», am Schluss «ERGEBNIS: kein Fehler» oder die Anzahl Fehler.

local T = 100.0
os.clock = function() return T end
local nFehler, nFaelle = 0, 0
local echtPrint = print
print = function(t, ...)   -- Schreibfehler der Widget-Datei (hier ohne Dateisystem) nicht anzeigen
  if type(t) == "string" and t:find("Datei konnte nicht geschrieben werden") then return end
  echtPrint(t, ...)
end

-- Ethos nachstellen: nur, was der Kern für Lesen, Warnungen und Ansagen braucht
local function leer() end
local stumm = setmetatable({}, { __index = function() return leer end })
system = setmetatable({ getLocale = function() return "de" end, getSource = function() return nil end }, { __index = stumm })
lcd = setmetatable({ isVisible = function() return false end }, { __index = stumm })
model = setmetatable({ name = function() return "TEST" end }, { __index = stumm })
UNIT_CELSIUS, UNIT_VOLT, UNIT_PERCENT = 1, 2, 3

local function Q(f, lo, hi)
  return { value = function() return f() end, minimum = function() return lo or 0 end, maximum = function() return hi or 10000 end,
    stringUnit = function() return "" end, decimals = function() return 0 end, name = function() return "q" end }
end

local function pruefe(name, ist, soll)
  nFaelle = nFaelle + 1
  if ist == soll then
    print("ok      " .. name)
  else
    nFehler = nFehler + 1
    print("FEHLER  " .. name .. ": erwartet " .. tostring(soll) .. ", ist " .. tostring(ist))
  end
end

for _, ordner in ipairs({ "gas_ecu", "gas_carb" }) do
  local DIR = "src/" .. ordner .. "/"
  local echtLoad = loadfile
  loadfile = function(p, ...) if p:sub(1, 1) ~= "/" then return echtLoad(DIR .. p, ...) end return echtLoad(p, ...) end
  local K = loadfile("kern.lua")()
  K.VERSION = "test"
  local ecu = ordner == "gas_ecu"

  -- d = Sensorwerte; sw: -100 = Stellung 1 (Aus/Kill), 0 = Ein, 100 = Choke
  local function neu(d)
    local w = K.neu()
    local c = w.cfg
    c.cht1 = Q(function() return d.z1 end, 0, 300); c.cht2 = Q(function() return d.z2 end, 0, 300)
    c.rpm = Q(function() return d.rpm end, 0, 10000)
    c.motorSw = Q(function() return d.sw end, -100, 100)
    c.gas = Q(function() return d.gas end, -1024, 1024)
    c.fluss = Q(function() return d.fluss end, 0, 500)
    if ecu then c.druck = Q(function() return d.druck end, 0, 5) end
    c.laeuftAb = 800; c.chtWarn = 170; c.chtAlarm = 190; c.chtDiff = 25; c.sperre = 10
    c.druckVon = 22; c.druckAlarm = 18
    c.tank = 2000; c.tankRes = 10; c.tankLeer = 5; c.tankMin = 5
    c.chokeTemp = 100; c.chokeGas = 30; c.swAus = 1; c.swChoke = 3
    c.ansage = false
    w.qTele = Q(function() return 1 end)
    w.autoOffen = false
    K.grenzen(w)
    return w
  end
  local function lauf(w, s) for _ = 1, math.floor(s * 10 + 0.5) do T = T + 0.1; K.wecke(w) end end
  local function an(w, n) return w.meld[n] ~= nil and w.meld[n].an == true end

  -- Grundwerte: Motor läuft, Zylinder gleich, Druck gut, Tank voll, Schalter Ein
  local function basis() return { z1 = 150, z2 = 148, rpm = 6000, sw = 0, gas = 0, fluss = 0, druck = 3.0 } end
  -- Motor über den Schalter abstellen (Kill): Schalter auf Aus, Drehzahl 0
  local function abstellen(d) d.sw, d.rpm, d.fluss = -100, 0, 0 end
  local P = ordner .. ": "

  -- 1. ZYL UNGLEICH: Motor ein (nach der Startsperre) / Motor aus nach dem Abstellen / Startsperre nach dem Anlassen
  do
    local d = basis(); d.z2 = 110
    local w = neu(d); lauf(w, 15)
    pruefe(P .. "ZYL UNGLEICH, Motor ein", an(w, "zDiff"), true)
    abstellen(d); lauf(w, 6)
    pruefe(P .. "ZYL UNGLEICH, Motor aus (Schalter aus)", an(w, "zDiff"), true)
    d.rpm, d.sw = 0, 0; lauf(w, 6)
    pruefe(P .. "ZYL UNGLEICH, Motor steht, Schalter ein", an(w, "zDiff"), true)
    d.rpm = 6000; lauf(w, 4)
    pruefe(P .. "ZYL UNGLEICH, Startsperre nach dem Anlassen", an(w, "zDiff"), false)
    lauf(w, 8)
    pruefe(P .. "ZYL UNGLEICH, nach der Startsperre", an(w, "zDiff"), true)
  end

  -- 2. Spritdruck tief (nur ECU): nur bei laufendem Motor
  if ecu then
    local d = basis(); d.druck = 1.0
    local w = neu(d); lauf(w, 15)
    pruefe(P .. "SPRITDRUCK TIEF, Motor ein", an(w, "druckA"), true)
    abstellen(d); lauf(w, 6)
    pruefe(P .. "SPRITDRUCK TIEF, Motor aus", an(w, "druckA") or an(w, "druckW"), false)
  end

  -- 3. Tank: Restzeit-Grenze nur bei laufendem Motor, Prozent-Grenze immer
  do
    local d = basis(); d.fluss = 300                       -- 300 ml/min, Tank 2000 ml
    local w = neu(d)
    w.tk.verbr = 1100                                      -- 900 ml übrig = 3 min < 5 min, 45 % > 5 %
    lauf(w, 75)
    pruefe(P .. "Restzeit, Motor ein: Restzeit da", w.tk.restMin ~= nil, true)
    pruefe(P .. "TANK FAST LEER (Restzeit), Motor ein", an(w, "tankLeer"), true)
    abstellen(d); lauf(w, 6)
    pruefe(P .. "Restzeit, Motor aus: keine Restzeit", w.tk.restMin, nil)
    pruefe(P .. "TANK FAST LEER (Restzeit), Motor aus", an(w, "tankLeer"), false)
    w.tk.verbr = 1950                                      -- 2,5 % < 5 %
    lauf(w, 3)
    pruefe(P .. "TANK FAST LEER (Prozent), Motor aus", an(w, "tankLeer"), true)
    local d2 = basis(); local w2 = neu(d2); w2.tk.verbr = 1950; lauf(w2, 3)
    pruefe(P .. "TANK FAST LEER (Prozent), Motor ein", an(w2, "tankLeer"), true)
  end

  -- 4. CHOKE AUS!: nur bei laufendem Motor
  do
    local d = basis(); d.sw = 100                          -- Choke-Stellung, Zylinder warm
    local w = neu(d); lauf(w, 15)
    pruefe(P .. "CHOKE AUS!, Motor ein", an(w, "choke"), true)
    d.rpm = 0; lauf(w, 6)
    pruefe(P .. "CHOKE AUS!, Motor aus", an(w, "choke"), false)
  end

  -- 5. Motorschalter auf Aus schaltet keinen Grenzwert-Alarm stumm (ZYL HEISS als Beispiel, dazu die Ansage)
  do
    local d = basis(); d.z1 = 200
    local w = neu(d); w.cfg.ansage = true
    local gespielt = {}
    system.playFile = function(f) gespielt[#gespielt + 1] = f end
    lauf(w, 15)
    pruefe(P .. "ZYL 1 HEISS, Motor ein", an(w, "zA1"), true)
    abstellen(d); gespielt = {}; lauf(w, 35)
    pruefe(P .. "ZYL 1 HEISS, Schalter aus", an(w, "zA1"), true)
    local ansage = false
    for _, f in ipairs(gespielt) do if f:find("zyl1_alarm") then ansage = true end end
    pruefe(P .. "Ansage ZYL 1 HEISS, Schalter aus", ansage, true)
    system.playFile = leer
  end

  -- 6. «Alarm auch bei Motor aus» (beiMotorAus, Format 2 §3.5): Haken EIN/AUS x Schalter aus/ein (ZYL 1 HEISS)
  for _, fall in ipairs({ { true, -100, true, "Haken EIN, Schalter aus" }, { false, -100, false, "Haken AUS, Schalter aus" },
                          { false, 0, true, "Haken AUS, Schalter ein" } }) do
    local d = basis(); d.z1 = 200; d.sw = fall[2]; if fall[2] < 0 then d.rpm = 0 end
    local w = neu(d); w.cfg.ansage = true; w.cfg.vibration = true; w.cfg.maChtMax = fall[1]
    local gespielt, vib = {}, 0
    system.playFile = function(f) gespielt[#gespielt + 1] = f end
    system.playHaptic = function() vib = vib + 1 end
    lauf(w, 40)
    local ansage = false
    for _, f in ipairs(gespielt) do if f:find("zyl1_alarm") then ansage = true end end
    pruefe(P .. "beiMotorAus " .. fall[4] .. ": Anzeige rot", an(w, "zA1") and w.stufe == 2, true)
    pruefe(P .. "beiMotorAus " .. fall[4] .. ": Ansage", ansage, fall[3])
    pruefe(P .. "beiMotorAus " .. fall[4] .. ": Vibration", vib > 0, fall[3])
    system.playFile, system.playHaptic = leer, leer
  end
  -- 6b. Abschaltgründe kommen immer, auch wenn alle Haken aus sind
  do
    local d = basis(); d.sw = -100; d.rpm = 0
    local w = neu(d)
    for k in pairs(w.cfg) do if k:sub(1, 2) == "ma" then w.cfg[k] = false end end
    lauf(w, 1)
    for _, n in ipairs({ "motorAus", "rbF", "tele", "choke" }) do
      pruefe(P .. "immer: " .. n .. " schweigt nie", K.still(w, { name = n }), false)
    end
    pruefe(P .. "Haken aus, Schalter aus: zA1 schweigt", K.still(w, { name = "zA1" }), true)
    w.leerP, w.leerR, w.cfg.maRestzeit = true, true, true
    pruefe(P .. "Tank leer, Prozent still, Restzeit nicht: kommt", K.still(w, { name = "tankLeer" }), false)
  end

  -- 7. Studio-Datei: ohne Zahl-Stufe und ohne «aus» nie abschalten (Werkgrenze), beiMotorAus, .funke.lua
  do
    local S = loadfile("studio.lua")()
    local F = loadfile("felder.lua")()
    local WERTE = loadfile("werte.lua")()
    local std = F.standard()
    local function cfg(gr, fk)
      local st = S.pruefe({ format = 1, grenzen = { ["lua:cht_max"] = gr } }, fk, F, WERTE)
      local w = { cfg = {} }
      S.anwenden(w, st, F)
      return w.cfg, st, w
    end
    local function werk(c) return c.chtWarn == std.chtWarn and c.chtAlarm == std.chtAlarm and std.chtAlarm > 0 end
    pruefe(P .. "Studio nur beiMotorAus = false: Werkgrenze", werk((cfg({ beiMotorAus = false }))), true)
    pruefe(P .. "Studio nur beiMotorAus = false: Haken aus", (cfg({ beiMotorAus = false })).maChtMax, false)
    pruefe(P .. "Studio nur ansage = false: Werkgrenze", werk((cfg({ ansage = false }))), true)
    pruefe(P .. "Studio warnung/alarm = false: Werkgrenze", werk((cfg({ warnung = false, alarm = false }))), true)
    pruefe(P .. "Studio leerer Eintrag: Werkgrenze", werk((cfg({}))), true)
    local c = cfg({ aus = true })
    pruefe(P .. "Studio aus = true: Alarm aus", c.chtWarn == 0 and c.chtAlarm == 0, true)
    c = cfg({ warnung = 150 })
    pruefe(P .. "Studio nur warnung: Alarmstufe aus", c.chtWarn == 150 and c.chtAlarm == 0, true)
    pruefe(P .. "Studio ohne beiMotorAus: Haken an", (cfg({ warnung = 150, alarm = 180 })).maChtMax, true)
    pruefe(P .. "Studio beiMotorAus falscher Typ: Haken an", (cfg({ beiMotorAus = "nein" })).maChtMax, true)
    pruefe(P .. ".funke.lua true hebt false auf",
      (cfg({ beiMotorAus = false }, { format = 1, grenzen = { ["lua:cht_max"] = { beiMotorAus = true } } })).maChtMax, true)
    -- im Menü geändert: der Haken kommt als beiMotorAus in die Grenze, nicht unter «einstellungen»
    local c2, st, w = cfg({ beiMotorAus = false })
    local basis2 = {}
    for k, v in pairs(c2) do basis2[k] = v end
    w.cfg.maChtMax = true
    local t = S.funkeText(w, F, basis2, st.werte)
    pruefe(P .. ".funke.lua schreibt beiMotorAus = true", t:find("beiMotorAus = true", 1, true) ~= nil, true)
    pruefe(P .. ".funke.lua ohne ma_-Einstellung", t:find("ma_", 1, true) == nil, true)
    local fk = load(t)()
    local st3 = S.pruefe({ format = 1, grenzen = { ["lua:cht_max"] = { beiMotorAus = false } } }, fk, F, WERTE)
    local w3 = { cfg = {} }; S.anwenden(w3, st3, F)
    pruefe(P .. ".funke.lua zurückgelesen: Haken an, Werkgrenze", w3.cfg.maChtMax == true and werk(w3.cfg), true)
  end

  loadfile = echtLoad
end

print(nFaelle .. " Fälle")
if nFehler == 0 then print("ERGEBNIS: kein Fehler") os.exit(0) end
print("ERGEBNIS: " .. nFehler .. " Fehler")
os.exit(1)
