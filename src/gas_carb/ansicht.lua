-- Gas Engine Carb: Plätze einer Studio-Ansicht zeichnen (Lua-Studio-Format v1, Abschnitte 6.3, 6.4 und 7).
-- Darstellungsarten: zahl, ring, balken_w, balken_s, kurve, status, zylinder, tank. Zeichnet nur; die Werte kommen aus w (Lua-Werte),
-- aus w.studio.q (Sensoren, Kanäle), die Farben aus den Grenzen je Wert (w.studio.gr bzw. den Einstellungen).
local A = {}
local floor, max, min, abs = math.floor, math.max, math.min, math.abs

-- Lua-Wert nach Schlüssel (lua:<s>); Status-Werte geben die Nummer des Zustands zurück
local ZUSTAND = { ["KEINE DATEN"] = 0, ["WARMLAUF"] = 1, ["LÄUFT"] = 2, ["WARNUNG"] = 3, ["ALARM"] = 4 }
local function luaWert(w, s)
  local v, tk = w.v, w.tk
  if s == "rpm" then return v.rpm
  elseif s == "cht_max" then
    local m
    for i = 1, w.nZyl or 2 do local x = v["cht" .. i]; if x and (m == nil or x > m) then m = x end end
    return m
  elseif s:match("^cht%d$") then return v[s]
  elseif s == "cht_diff" then return v.chtDiff
  elseif s == "druck" then return v.druck
  elseif s == "ecu_v" then return v.ecuV
  elseif s == "gas" then return v.gas
  elseif s == "tank_proz" then return tk.proz
  elseif s == "tank_ml" then return tk.rest
  elseif s == "restzeit" then return tk.restMin
  elseif s == "fluss" then return tk.fluss
  elseif s == "verbrauch" then return tk.verbr
  elseif s == "hoehe" then return v.hoehe
  elseif s == "vario" then return v.vario
  elseif s == "speed" then return v.speed
  elseif s == "rssi" then return v.rssi
  elseif s == "rx1_rssi" then return v.rx1R24 or v.rx1R900
  elseif s == "rx2_rssi" then return v.rx2R24 or v.rx2R900
  elseif s == "rx_batt" then return v.rxBatt
  elseif s == "akku_diff" then
    local m
    for i = 1, 3 do local d = w.akku[i].diff; if d and (m == nil or d > m) then m = d end end
    return m
  elseif s == "kanalstrom_max" then return w.rb and w.rb.max
  elseif s == "laufzeit" then return w.sl and w.sl.t
  elseif s == "zustand" then return ZUSTAND[w.zustand]
  elseif s == "zuendung" then
    if v.zuend == nil then return nil end
    if v.choke then return 2 end
    return v.zuend and 1 or 0
  end
  local i, art = s:match("^akku(%d)_(%a+)$")
  if i then
    local a = w.akku[tonumber(i)]
    if art == "zelle" then return a.tief end
    if art == "v" then return a.summe end
  end
  return nil
end

-- Wert eines Schlüssels, angepasst nach 6.4 (faktor, versatz); dazu Einheit, Stellen, Name, Zustände
function A.wert(w, k)
  local st, WERTE = w.studio, w.studio.WERTE
  local art, s = k:match("^(%a+):(.+)$")
  local roh, einh, stellen, name, zust
  if art == "lua" then
    local d = WERTE[s]
    roh = luaWert(w, s)
    if d then
      if d.zustaende then zust = d.zustaende else einh, stellen = d[3], d[4] end
      name = d[(w.sp == 2) and 2 or 1]
    end
  elseif art == "sensor" or art == "kanal" then
    local q = st.q[k]
    if q then
      local ok, x = pcall(q.value, q)
      if ok and type(x) == "number" and x == x then roh = x end
      if art == "kanal" and roh then roh = roh / 10.24 end           -- Kanal in % (−100 … 100)
      if art == "sensor" then
        local okE, e = pcall(q.stringUnit, q); if okE and type(e) == "string" then einh = e end
        local okD, dz = pcall(q.decimals, q); if okD and type(dz) == "number" then stellen = dz end
        local okN, n = pcall(q.name, q); if okN and type(n) == "string" then name = n end
      else
        einh, stellen, name = "%", 0, "CH" .. s
      end
    end
  end
  local a = st.st.werte[k]
  if a and roh and not zust then roh = roh * a.faktor + a.versatz end
  if a then einh = a.einheit or einh; stellen = a.stellen or stellen; name = a.name or name end
  return roh, einh or "", stellen or 0, name or k, zust
end

-- Grenzzustand eines Werts: 0 normal, 1 Warnung, 2 Alarm (in der angezeigten Einheit)
function A.stufe(w, k, x)
  if x == nil then return 0 end
  local g = w.studio.grenze[k]
  if not g then return 0 end
  local function ueber(gw) if gw == nil then return false end if g.richtung == "unter" then return x < gw end return x >= gw end
  if ueber(g.alarm) then return 2 end
  if ueber(g.warnung) then return 1 end
  return 0
end

local function rgb(f, sonst) if f then return lcd.RGB(f[1], f[2], f[3]) end return sonst end

-- Text in die Box einpassen (Z.text verkleinert die Schrift bis zur kleinsten Stufe)
local function zahlText(Z, x, stellen, einh, zust, sp)
  if zust then
    local z = x and zust[floor(x)]
    return z and z[(sp == 2) and 2 or 1] or "--", z and lcd.RGB(z[3], z[4], z[5])
  end
  if x == nil then return nil end
  return Z.zahl(x, stellen) .. ((einh ~= "") and (" " .. einh) or "")
end

-- Zusatzzeile: min/max/mittel über den Flug (je Platz gemerkt)
local function zusatz(w, pl, x)
  if pl.zusatz == "keine" or x == nil then return nil end
  local m = pl.mem
  if m == nil then m = { n = 0, s = 0 }; pl.mem = m end
  if m.t ~= w.tB then                         -- einmal je Bild
    m.t = w.tB
    if m.min == nil or x < m.min then m.min = x end
    if m.max == nil or x > m.max then m.max = x end
    m.n, m.s = m.n + 1, m.s + x
  end
  if pl.zusatz == "min" then return "min", m.min end
  if pl.zusatz == "max" then return "max", m.max end
  return "Ø", m.s / m.n
end

-- Verlauf: höchstens 120 Punkte über kurveS Sekunden
local function kurvePunkt(pl, x, now)
  local k = pl.kurve
  if k == nil then k = { n = 0, i = 0, t = -1e9 }; pl.kurve = k end
  if now - k.t < pl.kurveS / 120 then return k end
  k.t = now
  k.i = k.i % 120 + 1
  k[k.i] = x or false
  if k.n < 120 then k.n = k.n + 1 end
  return k
end

-- Plätze «zylinder» und «tank»: Zeichenroutinen der eingebauten Seite 1 (S1) mit eigener Skalierung.
-- Bezugsgrösse = Spalte der eingebauten Seite im Entwurf 800 x 480; die Schrift wächst höchstens auf das 1,2-Fache.
local GRUPPE = { zylinder = { 247, 356, "ZYLINDER" }, tank = { 247, 316, "KRAFTSTOFF" } }
local function gruppe(w, L, Z, S1, pl, x, y, b, h)
  local r = GRUPPE[pl.darstellung]
  local sp = min(1.2 * L.s, b / r[1], h / r[2])
  local Lp = pl.L
  if Lp == nil or Lp.basis ~= L or Lp.s ~= sp then
    Lp = setmetatable({ s = sp, klein = sp < 0.7, fi = {}, basis = L }, { __index = L })
    pl.L = Lp
  end
  Z.kasten(Lp, x, y, b, h, pl.titel or r[3])
  if pl.darstellung == "zylinder" then S1.zylinder(w, Lp, Z, x, b, y, h)
  else S1.kraftstoff(w, Lp, Z, x, b, y, h, true) end
end

function A.zeichne(w, L, Z, an, dy, S1)
  local C, s = Z.C, L.s
  local now = os.clock()
  for _, pl in ipairs(an.plaetze) do
    local x, y, b, h = pl.x, pl.y + (dy or 0), pl.b, pl.h
    if pl.w == "leer" then goto weiter end
    if GRUPPE[pl.darstellung] then
      if S1 and S1.zylinder then gruppe(w, L, Z, S1, pl, x, y, b, h) end
      goto weiter
    end
    do
      local v, einh, stellen, name, zust = A.wert(w, pl.w)
      local st = A.stufe(w, pl.w, v)
      local fb = rgb(pl.farbe, C.hblau)
      if st == 0 and pl.stufen and v then
        for _, e in ipairs(pl.stufen) do if v >= e.ab then fb = rgb(e.farbe) end end
      end
      if st == 1 then fb = rgb(pl.farbeWarn, lcd.RGB(255, 160, 0)) elseif st == 2 then fb = rgb(pl.farbeAlarm, lcd.RGB(230, 40, 40)) end
      local titel = pl.titel or name
      Z.feld(x, y, b, h, 6 * s, st == 2 and fb or C.rand, rgb(pl.hintergrund, C.panel), st == 2 and max(2, floor(3 * s)) or 1)
      local th = max(15, 16 * s)
      local mi, ma = pl.min or 0, pl.max or 100
      if not pl.min and pl.w:match("^lua:") then
        local d = w.studio.WERTE[pl.w:sub(5)]
        if d and not d.zustaende then mi, ma = d[5], d[6] end
      end
      local anteil = v and min(1, max(0, (v - mi) / (ma - mi))) or 0
      local txt, zf = zahlText(Z, v, stellen, einh, zust, w.sp)
      local wf = (st > 0) and fb or (zf or C.text)
      local zt, zv = zusatz(w, pl, v)
      local zl = zt and (zt .. " " .. Z.zahl(zv, stellen)) or nil
      local d = pl.darstellung
      if zust then d = "status" end
      if d == "zahl" or d == "status" then
        Z.text(L, x + b / 2, y + th * 0.6 + 2 * s, titel, 13, C.dim, CENTERED, b - 8 * s)
        local ym = y + (h + th) / 2 - (zl and 6 * s or 0)
        Z.wert(L, x + b / 2, ym, txt, d == "status" and 20 or 24, d == "status" and (zf or wf) or wf, CENTERED, b - 8 * s)
        if zl then Z.text(L, x + b / 2, y + h - 9 * s, zl, 12, C.dim, CENTERED, b - 8 * s) end
      elseif d == "ring" then
        Z.text(L, x + b / 2, y + 4 * s + th / 2, titel, 13, C.dim, CENTERED, b - 10 * s)
        local oben = y + 6 * s + th
        local r2 = min(b * 0.36, (y + h - oben - 4 * s) * 0.56)
        local r1 = r2 - max(5, floor(r2 * 0.16))
        local cx, cy = x + b / 2, oben + r2 + 2 * s
        Z.bogen(cx, cy, r1, r2, 225, 495, C.rand)
        if anteil > 0 then Z.bogen(cx, cy, r1, r2, 225, 225 + 270 * anteil, fb) end
        Z.wert(L, cx, cy - 2 * s, txt, 22, wf, CENTERED, r1 * 1.8)
        if zl then Z.text(L, cx, cy + r1 * 0.55, zl, 12, C.dim, CENTERED, r1 * 1.6) end
      elseif d == "balken_w" then
        Z.text(L, x + 8 * s, y + th * 0.6 + 2 * s, titel, 13, C.dim, LEFT, b * 0.5)
        Z.wert(L, x + b - 8 * s, y + th * 0.6 + 2 * s, txt, 16, wf, RIGHT, b * 0.5)
        local by, bh = y + th + 6 * s, max(6, h - th - 12 * s - (zl and 12 * s or 0))
        Z.feld(x + 8 * s, by, b - 16 * s, bh, 3 * s, C.grau, C.dunkel)
        if anteil > 0 then Z.rechteck(x + 8 * s + 2, by + 2, (b - 16 * s - 4) * anteil, bh - 4, fb) end
        if zl then Z.text(L, x + b / 2, y + h - 8 * s, zl, 12, C.dim, CENTERED, b - 8 * s) end
      elseif d == "balken_s" then
        Z.text(L, x + b / 2, y + th * 0.6 + 2 * s, titel, 13, C.dim, CENTERED, b - 6 * s)
        local unten = 18 * s + (zl and 12 * s or 0)
        local bw, by = min(b * 0.5, 40 * s), y + th + 6 * s
        local bh = max(6, h - th - 10 * s - unten)
        Z.feld(x + (b - bw) / 2, by, bw, bh, 3 * s, C.grau, C.dunkel)
        if anteil > 0 then Z.rechteck(x + (b - bw) / 2 + 2, by + 2 + (bh - 4) * (1 - anteil), bw - 4, (bh - 4) * anteil, fb) end
        Z.wert(L, x + b / 2, by + bh + 9 * s, txt, 15, wf, CENTERED, b - 6 * s)
        if zl then Z.text(L, x + b / 2, y + h - 7 * s, zl, 12, C.dim, CENTERED, b - 6 * s) end
      elseif d == "kurve" then
        Z.text(L, x + 8 * s, y + th * 0.6 + 2 * s, titel, 13, C.dim, LEFT, b * 0.5)
        Z.wert(L, x + b - 8 * s, y + th * 0.6 + 2 * s, txt, 16, wf, RIGHT, b * 0.5)
        local k = kurvePunkt(pl, v, now)
        local gx, gy, gb, gh = x + 8 * s, y + th + 6 * s, b - 16 * s, h - th - 12 * s
        lcd.color(fb)
        local vx, vy
        for j = 1, k.n do
          local idx = (k.i - k.n + j - 1) % 120 + 1
          local p = k[idx]
          if p then
            local px = gx + gb * (j - 1) / 119
            local py = gy + gh * (1 - min(1, max(0, (p - mi) / (ma - mi))))
            if vx then lcd.drawLine(floor(vx), floor(vy), floor(px), floor(py)) end
            vx, vy = px, py
          else
            vx = nil
          end
        end
      end
    end
    ::weiter::
  end
end

-- Hinweisband unten (8 s), danach ein kleines «!» oben rechts bis zum nächsten Modellwechsel
function A.hinweis(w, L, Z)
  local st = w.studio
  if not st or not st.text then return end
  local C, s = Z.C, L.s
  if os.clock() < st.textBis then
    local hb = max(18, floor(24 * s))
    Z.rechteck(0, L.H - hb, L.W, hb, C.dunkel)
    Z.text(L, L.W / 2, L.H - hb / 2, st.text, 14, C.orange, CENTERED, L.W - 16 * s)
  else
    Z.text(L, L.W - 6 * s, 10 * s, "!", 14, C.orange, RIGHT)
  end
end

return A
