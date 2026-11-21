-- Gas Engine ECU: Seite 1 «Motor» (Zylinder, Drehzahl, Kraftstoff, Fussleiste mit Höhe, Steigen, Geschwindigkeit).
-- Nicht zugewiesene Sensoren werden ausgeblendet; zugewiesene ohne Wert zeigen einen Strich.
local S = {}
local floor, abs, max, min, sin, cos, rad = math.floor, math.abs, math.max, math.min, math.sin, math.cos, math.rad

-- Farbe einer Zylindertemperatur. Ohne eingetragene Grenzwerte bleibt sie neutral.
local function zone(C, g, t)
  if t == nil then return C.grau end
  if not (g.chtKalt or g.chtWarn or g.chtAlarm) then return C.neutral end
  if g.chtAlarm and t >= g.chtAlarm then return C.rot end
  if g.chtWarn and t >= g.chtWarn then return C.orange end
  if g.chtKalt and t < g.chtKalt then return C.blau end
  return C.gruen
end

local function anteil(x, von, bis)
  return min(1, max(0, (x - von) / (bis - von)))
end

local function zylinder(w, L, Z, x0, b, top, h)
  local C, s, v, g, hoch, c = Z.C, L.s, w.v, w.g, w.hoch, w.cfg
  local n = w.nZyl or 2
  local cw, bt, bh = b * (n == 4 and 0.15 or n == 3 and 0.19 or n == 1 and 0.30 or 0.24), top + 64 * s, h * 0.46
  local tg = n == 4 and 20 or n == 3 and 24 or 28                  -- Schriftgrösse der Temperatur
  for i = 1, n do
    local cx = x0 + b * (n == 2 and (i == 1 and 0.27 or 0.73) or (i - 0.5) / n)
    local da = c["cht" .. i]
    local temp = v["cht" .. i]
    local zm = hoch["cht" .. i]
    local farbe = zone(C, g, temp)
    Z.text(L, cx, top + 41 * s, "Z" .. i, 15, C.dim, CENTERED)
    Z.rechteck(cx - 4 * s, bt - 14 * s, 8 * s, 10 * s, C.grau)
    Z.rund(cx - cw * 0.42, bt - 5 * s, cw * 0.84, 8 * s, 3 * s, C.grau)
    for k = 1, 8 do
      Z.rechteck(cx - cw / 2 - 9 * s, bt + 4 * s + bh * k / 9 - 1.5 * s, cw + 18 * s, 3 * s, C.grau)
    end
    Z.feld(cx - cw / 2, bt + 4 * s, cw, bh, 4 * s, C.grau, C.dunkel, max(1, floor(1.5 * s)))
    if temp then
      local fh = (bh - 4) * anteil(temp, g.chtVon, g.chtBis)
      Z.rechteck(cx - cw / 2 + 2, bt + 4 * s + 2 + (bh - 4) - fh, cw - 4, fh, farbe)
    end
    if zm then
      local ym = bt + 4 * s + bh * (1 - anteil(zm, g.chtVon, g.chtBis))
      Z.rechteck(cx - cw / 2 - 3 * s, ym - 1, cw + 6 * s, 2, C.weiss)
    end
    local ty = bt + bh + 30 * s
    if temp then
      local tr = v["trend" .. i] or 0
      local t = Z.zahl(temp, 0) .. "°"
      if tr == 0 then
        Z.text(L, cx, ty, t, tg, farbe, CENTERED, b / n)
      else
        local tb = Z.breite(L, t, tg)
        local x = cx - (tb + 16 * s) / 2
        Z.text(L, x, ty, t, tg, farbe, LEFT)
        Z.pfeil(x + tb + 3 * s, ty, 6 * s, tr, farbe)
      end
    elseif da then
      Z.strich(L, cx, ty, tg, C.grau, CENTERED)
    end
  end
  local teil = {}
  if v.chtDiff then teil[#teil + 1] = "Diff " .. Z.zahl(v.chtDiff, 0) .. "°" end
  local hm
  for i = 1, n do local x = hoch["cht" .. i]; if x and (hm == nil or x > hm) then hm = x end end
  if hm and not L.klein then teil[#teil + 1] = "max " .. Z.zahl(hm, 0) .. "°" end
  if #teil > 0 then
    Z.text(L, x0 + b / 2, top + h - 19 * s, table.concat(teil, "   |   "), 15, v.diffWarn and C.orange or C.dim, CENTERED,
      b - 12 * s)
  end
end

local function drehzahl(w, L, Z, x0, b, top, h)
  local C, s, v, g, hoch = Z.C, L.s, w.v, w.g, w.hoch
  local mitGas = w.cfg.gas ~= nil
  local hh = mitGas and h or h + 30 * s
  local cx, cy = x0 + b / 2, top + hh * 0.47
  local r2 = min(b * 0.42, hh * 0.36)
  local r1 = r2 - 16 * s
  local skala = g.rpmSkala
  -- Bogen über 270 Grad, Lücke unten: Anfang links unten (225 Grad), im Uhrzeigersinn
  local function a(x) return 225 + 270 * min(1, max(0, x / skala)) end
  local warn = g.rpmWarn and min(g.rpmWarn, skala) or nil
  local alarm = g.rpmAlarm and min(g.rpmAlarm, skala) or nil
  local gut = warn or alarm
  local leer = (g.laeuftAb > 0) and min(g.laeuftAb, gut or skala) or 0
  if leer > 0 then Z.bogen(cx, cy, r1, r2, a(0), a(leer), C.grau) end
  Z.bogen(cx, cy, r1, r2, a(leer), a(gut or skala), gut and C.dgruen or C.rand)
  if warn then Z.bogen(cx, cy, r1, r2, a(warn), a(alarm or skala), C.dorange) end
  if alarm then Z.bogen(cx, cy, r1, r2, a(alarm), a(skala), C.drot) end
  local rpm = v.rpm
  local farbe = gut and C.gruen or C.hblau
  if rpm and alarm and rpm >= alarm then farbe = C.rot elseif rpm and warn and rpm >= warn then farbe = C.orange end
  if rpm and rpm > 0 then Z.bogen(cx, cy, r1 + 3 * s, r2 - 3 * s, a(0), a(rpm), farbe) end
  if hoch.rpm then
    local wi = rad(a(hoch.rpm))
    local sx, sy = sin(wi), -cos(wi)
    local ra, rb = r1 - 4 * s, r2 + 5 * s
    lcd.color(C.weiss)
    for d = -1, 1 do
      lcd.drawLine(floor(cx + ra * sx + d * sy), floor(cy + ra * sy - d * sx), floor(cx + rb * sx + d * sy),
        floor(cy + rb * sy - d * sx))
    end
  end
  if rpm then
    Z.text(L, cx, cy - 4 * s, Z.tausend(rpm), 46, farbe == C.gruen and C.text or farbe, CENTERED, r1 * 2 - 8 * s)
  elseif w.cfg.rpm then
    Z.strich(L, cx, cy - 4 * s, 46, C.grau, CENTERED)
  end
  Z.text(L, cx, cy + 31 * s, "U/min", 15, C.dim, CENTERED)
  if hoch.rpm and not L.klein then
    Z.text(L, cx, cy + r2 * 0.86, "max " .. Z.tausend(hoch.rpm), 13, C.dim, CENTERED)
  end
  if mitGas then
    local by, bx, bw, bh = top + h - 30 * s, x0 + 52 * s, b - 122 * s, 16 * s
    Z.text(L, x0 + 12 * s, by + bh / 2, "Gas", 15, C.dim, LEFT)
    Z.feld(bx, by, bw, bh, 4 * s, C.grau, C.dunkel)
    if v.gas then Z.rechteck(bx + 2, by + 2, (bw - 4) * v.gas / 100, bh - 4, C.hblau) end
    Z.wert(L, x0 + b - 10 * s, by + bh / 2, v.gas and (Z.zahl(v.gas, 0) .. " %"), 16, C.text, RIGHT)
  end
end

-- nurTank: ohne Druck (Studio-Platz «tank»)
local function kraftstoff(w, L, Z, x0, b, top, h, nurTank)
  local C, s, v, g, tk, c = Z.C, L.s, w.v, w.g, w.tk, w.cfg
  local unten = top + h
  local y = top + 34 * s
  -- Druck mit Sollbereich (nur wenn ein Drucksensor gewählt ist)
  if c.druck and not nurTank then
    Z.text(L, x0 + 12 * s, y + 11 * s, "Druck", 15, C.dim, LEFT)
    local dx, dw, dy, dh = x0 + 12 * s, b * 0.58, y + 24 * s, 16 * s
    Z.feld(dx, dy, dw, dh, 4 * s, C.grau, C.dunkel)
    local sk = g.druckSkala
    if g.druckVon then
      local a0 = min(1, g.druckVon / sk)
      local a1 = g.druckBis and min(1, g.druckBis / sk) or 1
      if a1 > a0 then Z.rechteck(dx + 1 + (dw - 2) * a0, dy + 1, (dw - 2) * (a1 - a0), dh - 2, C.dgruen) end
    end
    local druck = v.druck
    local df = g.druckVon and C.gruen or C.hblau
    local m = w.meld
    if (m.druckA and m.druckA.an) then df = C.rot elseif (m.druckW and m.druckW.an) then df = C.orange end
    if druck then
      Z.rechteck(dx + 2, dy + 2, (dw - 4) * min(1, max(0, druck / sk)), dh - 4, df)
      Z.text(L, x0 + b - 10 * s, dy + dh / 2, Z.zahl(druck, w.dz.druck or 1) .. " " .. (w.eh.druck or ""), 17,
        df == C.hblau and C.text or df, RIGHT, b - dw - 30 * s)
    else
      Z.strich(L, x0 + b - 10 * s, dy + dh / 2, 17, C.grau, RIGHT)
    end
    y = dy + dh + 24 * s
  else
    y = y + 16 * s
  end
  -- Tank
  local kh = 34 * s                                   -- Knopf «VOLLGETANKT»
  local tx, tw = x0 + 14 * s, 46 * s
  local th = unten - y - 14 * s
  local proz = tk.proz
  local tf = C.neutral
  if proz and (g.tankRes or g.tankLeer) then
    local m = w.meld
    tf = (m.tankLeer and m.tankLeer.an) and C.rot or ((m.tankRes and m.tankRes.an) and C.orange or C.gruen)
  end
  Z.feld(tx, y, tw, th, 6 * s, C.grau, C.dunkel, max(1, floor(1.5 * s)))
  if proz then
    local fh = (th - 6) * proz / 100
    Z.rechteck(tx + 3, y + 3 + (th - 6) - fh, tw - 6, fh, tf)
  end
  if g.tankRes then
    local ry = floor(y + th * (1 - g.tankRes / 100))
    local x, xe = floor(tx - 4 * s), floor(tx + tw + 4 * s)
    lcd.color(C.orange)
    while x < xe do
      lcd.drawFilledRectangle(x, ry, min(4, xe - x), max(1, floor(1.5 * s)))
      x = x + 7
    end
  end
  local lx = tx + tw + 14 * s
  local lb = x0 + b - lx - 8 * s
  local ly = y + 13 * s
  if g.tank then
    Z.wert(L, lx, ly, proz and (Z.zahl(proz, 0) .. " %"), 26, tf, LEFT, lb)
    ly = ly + 29 * s
    Z.wert(L, lx, ly, tk.rest and (Z.zahl(tk.rest, 0) .. " ml"), 16, C.text, LEFT, lb)
    ly = ly + 28 * s
  else
    Z.text(L, lx, ly, "Tankinhalt", 14, C.dim, LEFT, lb)
    ly = ly + 22 * s
    Z.text(L, lx, ly, "im Menü setzen", 14, C.dim, LEFT, lb)
    ly = ly + 35 * s
  end
  local quelle = c.impulse or c.fluss
  if quelle then
    Z.text(L, lx, ly, "Verbr. " .. Z.zahl(tk.verbr, 0) .. " ml", 15, C.text, LEFT, lb)
    if not L.klein then
      ly = ly + 22 * s
      local fb = Z.text(L, lx, ly, "Fluss ", 15, C.text, LEFT)
      if tk.fluss then
        Z.text(L, lx + fb, ly, Z.zahl(tk.fluss, 0) .. " ml/min", 15, C.text, LEFT, lb - fb)
      else
        Z.strich(L, lx + fb + 2 * s, ly, 15, C.grau, LEFT)
      end
    end
    ly = ly + 30 * s
    Z.text(L, lx, ly, "Restzeit", 14, C.dim, LEFT, lb)
    ly = ly + 22 * s
    Z.wert(L, lx, ly, tk.restMin and ("ca. " .. Z.zahl(tk.restMin, 0) .. " min"), 19, C.text, LEFT, lb)
  end
  -- Knopf (Rückfrage folgt; ein einzelnes Antippen ändert nichts)
  Z.knopf(w, L, "vollgetankt", lx - 4 * s, unten - kh - 12 * s, x0 + b - lx - 8 * s, kh, "VOLLGETANKT", C.hblau, false, 15)
end

local FUSS = { "hoehe", "vario", "speed" }

local function fuss(w, L, Z)
  local C, s, v, hoch, gp, c = Z.C, L.s, w.v, w.hoch, L.gp, w.cfg
  local teile = {}
  for _, k in ipairs(FUSS) do
    if c[k] then teile[#teile + 1] = k end
  end
  local n = #teile
  if n == 0 then return end
  local fy = L.H - L.fuss
  Z.feld(gp, fy, L.W - 2 * gp, L.fuss - gp, 10 * s, C.rand, C.panel)
  local tb = (L.W - 2 * gp) / n
  for i = 1, n do
    local k = teile[i]
    local mx = gp + tb * (i - 1) + tb / 2
    if i > 1 then Z.rechteck(gp + tb * (i - 1), fy + 10 * s, 1, L.fuss - gp - 20 * s, C.rand) end
    local ym = fy + 39 * s
    if k == "hoehe" then
      Z.text(L, mx, fy + 17 * s, "Höhe", 13, C.dim, CENTERED)
      local t = v.hoehe and (Z.zahl(v.hoehe, 0) .. " " .. (w.eh.hoehe or ""))
      if t and hoch.hoehe and not L.klein then t = t .. "  (max " .. Z.zahl(hoch.hoehe, 0) .. ")" end
      Z.wert(L, mx, ym, t, 22, C.text, CENTERED, tb - 12 * s)
    elseif k == "vario" then
      Z.text(L, mx, fy + 17 * s, "Steigen", 13, C.dim, CENTERED)
      if v.vario then
        local t = Z.zahl(v.vario, w.dz.vario or 1)
        if v.vario > 0 then t = "+" .. t end
        if not L.klein then t = t .. " " .. (w.eh.vario or "") end
        local r = (v.vario > 0.05) and 1 or ((v.vario < -0.05) and -1 or 0)
        if r == 0 then
          Z.text(L, mx, ym, t, 22, C.text, CENTERED, tb - 12 * s)
        else
          local b = Z.text(L, mx + 10 * s, ym, t, 22, C.text, CENTERED, tb - 40 * s)
          Z.pfeil(mx + 10 * s - b / 2 - 20 * s, ym, 6 * s, r, C.text)
        end
      else
        Z.strich(L, mx, ym, 22, C.grau, CENTERED)
      end
    else
      Z.text(L, mx, fy + 17 * s, "Speed", 13, C.dim, CENTERED)
      Z.wert(L, mx, ym, v.speed and (Z.zahl(v.speed, 0) .. " " .. (w.eh.speed or "")), 22, C.text, CENTERED, tb - 12 * s)
    end
  end
end

function S.zeichne(w, L, Z)
  local W, top, gp, c = L.W, L.top, L.gp, w.cfg
  local mitFuss = c.hoehe or c.vario or c.speed
  local unten = mitFuss and L.unten or (L.H - gp)
  local h = unten - top
  local c1, c2 = W * 0.32, W * 0.36
  local c3 = W - c1 - c2
  local x1, b1 = gp, c1 - 1.5 * gp
  local x2, b2 = c1 + gp / 2, c2 - gp
  local x3, b3 = c1 + c2 + gp / 2, c3 - 1.5 * gp
  Z.kasten(L, x1, top, b1, h, "ZYLINDER")
  Z.kasten(L, x2, top, b2, h, "DREHZAHL")
  Z.kasten(L, x3, top, b3, h, "KRAFTSTOFF")
  zylinder(w, L, Z, x1, b1, top, h)
  drehzahl(w, L, Z, x2, b2, top, h)
  kraftstoff(w, L, Z, x3, b3, top, h)
  if mitFuss then fuss(w, L, Z) end
end

-- Für Studio-Plätze «zylinder» und «tank» (ansicht.lua)
S.zylinder, S.kraftstoff = zylinder, kraftstoff

return S
