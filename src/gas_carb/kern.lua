-- Gas Engine Carb: Kern des Widgets. Liest die gewählten Quellen, rechnet Höchstwerte, Tank und Warnungen
-- und ruft die Seiten zum Zeichnen. Alles Rechnen passiert in wecke(), zeichne() zeichnet nur.
-- Absturzsicher: jeder Wert wird geprüft (nil, NaN, unendlich, riesig), jede Rechnung ist begrenzt.
local K = {}
local Z = nil          -- zeichnen.lua
local SEITE = {}       -- geladene Seite (immer nur die sichtbare)
local KOMPAKT = nil    -- kompakt.lua (nur im Layout mit Kopf- und Fussleiste geladen)
local ANSICHT = nil    -- ansicht.lua (nur mit Studio-Datei geladen)
local SEITEN = 3

local DT_SCHNELL = 0.1 -- s: Motorwerte lesen
local DT_LANGSAM = 0.5 -- s: Akkus, RB35, Empfänger lesen
local DT_BILD = 0.2    -- s: Bild auffrischen
local AN_S = 1.0       -- s: so lange muss eine Bedingung gelten, bis die Warnung kommt
local AUS_S = 3.0      -- s: so lange muss sie weg sein, bis die Warnung geht
local ANSAGE_ABSTAND = 3.0
local TREND_DT = 2.0   -- s: Abstand der Trend-Messpunkte (6 Punkte = 10 s)
local TREND_BAND = 2   -- Änderung in 10 s, ab der ein Pfeil gezeigt wird
local RING_DT = 5.0    -- s: Abstand der Verbrauchs-Messpunkte (13 Punkte = 60 s)
local RESTZEIT_AB = 30 -- s Motorlauf, ab denen eine Restzeit gezeigt wird
local MAX_SCHRITT_ML = 20  -- ml: grösster glaubhafter Verbrauch zwischen zwei Lesungen (0,1 s)
local SLOP = 14        -- Pixel: ab hier gilt eine Bewegung als Wisch
local GROSS = 1e7      -- Werte darüber gelten als unplausibel
local AUDIO = { "audio/de/", "audio/en/" }   -- je Sprache derselbe Dateiname
local MAX_SCHLEPPS = 20

local floor, abs, max, min = math.floor, math.abs, math.max, math.min
local studioNeu
local NAME_LOG = "Gas Engine Carb"

local function lade(datei)
  local f, e = loadfile(datei)
  if not f then error(e, 0) end
  return f()
end

local function clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

-- Zahl prüfen: nil bei nil, Text, NaN, unendlich oder unplausibel gross.
local function gut(v)
  if type(v) ~= "number" or v ~= v or v > GROSS or v < -GROSS then return nil end
  return v
end

-- Wert einer Quelle als Zahl, sonst nil. Fehler der Quelle werden geschluckt.
local function zahl(q, opt)
  if q == nil then return nil end
  local ok, v
  -- Optionen (Zellenzahl, einzelne Zelle) nur als Tabelle: q:value(OPTION_…) liefert die Gesamtspannung
  -- (gemessen, Simulator 26.1.2), q:value({ options = OPTION_… }) den gewünschten Wert.
  if opt ~= nil then ok, v = pcall(q.value, q, { options = opt }) else ok, v = pcall(q.value, q) end
  if not ok then return nil end
  return gut(v)
end

-- Rohwert einer Quelle (Zahl oder Text), nil ohne Quelle oder bei Fehler.
local function roh(q)
  if q == nil then return nil end
  local ok, v = pcall(q.value, q)
  if not ok then return nil end
  if type(v) == "string" then return v end
  return gut(v)
end

-- Fehler der Stromweiche aus Empfänger- und Kanalzustand. Text: alles ausser «OK» ist ein Fehler, nur einzelne
-- verlorene Pakete («Lost Frame») sind normal. Zahl (Rückfall, 32 Bit nach EdgeTX): unten Kanäle, oben Empfänger
-- (Bit 4, 6, 12 = Lost Frame, ohne Alarm).
local function rbFehler(st, ch)
  local f = false
  if type(st) == "string" then
    for t in st:gmatch("[^+]+") do
      local teil = t:gsub("^%s+", ""):gsub("%s+$", "")
      if teil ~= "" and teil:upper() ~= "OK" and not teil:find("Lost Frame") then f = true end
    end
  elseif type(st) == "number" and st > 0 and st < 4294967296 then
    local kan, rx = floor(st) % 65536, floor(st / 65536) % 65536
    for n = 0, 14 do
      if floor(rx / 2 ^ n) % 2 == 1 and n ~= 4 and n ~= 6 and n ~= 12 then f = true end
    end
    if kan ~= 0 then f = true end
  end
  if type(ch) == "string" then
    if ch:find("KO") then f = true end
  elseif type(ch) == "number" and ch > 0 and floor(ch) % 65536 ~= 0 then
    f = true
  end
  return f
end

local function bereich(q)
  local ok1, lo = pcall(q.minimum, q)
  local ok2, hi = pcall(q.maximum, q)
  lo, hi = ok1 and gut(lo), ok2 and gut(hi)
  if lo and hi and hi > lo then return lo, hi end
  return nil
end

-- Stellung einer Quelle in Prozent ihres Bereichs (Kanal, Geber).
local function prozent(q)
  local v = zahl(q)
  if v == nil then return nil end
  local lo, hi = bereich(q)
  if lo == nil then return nil end
  return clamp((v - lo) / (hi - lo) * 100, 0, 100)
end

-- Schalterartige Quelle: aktiv = über der Mitte ihres Bereichs. nil = keine Quelle.
local function aktiv(q, umkehren)
  local v = zahl(q)
  if v == nil then return nil end
  local lo, hi = bereich(q)
  local a = v > (lo and (lo + hi) / 2 or 0)
  if umkehren then a = not a end
  return a
end

-- Stellung eines 3-Stufen-Schalters: 1 oben, 2 Mitte, 3 unten. Ethos: oben = Minimum (gemessen, Simulator 26.1.2).
local function stellung(q)
  local v = zahl(q)
  if v == nil then return nil end
  local lo, hi = bereich(q)
  if lo == nil then lo, hi = -100, 100 end
  local d = (hi - lo) / 3
  if v < lo + d then return 1 end
  if v > hi - d then return 3 end
  return 2
end

local function einheit(q)
  if q == nil then return "" end
  local ok, e = pcall(q.stringUnit, q)
  if ok and type(e) == "string" then return e end
  return ""
end

local function stellen(q, sonst)
  if q == nil then return sonst end
  local ok, d = pcall(q.decimals, q)
  if ok and type(d) == "number" and d >= 0 and d <= 3 then return floor(d) end
  return sonst
end

-- Ansagen, die mitgeliefert sind. Fehlt die Datei einer Rolle, kommt die allgemeine Ansage «Akku n».
local WAV_DA = { empf1 = true, empf2 = true, empf3 = true, zuend = true, anlass = true, ecuakku = true,
  akku1 = true, akku2 = true, akku3 = true }
local ROLLE_NAME = { "EMPFÄNGER", "ZÜNDUNG", "ANLASSER", "ECU-AKKU" }
local ROLLE_WAV = { "empf", "zuend", "anlass", "ecuakku" }

-- Name und Ansage je Akku aus der Rolle im Menü. Gibt es eine Rolle mehrfach, bekommt sie eine Nummer.
-- Übernimmt einen Zündakku aus früheren Fassungen (eigenes Feld) einmalig in den ersten freien Akku.
local function akkuRollen(w)
  local c, g = w.cfg, w.g
  if c.zuendAkku ~= nil then
    for i = 1, 3 do
      if c["lipo" .. i] == nil then
        c["lipo" .. i], c["a" .. i .. "Rolle"], c.zuendAkku = c.zuendAkku, 2, nil
        w.dateiOffen = true
        break
      end
    end
  end
  local anz, nr = {}, {}
  for i = 1, 3 do
    local r = c["a" .. i .. "Rolle"]
    if r ~= 1 and r ~= 2 and r ~= 3 and r ~= 4 and r ~= 5 then r = 5 end
    nr[i] = r
    if c["lipo" .. i] ~= nil then anz[r] = (anz[r] or 0) + 1 end
  end
  g.aName, g.aWav, g.aS = {}, {}, {}
  local zaehl = {}
  for i = 1, 3 do
    local r = nr[i]
    if c["lipo" .. i] ~= nil then zaehl[r] = (zaehl[r] or 0) + 1 end   -- nur Akkus mit Sensor zählen
    local k = max(1, zaehl[r] or 1)
    local name, wav
    if r == 5 then
      name, wav = "AKKU " .. i, "akku" .. i
    else
      name = ROLLE_NAME[r] .. (((anz[r] or 0) > 1) and (" " .. k) or "")
      wav = ROLLE_WAV[r] .. ((r == 1) and tostring(k) or "")
    end
    if not WAV_DA[wav] then wav = "akku" .. i end
    g.aName[i], g.aWav[i] = name, wav
    local n = c["a" .. i .. "S"]
    g.aS[i] = (type(n) == "number" and n >= 1 and n <= 6) and floor(n) or 0
  end
end

-- Grenzwerte aus den Einstellungen als Zahlen; nil = nicht gesetzt (Warnung aus).
local function grenzen(w)
  local c, g = w.cfg, w.g
  local function gz(k, teiler)
    local x = gut(c[k])
    if x and x > 0 then return x / (teiler or 1) end
    return nil
  end
  g.laeuftAb = gz("laeuftAb") or 0
  g.chtKalt, g.chtWarn, g.chtAlarm, g.chtDiff = gz("chtKalt"), gz("chtWarn"), gz("chtAlarm"), gz("chtDiff")
  g.rpmWarn, g.rpmAlarm = gz("rpmWarn"), gz("rpmAlarm")
  g.druckVon, g.druckBis, g.druckAlarm = gz("druckVon", 10), gz("druckBis", 10), gz("druckAlarm", 10)
  g.ecuWarn, g.ecuAlarm = gz("ecuWarn", 10), gz("ecuAlarm", 10)
  g.chokeTemp, g.chokeGas = gz("chokeTemp"), gz("chokeGas")
  g.chtVon = gut(c.chtVon) or 0
  g.chtBis = gz("chtBis") or 250
  if g.chtBis <= g.chtVon then g.chtBis = g.chtVon + 10 end
  g.rpmSkala = gz("rpmSkala") or 9000
  g.druckSkala = gz("druckSkala", 10) or 5
  g.mlImp = gz("mlImp", 1000) or 0.1
  g.tank, g.tankRes, g.tankLeer, g.tankMin = gz("tank"), gz("tankRes"), gz("tankLeer"), gz("tankMin")
  g.zWarn = { gz("z1Warn", 100), gz("z2Warn", 100), gz("z3Warn", 100) }
  g.zAlarm = { gz("z1Alarm", 100), gz("z2Alarm", 100), gz("z3Alarm", 100) }
  g.zDiff = gz("zDiff", 100)
  akkuRollen(w)
  g.zLeer = (gut(c.zLeer) or 300) / 100
  g.zVoll = (gut(c.zVoll) or 420) / 100
  if g.zVoll <= g.zLeer then g.zVoll = g.zLeer + 0.1 end
  -- Skala der Zellenbalken je Akku: LiPo nach Menü (zLeer/zVoll), LiFe und NiMH fest nach Art
  local SKALA = { nil, { 2.80, 3.60 }, { 1.00, 1.45 } }
  g.zLeerA, g.zVollA = g.zLeerA or {}, g.zVollA or {}
  for i = 1, 3 do
    local sk = SKALA[c["a" .. i .. "Typ"]]
    g.zLeerA[i], g.zVollA[i] = sk and sk[1] or g.zLeer, sk and sk[2] or g.zVoll
  end
  g.kWarn, g.kAlarm = gz("kWarn", 10), gz("kAlarm", 10)
  g.rssiWarn, g.rssiAlarm = gz("rssiWarn"), gz("rssiAlarm")
  g.pause = gut(c.pause) or 30
  g.sperre = gut(c.sperre) or 0
  g.swAus = c.swAus or 1
  g.swChoke = c.swChoke or 3
end
K.grenzen = grenzen

function K.neu()
  local F = lade("felder.lua")
  local w = {
    cfg = F.standard(), g = {}, v = {}, eh = {}, dz = {}, hoch = {},
    meld = {}, aktiv = {}, nAktiv = 0, stufe = 0, zustand = "KEINE DATEN", meldText = "",
    seite = 1, kopfText = {}, kopfN = 0, ziele = {},
    tk = { verbr = 0, pt = {}, pv = {}, pn = 0 },
    akku = { {}, {}, {} },
    rb = { k = {}, spitze = 0 },
    tr = { {}, {}, {}, {} }, trN = 0,
    lauf = false, laufSumme = 0, gelesen = false, autoOffen = true, version = K.VERSION,
    ue = {},                -- Übersicht seit dem letzten Zurücksetzen (dauerhaft)
    schlepps = {},          -- abgeschlossene Flüge { ml, h, steig } (dauerhaft, höchstens MAX_SCHLEPPS)
    sl = nil,               -- laufender oder pausierter Flug { ml, h, steig, pause } (dauerhaft)
    nSchlepp = 0,           -- Nummer des letzten abgeschlossenen Flugs
  }
  grenzen(w)
  if CATEGORY_SYSTEM_EVENT and SYSTEM_EVENT_TELEMETRY_ACTIVE then
    local ok, q = pcall(system.getSource, { category = CATEGORY_SYSTEM_EVENT, member = SYSTEM_EVENT_TELEMETRY_ACTIVE })
    if ok then w.qTele = q end
  end
  w.studioZ = w.studioZ or { art = "start" }   -- neues Widget ohne gespeicherten Stand: Ethos ruft kein read
  return w
end

-- Läuft die Telemetrie? Ohne Auskunft von Ethos gilt sie als vorhanden.
local function telemetrie(w)
  local q = w.qTele
  if q == nil then return true end
  local ok, v = pcall(q.value, q)
  if not ok then return true end
  if type(v) == "number" then return v > 0 end
  if type(v) == "boolean" then return v end
  return true
end

local function hinweis(w, text, now)
  w.hinweis = text
  w.hinweisBis = now + 3
end

local function spiele(w, name)
  if w.cfg.ansage and not w.v.stumm and system.playFile then pcall(system.playFile, AUDIO[w.sp or 1] .. name .. ".wav") end
end

-- Sprache aus dem Menü (0 = wie Sender: deutsch nur bei einem deutschen Sender). Lädt bei Englisch die Übersetzung.
local function sprache(w)
  local sp = w.cfg.sprache
  if sp ~= 1 and sp ~= 2 then
    sp = 2
    if system.getLocale then
      local ok, l = pcall(system.getLocale)
      if ok and type(l) == "string" and l:sub(1, 2):lower() == "de" then sp = 1 end
    end
  end
  if w.sp ~= sp then
    w.sp = sp
    w.uebers = nil
    collectgarbage()
    if sp == 2 then w.uebers = lade("texte.lua") end
  end
end
K.sprache = sprache

-- Dauerhafte Werte (Tankstand, Einstellungen) in die Datei: vormerken, wecke() schreibt gebündelt.
local function sichern(w)
  w.dateiOffen = true
end

local function hoeher(t, k, x) if x and (t[k] == nil or x > t[k]) then t[k] = x end end
local function tiefer(t, k, x) if x and (t[k] == nil or x < t[k]) then t[k] = x end end
-- Tiefste Zelle nur aus glaubhaften Werten: unter 0,5 V liefert ein Sensor beim Einschalten oder Umstecken
-- Unsinn (gemessen 0,02 V). 0,5 V statt 1 V, damit eine tief entladene NiMH-Zelle (um 0,9 V) noch zählt.
local function zelle(a) local z = a.tief; if z and z >= 0.5 then return z end end

-- Höchst- und Tiefstwerte der Übersicht (nur bei aktiver Telemetrie, nur glaubhafte Werte).
local function uebersicht(w, dt)
  local v, ue, sl = w.v, w.ue, w.sl
  if not v.tele then return end
  hoeher(ue, "hMax", v.hoehe)
  if v.vario and v.vario > -100 and v.vario < 100 then
    hoeher(ue, "steigMax", v.vario)
    tiefer(ue, "sinkMax", v.vario)
  end
  for i = 1, 4 do hoeher(ue, "chtMax", v["cht" .. i]) end
  hoeher(ue, "rpmMax", v.rpm)
  hoeher(ue, "flussMax", w.tk.fluss)
  if v.ecuV and v.ecuV > 0 then tiefer(ue, "ecuMin", v.ecuV) end
  for i = 1, 3 do tiefer(ue, "zelleMin", zelle(w.akku[i])) end
  if w.lauf then ue.laufS = (ue.laufS or 0) + dt end
  if sl and not sl.pause then                          -- dieselben Eckwerte nur für den laufenden Flug
    hoeher(sl, "h", v.hoehe)
    if v.vario and v.vario > -100 and v.vario < 100 then
      hoeher(sl, "steig", v.vario)
      tiefer(sl, "sink", v.vario)
    end
    hoeher(sl, "fl", w.tk.fluss)
    for i = 1, 4 do hoeher(sl, "cht", v["cht" .. i]) end
    hoeher(sl, "rpm", v.rpm)
    if v.ecuV and v.ecuV > 0 then tiefer(sl, "ecu", v.ecuV) end
    for i = 1, 3 do tiefer(sl, "zel", zelle(w.akku[i])) end
    if w.lauf then sl.t = min((sl.t or 0) + dt, 1e6) end  -- Motorlaufzeit, nur für den mittleren Durchfluss
  end
end

-- Motorschalter: Aus → Ein beginnt einen Flug (oder setzt einen pausierten fort); Ein → Aus fragt «Flug beendet?».
local function schlepp(w, now)
  local v = w.v
  if v.sw == nil then return end
  local aus = v.zuend == false
  local war = w.swAusAlt
  w.swAusAlt = aus
  if war == nil then return end                       -- erster Durchlauf: nur merken
  if war and not aus then
    if w.dialog == "schlepp" then w.dialog = nil end  -- unbeantwortet wieder eingeschaltet = nur Pause
    if w.sl and w.sl.pause then
      w.sl.pause = false
      spiele(w, "flug_weiter")
    elseif not w.sl then
      w.sl = { ml = 0 }
    end
    w.dateiOffen = true
  elseif aus and not war and w.sl and not w.sl.pause then
    w.sl.pause = true                                  -- bis zur Antwort zählt nichts weiter
    w.dialog = "schlepp"
    w.dateiOffen = true
  end
end

local function schleppEnde(w, ja)
  local sl = w.sl
  if not sl then return end
  if ja then
    w.nSchlepp = w.nSchlepp + 1
    local s = w.schlepps
    local neu = { nr = w.nSchlepp }
    for k, x in pairs(sl) do if k ~= "pause" then neu[k] = x end end
    neu.ml = sl.ml or 0
    s[#s + 1] = neu
    while #s > MAX_SCHLEPPS do table.remove(s, 1) end
    w.sl = nil
    spiele(w, "flug_beendet")
    if w.cfg.ansage and w.cfg.zahl and not w.v.stumm and system.playNumber then
      pcall(system.playNumber, floor((sl.ml or 0) + 0.5), UNIT_MILLILITER, 0)
    end
  else
    sl.pause = true
    spiele(w, "flug_pause")
  end
  w.dateiOffen, w.dateiJetzt = true, true
end

-- «JA, ZURÜCKSETZEN»: löscht Übersicht und Flugliste. Der Tank bleibt unverändert.
local function uebersichtZurueck(w, now)
  w.ue, w.schlepps, w.nSchlepp = {}, {}, 0
  if w.sl then w.sl = { ml = 0, pause = w.sl.pause } end
  hinweis(w, "Übersicht zurückgesetzt", now)
  spiele(w, "uebersicht_geloescht")
  w.dateiOffen, w.dateiJetzt = true, true
end

-- «JA, VOLLGETANKT»: einzige Stelle, an der der Tank zurückgesetzt wird.
local function vollgetankt(w, now)
  local tk = w.tk
  tk.verbr, tk.pn, tk.restMin, tk.flussRing = 0, 0, nil, nil
  hinweis(w, "Tank auf voll gesetzt", now)
  spiele(w, "tank_voll")
  sichern(w)
  w.dateiJetzt = true
end

-- Motorwerte (10-mal pro Sekunde).
local function liesSchnell(w, now, dt)
  local c, v, g, h = w.cfg, w.v, w.g, w.hoch
  v.tele = telemetrie(w)
  if v.tele then w.teleWar = true end
  -- Zylinder: nur so viele, wie im Menü eingestellt (1 bis 4)
  local nz = c.zylAnz
  if nz ~= 1 and nz ~= 3 and nz ~= 4 then nz = 2 end
  w.nZyl = nz
  for i = 1, 4 do v["cht" .. i] = (i <= nz) and zahl(c["cht" .. i]) or nil end
  v.rpm = zahl(c.rpm)
  if v.rpm and v.rpm < 0 then v.rpm = 0 end
  v.gas = prozent(c.gas)
  local st = stellung(c.motorSw)
  v.sw = st
  if st == nil then
    v.zuend, v.choke = nil, nil
  else
    v.zuend = st ~= g.swAus
    v.choke = st == g.swChoke and st ~= g.swAus
  end
  v.hoehe, v.vario, v.speed, v.rssi = zahl(c.hoehe), zahl(c.vario), zahl(c.speed), zahl(c.rssi)

  if v.tele then
    for _, k in ipairs({ "cht1", "cht2", "cht3", "cht4", "rpm", "hoehe" }) do
      local x = v[k]
      if x and (h[k] == nil or x > h[k]) then h[k] = x end
    end
  end

  -- Motor läuft?
  local laeuft = v.tele and v.rpm ~= nil and v.rpm > g.laeuftAb
  if laeuft and not w.lauf then
    w.laufSeit = now
    w.motorAus = false
  elseif w.lauf and not laeuft then
    -- Motor steht, obwohl der Schalter auf Ein steht: Alarm (erst nach der Startsperre)
    if v.tele and v.zuend == true and (now - w.laufSeit) >= g.sperre then w.motorAus = true end
    sichern(w)
  end
  w.lauf = laeuft
  if laeuft then w.laufSumme = w.laufSumme + dt end
  if w.motorAus and (laeuft or v.zuend ~= true) then w.motorAus = false end
end

-- Akku lesen. S = Zellenzahl aus dem Menü (0 = automatisch). Ein echter Zellensensor (FLVS) liefert die Zellen
-- einzeln; ein reiner Spannungssensor nur die Gesamtspannung: mit S gibt das den Mittelwert je Zelle.
local function liesAkku(a, q, S)
  a.da = q ~= nil
  a.n, a.summe, a.tief, a.iTief, a.diff, a.mittel = 0, nil, nil, nil, nil, nil
  for k = 1, 8 do a[k] = nil end
  if q == nil then return end
  a.summe = zahl(q)
  local function nurSumme()
    if S and S > 0 and a.summe and a.summe > 0 then
      a.mittel = a.summe / S
      a.tief = a.mittel
    end
  end
  if OPTION_CELL_COUNT == nil or OPTION_CELL_INDEX == nil then return nurSumme() end
  local n = zahl(q, OPTION_CELL_COUNT)
  -- Nur ein echter Zellensensor (FLVS) hat eine ganze Zellenzahl und Zellen bis 5 V. Ein reiner Spannungssensor
  -- liefert auf jede Abfrage die Gesamtspannung: dann ohne Zellen anzeigen.
  if n == nil or n < 1 or n ~= floor(n) or n > 8 then return nurSumme() end
  local m = (S and S > 0) and min(n, S) or n
  local lo, hi
  for i = 1, m do
    local ok, opt = pcall(OPTION_CELL_INDEX, i)
    local z = ok and zahl(q, opt) or nil
    if z and z > 5 then
      for k = 1, i - 1 do a[k] = nil end
      a.iTief = nil
      return nurSumme()
    end
    if z and z < 0 then z = nil end
    a[i] = z
    if z then
      if lo == nil or z < lo then lo, a.iTief = z, i end
      if hi == nil or z > hi then hi = z end
    end
  end
  a.n, a.tief = (S and S > 0) and S or n, lo
  if lo then a.diff = hi - lo end
end

local RBK = { "rbK1", "rbK2", "rbK3", "rbK4", "rbK5", "rbK6", "rbK7", "rbK8" }

-- Elektrik (2-mal pro Sekunde, auch wenn eine andere Seite sichtbar ist: die Warnungen brauchen die Werte).
local function liesLangsam(w)
  local c, v, rb = w.cfg, w.v, w.rb
  local aS = w.g.aS or {}
  for i = 1, 3 do liesAkku(w.akku[i], c["lipo" .. i], aS[i]) end
  v.rxBatt = zahl(c.rxBatt)
  v.zuendAkku = zahl(c.zuendAkku)   -- nur noch, wenn ein alter Zündakku keinen freien Akku fand
  v.bat1V, v.bat1A, v.bat2V, v.bat2A = zahl(c.bat1V), zahl(c.bat1A), zahl(c.bat2V), zahl(c.bat2A)
  -- Zustand der Stromweiche: Ethos 26.2 liefert Text («OK», «RX1 Failsafe+RX1 Lost Frame», «+K3 KO»), ältere
  -- Fassungen eventuell eine Zahl; beides wird in rbFehler() ausgewertet
  v.rbState, v.rbCh = roh(c.rbState), roh(c.rbChState)
  rb.max = nil
  for i = 1, 8 do
    local x = zahl(c[RBK[i]])
    rb.k[i] = x
    if x then
      if rb.max == nil or x > rb.max then rb.max = x end
      if x > rb.spitze then rb.spitze = x end
    end
  end
  v.rx1R24, v.rx1R900, v.rx1Vfr = zahl(c.rx1R24), zahl(c.rx1R900), zahl(c.rx1Vfr)
  v.rx2R24, v.rx2R900, v.rx2Vfr = zahl(c.rx2R24), zahl(c.rx2R900), zahl(c.rx2Vfr)
  v.winde = aktiv(c.winde, c.windeInv)
  v.bremse = aktiv(c.bremse, c.bremseInv)
  local stumm = aktiv(c.stumm) == true
  if w.stummAlt ~= nil and stumm ~= w.stummAlt and c.ansage and system.playFile then
    pcall(system.playFile, AUDIO[w.sp or 1] .. (stumm and "ansagen_aus" or "ansagen_ein") .. ".wav")
  end
  w.stummAlt, v.stumm = stumm, stumm
end

-- Einheiten und Kommastellen der Sensoren (alle 2 s).
local function liesEinheiten(w)
  local c, eh, dz = w.cfg, w.eh, w.dz
  eh.druck, eh.hoehe, eh.vario, eh.speed, eh.rssi = einheit(c.druck), einheit(c.hoehe), einheit(c.vario),
    einheit(c.speed), einheit(c.rssi)
  dz.druck, dz.ecuV, dz.vario = stellen(c.druck, 1), stellen(c.ecuV, 1), stellen(c.vario, 1)
end

-- Trend der Zylindertemperaturen über 10 s: +1 steigt, -1 fällt, 0 gleich (kein Pfeil).
local function trend(w)
  local v = w.v
  local n = w.trN % 6 + 1
  w.trN = w.trN + 1
  for i = 1, 4 do
    local r, x = w.tr[i], v["cht" .. i]
    local alt = r[n]
    r[n] = x
    local t = 0
    if x and alt then
      if x - alt > TREND_BAND then t = 1 elseif alt - x > TREND_BAND then t = -1 end
    end
    v["trend" .. i] = t
  end
end

-- Tank: Verbrauch aus den Zuwächsen des Impulszählers (Hauptquelle), sonst aus dem Durchfluss.
-- Der Tankstand ändert sich nur durch Verbrauch und durch «JA, VOLLGETANKT».
local function kraftstoff(w, now, dt)
  local c, g, v, tk = w.cfg, w.g, w.v, w.tk
  local zu = nil                      -- Verbrauch seit der letzten Lesung in ml
  local imp = v.tele and zahl(c.impulse) or nil
  if imp and imp >= 0 then
    imp = floor(imp)
    if tk.impAlt ~= nil then
      local d = imp - tk.impAlt
      if d < 0 then d = imp end       -- Zähler zurückgesprungen: Sensor neu gestartet
      zu = d * g.mlImp
      if zu > MAX_SCHRITT_ML then zu = 0 end   -- unglaubhafter Sprung: nicht zählen
    end
    tk.impAlt = imp
    tk.quelle = "imp"
  else
    if c.impulse == nil then tk.impAlt = nil end
    local f = v.tele and zahl(c.fluss) or nil
    if f and f > 0 and f < 10000 then zu = f * dt / 60 end
    tk.quelle = f and "fluss" or nil
  end
  if zu and zu > 0 then
    tk.verbr = min(tk.verbr + zu, 1e6)
    w.ue.verbr = min((w.ue.verbr or 0) + zu, 1e7)
    if w.sl and not w.sl.pause then w.sl.ml = min((w.sl.ml or 0) + zu, 1e6) end
  end
  local fs = zahl(c.fluss)
  tk.flussSensor = (fs and fs >= 0 and fs < 10000) and fs or nil
  tk.rest = g.tank and max(0, g.tank - tk.verbr) or nil
  tk.proz = (tk.rest and g.tank) and clamp(tk.rest / g.tank * 100, 0, 100) or nil

  -- Messpunkte alle 5 s, höchstens 13 (= 60 s)
  if tk.pn == 0 or now - tk.pt[tk.pn] >= RING_DT then
    if tk.pn == 13 then
      for i = 1, 12 do tk.pt[i], tk.pv[i] = tk.pt[i + 1], tk.pv[i + 1] end
      tk.pn = 12
    end
    tk.pn = tk.pn + 1
    tk.pt[tk.pn], tk.pv[tk.pn] = now, tk.verbr
    local spanne = now - tk.pt[1]
    tk.mittel = (spanne >= 20) and max(0, (tk.verbr - tk.pv[1]) / spanne * 60) or nil
    if tk.pn >= 3 then
      local i = tk.pn - 2
      local s = now - tk.pt[i]
      tk.flussRing = (s > 0) and max(0, (tk.verbr - tk.pv[i]) / s * 60) or nil
    end
    -- Restzeit erst nach 30 s Motorlauf
    tk.restMin = nil
    if w.lauf and (now - w.laufSeit) >= RESTZEIT_AB and tk.rest and tk.mittel and tk.mittel > 0.5 then
      tk.restMin = min(tk.rest / tk.mittel, 999)
    end
    -- Verbrauch sichern, solange er sich ändert (höchstens einmal pro Minute)
    if abs(tk.verbr - (tk.gesichert or 0)) >= 1 and now - (tk.tSicher or -100) >= 60 then
      tk.gesichert, tk.tSicher = tk.verbr, now
      sichern(w)
    end
  end
  if not w.lauf then tk.restMin = nil end       -- Restzeit nur bei laufendem Motor (Entscheid User 21.11.2026)
  tk.fluss = tk.flussSensor or tk.flussRing
end

-- Eine Warnung führen: kommt nach AN_S, geht nach AUS_S (so flattert sie an der Grenze nicht).
-- zahl/einheit/dez: Wert, den Ethos nach dem Text ansagt.
local function melde(w, now, name, stufe, bed, text, wav, wert, einh, dez)
  local m = w.meld[name]
  if m == nil then
    m = { an = false, text = text, name = name }
    w.meld[name] = m
  end
  if bed then
    m.weg = nil
    if not m.an then
      m.seit = m.seit or now
      if now - m.seit >= AN_S then
        m.an = true
        m.tAns = nil
      end
    end
  else
    m.seit = nil
    if m.an then
      m.weg = m.weg or now
      if now - m.weg >= AUS_S then m.an = false end
    end
  end
  if m.an then
    m.stufe, m.wav, m.wert, m.einh, m.dez = stufe, wav, wert, einh, dez
    w.nAktiv = w.nAktiv + 1
    w.aktiv[w.nAktiv] = m
  end
  return m.an
end


-- «Alarm auch bei Motor aus» (Lua-Studio-Format 2 §3.5): Meldung -> Haken in felder.lua. Nicht in der Liste
-- (MOTOR AUS, STROMWEICHE FEHLER, TELEMETRIE WEG, CHOKE AUS!, Spritdruck und ECU-Spannung: im Vergaser ohne
-- eigenes Menüfeld) kommt immer.
local MA = { zDiff = "maChtDiff", rpmA = "maRpm", rpmW = "maRpm", tankRes = "maTankProz", zd1 = "maAkkuDiff", zd2 = "maAkkuDiff", zd3 = "maAkkuDiff", kA = "maKanal",
  kW = "maKanal", rxA1 = "maRssi", rxW1 = "maRssi", rxA2 = "maRssi", rxW2 = "maRssi" }
for i = 1, 4 do MA["zA" .. i], MA["zW" .. i] = "maChtMax", "maChtMax" end
for i = 1, 3 do MA["za" .. i], MA["zw" .. i] = "maAkku" .. i, "maAkku" .. i end

-- Schweigt diese Meldung (nur Ton, Ansage, Vibration; die Anzeige bleibt)? Nur bei Motorschalter auf Aus und Haken aus.
local function still(w, m)
  if w.v.zuend ~= false then return false end
  local c = w.cfg
  if m.name == "tankLeer" then     -- zwei Grenzen auf einer Meldung: still nur, wenn jede auslösende Grenze still ist
    return (not w.leerP or c.maTankProz == false) and (not w.leerR or c.maRestzeit == false)
  end
  if m.gr then return m.gr.beiMotorAus == false end
  local f = MA[m.name]
  return f ~= nil and c[f] == false
end
K.still = still

local function warnungen(w, now)
  local v, g, tk = w.v, w.g, w.tk
  w.nAktiv = 0
  local d = v.tele
  local frei = w.lauf and (now - w.laufSeit) >= g.sperre       -- Motor läuft, Startsperre nach dem Anlassen vorbei
  -- Startsperre nur ab dem Anlassen; bei stehendem Motor (auch nach dem Abstellen, Kill über den Motorschalter) gilt sie nicht
  local start = w.lauf and (now - w.laufSeit) < g.sperre
  local GC, VO, PR = UNIT_CELSIUS, UNIT_VOLT, UNIT_PERCENT

  -- Zylinder 1..4: Alarm/Warnung je Zylinder, Unterschied = heissester minus kältester
  local tMin, tMax
  for i = 1, 4 do
    local x = v["cht" .. i]
    local a = d and g.chtAlarm and x and x >= g.chtAlarm
    melde(w, now, "zA" .. i, 2, a, "ZYL " .. i .. " HEISS", "zyl" .. i .. "_alarm", x, GC, 0)
    melde(w, now, "zW" .. i, 1, d and not a and g.chtWarn and x and x >= g.chtWarn, "ZYL " .. i .. " WARM", "zyl" .. i .. "_heiss",
      x, GC, 0)
    if x then
      if tMin == nil or x < tMin then tMin = x end
      if tMax == nil or x > tMax then tMax = x end
    end
  end
  local diff = (tMin and tMax and w.nZyl > 1) and (tMax - tMin) or nil
  v.chtDiff = diff
  v.diffWarn = melde(w, now, "zDiff", 1, d and not start and g.chtDiff and diff and diff >= g.chtDiff,
    "ZYL UNGLEICH", "zyl_ungleich", diff, GC, 0)
  local ra = d and g.rpmAlarm and v.rpm and v.rpm >= g.rpmAlarm
  melde(w, now, "rpmA", 2, ra, "DREHZAHL HOCH", "drehzahl_hoch")
  melde(w, now, "rpmW", 1, d and not ra and g.rpmWarn and v.rpm and v.rpm >= g.rpmWarn, "DREHZAHL HOCH", "drehzahl_hoch")
  -- Spritdruck nur bei laufendem Motor (bei stehendem Motor ist er fachlich tief; Entscheid User 21.11.2026)
  local da = d and frei and g.druckAlarm and v.druck and v.druck < g.druckAlarm
  melde(w, now, "druckA", 2, da, "SPRITDRUCK TIEF", "spritdruck_alarm")
  melde(w, now, "druckW", 1, d and frei and not da and g.druckVon and v.druck and v.druck < g.druckVon,
    "SPRITDRUCK TIEF", "spritdruck_tief")
  w.leerP = (g.tankLeer and tk.proz and tk.proz < g.tankLeer) or false
  w.leerR = (g.tankMin and w.lauf and tk.restMin and tk.restMin < g.tankMin) or false
  local leer = w.leerP or w.leerR
  melde(w, now, "tankLeer", 2, leer, "TANK FAST LEER", "tank_leer", tk.proz, PR, 0)
  melde(w, now, "tankRes", 1, not leer and g.tankRes and tk.proz and tk.proz < g.tankRes, "TANK RESERVE", "tank_reserve",
    tk.proz, PR, 0)
  local ea = d and g.ecuAlarm and v.ecuV and v.ecuV < g.ecuAlarm
  melde(w, now, "ecuA", 2, ea, "ECU-SPANNUNG TIEF", "ecu_alarm", v.ecuV, VO, 1)
  melde(w, now, "ecuW", 1, d and not ea and g.ecuWarn and v.ecuV and v.ecuV < g.ecuWarn, "ECU-SPANNUNG TIEF", "ecu_tief",
    v.ecuV, VO, 1)
  melde(w, now, "motorAus", 2, w.motorAus, "MOTOR AUS", "motor_aus")
  melde(w, now, "tele", 1, w.teleWar and not d, "TELEMETRIE WEG", "telemetrie_weg")
  local warm = g.chokeTemp and tMin and tMin >= g.chokeTemp            -- alle vorhandenen Zylinder warm
  local gasHoch = g.chokeGas and v.gas and v.gas >= g.chokeGas
  w.chokeWarn = melde(w, now, "choke", 1, d and v.choke == true and w.lauf and (warm or gasHoch), "CHOKE AUS!", "choke_aus")
  for i = 1, 3 do
    local a = w.akku[i]
    local nm, wv = g.aName and g.aName[i] or ("AKKU " .. i), g.aWav and g.aWav[i] or ("akku" .. i)
    local al = d and g.zAlarm[i] and a.tief and a.tief < g.zAlarm[i]
    a.alarm = melde(w, now, "za" .. i, 2, al, nm .. " TIEF", wv .. "_alarm", a.tief, VO, 2)
    a.warn = melde(w, now, "zw" .. i, 1, d and not al and g.zWarn[i] and a.tief and a.tief < g.zWarn[i],
      nm .. " TIEF", wv .. "_tief", a.tief, VO, 2)
    a.warnDiff = melde(w, now, "zd" .. i, 1, d and g.zDiff and a.diff and a.diff >= g.zDiff,
      nm .. " ZELLEN UNGLEICH", wv .. "_ungleich")
  end
  local rb = w.rb
  local ka = d and g.kAlarm and rb.max and rb.max > g.kAlarm
  melde(w, now, "kA", 2, ka, "SERVOSTROM HOCH", "servostrom_hoch")
  melde(w, now, "kW", 1, d and not ka and g.kWarn and rb.max and rb.max > g.kWarn, "SERVOSTROM HOCH", "servostrom_hoch")
  w.rbFehler = d and rbFehler(v.rbState, v.rbCh) or false
  melde(w, now, "rbF", 2, w.rbFehler, "STROMWEICHE FEHLER", "rb_fehler")
  for i = 1, 2 do
    local r24, r900 = v["rx" .. i .. "R24"], v["rx" .. i .. "R900"]
    local r = r24
    if r900 and (r == nil or r900 < r) then r = r900 end
    local al = d and g.rssiAlarm and r and r < g.rssiAlarm
    melde(w, now, "rxA" .. i, 2, al, "RX" .. i .. " SCHWACH", "rx" .. i .. "_schwach")
    melde(w, now, "rxW" .. i, 1, d and not al and g.rssiWarn and r and r < g.rssiWarn, "RX" .. i .. " SCHWACH",
      "rx" .. i .. "_schwach")
  end

  -- Ist der Alarm eines Werts an, fällt dessen Warnung weg (sonst stünde «ZYL 2 HEISS» und «ZYL 2 WARM» zugleich da)
  local PAAR = { zW1 = "zA1", zW2 = "zA2", zW3 = "zA3", zW4 = "zA4", rpmW = "rpmA", druckW = "druckA", ecuW = "ecuA", zw1 = "za1", zw2 = "za2",
    zw3 = "za3", kW = "kA", rxW1 = "rxA1", rxW2 = "rxA2", tankRes = "tankLeer" }
  local n = 0
  for i = 1, w.nAktiv do
    local m = w.aktiv[i]
    local alarm = m.name and PAAR[m.name] and w.meld[PAAR[m.name]]
    if not (alarm and alarm.an) then
      n = n + 1
      w.aktiv[n] = m
    end
  end
  w.nAktiv = n

  -- Telemetrie wieder da: einmal ansagen
  local tm = w.meld.tele
  if tm and tm.an and not d then w.teleWeg = true end
  if w.teleWeg and d then
    w.teleWeg = false
    spiele(w, "telemetrie_da")
  end

  -- höchste Stufe und Text der Meldezeile (Alarme zuerst)
  -- Grenzen aus dem Studio auf Sensoren und Kanäle (Lua-Werte laufen über die Einstellungen oben)
  local stu = w.studio
  if stu and stu.st and d then
    for k, gr in pairs(stu.st.gr) do
      local q = stu.q[k]
      if q and not k:find("^lua:") then
        local ok, x = pcall(q.value, q)
        if ok and type(x) == "number" and x == x then
          if k:find("^kanal:") then x = x / 10.24 end
          local a = stu.st.werte[k]
          if a then x = x * a.faktor + a.versatz end
          local function ueber(gw) if gw == nil then return false end if gr.richtung == "unter" then return x < gw end return x >= gw end
          local name = (a and a.name) or (stu.namen and stu.namen[k]) or k
          local al = ueber(gr.alarm)
          melde(w, now, "sA" .. k, 2, al, name .. (gr.richtung == "unter" and " TIEF" or " HOCH"), nil)
          melde(w, now, "sW" .. k, 1, not al and ueber(gr.warnung), name .. (gr.richtung == "unter" and " TIEF" or " HOCH"), nil)
          if not gr.vibration and w.meld["sA" .. k] then w.meld["sA" .. k].keinVib = true end
          if w.meld["sA" .. k] then w.meld["sA" .. k].gr = gr end
          if w.meld["sW" .. k] then w.meld["sW" .. k].gr = gr end
        end
      end
    end
  end

  local st = 0
  for i = 1, w.nAktiv do
    if w.aktiv[i].stufe > st then st = w.aktiv[i].stufe end
  end
  w.stufe = st
  if w.nAktiv > 0 then
    local t = nil
    for s = 2, 1, -1 do
      for i = 1, w.nAktiv do
        local m = w.aktiv[i]
        if m.stufe == s then t = t and (t .. "  |  " .. m.text) or m.text end
      end
    end
    w.meldText = t
  end

  if st == 2 then
    w.zustand = "ALARM"
  elseif st == 1 then
    w.zustand = "WARNUNG"
  elseif not d or v.rpm == nil then
    w.zustand = "KEINE DATEN"
  elseif w.lauf then
    local kalt = false
    for i = 1, 4 do local x = v["cht" .. i]; if g.chtKalt and x and x < g.chtKalt then kalt = true end end
    w.zustand = kalt and "WARMLAUF" or "LÄUFT"
  else
    w.zustand = "AUS"
  end
end

-- Ansage und Vibration: sofort beim Auftreten, danach alle «Wiederholung» Sekunden; Alarme gehen vor.
local function ansagen(w, now)
  if w.nAktiv == 0 or w.v.stumm then return end
  if w.tAnsage and now - w.tAnsage < ANSAGE_ABSTAND then return end
  local wahl = nil
  for i = 1, w.nAktiv do
    local m = w.aktiv[i]
    if (m.tAns == nil or now - m.tAns >= w.g.pause) and (wahl == nil or m.stufe > wahl.stufe) and not still(w, m) then wahl = m end
  end
  if wahl == nil then return end
  wahl.tAns, w.tAnsage = now, now
  local c = w.cfg
  if c.ansage and system.playFile and wahl.wav then
    pcall(system.playFile, AUDIO[w.sp or 1] .. wahl.wav .. ".wav")
    if c.zahl and wahl.wert and wahl.einh and system.playNumber then
      pcall(system.playNumber, wahl.wert, wahl.einh, wahl.dez or 0)
    end
  end
  if c.vibration and wahl.stufe == 2 and not wahl.keinVib and system.playHaptic then pcall(system.playHaptic, "- . -") end
end


-- ---------------------------------------------------------------- Lua-Studio (Format v1)
-- Ablauf nach jedem Modellwechsel, ein Schritt je wakeup (Befehlsgrenze): Studio-Datei laden, .funke.lua laden,
-- Felder in Schritten prüfen, Einstellungen übernehmen, Sensoren der Plätze suchen, Info-Datei schreiben.
-- Ohne Studio-Datei bleibt alles wie bisher (nur die Info-Datei wird geschrieben).
local STUDIO_TEXT = {
  kaputt = "Studio-Datei kaputt – Standard", zuNeu = "Studio-Datei zu neu – Lua aktualisieren",
  funke = "Änderungen an der Funke verworfen", nicht = "Änderung nicht gespeichert",
}

local function studioHinweis(w, text)
  print("Gas Engine Carb: Studio: " .. text)
  w.studio = w.studio or { q = {}, grenze = {} }
  w.studio.text, w.studio.textBis = text, os.clock() + 8
end

-- Grenzen je Wert für die Farben der Plätze (angezeigte Einheit): Lua-Werte aus den Einstellungen, sonst aus dem Studio
local function studioGrenzen(w, S)
  local stu, c = w.studio, w.cfg
  local gr = {}
  for s, m in pairs(S.GRENZ_FELD) do
    local k = "lua:" .. s
    local a = stu.st.werte[k] or { faktor = 1, versatz = 0 }
    local function anz(x) if x == nil or x <= 0 then return nil end return x / 10 ^ m[3] * a.faktor + a.versatz end
    local d = stu.WERTE[s]
    if d then gr[k] = { richtung = d[7], warnung = m[1] and anz(c[m[1]]), alarm = m[2] and anz(c[m[2]]) } end
  end
  for k, g in pairs(stu.st.gr) do if not gr[k] then gr[k] = g end end
  stu.grenze = gr
end

local function studioSchritt(w, now)
  local z = w.studioZ
  if z == nil or z.fertig then return end
  if z.art == "start" then
    local S = lade("studio.lua")
    z.S = S
    S.funkeAufraeumen()
    local _, pf = S.pfade()
    -- R2: ausdrückliche Wahl im Menü vor der Datei zum Modellnamen; R1: alle Orte
    local d, grund, quelle
    local wp = S.wahlPfad(w.wahl)
    w.studioWahl = wp and "menue" or "auto"
    if wp then
      d, grund = S.laden(wp, S.FORMAT)
      quelle = wp
    else
      d, grund, quelle = S.suchen()
    end
    if not d and grund == "fehlt" and not wp and S.LUA_ALT then   -- Übergang: Studio-Datei mit dem alten Namen
      local da, ga = S.laden(S.ORDNER .. S.kennung() .. "." .. S.LUA_ALT .. ".lua", S.FORMAT)
      if da or ga ~= "fehlt" then
        d, grund, quelle = da, ga, S.ORDNER .. S.kennung() .. "." .. S.LUA_ALT .. ".lua"
        if da then print("Gas Engine Carb: old studio file found, please re-transfer") end
      end
    end
    w.studioStatus = d and "geladen" or grund
    w.studioQuelle = (d or grund ~= "fehlt" or wp) and quelle or ""
    -- R4: Standardanzeige trotz gefundener oder gewählter Datei: Hinweiszeile mit Grund, bleibt stehen
    if not d and (grund ~= "fehlt" or wp) then
      local en = w.sp == 2
      local g = grund == "zuNeu" and (en and "format too new" or "Format zu neu")
        or grund == "fehlt" and (en and "missing" or "fehlt") or (en and "content invalid" or "Inhalt ungültig")
      w.studioFehl = (en and "Studio: file faulty (" or "Studio: Datei fehlerhaft (") .. g .. ")"
      print(NAME_LOG .. ": " .. w.studioFehl .. " " .. tostring(quelle))
    end
    if not d then
      z.art = "info"
    else
      z.d, z.pf, z.art = d, pf, "funke"
    end
  elseif z.art == "funke" then
    local S = z.S
    if S == nil or type(z.d) ~= "table" then z.art = "start" return end   -- Ablauf unterbrochen: neu beginnen
    local fk, g2 = S.laden(z.pf, S.FORMAT)
    if not fk and g2 ~= "fehlt" then studioHinweis(w, STUDIO_TEXT.funke) end
    z.F, z.WERTE = lade("felder.lua"), lade("werte.lua")
    z.pz = S.pruefeStart(z.d, fk, z.F, z.WERTE)
    z.d, z.art = nil, "pruefen"
  elseif z.art == "pruefen" then
    local S = z.S
    if S.pruefeSchritt(z.pz) then
      local st = z.pz.st
      S.anwenden(w, st, z.F)
      grenzen(w)
      w.studio = { st = st, WERTE = z.WERTE, q = {}, namen = {}, grenze = {},
        text = w.studio and w.studio.text, textBis = w.studio and w.studio.textBis }
      -- Basis für .funke.lua: nur der Stand der Studio-Datei (ohne frühere Änderungen an der Funke), Quellen wie jetzt
      local b = { cfg = {} }
      S.anwenden(b, st, z.F, true)
      w.studioBasis = b.cfg
      if st.fehler > 0 then studioHinweis(w, "Studio-Datei: " .. st.fehler .. " Fehler") end
      if #st.ansichten == 0 and (st.nRoh or 0) > 0 then
        w.studioFehl = w.sp == 2 and "Studio: no matching view" or "Studio: keine passende Ansicht"
      end
      studioGrenzen(w, S)
      -- Schlüssel, für die ein Sensor oder Kanal gesucht werden muss
      local ks, da = {}, {}
      local function dazu(k) if not da[k] and (k:find("^sensor:") or k:find("^kanal:")) then da[k] = true; ks[#ks + 1] = k end end
      for _, an in ipairs(st.ansichten) do for _, pl in ipairs(an.plaetze) do dazu(pl.w) end end
      for k in pairs(st.gr) do dazu(k) end
      z.ks, z.i, z.pz, z.art = ks, 1, nil, "quellen"
    end
  elseif z.art == "quellen" then
    -- je Aufruf höchstens 4 Schlüssel; mit Physical ID die Sensorliste selbst durchgehen (getSource kennt sie nicht)
    local S, stu = z.S, w.studio
    for _ = 1, 4 do
      local k = z.ks[z.i]
      if k == nil then z.art = "info" break end
      local art, a, sub, ph = S.schluessel(k, z.WERTE)
      local q
      if art == "kanal" and CATEGORY_CHANNEL then
        local ok, x = pcall(system.getSource, { category = CATEGORY_CHANNEL, member = a - 1 })
        if ok then q = x end
      elseif art == "sensor" and not ph then
        local ok, x = pcall(system.getSource, { category = CATEGORY_TELEMETRY_SENSOR, appId = a, subId = sub })
        if ok then q = x end
      elseif art == "sensor" then
        -- mit Physical ID: Sensorliste in Stücken zu 20 je Aufruf durchgehen (Befehlsgrenze)
        if z.liste == nil then
          local ok, l = pcall(system.getSources, { category = CATEGORY_TELEMETRY_SENSOR })
          z.liste = (ok and type(l) == "table") and l or {}
        end
        local j0 = z.j or 1
        local j1 = math.min(#z.liste, j0 + 19)
        for j = j0, j1 do
          local x = z.liste[j]
          local o1, xa = pcall(x.appId, x); local o2, xs = pcall(x.subId, x); local o3, xp = pcall(x.physId, x)
          if o1 and o2 and o3 and xa == a and xs == sub and xp == ph then q = x break end
        end
        if not q and j1 < #z.liste then z.j = j1 + 1 return end    -- nächster Aufruf, gleicher Schlüssel
        z.j = nil
      end
      if q then
        stu.q[k] = q
        local okN, n = pcall(q.name, q)
        if okN and type(n) == "string" then stu.namen[k] = n end
      else
        print("Gas Engine Carb: Studio: kein Sensor für " .. k)
      end
      z.i = z.i + 1
    end
  elseif z.art == "info" then
    local okI, fertig = pcall(lade("info.lua").schritt, w, w.version or "", z.S or lade("studio.lua"))
    if not okI then print("Gas Engine Carb: Info-Datei: " .. tostring(fertig)) end
    if not okI or fertig then
      z.fertig, z.S, z.F, z.liste = true, nil, nil, nil
      if w.studio and w.studio.st and #w.studio.st.ansichten > 0 then ANSICHT = ANSICHT or lade("ansicht.lua") end
      collectgarbage()
    end
  end
end

-- Änderungen aus dem Widget-Menü bei Studio-Modellen in .funke.lua schreiben
local function studioFunke(w)
  local S, F = lade("studio.lua"), lade("felder.lua")
  local ok = S.funkeSchreiben(S.funkeText(w, F, w.studioBasis or {}, w.studio and w.studio.st and w.studio.st.werte))
  if not ok then studioHinweis(w, STUDIO_TEXT.nicht) end
  if w.studio and w.studio.st then studioGrenzen(w, S) end
end

-- Studio-Ansicht für diese Fenstergrösse (R3), einmal je Grösse gerechnet und gemerkt
local function studioAnsicht(w, W, H)
  local stu = w.studio
  if not (ANSICHT and stu and stu.st and #stu.st.ansichten > 0) then return nil end
  local c = w.anCache
  if c and c.st == stu.st and c.W == W and c.H == H then return c.an end
  local an, angepasst, weg, quelle = ANSICHT.waehle(stu.st.ansichten, W, H)
  w.anCache = { st = stu.st, W = W, H = H, an = an }
  local en = w.sp == 2
  local alt = tostring(w.ansichtGenutzt) .. tostring(w.angepasst)
  w.ansichtGenutzt = quelle and (quelle.breite .. "x" .. quelle.hoehe) or ""
  w.angepasst = angepasst and an ~= nil
  w.anpText, w.anpBis = nil, nil
  if an == nil then
    w.studioFehl = en and "Studio: no matching view" or "Studio: keine passende Ansicht"
  elseif angepasst then
    w.anpText = (en and "Studio: view %dx%d adapted" or "Studio: Ansicht %dx%d angepasst"):format(quelle.breite, quelle.hoehe)
      .. (weg > 0 and ((en and ", %d omitted" or ", %d weggelassen"):format(weg)) or "")
    w.anpBis = os.clock() + 5
    print(NAME_LOG .. ": " .. w.anpText .. " -> " .. W .. "x" .. H)
  end
  if alt ~= tostring(w.ansichtGenutzt) .. tostring(w.angepasst) then w.infoNeu = true end
  return an
end

-- Studio-Hinweis (R4, A1): steht in der eigenen Kopf- bzw. Meldezeile des Widgets (w.studioT), nie über den Plätzen.
-- Fehlergrund bleibt stehen, «angepasst» nur 5 s, übrige Studio-Hinweise 8 s.
local function studioText(w)
  local t = w.studioFehl
  if not t and w.anpBis then
    if os.clock() < w.anpBis then t = w.anpText else w.anpBis = nil end
  end
  local st = w.studio
  if not t and st and st.text and st.textBis and os.clock() < st.textBis then t = st.text end
  w.studioT = t
end
local function studioZeile() end

local SEITENNAME = { "Motor", "Elektrik", "Übersicht" }

-- Texte rechts in der Statusleiste, nach Wichtigkeit (Seitenanzeige zuerst, dann ECU, dann Empfang).
-- Modellname für die Anzeige; Strich, wenn Ethos keinen liefert. lang = höchste Zeichenzahl.
function K.modellName(lang)
  local ok, n = pcall(model.name)
  if not ok or type(n) ~= "string" or n:match("^%s*$") then return "-" end
  n = n:gsub("^%s+", ""):gsub("%s+$", "")
  if lang and #n > lang then
    local k = n:sub(1, lang)                       -- nicht mitten in einem Umlaut (UTF-8) abschneiden
    while #k > 0 and k:byte(#k) >= 0x80 and k:byte(#k) < 0xC0 do k = k:sub(1, -2) end
    if #k > 0 and k:byte(#k) >= 0xC0 then k = k:sub(1, -2) end
    n = k .. "."
  end
  return n
end

local function kopfTexte(w)
  local v, t, n = w.v, w.kopfText, 1
  w.kopfRot = nil
  t[1] = SEITENNAME[w.seite] .. " " .. w.seite .. "/" .. SEITEN
  -- Name des gewählten Modells (links neben ECU/Empfang, Vorrang vor diesen), zu lange Namen gekürzt
  n = n + 1
  t[n] = K.modellName(24)
  w.kopfName = n
  w.kopfLeer = w.kopfLeer or {}
  w.kopfLeer[n] = false
  if w.cfg.ecuV then
    n = n + 1
    t[n] = v.ecuV and ("ECU " .. Z.zahl(v.ecuV, w.dz.ecuV or 1) .. " V") or "ECU"
    w.kopfLeer = w.kopfLeer or {}
    w.kopfLeer[n] = v.ecuV == nil
    local e = w.meld
    if (e.ecuA and e.ecuA.an) or (e.ecuW and e.ecuW.an) then w.kopfRot = n end
  end
  if w.cfg.rssi then
    n = n + 1
    t[n] = v.rssi and ("Empfang " .. Z.zahl(v.rssi, 0) .. " " .. (w.eh.rssi or "")) or "Empfang"
    w.kopfLeer = w.kopfLeer or {}
    w.kopfLeer[n] = v.rssi == nil
  end
  w.kopfN = n
end

function K.wecke(w)
  local now = os.clock()
  if w.tS == nil then
    w.tS, w.tL, w.tE, w.tT, w.tB = now - 1, now - 1, now - 3, now, now - 1
  end
  local dt = now - w.tS
  if dt >= DT_SCHNELL then
    w.tS = now
    if dt > 1 or dt < 0 then dt = DT_SCHNELL end      -- nach einer Pause nichts nachrechnen
    liesSchnell(w, now, dt)
    if now - w.tL >= DT_LANGSAM then
      w.tL = now
      liesLangsam(w)
    end
    if now - w.tE >= 2 then
      w.tE = now
      liesEinheiten(w)
    end
    if now - w.tT >= TREND_DT then
      w.tT = now
      trend(w)
    end
    kraftstoff(w, now, dt)
    uebersicht(w, dt)
    schlepp(w, now)
    warnungen(w, now)
    ansagen(w, now)
    if w.hinweis and now >= w.hinweisBis then w.hinweis = nil end
    -- Datei schreiben: sofort nach «Vollgetankt», sonst frühestens 2 s nach der letzten Änderung
    if w.dateiOffen and (w.dateiJetzt or now - (w.tDatei or -100) >= 2) then
      w.dateiOffen, w.dateiJetzt, w.tDatei = false, false, now
      local ok, F = pcall(lade, "felder.lua")
      local okS, erfolg = false, false
      if ok then okS, erfolg = pcall(F.schreibeDatei, w) end
      if not (okS and erfolg) then print("Gas Engine Carb: Datei konnte nicht geschrieben werden") end
    end
    -- Erster Start ohne gespeicherte Einstellungen: Sensoren automatisch suchen, sobald Telemetrie da ist
    if w.suchZ == nil and w.autoOffen and w.v.tele and now - (w.tAuto or -100) >= 5 then
      w.tAuto, w.suchArt = now, "auto"
      w.suchLaeuft = true
    end
    -- Lua-Studio: ein Schritt je Aufruf nach dem Modellwechsel; Änderungen aus dem Menü in .funke.lua
    if w.infoNeu and w.studioZ and w.studioZ.fertig and not w.suchLaeuft then
      w.infoNeu = nil
      w.studioZ = { art = "info" }
    end
    if w.studioZ and not w.studioZ.fertig and not w.suchLaeuft then
      local ok, e = pcall(studioSchritt, w, now)
      if not ok then w.studioZ.fertig = true; print("Gas Engine Carb: Studio: " .. tostring(e)) end
    elseif w.funkeOffen and now - (w.tFunke or 0) >= 2 then
      w.funkeOffen = false
      local ok, e = pcall(studioFunke, w)
      if not ok then print("Gas Engine Carb: Studio: " .. tostring(e)) end
    end
    -- Die Suche läuft in Schritten, ein Schritt je Aufruf (Ethos begrenzt die Befehle je Aufruf)
    if w.suchLaeuft then
      local ok, n = pcall(function() return lade("suche.lua")(w) end)
      if not ok then
        w.suchZ, w.suchLaeuft = nil, false
        print("Gas Engine Carb: Fehler bei der Suche: " .. tostring(n))
      elseif type(n) == "number" then
        w.suchLaeuft = false
        grenzen(w)
        if w.suchArt == "auto" then
          if n > 0 then
            w.autoOffen = false
            hinweis(w, n .. (n == 1 and " Sensor automatisch zugewiesen" or " Sensoren automatisch zugewiesen"), now)
          end
        else
          hinweis(w, tostring(n) .. (n == 1 and " Sensor neu zugewiesen" or " Sensoren neu zugewiesen"), now)
        end
        print("Gas Engine Carb: Suche: " .. n .. " neu zugewiesen")
        if n > 0 and model and model.dirty then pcall(model.dirty) end
      end
    end
  end

  if lcd.isVisible and not lcd.isVisible() then return end
  if now - w.tB >= DT_BILD then
    w.tB = now
    if Z == nil then Z = lade("zeichnen.lua") end
    local stu = w.studio                          -- Studio-Ansicht nach dem Freigeben wieder laden (andere Instanz)
    if ANSICHT == nil and stu and stu.st and #stu.st.ansichten > 0 and w.studioZ and w.studioZ.fertig and not w.ansichtFehler then
      local ok, A = pcall(lade, "ansicht.lua")
      if ok then ANSICHT = A else w.ansichtFehler = true; print("Gas Engine: ansicht.lua: " .. tostring(A)) end
    end
    sprache(w)
    Z.tr, Z.punkt = w.uebers, w.sp == 2       -- Englisch: Texte übersetzen, Dezimalpunkt und Tausender-Komma
    local L = w.L
    if L and L.kompakt then                       -- Kompaktansicht: nur kompakt.lua, die Seiten freigeben
      if KOMPAKT == nil then
        for i = 1, SEITEN do SEITE[i] = nil end
        collectgarbage()
        KOMPAKT = lade("kompakt.lua")
      end
      -- Studio-Plätze «zylinder»/«tank» brauchen Seite 1 auch in der Kompaktansicht
      if SEITE[1] == nil and stu and stu.st and stu.st.seite1 then SEITE[1] = lade("seite1.lua") end
    elseif SEITE[w.seite] == nil then
      KOMPAKT = nil
      for i = 1, SEITEN do SEITE[i] = nil end
      collectgarbage()
      SEITE[w.seite] = lade("seite" .. w.seite .. ".lua")
    end
    w.blink = floor(now * 2) % 2 == 0
    kopfTexte(w)
    lcd.invalidate()
  end
end

function K.zeichne(w)
  if Z == nil then return end
  local W, H = lcd.getWindowSize()
  local L = w.L
  if L == nil or L.W ~= W or L.H ~= H then
    L = Z.layout(W, H)
    w.L = L
  end
  Z.grund(L)
  w.nZiele = 0
  -- Fenstergrössen für die Info-Datei merken
  w.fenster = w.fenster or {}
  local neuF = true
  for _, f in ipairs(w.fenster) do if f[1] == W and f[2] == H then neuF = false end end
  if neuF and #w.fenster < 6 then w.fenster[#w.fenster + 1] = { W, H }; w.infoAlt = nil end
  -- Studio-Ansicht genau für diese Fenstergrösse?
  local an = studioAnsicht(w, W, H)
  studioText(w)
  if an and L.kompakt then
    if KOMPAKT then KOMPAKT.leiste(w, L, Z, math.floor(36 * L.s)) end
    ANSICHT.zeichne(w, L, Z, an, nil, SEITE[1])
    ANSICHT.hinweis(w, L, Z)
    if w.dialog and w.dialog ~= "detail" then Z.dialog(w, L) end   -- z. B. Rückfrage des Knopfs im Platz «tank»
    studioZeile(w, L)
    if w.fehler then Z.fehlerZeichen(L) end
    return
  end
  if L.kompakt then
    if W < 400 or H < 180 then
      Z.zuKlein(L, K.modellName(24))
    elseif KOMPAKT then                          -- erstes Bild: kompakt.lua lädt erst im nächsten wakeup
      KOMPAKT.zeichne(w, L, Z)
    end
    studioZeile(w, L)
    if w.fehler then Z.fehlerZeichen(L) end
    return
  end
  if W < 400 or H < 250 then
    Z.zuKlein(L, K.modellName(24))
    return
  end
  local S = SEITE[w.seite]
  if an and w.seite == 1 then ANSICHT.zeichne(w, L, Z, an, nil, S)        -- Studio ersetzt nur Seite 1
  elseif S then S.zeichne(w, L, Z) end
  Z.kopf(w, L)
  if ANSICHT then ANSICHT.hinweis(w, L, Z) end
  if w.dialog == "detail" then
    if S and S.detail then S.detail(w, L, Z) end
  elseif w.dialog then
    Z.dialog(w, L)
  end
  studioZeile(w, L)
  if w.fehler then Z.fehlerZeichen(L) end
end

local function treffer(w, x, y)
  for i = w.nZiele or 0, 1, -1 do          -- zuletzt gezeichnet liegt oben (Rückfrage)
    local z = w.ziele[i]
    if x >= z.x and x < z.x + z.b and y >= z.y and y < z.y + z.h then return z.id end
  end
  return nil
end

-- Ein Knopf wurde angetippt (Finger auf und ab auf demselben Knopf, ohne Wisch).
local function knopf(w, id, now)
  if id == "vollgetankt" and w.dialog == nil then
    w.dialog = "tank"
  elseif id == "abbrechen" then
    w.dialog = nil
  elseif id == "ja_tank" and w.dialog == "tank" then
    w.dialog = nil
    vollgetankt(w, now)
  elseif id == "zuruecksetzen" and w.dialog == nil then
    w.dialog = "reset"
  elseif id == "ja_reset" and w.dialog == "reset" then
    w.dialog = nil
    uebersichtZurueck(w, now)
  elseif (id == "ja_schlepp" or id == "nein_schlepp") and w.dialog == "schlepp" then
    w.dialog = nil
    schleppEnde(w, id == "ja_schlepp")
  elseif type(id) == "string" and id:sub(1, 2) == "zs" and w.dialog == nil then
    w.detail = id == "zsl" and "sl" or tonumber(id:sub(3))   -- Zeile der Flugliste: Detailfenster
    w.dialog = "detail"
  elseif id == "schliessen" and w.dialog == "detail" then
    w.dialog = nil
  elseif id == "loeschen" and w.dialog == "detail" and ((w.detail == "sl" and w.sl) or (type(w.detail) == "number" and w.schlepps[w.detail])) then
    w.dialog = "loeschen"
  elseif id == "ja_loeschen" and w.dialog == "loeschen" then
    w.dialog = nil
    local s = w.schlepps
    if w.detail == "sl" then
      w.sl = nil                               -- laufender/pausierter Eintrag: zählt nicht, Nummer bleibt frei
      w.dateiOffen, w.dateiJetzt = true, true
    elseif type(w.detail) == "number" and s[w.detail] then
      table.remove(s, w.detail)                -- nur dieser Eintrag; Tank und «Dieser Flug» bleiben
      for i, e in ipairs(s) do e.nr = i end    -- neu durchnummerieren
      w.nSchlepp = #s
      w.dateiOffen, w.dateiJetzt = true, true
    end
  end
  w.tB = 0
end

-- Wisch nach links/rechts blättert zwischen den Seiten. Am Rand (Seite 1 nach rechts, letzte Seite nach links)
-- bleibt der Wisch bei Ethos, damit man wie gewohnt zum nächsten Bildschirm kommt (gemessen: Ethos blättert nur,
-- wenn das Widget die Bewegung nicht für sich behält). Bei offener Rückfrage wird nicht geblättert.
function K.ereignis(w, kat, wert, x, y)
  -- Drehrad: rechts = nächste Seite, links = vorige Seite (auch für Sender ohne Touch). Bei offener Rückfrage
  -- oder offenem Detailfenster nichts tun, das Ereignis aber behalten, damit Ethos das Widget nicht verlässt.
  if EVT_KEY and kat == EVT_KEY then
    local vor = KEY_ROTARY_RIGHT and wert == KEY_ROTARY_RIGHT
    local zur = KEY_ROTARY_LEFT and wert == KEY_ROTARY_LEFT
    if not (vor or zur) then return false end
    if w.dialog == nil then
      w.seite = clamp(w.seite + (vor and 1 or -1), 1, SEITEN)
      w.tB = 0
    end
    return true
  end
  if kat ~= EVT_TOUCH then return false end
  x, y = gut(x), gut(y)
  if x == nil or y == nil then return false end
  local t = w.touch
  if wert == TOUCH_START then
    w.touch = { x = x, y = y, id = treffer(w, x, y) }
    return w.dialog ~= nil
  elseif wert == TOUCH_MOVE and t then
    local dx, dy = x - t.x, y - t.y
    if abs(dx) > SLOP or abs(dy) > SLOP then t.id = nil end
    if w.dialog then return true end
    if not t.mein and not t.ethos and abs(dx) > SLOP and abs(dx) > abs(dy) then
      local hinein = (dx < 0 and w.seite < SEITEN) or (dx > 0 and w.seite > 1)
      if hinein then t.mein = true else t.ethos = true end
    end
    t.dx = dx
    return not t.ethos
  elseif wert == TOUCH_END and t then
    w.touch = nil
    if t.mein then
      if abs(t.dx or 0) >= 50 then
        w.seite = clamp(w.seite + ((t.dx < 0) and 1 or -1), 1, SEITEN)
        w.tB = 0
      end
      return true
    end
    if t.id and t.id == treffer(w, x, y) then
      knopf(w, t.id, os.clock())
      return true
    end
    return w.dialog ~= nil
  end
  return false
end

function K.menue(w)
  pcall(sprache, w)
  local F = lade("felder.lua")
  local okL, l = pcall(function() return lade("studio.lua").liste() end)
  w.studioListe = okL and l or {}
  lade("menue.lua")(w, F, function()
    grenzen(w); w.dateiOffen = true
    if w.studio and w.studio.st then w.funkeOffen, w.tFunke = true, os.clock() end
  end, function()
    -- Suche starten; sie läuft in den nächsten Aufrufen von wecke weiter (Ergebnis als Hinweis auf dem Bildschirm)
    w.suchZ, w.suchArt, w.suchLaeuft = nil, "menue", true
  end, function()
    -- «Zurück auf Studio-Stand» bzw. ohne Studio-Datei «Zurück auf Standard»
    if w.studio and w.studio.st then
      w.funkeOffen = false                 -- keine offene Menü-Änderung mehr nachschreiben
      pcall(function() lade("studio.lua").funkeLoeschen() end)
      w.studioZ = { art = "start" }
    else
      local std = F.standard()
      for k, v in pairs(std) do w.cfg[k] = v end
      grenzen(w); w.dateiOffen = true
    end
  end, function(wahl)
    if wahl == w.wahl then return end
    w.wahl = wahl
    studioNeu(w)
  end)
end

-- Studio neu suchen und laden (Modellwechsel oder neue Wahl im Menü)
studioNeu = function(w)
  w.studio, w.studioStatus, w.infoAlt, w.fenster = nil, nil, nil, {}
  w.studioFehl, w.anpText, w.anpBis, w.anCache, w.ansichtGenutzt, w.angepasst = nil, nil, nil, nil, nil, nil
  ANSICHT = nil                         -- Studio-Ansicht erst wieder laden, wenn das neue Modell eine hat
  w.studioZ = { art = "start" }
end

function K.lies(w)
  local F = lade("felder.lua")
  w.gelesen = F.lies(w)
  w.autoOffen = not w.gelesen
  grenzen(w)
  studioNeu(w)
end

function K.schreibe(w)
  local F = lade("felder.lua")
  F.schreibe(w)
end

return K
