-- Gas Engine ECU Demo: Makro für die FrSky Suite (Simulator). Spielt einen Flug als Schleife ab.
-- Nur zur Vorführung, nie Teil des Widgets. Legt fehlende Sensoren im Modell an, speist Telemetrie ein
-- (S.Port wie die Telemetrie-Simulation der Suite) und stellt den Motorschalter SA und den Geber selbst.
-- Ablauf: Motor aus, Kaltstart mit Choke, Warmlauf, Choke aus, Steigflug (mit kurzem Zylinder-Alarm),
-- Ausklinken und Sinkflug, Landung, Motor aus. Stoppen mit «Makro stoppen» in der Suite.
local GAS_GEBER = 0      -- simulator.setAnalog: Geber 0
local SCHALTER = 0       -- simulator.setSwitch: SA (-1 oben = Aus, 0 Mitte = Ein, 1 unten = Choke)
local DT = 0.1

-- Sensoren: Name, AppID, PhysID, Einheit, Kommastellen
local SENS = {
  { "CHT1", 0x5110, 0x10, UNIT_CELSIUS, 0 }, { "CHT2", 0x5111, 0x10, UNIT_CELSIUS, 0 },
  { "Drehzahl", 0x5112, 0x10, UNIT_RPM, 0 }, { "Druck", 0x5113, 0x10, UNIT_BAR, 1 },
  { "ECU", 0x5114, 0x10, UNIT_VOLT, 1 },
  { "Höhe", 0x5115, 0x11, UNIT_METER, 0 }, { "Steigr. Vario", 0x5116, 0x11, UNIT_METER_PER_SECOND, 1 },
  { "Speed", 0x5117, 0x11, UNIT_KILOMETER_PER_HOUR, 0 },
  { "Durchfluss", 0x0D50, 0x16, UNIT_MILLILITER_PER_MINUTE, 0 }, { "Impulse", 0x5102, 0x16, UNIT_NONE, 0 },
  { "Bat1 Spannung", 0x5118, 0x12, UNIT_VOLT, 2 }, { "Bat1 Strom", 0x5119, 0x12, UNIT_AMPERE, 1 },
  { "Bat2 Spannung", 0x511A, 0x12, UNIT_VOLT, 2 }, { "Bat2 Strom", 0x511B, 0x12, UNIT_AMPERE, 1 },
  { "RSSI 2.4G", 0x511C, 0x13, UNIT_PERCENT, 0 }, { "RSSI 900M", 0x511D, 0x13, UNIT_PERCENT, 0 },
  { "RSSI 2.4G", 0x511E, 0x14, UNIT_PERCENT, 0 }, { "RSSI 900M", 0x511F, 0x14, UNIT_PERCENT, 0 },
}
for k = 1, 8 do SENS[#SENS + 1] = { "RB K" .. k .. "_A", 0x5120 + k, 0x12, UNIT_AMPERE, 1 } end
-- Drei Zellensensoren: eigene AppID im FLVS-Bereich je Sensor (mit gleicher AppID füllte Ethos nur den ersten, gemessen)
local LIPO = { { "LiPo E1", 0x01, 0x0300 }, { "LiPo E2", 0x02, 0x0301 }, { "LiPo ANL", 0x03, 0x0302 } }

local function frame(phys, app, v)
  simulator.injectSPortFrame({ module = 0, band = 0, rx = 0, physId = phys, primId = 0x10, appId = app, value = v })
end
-- Sensor nach AppID und PhysID suchen (getSource beachtet die PhysID nicht, gemessen 26.1.2)
local function finde(app, phys)
  local ok, liste = pcall(system.getSources, CATEGORY_TELEMETRY_SENSOR)
  if not ok or type(liste) ~= "table" then return nil end
  for _, q in ipairs(liste) do
    local o1, a = pcall(q.appId, q)
    local o2, p = pcall(q.physId, q)
    if o1 and o2 and a == app and p == phys then return q end
  end
  return nil
end
local function anlegen(name, app, phys, unit, dez, sport)
  if finde(app, phys) then return "da" end
  local ok, e = pcall(function()
    local s = sport and model.createSensor({ type = SENSOR_TYPE_SPORT, appId = app, physId = phys }) or nil
    if not s then
      s = model.createSensor({ type = SENSOR_TYPE_DIY })
      s:appId(app); s:physId(phys)
      if unit then s:unit(unit) end
      if dez then s:decimals(dez); pcall(s.protocolDecimals, s, dez) end
    end
    s:name(name)
  end)
  return ok and "neu" or ("Fehler: " .. tostring(e))
end
-- Zellensensor (FLVS): zwei Zellen pro Rahmen, 2 mV je Schritt
local function zellen(phys, z, app)
  local function p(a, b, start) return (math.floor(b * 500) << 20) | (math.floor(a * 500) << 8) | (#z << 4) | start end
  frame(phys, app, p(z[1], z[2], 0))
  frame(phys, app, p(z[3], 0, 2))
end

-- Abschnitte: Dauer s, Schalter, Gas %, Drehzahl, CHT1, CHT2, Druck, Höhe, Speed, Fluss ml/min, Text
local AB = {
  { 6, -1, 0, 0, 22, 21, 0, 0, 0, 0, "Motor aus" },
  { 4, 1, 10, 2200, 35, 33, 3.0, 0, 0, 10, "Kaltstart mit Choke" },
  { 12, 1, 12, 2300, 100, 96, 3.1, 0, 0, 12, "Warmlauf mit Choke" },
  { 6, 0, 15, 2500, 110, 106, 3.1, 0, 0, 14, "Choke aus, Leerlauf warm" },
  { 17, 0, 95, 7400, 165, 160, 3.2, 60, 95, 120, "Start und Steigflug" },
  { 8, 0, 95, 7450, 172, 202, 3.2, 90, 95, 125, "Steigflug: Zylinder 2 zu heiss" },
  { 15, 0, 20, 3000, 130, 128, 3.1, 30, 120, 25, "Ausklinken und Sinkflug" },
  { 6, 0, 12, 2300, 120, 118, 3.1, 0, 0, 12, "Landung, Leerlauf" },
  { 4, -1, 0, 0, 115, 113, 0, 0, 0, 0, "Motor aus" },
}

-- Selbsttest in eine Datei, damit man nach einem Lauf sieht, ob alles geht
local out = io.open("USER:/gas-engine-demo-ergebnis.txt", "w")
local function bericht(s) print("MOTORENDEMO " .. s); if out then out:write(s .. "\n") end end
bericht("Gas Engine ECU Demo, Selbsttest")
for _, s in ipairs(SENS) do bericht("Sensor " .. s[1] .. " " .. anlegen(s[1], s[2], s[3], s[4], s[5], false)) end
for _, l in ipairs(LIPO) do bericht("Sensor " .. l[1] .. " " .. anlegen(l[1], l[3], l[2], nil, nil, true)) end

local imp, akku, t = 0, 0, 0
local function wert(app, phys, x, dez) frame(phys, app, math.floor(x * 10 ^ (dez or 0) + 0.5)) end
local function schritt(a, b, f)
  local function m(i) return a[i] + (b[i] - a[i]) * f end
  local rpm, c1, c2, dr, h, sp, fl = m(4), m(5), m(6), m(7), m(8), m(9), m(10)
  local vario = (b[8] - a[8]) / b[1]
  frame(0x00, 0xF101, 75 + math.random(0, 10))                -- RSSI: hält die Telemetrie aktiv
  wert(0x5110, 0x10, c1); wert(0x5111, 0x10, c2); wert(0x5112, 0x10, rpm); wert(0x5113, 0x10, dr, 1)
  wert(0x5114, 0x10, 12.1 - akku * 0.4, 1)
  wert(0x5115, 0x11, h); wert(0x5116, 0x11, vario, 1); wert(0x5117, 0x11, sp)
  wert(0x0D50, 0x16, fl)
  imp = imp + fl / 60 * DT / 0.1                               -- 0,1 ml pro Impuls
  wert(0x5102, 0x16, imp)
  local e = 4.10 - akku
  wert(0x5118, 0x12, e * 3 - 0.02, 2); wert(0x5119, 0x12, 1.2 + rpm / 9000, 1)
  wert(0x511A, 0x12, e * 3 - 0.04, 2); wert(0x511B, 0x12, 1.1 + rpm / 9000, 1)
  wert(0x511C, 0x13, 96 + math.random(0, 3)); wert(0x511D, 0x13, 90 + math.random(0, 4))
  wert(0x511E, 0x14, 94 + math.random(0, 4)); wert(0x511F, 0x14, 88 + math.random(0, 5))
  for k = 1, 8 do wert(0x5120 + k, 0x12, (k == 3 or k == 4) and (0.3 + rpm / 12000) or 0.2, 1) end
  zellen(0x01, { e + 0.01, e, e + 0.02 }, 0x0300)
  zellen(0x02, { e, e - (f > 0.5 and b[11]:find("heiss") and 0.6 or 0), e + 0.01 }, 0x0301)   -- Zelle tief beim Alarm
  zellen(0x03, { e - 0.1, e - 0.09, e - 0.1 }, 0x0302)
  simulator.setSwitch(SCHALTER, b[2])
  simulator.setAnalog(GAS_GEBER, math.floor(m(3) * 2 - 100))
end

-- kurz einschwingen, dann Selbsttest der Werte
for _ = 1, 20 do schritt(AB[1], AB[2], 0.5); simulator.sleep(DT) end
local tel = system.getSource({ category = CATEGORY_SYSTEM_EVENT, member = SYSTEM_EVENT_TELEMETRY_ACTIVE })
bericht("Telemetrie aktiv: " .. ((tel and (tel:value() or 0) > 0) and "ja" or "nein"))
for _, s in ipairs(SENS) do
  local q = finde(s[2], s[3])
  bericht("Wert " .. s[1] .. " = " .. tostring(q and q:value()))
end
local l = finde(0x0301, 0x02)
bericht("Zellen E2: " .. tostring(l and l:value({ options = OPTION_CELL_COUNT })) .. " Zellen, Zelle 2 = " ..
  tostring(l and l:value({ options = OPTION_CELL_INDEX(2) })))
if out then out:close(); out = nil end

-- Schleife
while true do
  for i = 1, #AB do
    local a, b = AB[i == 1 and #AB or i - 1], AB[i]
    print("MOTORENDEMO Abschnitt: " .. b[11])
    local n = math.floor(b[1] / DT)
    for k = 1, n do
      schritt(a, b, k / n)
      t = t + DT
      akku = math.min(0.5, t / 1500)                           -- Akkus sinken langsam
      simulator.sleep(DT)
    end
  end
end
