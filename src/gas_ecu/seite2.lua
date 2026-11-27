-- Gas Engine ECU: Seite 2 «Elektrik» (bis 3 Akkus als Spalten, Stromweiche falls vorhanden, Empfang, Empfängerspannung).
-- Nicht zugewiesene Teile werden ausgeblendet; zugewiesene ohne Wert zeigen einen Strich.
local S = {}
local floor, max, min = math.floor, math.max, math.min

local function zellFarbe(C, g, i, z)
  if z == nil then return C.grau end
  local wa, al = g.zWarn[i], g.zAlarm[i]
  if al and z < al then return C.rot end
  if wa and z < wa then return C.orange end
  if wa or al then return C.gruen end
  return C.neutral
end

-- Ein Akku als Spalte: Name und Zellenzahl, Gesamtspannung, je Zelle ein senkrechter Balken mit Wert darunter
-- (bis 4 Zellen eine Reihe, 5 und 6 Zellen zwei Reihen zu 3), unten der Unterschied der Zellen.
local function akku(w, L, Z, i, x0, y0, b, h)
  local C, s, g, a = Z.C, L.s, w.g, w.akku[i]
  local kl = L.klein
  local f = (a.alarm and C.rot) or (a.warn and C.orange) or nil
  Z.feld(x0, y0, b, h, 10 * s, f or C.rand, C.panel, f and max(2, floor(2 * s)) or 1)
  local name = (g.aName and g.aName[i]) or ("AKKU " .. i)
  local an = a.n or 0                                     -- vor dem ersten wakeup noch ohne Zellenzahl
  local nS = an > 0 and an or (g.aS and g.aS[i] or 0)
  local kopfY = y0 + max(12, 16 * s)                      -- auf kleinen Anzeigen nicht auf den Rand
  Z.text(L, x0 + 10 * s, kopfY, name, kl and 12 or 14, C.dim, LEFT, b - (nS > 0 and 44 or 20) * s)
  if nS > 0 then Z.text(L, x0 + b - 10 * s, kopfY, nS .. "S", kl and 12 or 14, C.dim, RIGHT) end
  local n = an
  if n == 0 then
    -- nur Gesamtspannung (kein Zellensensor): Gesamtspannung oben, EIN Balken mit der mittleren Zelle
    -- (Gesamt / Zellenzahl aus dem Menü), darunter der Mittelwert; ohne Zellenzahl ein Hinweis
    Z.wert(L, x0 + b / 2, y0 + max(29, 44 * s), a.summe and (Z.zahl(a.summe, 2) .. " V"), kl and 20 or 26, f or C.text, CENTERED, b - 16 * s)
    if not a.summe then return end
    local fuss = max(17, 22 * s)
    local by, bh = y0 + max(44, 66 * s) + 2 * s, h - max(44, 66 * s) - fuss - (kl and 18 or 26) * s
    local bw = min(b * 0.3, 56 * s)
    local cx = x0 + b / 2
    local z = a.mittel
    local zf = zellFarbe(C, g, i, z)
    Z.feld(cx - bw / 2, by, bw, bh, 4 * s, C.grau, C.dunkel, max(1, floor(1.5 * s)))
    if z then
      local lo, hi = g.zLeerA and g.zLeerA[i] or g.zLeer, g.zVollA and g.zVollA[i] or g.zVoll
      local an = min(1, max(0, (z - lo) / (hi - lo)))
      Z.rechteck(cx - bw / 2 + 3, by + 3 + (bh - 6) * (1 - an), bw - 6, (bh - 6) * an, zf)
      Z.text(L, cx, by + bh + (kl and 10 or 13) * s, "Ø " .. Z.zahl(z, 2) .. " V je Zelle", kl and 12 or 14,
        (zf == C.grau or zf == C.neutral) and C.text or zf, CENTERED, b - 16 * s)
    else
      Z.text(L, cx, by + bh + (kl and 10 or 13) * s, "Zellenzahl im Menü wählen", kl and 12 or 14, C.dim, CENTERED, b - 16 * s)
    end
    return
  end
  Z.wert(L, x0 + b / 2, y0 + max(29, 44 * s), a.summe and (Z.zahl(a.summe, 2) .. " V"), kl and 20 or 26, f or C.text, CENTERED, b - 16 * s)
  local reihen = n >= 5 and 2 or 1
  local je = reihen == 2 and 3 or n
  local fuss = max(17, 22 * s)                      -- Platz für den Unterschied unten
  local yb0, yb1 = y0 + max(44, 66 * s), y0 + h - fuss
  local rhh = (yb1 - yb0) / reihen
  local zw = (kl and 22 or 24) * s                         -- Platz für den Zellenwert unter dem Balken
  local sp = (b - 16 * s) / je
  local bw = min(sp * 0.62, 44 * s)
  for k = 1, n do
    local r, col = floor((k - 1) / je), (k - 1) % je
    local z = a[k]
    local zf = zellFarbe(C, g, i, z)
    local cx = x0 + 8 * s + sp * (col + 0.5)
    local by = yb0 + rhh * r + 2 * s
    local bh = rhh - zw - 2 * s
    Z.feld(cx - bw / 2, by, bw, bh, 4 * s, C.grau, C.dunkel, max(1, floor(1.5 * s)))
    if z then
      local lo, hi = g.zLeerA and g.zLeerA[i] or g.zLeer, g.zVollA and g.zVollA[i] or g.zVoll
      local an = min(1, max(0, (z - lo) / (hi - lo)))
      local fh = (bh - 6) * an
      Z.rechteck(cx - bw / 2 + 3, by + 3 + (bh - 6) - fh, bw - 6, fh, zf)
    end
    Z.wert(L, cx, by + bh + zw / 2, z and Z.zahl(z, 2), kl and 12 or 14, (zf == C.grau or zf == C.neutral) and C.text or zf, CENTERED, sp - 2)
  end
  if a.diff then
    Z.text(L, x0 + b / 2, y0 + h - fuss / 2 - 1 * s, "Δ " .. Z.zahl(a.diff, 2) .. " V", kl and 12 or 13,
      a.warnDiff and C.orange or C.dim, CENTERED, b - 16 * s)
  end
end

local function kanaele(w, L, Z, x0, y0, b, h)
  local C, s, g, rb, v, c = Z.C, L.s, w.g, w.rb, w.v, w.cfg
  Z.feld(x0, y0, b, h, 10 * s, C.rand, C.panel)
  local tb = Z.text(L, x0 + 14 * s, y0 + 18 * s, L.klein and "STROMWEICHE" or "STROMWEICHE (KANALSTRÖME)", 14, C.dim, LEFT, b * 0.5)
  -- rechts oben: Zustand zuerst (bleibt bei Platzmangel stehen), dann Bat1 / Bat2 Spannung, soweit gewählt
  local teile = {}
  if c.rbState or c.rbChState then
    teile[1] = "Zustand " .. ((v.rbState == nil and v.rbCh == nil) and "--" or (w.rbFehler and "FEHLER" or "OK"))
  end
  for k = 1, 2 do
    local u, i = v["bat" .. k .. "V"], v["bat" .. k .. "A"]
    if c["bat" .. k .. "V"] or c["bat" .. k .. "A"] then
      teile[#teile + 1] = "Bat" .. k .. " " .. (u and (Z.zahl(u, 2) .. " V") or "--") .. (i and (" " .. Z.zahl(i, 1) .. " A") or "")
    end
  end
  -- nur zeigen, wenn es neben den Titel passt (sonst würde es ihn überdecken)
  local platz = b - tb - 40 * s
  while #teile > 0 and Z.breite(L, table.concat(teile, "  "), 14) > platz do teile[#teile] = nil end
  if #teile > 0 then
    Z.text(L, x0 + b - 12 * s, y0 + 18 * s, table.concat(teile, "  "), 14, C.text, RIGHT)
  end
  local da = false
  for k = 1, 8 do if c["rbK" .. k] then da = true end end
  if not da then
    if #teile == 0 then Z.text(L, x0 + b / 2, y0 + h / 2 + 8 * s, "Keine Kanalströme gewählt", 15, C.dim, CENTERED, b - 20 * s) end
    return
  end
  local skala = g.kAlarm or (g.kWarn and g.kWarn * 1.5) or max(2, rb.spitze or 0)
  local sp = (b - 20 * s) / 8
  local bw = min(sp * 0.5, 40 * s)
  local by, bh = y0 + 38 * s, h - 38 * s - 34 * s
  for k = 1, 8 do
    local cx = x0 + 10 * s + sp * (k - 0.5)
    if c["rbK" .. k] then
      local x = rb.k[k]
      local f = C.hblau
      if x and g.kAlarm and x > g.kAlarm then f = C.rot elseif x and g.kWarn and x > g.kWarn then f = C.orange end
      Z.feld(cx - bw / 2, by, bw, bh, 4 * s, C.grau, C.dunkel)
      if x then
        local fh = (bh - 6) * min(1, max(0, x / skala))
        Z.rechteck(cx - bw / 2 + 3, by + 3 + (bh - 6) - fh, bw - 6, max(fh, 2), f)
      end
      Z.text(L, cx, by + bh + 14 * s, "K" .. k, 14, C.dim, CENTERED)
    end
  end
end

local function empfang(w, L, Z, x0, y0, b, h)
  local C, s, g, v, c = Z.C, L.s, w.g, w.v, w.cfg
  Z.feld(x0, y0, b, h, 10 * s, C.rand, C.panel)
  Z.text(L, x0 + 14 * s, y0 + 18 * s, "EMPFANG", 14, C.dim, LEFT, b - 28 * s)
  local reihen = {}
  for i = 1, 2 do
    local p = "rx" .. i
    if c[p .. "R24"] or c[p .. "R900"] or c[p .. "Vfr"] then reihen[#reihen + 1] = i end
  end
  if #reihen == 0 then
    Z.text(L, x0 + b / 2, y0 + h / 2 + 8 * s, "Keine Empfangssensoren gewählt", 15, C.dim, CENTERED, b - 20 * s)
    return
  end
  local rh = (h - 40 * s) / 2
  local klein = L.klein
  for r, i in ipairs(reihen) do
    local p = "rx" .. i
    local ym = y0 + 40 * s + rh * (r - 0.5)
    Z.text(L, x0 + 14 * s, ym + 6 * s, "RX" .. i, 22, C.text, LEFT)
    local x = x0 + 70 * s
    local vfrB = klein and 0 or 110 * s
    local feld = (b - (x - x0) - vfrB - 10 * s) / 2
    for _, band in ipairs({ { "R24", "2,4 GHz" }, { "R900", "900 MHz" } }) do
      if c[p .. band[1]] then
        local wert = v[p .. band[1]]
        local f = C.gruen
        if wert and g.rssiAlarm and wert < g.rssiAlarm then f = C.rot elseif wert and g.rssiWarn and wert < g.rssiWarn then f = C.orange end
        if not (g.rssiWarn or g.rssiAlarm) then f = C.hblau end
        Z.text(L, x, ym - 14 * s, band[2], 13, C.dim, LEFT)
        local bw = feld - Z.breite(L, "100", 22) - 14 * s     -- Platz für drei Stellen, sonst überlappt «100» den Balken
        Z.feld(x, ym + 1 * s, bw, 14 * s, 3 * s, C.grau, C.dunkel)
        if wert then Z.rechteck(x + 2, ym + 1 * s + 2, (bw - 4) * min(1, max(0, wert / 100)), 14 * s - 4, f) end
        Z.wert(L, x + feld - 8 * s, ym + 8 * s, wert and Z.zahl(wert, 0), 22, f, RIGHT)
      end
      x = x + feld
    end
    if not klein and c[p .. "Vfr"] then
      local vf = v[p .. "Vfr"]
      Z.wert(L, x0 + b - 12 * s, ym + 8 * s, vf and ("VFR " .. Z.zahl(vf, 0) .. " %"), 16, C.text, RIGHT, vfrB)
    end
  end
end

function S.zeichne(w, L, Z)
  local C, W, H, top, gp, s, c = Z.C, L.W, L.H, L.top, L.gp, L.s, w.cfg
  top = top + floor(30 * s)          -- Platz für die Meldezeile, sonst verdeckt sie den Namen des ersten Akkus
  local akkus = {}
  for i = 1, 3 do if c["lipo" .. i] then akkus[#akkus + 1] = i end end
  local unten = H - gp
  local na = #akkus
  -- Akkus als Spalten nebeneinander
  local hOben = na > 0 and (unten - top) * 0.64 or (unten - top) * 0.3
  if na == 0 then
    Z.feld(gp, top, W - 2 * gp, hOben, 10 * s, C.rand, C.panel)
    Z.text(L, W / 2, top + hOben / 2, "Keine Akkus gewählt", 18, C.dim, CENTERED, W - 40 * s)
  else
    local bA = (W - gp * (na + 1)) / na
    for k, i in ipairs(akkus) do akku(w, L, Z, i, gp + (bA + gp) * (k - 1), top, bA, hOben) end
  end
  local yU = top + hOben + gp
  local hU = unten - yU
  -- untere Reihe: Stromweiche nur, wenn dafür etwas gewählt ist; Empfang; Empfängerspannung als kleine Karte
  local rb = c.bat1V or c.bat1A or c.bat2V or c.bat2A or c.rbState or c.rbChState
  for k = 1, 8 do rb = rb or c["rbK" .. k] end
  -- kleine Karten: Empfängerspannung, und ein alter Zündakku, der keinen freien Akku fand
  local karten = {}
  if c.rxBatt then karten[#karten + 1] = { "RXBATT", w.v.rxBatt } end
  if c.zuendAkku then karten[#karten + 1] = { "ZÜNDAKKU", w.v.zuendAkku } end
  local rx = false
  for i = 1, 2 do for _, k in ipairs({ "R24", "R900", "Vfr" }) do rx = rx or c["rx" .. i .. k] ~= nil end end
  local bZ = 150 * s
  local rest = W - 2 * gp - #karten * (bZ + gp)
  if not rx and not rb and #karten > 0 then
    -- ohne Empfang und Stromweiche die Karten über die ganze Breite verteilen
    bZ = (W - gp * (#karten + 1)) / #karten
    rest = 0
  end
  local x = gp
  if rb then
    local bK = rx and (rest - gp) * 0.5 or rest           -- ohne Empfang bekommt die Stromweiche den ganzen Platz
    kanaele(w, L, Z, x, yU, bK, hU)
    x = x + bK + gp
    rest = rest - bK - gp
  end
  if rx or (not rb and #karten == 0) then
    empfang(w, L, Z, x, yU, rest, hU)                -- ohne jeden Sensor bleibt der Hinweis stehen
    x = x + rest + gp
  elseif rb then
    x = x + rest + gp
  end
  for _, k in ipairs(karten) do
    Z.feld(x, yU, bZ, hU, 10 * s, C.rand, C.panel)
    Z.text(L, x + bZ / 2, yU + 18 * s, k[1], 14, C.dim, CENTERED, bZ - 10 * s)
    Z.wert(L, x + bZ / 2, yU + hU / 2 + 6 * s, k[2] and (Z.zahl(k[2], 2) .. " V"), 26, C.text, CENTERED, bZ - 10 * s)
    x = x + bZ + gp
  end
end

return S
