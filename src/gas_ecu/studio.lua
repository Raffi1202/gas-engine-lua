-- Gas Engine ECU: Lua-Studio-Format v1 (FrSky Koordination, «Lua-Studio-Format v1.md»). Laden, prüfen und zusammenführen
-- der Studio-Datei und der .funke.lua, Schreiben der .funke.lua. Wird nur geladen, wenn eine Studio-Datei da ist
-- oder das Menü an der Funke etwas ändert, und danach wieder freigegeben.
-- Die Funktion studioLaden ist WÖRTLICH aus «Lua-Studio-Format v1 - Referenz studio_laden.lua» übernommen.

-- ===== Beginn Referenz (wörtlich) =====
-- Referenz: Studio-Datei sicher laden (Lua-Studio-Format v1, Abschnitt 3). Alle Luas übernehmen das wörtlich.
-- Rückgabe: Tabelle oder nil, Grund ("fehlt" | "kaputt" | "zuNeu").
local MAX_BYTE = 16384
local MAX_ELEMENTE = 1200   -- Kommas + «=» + «{» ausserhalb von Texten (Befehle und Speicher, gemessen)
local MAX_TABELLEN = 240    -- «{» ausserhalb von Texten (Speicher)
local SCHLUESSELWOERTER = { "and", "break", "do", "else", "elseif", "end", "for", "function", "goto", "if", "in",
  "local", "nil", "not", "or", "repeat", "then", "until", "while" }

local function studioLaden(pfad, hoechstesFormat)
  local ok, f = pcall(io.open, pfad, "r")
  if not ok or not f then return nil, "fehlt" end
  local teile, n = {}, 0
  while true do
    local ok2, s = pcall(f.read, f, 512)
    if not ok2 then f:close() return nil, "kaputt" end
    if not s or #s == 0 then break end
    n = n + #s
    if n > MAX_BYTE then f:close() return nil, "kaputt" end
    teile[#teile + 1] = s
  end
  f:close()
  local s = table.concat(teile)
  teile = nil
  -- 1. Anfang: nur «return {»
  if not s:find("^%s*return%s*{") then return nil, "kaputt" end
  -- 2. erlaubte Bytes: Buchstaben, Ziffern, Leerraum, _ { } [ ] = , " \ - .
  if s:find('[^%w%s_{}%[%]=,"\\%-%.]') then return nil, "kaputt" end
  -- 2b. nach «\» nur Ziffern (Dezimal-Escapes); sperrt \" \z \x \u{…}, die die Textgrenzen verschieben könnten
  if s:find("\\%D") then return nil, "kaputt" end
  -- 3. verbotene Folgen: Verkettung, Kommentar, lange Texte
  if s:find("..", 1, true) or s:find("--", 1, true) or s:find("[[", 1, true) then return nil, "kaputt" end
  -- 4. Schlüsselwörter ausserhalb von Texten (Texte enthalten nie ein rohes ", das Studio schreibt \34)
  local ohneTexte = s:gsub('"[^"]*"', '""')
  for _, w in ipairs(SCHLUESSELWOERTER) do
    if ohneTexte:find("%f[%w_]" .. w .. "%f[^%w_]") then return nil, "kaputt" end
  end
  -- 4b. «-» nur als Vorzeichen direkt vor einer Ziffer, nach = , { [ (keine Rechenketten)
  if ohneTexte:find("%-%s*%D") or ohneTexte:find("[^=,{%[%s]%s*%-") then return nil, "kaputt" end
  local _, anzahlReturn = ohneTexte:gsub("%f[%w_]return%f[^%w_]", "")
  if anzahlReturn ~= 1 then return nil, "kaputt" end
  -- 4b2. kein Name und keine Zahl länger als 24 Zeichen (Speicher: lange Schlüssel)
  if ohneTexte:find(string.rep("[%w_]", 25)) then return nil, "kaputt" end
  -- 4c. reine Daten: Namen nur als Schlüssel direkt vor «=», sonst nur true/false (kein _ENV, keine Variablen, keine Aufrufe)
  if ohneTexte:find("==", 1, true) then return nil, "kaputt" end
  local rest = ohneTexte:gsub("^%s*return", "")
  rest = rest:gsub("[%a_][%w_]*%s*=", "=")
  rest = rest:gsub("%f[%w_]true%f[^%w_]", "")
  rest = rest:gsub("%f[%w_]false%f[^%w_]", "")
  local nameGefunden = rest:find("[%a_]")
  rest = nil
  if nameGefunden then return nil, "kaputt" end
  -- 4d. nach «[» nur ein Text, eine Zahl oder ein Vorzeichen (keine Ausdrücke als Schlüssel)
  if ohneTexte:find('%[%s*[^%d"%-]') then return nil, "kaputt" end
  -- 5. Grösse der Tabelle begrenzen (Befehlsgrenze beim Aufbau)
  local _, kommas = ohneTexte:gsub(",", "")
  local _, gleich = ohneTexte:gsub("=", "")
  local _, klammern = ohneTexte:gsub("{", "")
  if klammern > MAX_TABELLEN or kommas + gleich + klammern > MAX_ELEMENTE then return nil, "kaputt" end
  -- 6. laden ohne Umgebung, nur Text
  -- Zwischentexte der Prüfung freigeben, bevor übersetzt wird (Speicher-Spitze)
  ohneTexte = nil
  collectgarbage("collect")
  local ok3, chunk = pcall(load, s, "=studio", "t", {})
  s = nil
  collectgarbage("collect")
  if not ok3 or type(chunk) ~= "function" then return nil, "kaputt" end
  local ok4, d = pcall(chunk)
  if not ok4 or type(d) ~= "table" or math.type(d.format) ~= "integer" or d.format < 1 then return nil, "kaputt" end
  if d.format > hoechstesFormat then return nil, "zuNeu" end
  return d
end
-- ===== Ende Referenz =====

local S = {}
S.FORMAT = 1                       -- höchstes Studio-Format, das dieses Lua liest
S.ORDNER = "SCRIPTS:/studio/"
S.LUA = "gas_ecu"
S.LUA_ALT = "motoren_ecu"   -- Name bis 1.9.0 / 0.9.0: alte Studio-Datei einmal lesen (Übergang)
S.laden = studioLaden
local floor = math.floor

-- Modellkennung (Abschnitt 2.1, byteweise; %w ist in Ethos nur ASCII)
function S.kennung()
  local ok, n = pcall(model.name)
  local k = ((ok and type(n) == "string") and n or ""):gsub("[^%w]", "_"):sub(1, 32)
  if k == "" then k = "modell" end
  return k
end

function S.pfade()
  local b = S.ORDNER .. S.kennung() .. "." .. S.LUA
  return b .. ".lua", b .. ".funke.lua", b .. ".funke.neu", b .. ".info.json"
end

-- ---------------------------------------------------------------- Prüfhilfen (Abschnitt 4 und 6)
local function endlich(v) return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge end
local function ganz(v) return endlich(v) and math.type(v) == "integer" end
-- Text auf höchstens n Byte kürzen, nur vor einem Byte, das ein Zeichen beginnt
local function kuerze(t, n)
  if type(t) ~= "string" then return nil end
  if #t <= n then return t end
  local p = n + 1
  while p > 1 and t:byte(p) and t:byte(p) >= 0x80 and t:byte(p) < 0xC0 do p = p - 1 end
  return t:sub(1, p - 1)
end
local function farbe(f)
  if type(f) ~= "table" then return nil end
  local r, g, b = f[1], f[2], f[3]
  if not (ganz(r) and ganz(g) and ganz(b)) then return nil end
  if r < 0 or r > 255 or g < 0 or g > 255 or b < 0 or b > 255 then return nil end
  return { r, g, b }
end

-- Wert-Schlüssel (6.6): gibt Art und Teile zurück oder nil
function S.schluessel(k, WERTE)
  if type(k) ~= "string" then return nil end
  if k == "leer" then return "leer" end
  local s = k:match("^lua:([%w_]+)$")
  if s then if WERTE[s] then return "lua", s end return nil end
  local a, sub, ph = k:match("^sensor:(%x%x%x%x):(%d+):(%d+)$")
  if a then
    if a:upper() ~= a then return nil end
    ph = tonumber(ph)
    if ph > 27 then return nil end
    return "sensor", tonumber(a, 16), tonumber(sub), ph
  end
  a, sub = k:match("^sensor:(%x%x%x%x):(%d+)$")
  if a then
    if a:upper() ~= a then return nil end
    return "sensor", tonumber(a, 16), tonumber(sub)
  end
  local nr = k:match("^kanal:(%d+)$")
  if nr then nr = tonumber(nr); if nr >= 1 and nr <= 64 then return "kanal", nr end end
  return nil
end

-- Grenzen der Lua-Werte, die auf bestehende Einstellungen abbilden: { Warnfeld, Alarmfeld, Kommastellen }
-- (Grenzen gelten in der Einheit des Werts; das Lua speichert sie ganzzahlig mit Kommastellen.)
S.GRENZ_FELD = {
  cht_max = { "chtWarn", "chtAlarm", 0 }, cht_diff = { "chtDiff", nil, 0 }, rpm = { "rpmWarn", "rpmAlarm", 0 },
  druck = { "druckVon", "druckAlarm", 1 }, ecu_v = { "ecuWarn", "ecuAlarm", 1 }, tank_proz = { "tankRes", "tankLeer", 0 },
  restzeit = { nil, "tankMin", 0 }, akku1_zelle = { "z1Warn", "z1Alarm", 2 }, akku2_zelle = { "z2Warn", "z2Alarm", 2 },
  akku3_zelle = { "z3Warn", "z3Alarm", 2 }, akku_diff = { "zDiff", nil, 2 }, kanalstrom_max = { "kWarn", "kAlarm", 1 },
  rx1_rssi = { "rssiWarn", "rssiAlarm", 0 },          -- gilt für beide Empfänger (ein Feldpaar im Lua)
}

-- Name einer Einstellung im Studio (snake_case) zum Feldnamen in felder.lua
local function snake(n) return (n:gsub("%u", function(c) return "_" .. c:lower() end)) end

local DARST = { zahl = { 90, 50 }, ring = { 110, 110 }, balken_w = { 140, 40 }, balken_s = { 50, 110 },
  kurve = { 180, 90 }, status = { 120, 40 } }
local ZUSATZ = { keine = true, min = true, max = true, mittel = true }

-- ---------------------------------------------------------------- Zusammenführen und prüfen
-- Die Prüfung läuft in Schritten (Ethos begrenzt die Befehle je Aufruf, unter 5000): S.pruefeStart legt den
-- Zustand an, S.pruefeSchritt arbeitet je Aufruf höchstens SCHRITT Einträge ab und gibt true zurück, wenn fertig.
-- d = Studio-Datei (geprüft durch studioLaden), fk = .funke.lua oder nil. F = felder.lua, WERTE = werte.lua.
-- Ergebnis z.st = { ansichten, werte, gr = { [schluessel] = { richtung, warnung, alarm, ansage, vibration } },
--   ein = { [feld] = wert } (Einstellungen in Speicherform), fehler = n }
local SCHRITT = 8

local function fehler(st, feld, grund)
  st.fehler = st.fehler + 1
  print("Gas Engine ECU: Studio-Datei: " .. tostring(feld) .. ": " .. grund)
end

local function liste(t)
  local r = {}
  if type(t) == "table" then for k, v in pairs(t) do r[#r + 1] = { k, v } end end
  return r
end

function S.pruefeStart(d, fk, F, WERTE)
  if type(d) ~= "table" then d = { format = 1 } end
  local st = { ansichten = {}, werte = {}, gr = {}, ein = {}, einS = {}, grS = {}, fehler = 0 }
  local z = { st = st, d = d, fk = fk, F = F, WERTE = WERTE, phase = 1, i = 1, roh = {}, rohS = {} }
  for _, q in ipairs({ { d, "studio" }, { fk, "funke" } }) do
    local t = q[1]
    if t then
      if t.einstellungen ~= nil and type(t.einstellungen) ~= "table" then fehler(st, q[2] .. ".einstellungen", "keine Tabelle") end
      if t.grenzen ~= nil and type(t.grenzen) ~= "table" then fehler(st, q[2] .. ".grenzen", "keine Tabelle") end
    end
  end
  if d.werte ~= nil and type(d.werte) ~= "table" then fehler(st, "werte", "keine Tabelle") end
  if d.ansichten ~= nil and type(d.ansichten) ~= "table" then fehler(st, "ansichten", "keine Liste") end
  -- Arbeitslisten: Einstellungen (Studio, dann Funke), Werte, Grenzen (Studio, dann Funke), Plätze je Ansicht
  z.ein = liste(d.einstellungen)
  z.nEinStudio = #z.ein
  if fk then for _, e in ipairs(liste(fk.einstellungen)) do z.ein[#z.ein + 1] = e end end
  z.werte = liste(d.werte)
  z.grenzen = liste(d.grenzen)
  z.nGrStudio = #z.grenzen
  if fk then for _, e in ipairs(liste(fk.grenzen)) do z.grenzen[#z.grenzen + 1] = e end end
  z.ansichten = type(d.ansichten) == "table" and d.ansichten or {}
  return z
end

local function einstellung(z, k, v, quelle)
  local st, F = z.st, z.F
  if z.idx == nil then
    z.idx = {}
    for _, g in ipairs(F.gruppen) do for _, f in ipairs(g[2]) do if f[2] ~= "q" and not f.studio and not f.alle then z.idx[snake(f[1])] = f end end end
  end
  local f = type(k) == "string" and z.idx[k]
  if not f then return end                    -- unbekannte Schlüssel ohne Hinweis überlesen
  local art, gut = f[2], nil
  if art == "z" then
    if endlich(v) then
      local x = floor(v * 10 ^ (f[7] or 0) + 0.5)
      if x >= f[5] and x <= f[6] then gut = x end
    end
  elseif art == "b" then
    if type(v) == "boolean" then gut = v end
  elseif art == "w" then
    if ganz(v) then for _, a in ipairs(f[5]) do if a[2] == v then gut = v end end end
  elseif art == "t" then
    gut = F.text(v)
  end
  if gut == nil then fehler(st, quelle .. ".einstellungen." .. k, "ungültig, Werkwert") return end
  st.ein[f[1]] = gut
  if quelle == "studio" then st.einS[f[1]] = gut end
end

local function wert(z, k, e)
  local st = z.st
  if not (S.schluessel(k, z.WERTE) and k ~= "leer" and type(e) == "table") then fehler(st, tostring(k), "Wert verworfen") return end
  local a = { faktor = 1, versatz = 0 }
  if e.faktor ~= nil then
    if endlich(e.faktor) and math.abs(e.faktor) >= 0.0001 and math.abs(e.faktor) <= 10000 then a.faktor = e.faktor
    else fehler(st, k .. ".faktor", "ungültig") end
  end
  if e.versatz ~= nil then
    if endlich(e.versatz) and e.versatz >= -100000 and e.versatz <= 100000 then a.versatz = e.versatz
    else fehler(st, k .. ".versatz", "ungültig") end
  end
  if e.einheit ~= nil then a.einheit = kuerze(e.einheit, 8); if not a.einheit then fehler(st, k .. ".einheit", "kein Text") end end
  if e.name ~= nil then a.name = kuerze(e.name, 24); if not a.name then fehler(st, k .. ".name", "kein Text") end end
  if e.stellen ~= nil then
    if ganz(e.stellen) and e.stellen >= 0 and e.stellen <= 3 then a.stellen = e.stellen else fehler(st, k .. ".stellen", "ungültig") end
  end
  st.werte[k] = a
end

local function grenzeSammeln(z, k, e, quelle)
  if type(k) == "string" and type(e) == "table" and S.schluessel(k, z.WERTE) and k ~= "leer" then
    local r = z.roh[k]
    if r == nil then r = {}; z.roh[k] = r; z.rohListe = z.rohListe or {}; z.rohListe[#z.rohListe + 1] = k end
    -- Ein Eintrag der Funke mit «aus» ist vollständig (so schreibt ihn das Lua): er ersetzt die Stufen der Studio-Datei
    if quelle == "funke" and e.aus ~= nil then r.warnung, r.alarm, r.aus = nil, nil, nil end
    for _, f in ipairs({ "richtung", "warnung", "alarm", "ansage", "vibration", "aus", "beiMotorAus" }) do if e[f] ~= nil then r[f] = e[f] end end
    if quelle == "studio" then
      local rs = {}
      for _, f in ipairs({ "richtung", "warnung", "alarm", "ansage", "vibration", "aus", "beiMotorAus" }) do rs[f] = e[f] end
      z.rohS[k] = rs
    end
  else
    fehler(z.st, quelle .. ".grenzen." .. tostring(k), "verworfen")
  end
end

local function grenzePruefen(z, k, nurStudio)
  local st, r = z.st, (nurStudio and z.rohS or z.roh)[k]
  if r == nil then return end
  local ziel = nurStudio and st.grS or st.gr
  local fehler = nurStudio and function() end or fehler
  local art, s = S.schluessel(k, z.WERTE)
  local richtung = r.richtung
  if richtung ~= nil and richtung ~= "unter" and richtung ~= "ueber" then
    fehler(st, k .. ".richtung", "ungültig, Werkgrenze") return
  end
  if art == "lua" then
    local fest = z.WERTE[s][7]
    if fest == nil then fehler(st, k, "Wert ohne Grenze, verworfen") return end
    if richtung ~= nil and richtung ~= fest then fehler(st, k .. ".richtung", "passt nicht zum Wert, Werkgrenze") return end
    richtung = fest
  end
  -- Grenzen auf Sensoren und Kanäle prüft das Lua bei jedem Aufruf: höchstens 24 (Befehlsgrenze)
  if art ~= "lua" then
    local zk = nurStudio and "nSensorGrS" or "nSensorGr"      -- je Lauf ein eigener Zähler
    z[zk] = (z[zk] or 0) + 1
    if z[zk] > 24 then fehler(st, k, "mehr als 24 Grenzen auf Sensoren/Kanäle, verworfen") return end
  end
  -- ausdrücklich abgeschaltet (Ergänzung Alarm-Sicherheit): nur mit aus = true
  if r.aus == true then ziel[k] = { richtung = richtung or "ueber", aus = true } return end
  if richtung == nil then fehler(st, k .. ".richtung", "fehlt, Grenze aus") return end
  local g = { richtung = richtung, ansage = r.ansage ~= false, vibration = r.vibration ~= false, beiMotorAus = r.beiMotorAus ~= false }
  -- Format 2 §3.5: falscher Typ zählt als true, mit Hinweis
  if r.beiMotorAus ~= nil and type(r.beiMotorAus) ~= "boolean" then fehler(st, k .. ".beiMotorAus", "ungültig, true") end
  if endlich(r.warnung) then g.warnung = r.warnung elseif r.warnung ~= nil then fehler(st, k .. ".warnung", "ungültig") end
  if endlich(r.alarm) then g.alarm = r.alarm elseif r.alarm ~= nil then fehler(st, k .. ".alarm", "ungültig") end
  if g.warnung and g.alarm then
    local falsch = (richtung == "unter" and g.alarm >= g.warnung) or (richtung == "ueber" and g.alarm <= g.warnung)
    if falsch then g.warnung = nil; fehler(st, k, "Reihenfolge Warnung/Alarm falsch, nur Alarm") end
  end
  -- Kein Abschalten ohne «aus» (v1 §6.5, Ergänzung 21.11.2026): ein Eintrag ohne Zahl-Stufe (nur ansage, vibration,
  -- beiMotorAus oder warnung = false plus alarm = false) schaltet nie ab; dann gelten die Werkgrenzen.
  if g.warnung == nil and g.alarm == nil then g.werk = true end
  ziel[k] = g
end

local function platz(z, an, a, pi, p)
  local st = z.st
  local ok = type(p) == "table" and ganz(p.x) and ganz(p.y) and ganz(p.b) and ganz(p.h)
    and p.x >= 0 and p.y >= 0 and p.b > 0 and p.h > 0 and p.x + p.b <= a.breite and p.y + p.h <= a.hoehe
  if not (ok and S.schluessel(p.w, z.WERTE)) then fehler(st, "platz " .. pi, "Lage oder Wert ungültig, verworfen") return end
  local pl = { x = p.x, y = p.y, b = p.b, h = p.h, w = p.w, darstellung = "zahl", zusatz = "keine", kurveS = 120 }
  if p.darstellung ~= nil then
    if DARST[p.darstellung] then pl.darstellung = p.darstellung else fehler(st, "platz " .. pi .. ".darstellung", "unbekannt, Zahl") end
  end
  if pl.darstellung == "kurve" then
    an.kurven = an.kurven + 1
    if an.kurven > 2 then pl.darstellung = "zahl"; fehler(st, "platz " .. pi, "mehr als 2 Kurven, Zahl") end
  end
  local mi, m = DARST[pl.darstellung], a.breite / 800        -- Mindestgrössen im Verhältnis zur Breite (Abschnitt 7)
  if p.b < floor(mi[1] * m) or p.h < floor(mi[2] * m) then fehler(st, "platz " .. pi, "zu klein für " .. pl.darstellung .. ", verworfen") return end
  if p.titel ~= nil then pl.titel = kuerze(p.titel, 24) end
  if endlich(p.min) and endlich(p.max) and p.max > p.min then pl.min, pl.max = p.min, p.max
  elseif p.min ~= nil or p.max ~= nil then fehler(st, "platz " .. pi .. ".min/max", "ungültig") end
  for _, f in ipairs({ "farbe", "farbeWarn", "farbeAlarm", "hintergrund" }) do
    if p[f] ~= nil then pl[f] = farbe(p[f]); if not pl[f] then fehler(st, "platz " .. pi .. "." .. f, "ungültig") end end
  end
  if p.zusatz ~= nil then
    if ZUSATZ[p.zusatz] then pl.zusatz = p.zusatz else fehler(st, "platz " .. pi .. ".zusatz", "ungültig") end
  end
  if p.kurveS ~= nil then
    if ganz(p.kurveS) and p.kurveS >= 30 and p.kurveS <= 600 then pl.kurveS = p.kurveS else fehler(st, "platz " .. pi .. ".kurveS", "ungültig") end
  end
  if p.stufen ~= nil then
    local ok2, l, vor = type(p.stufen) == "table", {}, nil
    if ok2 then
      for si, e in ipairs(p.stufen) do
        if si > 3 or type(e) ~= "table" or not endlich(e.ab) or (vor and e.ab <= vor) or not farbe(e.farbe) then ok2 = false break end
        vor = e.ab
        l[si] = { ab = e.ab, farbe = farbe(e.farbe) }
      end
    end
    if ok2 then pl.stufen = l else fehler(st, "platz " .. pi .. ".stufen", "verworfen") end
  end
  an.plaetze[#an.plaetze + 1] = pl
end

-- Ein Schritt der Prüfung. Gibt true zurück, wenn alles geprüft ist.
function S.pruefeSchritt(z)
  local n = 0
  while n < SCHRITT do
    if z.phase == 1 then                                   -- Einstellungen
      local e = z.ein[z.i]
      if not e then z.phase, z.i = 2, 1 else einstellung(z, e[1], e[2], z.i <= z.nEinStudio and "studio" or "funke"); z.i = z.i + 1 end
    elseif z.phase == 2 then                               -- Wert-Anpassungen
      local e = z.werte[z.i]
      if not e then z.phase, z.i = 3, 1 else wert(z, e[1], e[2]); z.i = z.i + 1 end
    elseif z.phase == 3 then                               -- Grenzen sammeln (Studio, dann Funke je Feld darüber)
      local e = z.grenzen[z.i]
      if not e then z.phase, z.i = 4, 1 else grenzeSammeln(z, e[1], e[2], z.i <= z.nGrStudio and "studio" or "funke"); z.i = z.i + 1 end
    elseif z.phase == 4 then                               -- Grenzen prüfen
      local k = z.rohListe and z.rohListe[z.i]
      if not k then z.phase, z.i, z.ai = 5, 1, 1 else grenzePruefen(z, k); grenzePruefen(z, k, true); z.i = z.i + 1 end
    elseif z.phase == 5 then                               -- Ansichten und Plätze
      local a = z.ansichten[z.ai]
      if a == nil then return true end
      if z.ai > 2 then fehler(z.st, "ansichten", "mehr als 2, verworfen") return true end
      if z.i == 1 then
        if type(a) == "table" and ganz(a.breite) and ganz(a.hoehe) and a.breite >= 100 and a.breite <= 1024
          and a.hoehe >= 100 and a.hoehe <= 1024 and type(a.plaetze) == "table" then
          z.an = { breite = a.breite, hoehe = a.hoehe, plaetze = {}, kurven = 0 }
          z.st.ansichten[#z.st.ansichten + 1] = z.an
        else
          fehler(z.st, "ansicht " .. z.ai, "ungültig, verworfen")
          z.ai, z.i = z.ai + 1, 1
          z.an = nil
        end
      end
      if z.an then
        local p = a.plaetze[z.i]
        if p == nil or z.i > 16 then
          if p ~= nil then fehler(z.st, "ansicht " .. z.ai, "mehr als 16 Plätze, verworfen") end
          z.ai, z.i, z.an = z.ai + 1, 1, nil
        else
          platz(z, z.an, a, z.i, p)
          z.i = z.i + 1
          n = n + 2                                -- ein Platz kostet etwa dreimal so viel wie ein anderer Eintrag
        end
      end
    end
    n = n + 1
  end
  return false
end

-- Für Tests am Mac: alles in einem Zug
function S.pruefe(d, fk, F, WERTE)
  local z = S.pruefeStart(d, fk, F, WERTE)
  while not S.pruefeSchritt(z) do end
  return z.st
end

-- Einstellungen und Grenzen in w.cfg übernehmen (mit Studio-Datei: Werkwerte, darüber Studio, darüber .funke.lua).
-- Fehlt für einen Lua-Wert der Eintrag in «grenzen», bleiben die Werkgrenzen (ein fehlender Eintrag schaltet nie
-- einen Alarm ab). In einem vorhandenen Eintrag heisst ein fehlendes warnung/alarm: diese Stufe aus; aus = true: beide aus.
-- Sensorzuordnungen (Quellen) bleiben, wie sie im Widget-Speicher stehen.
function S.anwenden(w, st, F, nurStudio)
  local c, std = w.cfg, F.standard()
  for k, v in pairs(std) do c[k] = v end
  for k, v in pairs(nurStudio and st.einS or st.ein) do c[k] = v end
  for k, g in pairs(nurStudio and st.grS or st.gr) do
    local s = k:match("^lua:([%w_]+)$")
    local m = s and S.GRENZ_FELD[s]
    if m then
      local a = st.werte[k] or { faktor = 1, versatz = 0 }
      local function roh(feld, x)
        if x == nil then return 0 end
        local f = F.feld(feld)
        local v = floor(((x - a.versatz) / a.faktor) * 10 ^ m[3] + 0.5)
        if f and f[2] == "z" then v = math.max(f[5], math.min(f[6], v)) end
        return math.max(0, v)
      end
      if not g.werk then
        if m[1] then c[m[1]] = roh(m[1], g.warnung) end
        if m[2] then c[m[2]] = roh(m[2], g.alarm) end
      end
      local mf = S.maFeld(F, s)
      if mf then c[mf] = g.beiMotorAus ~= false end
    end
  end
end

-- Feld «Alarm auch bei Motor aus» zu einem Studio-Schlüssel (ohne «lua:»), aus felder.lua (Eintrag studio = …)
function S.maFeld(F, s)
  if S.MA == nil then
    S.MA = {}
    for _, g in ipairs(F.gruppen) do for _, f in ipairs(g[2]) do if f.studio then S.MA[f.studio] = f[1] end end end
  end
  return S.MA[s]
end

-- ---------------------------------------------------------------- .funke.lua schreiben (Abschnitt 4 und 9)
local function esc(t)
  return '"' .. t:gsub(".", function(ch) return "\\" .. ch:byte() end) .. '"'
end
local function zahl(v)
  if math.type(v) == "integer" then return string.format("%d", v) end
  return string.format("%.4f", v)
end

-- Unterschiede zwischen jetzigen Einstellungen und dem Stand nach der Studio-Datei (basis) als Text der .funke.lua.
-- Einstellungen: nur die geänderten. Grenzen: ist ein Feld einer Grenze geändert, kommt der GANZE Eintrag
-- (warnung, alarm, aus) in die Datei, in der angezeigten Einheit (faktor/versatz aus werte). So schaltet ein
-- fehlendes Feld nie einen Alarm ab, und ein im Studio abgeschalteter Wert wird an der Funke wirklich eingeschaltet.
function S.funkeText(w, F, basis, werte)
  local ein = {}
  local geaendert = {}
  for _, g in ipairs(F.gruppen) do
    for _, f in ipairs(g[2]) do
      local n, art = f[1], f[2]
      local v, b = w.cfg[n], basis[n]
      if art ~= "q" and v ~= nil and v ~= b and not f.alle then
        local gf = f.studio
        for s, m in pairs(S.GRENZ_FELD) do if m[1] == n or m[2] == n then gf = s end end
        if gf then
          geaendert[gf] = true
        elseif art == "z" then
          local x = v / 10 ^ (f[7] or 0)
          if (f[7] or 0) == 0 then x = floor(x) end
          ein[#ein + 1] = snake(n) .. " = " .. zahl(x)
        elseif art == "b" then
          ein[#ein + 1] = snake(n) .. " = " .. (v and "true" or "false")
        elseif art == "w" then
          ein[#ein + 1] = snake(n) .. " = " .. string.format("%d", v)
        elseif art == "t" and type(v) == "string" then
          ein[#ein + 1] = snake(n) .. " = " .. esc(v)
        end
      end
    end
  end
  local g = {}
  for s in pairs(geaendert) do
    local m = S.GRENZ_FELD[s]
    local a = (werte and werte["lua:" .. s]) or { faktor = 1, versatz = 0 }
    local function anz(feld)
      local x = feld and w.cfg[feld]
      if type(x) ~= "number" or x <= 0 then return nil end
      local y = x / 10 ^ m[3] * a.faktor + a.versatz
      if m[3] == 0 and a.faktor == 1 and a.versatz == 0 then y = floor(y) end
      return y
    end
    local wa, al = anz(m[1]), anz(m[2])
    local t = {}
    if wa then t[#t + 1] = "warnung = " .. zahl(wa) end
    if al then t[#t + 1] = "alarm = " .. zahl(al) end
    t[#t + 1] = (wa or al) and "aus = false" or "aus = true"
    local mf = S.maFeld(F, s)                        -- Format 2 §3.5: true hebt ein false der Studio-Datei auf
    if mf and w.cfg[mf] ~= nil then t[#t + 1] = "beiMotorAus = " .. (w.cfg[mf] == false and "false" or "true") end
    g[#g + 1] = "[" .. esc("lua:" .. s) .. "] = { " .. table.concat(t, ", ") .. " }"
  end
  return "return { format = 1, einstellungen = { " .. table.concat(ein, ", ") .. " }, grenzen = { " ..
    table.concat(g, ", ") .. " } }\n"
end

-- Gibt es die Datei?
local function da(p)
  local ok, f = pcall(io.open, p, "r")
  if ok and f then pcall(f.close, f) return true end
  return false
end

-- Schreiben ohne Halbfertiges: .funke.neu schreiben, zurücklesen, alte .funke.lua löschen, umbenennen.
function S.funkeSchreiben(text)
  local _, pf, pn = S.pfade()
  if os.mkdir then pcall(os.mkdir, "SCRIPTS:/studio") end
  local ok, f = pcall(io.open, pn, "w")
  if not ok or not f then return false end
  local ok2 = pcall(f.write, f, text)
  pcall(f.close, f)
  local d = ok2 and studioLaden(pn, S.FORMAT)
  if not d then pcall(os.remove, pn) return false end
  -- os.rename überschreibt in Ethos kein vorhandenes Ziel (X18RS 20.11.): zuerst löschen, dann umbenennen,
  -- Erfolg an den Dateien prüfen (nicht am Rückgabewert)
  if da(pf) then pcall(os.remove, pf) end
  pcall(os.rename, pn, pf)
  return da(pf) and not da(pn)
end

-- «Zurück auf Studio-Stand»: .funke.lua löschen
function S.funkeLoeschen()
  local _, pf, pn = S.pfade()
  if da(pn) then pcall(os.remove, pn) end
  if da(pf) then pcall(os.remove, pf) end
end

-- Übrig gebliebene .funke.neu (Strom weg beim Schreiben): verwenden, wenn .funke.lua fehlt und sie gut ist
function S.funkeAufraeumen()
  local _, pf, pn = S.pfade()
  if not da(pn) then return end                  -- der Normalfall: nichts übrig geblieben
  if da(pf) then pcall(os.remove, pn) return end
  if studioLaden(pn, S.FORMAT) then pcall(os.rename, pn, pf) else pcall(os.remove, pn) end
end

return S
