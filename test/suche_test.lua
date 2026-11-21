-- Feste Fälle der automatischen Sensorzuordnung (Vorgaben Sensorzuordnung, FrSky Koordination 20.11.2026), ohne Simulator.
-- Aufruf aus dem Projektordner:  /opt/homebrew/opt/lua@5.4/bin/lua test/suche_test.lua
-- Prüft beide Widgets mit nachgebildeten Ethos-Quellen (appId, subId, physId, name, value).
CATEGORY_TELEMETRY_SENSOR, CATEGORY_NONE, UNIT_VOLT, UNIT_AMPERE = 4, 0, 1, 2
local fehler, faelle, maxBefehle = 0, 0, 0
local echtLoad = loadfile
local ordner

local function sensor(id, ph, name, wert, sub, einheit)
  if sub == false then sub = nil elseif sub == nil then sub = 0 end   -- false = ohne Teilwert (per Lua angelegt)
  return { appId = function() return id end, physId = function() return ph end, subId = function() return sub end,
    unit = function() return einheit end,
    name = function() return name end, value = function() return wert end, category = function() return 4 end }
end
local liste = {}
system = { getSources = function() return liste end }
print = function() end   -- Protokollzeilen der Suche ausblenden
local function suche(sensoren, cfg, sp)
  liste = sensoren
  loadfile = function(n) return echtLoad(ordner .. "/" .. n) end
  local w = { cfg = cfg or {}, sp = sp }
  -- Die Suche läuft in Schritten: wie kern.lua je Aufruf suche.lua neu laden und einen Schritt machen, bis eine Zahl kommt.
  -- Je Aufruf werden die Lua-Befehle gezählt (Ethos bricht bei zu vielen ab: «Max instructions count reached»).
  local n, aufrufe = nil, 0
  repeat
    local f = echtLoad(ordner .. "/suche.lua")
    local befehle = 0
    debug.sethook(function() befehle = befehle + 1 end, "", 1)
    n = f()(w)
    debug.sethook()
    aufrufe = aufrufe + 1
    if befehle > maxBefehle then maxBefehle = befehle end
  until n ~= nil or aufrufe > 1000
  loadfile = echtLoad
  return w, n
end
local function pruefe(name, ok)
  faelle = faelle + 1
  if not ok then fehler = fehler + 1; io.write("FEHLER: ", ordner, ": ", name, "\n") end
end
local function ist(w, feld, q) return w.cfg[feld] == q end

for _, o in ipairs({ "src/gas_ecu", "src/gas_carb" }) do
  ordner = o
  local ecu = o:find("ecu") ~= nil
  -- (a) gleichnamige Sensoren verschiedener Geräte: «Strom» 0x0200 (FAS) und 0x0F10 (RB25), «Bat1 Spannung» 0x0B00/0x0F00/0x1000
  local rb35 = sensor(0x0F00, 0x0C, "Bat1 Spannung", 8.1, 0)
  local rb = sensor(0x0B00, 0x0B, "Bat1 Spannung", 8.0, 0)
  local sp = sensor(0x1000, 0x0D, "Bat1 Spannung", 7.9, 0)
  local fas = sensor(0x0200, 0x02, "Strom", 3.0)
  local w = suche({ sp, rb, fas, rb35 })
  pruefe("(a) Bat1 Spannung: RB35 vor RB und Sensor 0x1000", ist(w, "bat1V", rb35))
  pruefe("(a) FAS-Strom landet nicht in Akku-Strom", w.cfg.bat1A == nil and w.cfg.bat2A == nil)
  pruefe("(a) kein Hinweis bei verschiedenen Geräten", w.suchHinweise == nil)
  -- Teilwert fehlt (Sensor per Lua angelegt): gepackte AppID über die Einheit
  local bu, bi = sensor(0x1000, 0x0D, "Bat1 Spannung", 8.2, false, UNIT_VOLT), sensor(0x1000, 0x0D, "Bat1 Strom", 1.5, false, UNIT_AMPERE)
  w = suche({ bi, bu })
  pruefe("ohne Teilwert: Spannung und Strom über die Einheit", ist(w, "bat1V", bu) and ist(w, "bat1A", bi))
  local nz = sensor(0x0F00, 0x0C, "Bat2 Strom", 0.8, false, UNIT_AMPERE)
  w = suche({ nz })
  pruefe("ohne Teilwert: RB35-Strom nicht als Spannung", w.cfg.bat1V == nil and w.cfg.bat2V == nil and (w.cfg.bat1A == nz or w.cfg.bat2A == nz))
  -- (b) zwei Instanzen derselben AppID: Drehzahl 0x0500 und 0x0501; die mit Wert gewinnt, sonst die niedrigere
  local r0, r1 = sensor(0x0500, 0x04, "Drehzahl", nil), sensor(0x0501, 0x05, "Drehzahl", 5200)
  w = suche({ r0, r1 })
  pruefe("(b) Instanz mit gültigem Wert gewählt", ist(w, "rpm", r1))
  pruefe("(b) Hinweis «2 Sensoren passen»", w.suchHinweise and w.suchHinweise[1][1] == "rpm" and w.suchHinweise[1][2] == 2)
  pruefe("(b) Hinweis nennt Physical ID/AppID", w.suchHinweise and w.suchHinweise[1][3] == "Drehzahl (05/0501)")
  r0 = sensor(0x0500, 0x04, "Drehzahl", 4000)
  w = suche({ r1, r0 })
  pruefe("(b) beide mit Wert: niedrigste Instanz", ist(w, "rpm", r0))
  -- (c) gleiche AppID auf zwei Physical IDs (am Sender getrennte Sensoren): Standard-Physical-ID 0x04 bei Drehzahl
  local p9, p4 = sensor(0x0500, 0x09, "Drehzahl", 3000), sensor(0x0500, 0x04, "Drehzahl", 3100)
  w = suche({ p9, p4 })
  pruefe("(c) Standard-Physical-ID gewählt", ist(w, "rpm", p4))
  pruefe("(c) Hinweis gesetzt", w.suchHinweise ~= nil)
  local z1, z2 = sensor(0x0300, 0x03, "LiPo", 12.0), sensor(0x0300, 0x01, "LiPo", 12.1)
  w = suche({ z1, z2 })
  pruefe("(c) zwei Zellensensoren auf Akku 1 und 2, Standard-ID zuerst", ist(w, "lipo1", z2) and ist(w, "lipo2", z1))
  -- (d) nur Gesamtspannung ohne Zellen: VFAS 0x0210 wird nicht als Zellensensor eingetragen
  w = suche({ sensor(0x0210, 0x02, "Spannung", 22.2) })
  pruefe("(d) Gesamtspannung nicht in Akku-Feldern", w.cfg.lipo1 == nil and w.cfg.bat1V == nil and w.cfg.ecuV == nil)
  -- (e) Betaflight-«Kraftstoff» 0x0600 = verbrauchte mAh: nie Durchfluss, Impulse oder Tank
  local n
  w, n = suche({ sensor(0x0600, 0x1B, "Kraftstoff", 850) })
  pruefe("(e) «Kraftstoff» 0x0600 nicht zugewiesen", n == 0 and next(w.cfg) == nil)
  -- (f) leeres Modell
  w, n = suche({})
  pruefe("(f) leeres Modell: nichts zugewiesen, kein Fehler", n == 0 and w.suchHinweise == nil)
  -- (g) 100 Sensoren (Höchstzahl je Modell): Zuordnung bleibt richtig
  local viele = {}
  for i = 1, 95 do viele[i] = sensor(0x0400 + (i % 16), 0x0A, "Temp. 1", 20 + i) end
  local rpm, gas, aesr, f101, zz = sensor(0x0500, 0x04, "Drehzahl", 6000), sensor(0x0D20, 0x0E, "Drehzahl", 6100),
    sensor(0x0DB0, 0x0F, "Drehzahl 1", 6200, 0), sensor(0xF101, 0x00, "RSSI", 80), sensor(0x0300, 0x01, "LiPo", 16.4)
  viele[96], viele[97], viele[98], viele[99], viele[100] = rpm, gas, aesr, f101, zz
  w = suche(viele, { zylAnz = 2 })
  pruefe("(g) RSSI in Statusleiste und RX1", ist(w, "rssi", f101) and ist(w, "rx1R24", f101))
  pruefe("(g) Zellensensor auf Akku 1", ist(w, "lipo1", zz))
  pruefe("(g) Drehzahl: " .. (ecu and "0x0500" or "Gas Suite 0x0D20"), ist(w, "rpm", ecu and rpm or gas))
  pruefe("(g) nur 2 Zylinder belegt (Vorgabe 2 Zylinder)", w.cfg.cht1 ~= nil and w.cfg.cht2 ~= nil and w.cfg.cht3 == nil)
  -- Von Hand gesetzte Felder bleiben
  local hand = sensor(0x5100, 0x16, "Eigener", 1)
  w = suche({ rpm }, { rpm = hand })
  pruefe("von Hand gesetztes Feld bleibt", ist(w, "rpm", hand))
  -- DIY 0x5102 (Impulszähler, Stufe 2)
  local imp = sensor(0x5102, 0x16, "Impulse", 10)
  w = suche({ imp })
  pruefe("Stufe 2: Impulszähler 0x5102", ist(w, "impulse", imp))
  -- Zylinderzahl: 4 Temperaturen bei 4 Zylindern
  local t = {}
  for i = 1, 4 do t[i] = sensor(0x0400 + i - 1, 0x0A, "Temp. 1", 100 + i) end
  w = suche(t, { zylAnz = 4 })
  pruefe("4 Zylinder der Reihe nach", ist(w, "cht1", t[1]) and ist(w, "cht4", t[4]))
  if ecu then
    -- SportECU/Hornet: 0x0400 EGT, 0x0410 Status, 0x0900 ECU-Akku, 0x0910 Pumpe
    local egt, st, ak, pu = sensor(0x0400, 0x0A, "Temp. 1", 650), sensor(0x0410, 0x0A, "Temp. 2", 3),
      sensor(0x0900, 0x0A, "ADC3", 7.4), sensor(0x0910, 0x0A, "ADC4", 3.1)
    w = suche({ st, egt, ak, pu })
    pruefe("SportECU: EGT in Zylinder 1, Status nicht in Zylinder 2", ist(w, "cht1", egt) and w.cfg.cht2 == nil)
    pruefe("SportECU: ECU-Akku 0x0900 in ECU-Spannung", ist(w, "ecuV", ak))
    -- Kolbenmotor mit Temp. 1 und Temp. 2 (ohne ECU-Merkmal): beide Zylinder
    local ta, tb = sensor(0x0400, 0x0A, "Temp. 1", 120), sensor(0x0410, 0x0A, "Temp. 2", 125)
    w = suche({ tb, ta })
    pruefe("Kolbenmotor: Temp. 1 und Temp. 2 auf Zylinder 1 und 2", ist(w, "cht1", ta) and ist(w, "cht2", tb))
  else
    -- AES II und Gas Suite vor Temp. 1/Temp. 2 und Drehzahl
    local at1, at2, t1, ar = sensor(0x0D90, 0x0F, "Temp. 1", 110, 1), sensor(0x0DC0, 0x0F, "Temp. 2", 112, 0),
      sensor(0x0400, 0x0A, "Temp. 1", 30), sensor(0x0DB0, 0x0F, "Drehzahl 1", 6000, 0)
    w = suche({ t1, at1, at2, ar, rpm })
    pruefe("AES II: Temperaturen vor Temp. 1", ist(w, "cht1", at1) and ist(w, "cht2", at2))
    pruefe("AES II: Drehzahl vor 0x0500", ist(w, "rpm", ar))
    local gf = sensor(0x0D50, 0x0E, "Durchfluss", 12)
    w = suche({ gf })
    pruefe("Gas Suite: Durchfluss 0x0D50", ist(w, "fluss", gf))
  end
end
io.write(string.format("höchstens %d Lua-Befehle je Aufruf (Ziel deutlich unter 10000)\n", maxBefehle))
pruefe("Befehle je Aufruf unter 5000", maxBefehle < 5000)
io.write(string.format("%d Fälle, %d Fehler\nERGEBNIS: %s\n", faelle, fehler, fehler == 0 and "kein Fehler" or "FEHLER"))
os.exit(fehler == 0 and 0 or 1)
