-- Simulator-Makro: automatische Sensorzuordnung auf echter Firmware (Ethos 26.2) mit per Lua angelegten Sensoren.
-- Läuft über test/suche_ablauf.json (simulator.cjs); beide Widgets liegen unter scripts/gas_ecu und scripts/gas_carb.
-- Gleiche AppID auf zwei Physical IDs (Fall c) mischt der Simulator zu einem Sensor; dieser Fall steht in suche_test.lua.
local aus, fehler = {}, 0
local function melde(t) aus[#aus + 1] = t end
local function pruefe(name, ok) if not ok then fehler = fehler + 1; melde("FEHLER " .. name) else melde("ok " .. name) end end

local echt = loadfile
local function suche(ordner, cfg)
  loadfile = function(n) return echt("/scripts/" .. ordner .. "/" .. n) or echt("scripts/" .. ordner .. "/" .. n) end
  local w = { cfg = cfg or { zylAnz = 2 } }
  -- in Schritten wie im Widget: je Aufruf ein Schritt, bis eine Zahl kommt
  local ok, n, k = true, nil, 0
  repeat
    local f = loadfile("suche.lua")
    ok, n = pcall(function() return f()(w) end)
    k = k + 1
  until not ok or n ~= nil or k > 1000
  loadfile = echt
  if not ok then melde("FEHLER Suche " .. ordner .. ": " .. tostring(n)) fehler = fehler + 1 return w, -1 end
  return w, n
end
local function name(q) if q == nil then return "-" end local ok, v = pcall(q.name, q) return ok and tostring(v) or "?" end
local function app(q) if q == nil then return -1 end local ok, v = pcall(q.appId, q) return ok and v or -1 end
local function neu(id, ph)
  local s = model.createSensor({ type = SENSOR_TYPE_SPORT, appId = id, physId = ph })
  return s
end

-- (f) leeres Modell
for _, o in ipairs({ "gas_ecu", "gas_carb" }) do
  local w, n = suche(o)
  pruefe("(f) " .. o .. " leer: 0 zugewiesen", n == 0)
end
-- Sensoren anlegen
neu(0x0B00, 0x0B); neu(0x1000, 0x0D); neu(0x0200, 0x02)     -- (a) gleichnamige: Bat1 Spannung, Strom
neu(0x0500, 0x04); neu(0x0501, 0x05)                         -- (b) zwei Instanzen Drehzahl
neu(0x0210, 0x02)                                            -- (d) nur Gesamtspannung
neu(0x0600, 0x1B)                                            -- (e) «Kraftstoff» = mAh
neu(0x0300, 0x01)                                            -- Zellensensor
neu(0x0400, 0x0A); neu(0x0410, 0x0A)                         -- Temp. 1 / Temp. 2
neu(0x0D20, 0x0E); neu(0x0D50, 0x0E)                         -- Gas Suite Drehzahl, Durchfluss
neu(0x0D80, 0x0F)                                            -- AES II Fluss (gepackt)
local liste = system.getSources(CATEGORY_TELEMETRY_SENSOR) or {}
melde("Sensoren angelegt: " .. #liste)
for _, q in ipairs(liste) do
  local okS, s = pcall(q.subId, q)
  melde(string.format("  %04X %s sub=%s", app(q), name(q), okS and tostring(s) or "Fehler"))
end

local w, n = suche("gas_ecu")
melde("ECU: " .. n .. " zugewiesen")
pruefe("(a) ECU Bat1 Spannung = 0x0B00 (RB)", app(w.cfg.bat1V) == 0x0B00)
pruefe("(a) ECU FAS-Strom nicht in Akku-Strom", app(w.cfg.bat1A) ~= 0x0200)
pruefe("(b) ECU Drehzahl 0x0500 + Hinweis", app(w.cfg.rpm) == 0x0500 and w.suchHinweise ~= nil)
pruefe("(d) ECU Gesamtspannung nicht in Akku 1", app(w.cfg.lipo1) == 0x0300)
pruefe("(e) ECU Kraftstoff nicht zugewiesen", app(w.cfg.fluss) == 0x0D50)
pruefe("ECU Temp. 1 / Temp. 2 auf Zylinder 1 / 2", app(w.cfg.cht1) == 0x0400 and app(w.cfg.cht2) == 0x0410)
for _, h in ipairs(w.suchHinweise or {}) do melde("  Hinweis " .. h[1] .. ": " .. h[2] .. " passen, gewählt " .. h[3]) end

w, n = suche("gas_carb")
melde("Vergaser: " .. n .. " zugewiesen")
pruefe("Vergaser Drehzahl = Gas Suite 0x0D20", app(w.cfg.rpm) == 0x0D20)
pruefe("Vergaser Durchfluss = Gas Suite 0x0D50", app(w.cfg.fluss) == 0x0D50)
pruefe("(a) Vergaser Bat1 Spannung = 0x0B00", app(w.cfg.bat1V) == 0x0B00)
pruefe("(e) Vergaser Kraftstoff nicht zugewiesen", app(w.cfg.impulse) == -1)

-- (g) auf 100 Sensoren auffüllen (Temp.-1-Instanzen auf verschiedenen Physical IDs)
local i = 0
while #(system.getSources(CATEGORY_TELEMETRY_SENSOR) or {}) < 100 and i < 200 do
  neu(0x0400 + (i % 16), 0x10 + (i // 16) % 10); i = i + 1
end
liste = system.getSources(CATEGORY_TELEMETRY_SENSOR) or {}
melde("(g) Sensoren jetzt: " .. #liste)
w, n = suche("gas_ecu")
pruefe("(g) ECU bei " .. #liste .. " Sensoren: Drehzahl, Zellen, RB", app(w.cfg.rpm) == 0x0500 and app(w.cfg.lipo1) == 0x0300 and app(w.cfg.bat1V) == 0x0B00)
w, n = suche("gas_carb")
pruefe("(g) Vergaser bei " .. #liste .. " Sensoren: Drehzahl Gas Suite", app(w.cfg.rpm) == 0x0D20)

melde(fehler == 0 and "SIMTEST: kein Fehler" or ("SIMTEST: " .. fehler .. " Fehler"))
print(table.concat(aus, "\n"))
return table.concat(aus, "\n")
