-- Gas Engine Carb: Sensoren automatisch zuweisen. Füllt nur leere Felder; was von Hand gesetzt ist, bleibt.
-- Ablauf nach «Vorgaben Sensorzuordnung» (20.11.2026):
-- Stufe 1: Kennung aus AppID + Teilwert (kennung.lua, nur während der Suche geladen), je Feld Schlüssel in Rangfolge.
-- Stufe 2: nur für Sensoren ohne Kennung (DIY 0x5xxx, berechnete Sensoren): bekannte AppIDs und Namen.
-- Jeder Aufruf macht einen Schritt (siehe unten). Mehrdeutige Treffer stehen danach in w.suchHinweise
-- als { Feld, Anzahl passender Sensoren, «Name (Physical ID/AppID)» des gewählten }; das Menü zeigt sie an.

-- Feld -> Schlüssel in Rangfolge. Gas Suite (0x0D00–0x0D70) und AES II (0x0D80–0x0E20) vor den allgemeinen Sensoren.
local EINZEL = {
  { "rpm", { "gas_rpm", "aes_rpm1", "rpm", "rpm_adv" } },
  { "fluss", { "gas_fluss", "aes_fluss" } },
  { "hoehe", { "hoehe", "rb35_hoehe", "gps_hoehe", "d_hoehe" } },
  { "vario", { "vario", "rb35_vario", "d_vario" } },
  { "speed", { "gps_speed", "airspeed" } },
  { "rxBatt", { "rx_batt", "rx_batt1" } },
  { "bat1V", { "rb35_bat1_u", "rb25_bat1_u", "rb_bat1_u", "bat1_u" } },
  { "bat1A", { "rb35_bat1_i", "rb_bat1_i", "bat1_i" } },
  { "bat2V", { "rb35_bat2_u", "rb25_bat2_u", "rb_bat2_u", "bat2_u" } },
  { "bat2A", { "rb35_bat2_i", "rb_bat2_i", "bat2_i" } },
  { "rbState", { "rb_status" } },
  { "rbChState", { "rb_kanalstatus" } },
}
for i = 1, 8 do EINZEL[#EINZEL + 1] = { "rbK" .. i, { "rb35_k" .. i .. "_i", "rb_k" .. i .. "_i" } } end
-- Gruppen: mehrere Sensoren füllen die Felder der Reihe nach (Zylinder, Empfänger, Zellensensoren)
local GRUPPE = {
  { { "cht1", "cht2", "cht3", "cht4", "cht5" }, { "gas_temp1", "gas_temp2", "aes_temp1", "aes_temp2", "aes_temp3", "aes_temp4",
    "aes_temp5", "aes_temp6", "aes_temp7", "temp1", "temp2" }, zyl = true },
  { { "rssi", "rx1R24", "rx2R24" }, { "rssi" }, beide = true },             -- 0xF101: erster Empfänger füllt Statusleiste und RX1
  { { "rx1Vfr", "rx2Vfr" }, { "vfr", "rx_vfr" } },
  { { "lipo1", "lipo2", "lipo3" }, { "zellen" } },                           -- Zellensensoren 0x0300
}
-- (nur Gas Engine ECU: Turbinen-ECU erkennen; beim Vergaser leer)
local ECU_MERKMAL, ECU_STATUS = {}, nil
-- Standard-Physical-ID je Schlüssel (Tabelle «Ethos 26.2 Sensornamen je AppID»), letzte Wahl bei Gleichstand
local STDPHYS = { zellen = 1, rpm = 4, hoehe = 0, vario = 0 }
-- Stufe 2: AppIDs ohne Kennung und Namen (klein geschrieben) -> Felder
local APPID = { [0x5102] = "impulse" }
local NAMEN = {
  ["rssi 2.4g"] = { "rx1R24", "rx2R24" }, ["rssi 900m"] = { "rx1R900", "rx2R900" },
  ["rxbatt"] = { "rxBatt" }, ["rxbt"] = { "rxBatt" },
}

local NAME = "Gas Engine Carb"

-- Ethos begrenzt die Befehle je Aufruf («Max instructions count reached»): Die Suche läuft darum in Schritten über
-- mehrere Aufrufe. Zustand in w.suchZ; jeder Aufruf macht einen Schritt und gibt nil zurück, am Ende die Zahl der
-- neu zugewiesenen Felder (und w.suchZ ist wieder nil).
local PRO_AUFRUF = 10   -- Sensoren je Aufruf
local MAX_KAND = 5      -- je Schlüssel nur die besten Kandidaten behalten (mehr braucht kein Feld)

local function rufe(q, f)
  local okf, v = pcall(q[f], q)
  if okf then return v end
  return nil
end
local function zahl(v) return type(v) == "number" and v == v and v > -math.huge and v < math.huge end
-- Bereich einer AppID im Index: D-Hub (< 0x0100) und 0xF000 und höher einzeln, sonst 16 Instanzen je Bereich
local function bereich(id) if id < 0x0100 or id >= 0xF000 then return id end return id - id % 16 end
-- Reihenfolge der Kandidaten: (a) liefert einen Wert, (b) niedrigste Instanz, (c) Standard-Physical-ID, dann Physical ID
local function besser(a, b)
  if a.gut ~= b.gut then return a.gut < b.gut end
  if a.id ~= b.id then return a.id < b.id end
  if a.std ~= b.std then return a.std < b.std end
  return a.ph < b.ph
end
-- leer gilt auch eine ungültige Quelle (z. B. Sensor gelöscht: Ethos zeigt «---»)
local function leer(q)
  if q == nil then return true end
  if CATEGORY_NONE and rufe(q, "category") == CATEGORY_NONE then return true end
  local nm = rufe(q, "name")
  return type(nm) ~= "string" or nm == "" or nm:match("^%-+$") ~= nil
end

return function(w)
  local c, z = w.cfg, w.suchZ
  if z == nil then   -- Start: Sensorliste holen
    w.suchHinweise = nil
    if not (system.getSources and CATEGORY_TELEMETRY_SENSOR) then return 0 end
    local ok, liste = pcall(system.getSources, CATEGORY_TELEMETRY_SENSOR)
    if not ok or type(liste) ~= "table" then return 0 end
    w.suchZ = { liste = liste, i = 1, kand = {}, ohne = {}, schritt = 1, n = 0, belegt = {}, hinweise = {} }
    return nil
  end
  local function setze(feld, q)
    if leer(c[feld]) and not z.belegt[feld] then
      c[feld] = q
      z.belegt[feld] = true
      z.n = z.n + 1
      return true
    end
    z.belegt[feld] = true
    return false
  end

  if z.schritt == 1 then   -- Kennung laden und nach Bereich ordnen (kennung.lua bleibt unverändert)
    if z.tab == nil then   -- erster Aufruf: nur laden, ordnen im nächsten (Befehle je Aufruf klein halten)
      local okk, tab = pcall(function() local f = loadfile("kennung.lua"); return f and f() end)
      z.tab = (okk and type(tab) == "table") and tab or {}
      return nil
    end
    local tab, idx = z.tab, {}
    z.tab = nil
    do
      for _, e in ipairs(tab) do
        local b = bereich(e[1])
        local l = idx[b]
        if l == nil then l = {}; idx[b] = l end
        l[#l + 1] = e
      end
    end
    z.idx, z.schritt = idx, 2
    return nil
  end

  if z.schritt == 2 then   -- Stufe 1: Kennung je Sensor, höchstens PRO_AUFRUF Sensoren je Aufruf
    local bis = math.min(#z.liste, z.i + PRO_AUFRUF - 1)
    for j = z.i, bis do
      local q = z.liste[j]
      if type(q) == "userdata" or type(q) == "table" then
        local id, sub = rufe(q, "appId"), rufe(q, "subId")
        local key
        local l = zahl(id) and z.idx[bereich(id)]
        if l and zahl(sub) then
          for _, e in ipairs(l) do
            if id >= e[1] and id <= e[2] and (e[3] == nil or e[3] == sub) then key = e[4] break end
          end
        elseif l then
          -- Teilwert fehlt (per Lua angelegter Sensor, z. B. im Simulator): bei gepackten AppIDs über die Einheit
          -- entscheiden («_u» = Volt, «_i» = Ampere), sonst der erste Teilwert
          local u = rufe(q, "unit")
          local art = (UNIT_VOLT and u == UNIT_VOLT and "_u") or (UNIT_AMPERE and u == UNIT_AMPERE and "_i") or nil
          for _, e in ipairs(l) do
            if id >= e[1] and id <= e[2] then
              if e[3] == nil or (art and e[4]:sub(-2) == art) then key = e[4] break end
              key = key or e[4]
            end
          end
        end
        if key then
          local ph, v = rufe(q, "physId"), rufe(q, "value")
          ph = zahl(ph) and ph or 99
          local k = { q = q, id = id, ph = ph, gut = zahl(v) and 0 or 1, std = STDPHYS[key] == ph and 0 or 1 }
          local kl = z.kand[key]
          if kl == nil then kl = { anz = 0 }; z.kand[key] = kl end
          kl.anz = kl.anz + 1
          -- sortiert einfügen, nur die besten MAX_KAND behalten
          local p = #kl + 1
          while p > 1 and besser(k, kl[p - 1]) do p = p - 1 end
          if p <= MAX_KAND then
            table.insert(kl, p, k)
            if #kl > MAX_KAND then kl[#kl] = nil end
          end
        else
          z.ohne[#z.ohne + 1] = q
        end
      end
    end
    z.i = bis + 1
    if z.i > #z.liste then z.schritt, z.idx, z.liste = 3, nil, nil end
    return nil
  end

  if z.schritt == 3 then   -- Felder nach Rangfolge füllen
    for _, r in ipairs(EINZEL) do
      for _, key in ipairs(r[2]) do
        local l = z.kand[key]
        if l then
          if setze(r[1], l[1].q) and l.anz > 1 then
            local nm = rufe(l[1].q, "name")
            z.hinweise[#z.hinweise + 1] = { r[1], l.anz, string.format("%s (%s/%04X)", type(nm) == "string" and nm or "?",
              l[1].ph < 99 and string.format("%02X", l[1].ph) or "--", l[1].id) }
          end
          break
        end
      end
    end
    local ecu = false
    for _, key in ipairs(ECU_MERKMAL) do if z.kand[key] then ecu = true end end
    for _, g in ipairs(GRUPPE) do
      local felder, i = g[1], 1
      local bis = #felder
      if g.zyl and zahl(c.zylAnz) and c.zylAnz >= 1 and c.zylAnz < bis then bis = c.zylAnz end
      for _, key in ipairs(g[2]) do
        if not (g.zyl and ecu and key == ECU_STATUS) then
          for _, k in ipairs(z.kand[key] or {}) do
            if i > bis then break end
            if g.beide and i == 1 then
              setze(felder[1], k.q)
              setze(felder[2], k.q)
              i = 3
            else
              setze(felder[i], k.q)
              i = i + 1
            end
          end
        end
      end
    end
    z.kand, z.schritt, z.i = nil, 4, 1
    return nil
  end

  -- Stufe 2: Sensoren ohne Kennung (DIY-AppIDs, Namen), höchstens PRO_AUFRUF je Aufruf
  local bis = math.min(#z.ohne, z.i + PRO_AUFRUF - 1)
  for j = z.i, bis do
    local q = z.ohne[j]
    local id, name = rufe(q, "appId"), rufe(q, "name")
    if zahl(id) and APPID[id] then
      setze(APPID[id], q)
    elseif type(name) == "string" then
      for _, f in ipairs(NAMEN[string.lower(name)] or {}) do
        if not z.belegt[f] then setze(f, q) break end
      end
    end
  end
  z.i = bis + 1
  if z.i <= #z.ohne then return nil end
  -- Ende. Empfang in der Statusleiste: ohne eigenen Sensor den 2,4-GHz-Wert von Empfänger 1 nehmen
  if leer(c.rssi) and c.rx1R24 ~= nil then setze("rssi", c.rx1R24) end
  for _, h in ipairs(z.hinweise) do print(NAME .. ": " .. h[1] .. ": " .. h[2] .. " Sensoren passen, gewählt: " .. h[3]) end
  if #z.hinweise > 0 then w.suchHinweise = z.hinweise end
  w.suchZ = nil
  return z.n
end
