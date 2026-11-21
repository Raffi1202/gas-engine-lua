-- Gas Engine ECU: Kompaktansicht für das Ethos-Layout «ein Widget mit Kopf- und Fussleiste» (gemessen 784 x 316 bei
-- X20/X18RS, 630 x 258 bei X14, 472 x 210 bei X18 und Twin X Lite). Der Kern lädt diese Datei statt der Seiten,
-- sobald das Fenster flacher als 1:2 ist. Modellname und Senderakku zeigt Ethos in seiner Kopfzeile.
-- Aufbau wie bei den anderen Luas: oben eine schmale Leiste (Motorlaufzeit des Flugs, Zustand, Zündung, Choke,
-- Empfang; Warnungen und Hinweise ersetzen die Pillen), darunter 4 Ringe (Drehzahl, heissester Zylinder, Tank,
-- Akku) und 8 Felder in zwei Reihen. Zeichnet nur. Texte deutsch, Englisch übersetzt Z.text (texte.lua).
-- Gleiche Datei bei Gas Engine ECU und Gas Engine Carb: Felder ohne Sensor (z. B. Druck beim Vergaser) werden ersetzt.
local K = {}
local floor, max, min, abs = math.floor, math.max, math.min, math.abs

local function anteil(x, von, bis)
  if x == nil or bis == nil or von == nil or bis <= von then return 0 end
  return min(1, max(0, (x - von) / (bis - von)))
end

-- Schmale Leiste oben (auch für Studio-Ansichten in der Kompaktgrösse)
local function leiste(w, L, Z, sb)
  local C, s, W, v = Z.C, L.s, L.W, w.v
  Z.rechteck(0, 0, W, sb, C.panel)
  local x = 8 * s
  -- Motorlaufzeit des laufenden Flugs links
  local zt = Z.zeit(w.sl and w.sl.t or 0)
  Z.text(L, x, sb / 2, zt, 22, C.text, LEFT)
  x = x + Z.breite(L, zt, 22) + 12 * s
  -- Empfang rechts
  local rt = v.rssi and ((L.klein and "" or "Empfang ") .. Z.zahl(v.rssi, 0) .. " " .. (w.eh.rssi or "")) or nil
  local rb = 0
  if rt then
    rb = Z.breite(L, rt, 16)
    Z.text(L, W - 8 * s, sb / 2, rt, 16, C.text, RIGHT)
  end
  local rest = W - 8 * s - rb - 12 * s
  local ph = max(18, floor(sb - 10 * s))
  local py = floor((sb - ph) / 2)
  local gr = ph * 0.92 / (1.25 * s)
  -- Warnung oder Hinweis statt der Pillen
  local mt, mf, tf
  if (w.nAktiv or 0) > 0 and w.meldText and w.meldText ~= "" then
    mt, mf, tf = w.meldText, w.stufe == 2 and C.rot or C.orange, C.dunkel
  elseif w.hinweis then
    mt, mf, tf = w.hinweis, C.blau, C.weiss or C.text
  end
  if mt and rest - x > 40 then
    -- zu lang: hintere Meldungen weglassen (wichtigste stehen vorne), sonst Zeichen kürzen
    local platz = rest - x - 14 * s
    while Z.breite(L, mt, 12) > platz and mt:find(" | ", 1, true) do
      mt = mt:gsub(" | [^|]*$", "")
    end
    while #mt > 4 and Z.breite(L, mt, 12) > platz do
      local p = #mt - 1
      while p > 1 and mt:byte(p) >= 0x80 and mt:byte(p) < 0xC0 do p = p - 1 end
      mt = mt:sub(1, p - 1)
    end
    Z.rund(x, py, rest - x, ph, ph / 2, mf)
    Z.text(L, x + (rest - x) / 2, sb / 2, mt, 16, tf, CENTERED, rest - x - 12 * s)
    return
  end
  local ab = max(4, floor(6 * s))
  local function pille(t, fb, voll, mind)
    local b = max(mind or 0, Z.breite(L, t, gr) + ph * 0.8)
    if x + b > rest then b = rest - x end
    if b < ph * 1.5 then return end
    Z.pille(L, x, py, b, ph, t, fb, voll, gr)
    x = x + b + ab
  end
  pille(w.zustand or "", Z.zustandFarbe(w.zustand), not (w.stufe == 2 and w.blink), 90 * s)
  if v.zuend ~= nil then
    pille(v.zuend and "ZÜND. EIN" or "ZÜND. AUS", v.zuend and C.rot or C.grau, false)
  end
  if v.choke then
    pille(w.chokeWarn and "CHOKE AUS!" or "CHOKE", w.chokeWarn and C.orange or C.blau, w.chokeWarn)
  end
end

-- Ring: Titel oben, Bogen von 225° bis 135° (unten offen), Wert in der Mitte, zweite Zeile darunter.
local function ring(L, Z, x, y, b, h, titel, wert, zweit, fw, a, fb, rand)
  local C, s = Z.C, L.s
  Z.feld(x, y, b, h, 8 * s, rand or C.rand, C.panel, rand and max(2, floor(3 * s)) or 1)
  local th = max(16 * s, 15)
  Z.text(L, x + b / 2, y + 4 * s + th / 2, titel, 13, C.dim, CENTERED, b - 10 * s)
  local oben = y + 6 * s + th
  local r2 = min(b * 0.36, (y + h - oben - 4 * s) * 0.56)
  local d = max(5, floor(r2 * 0.16))
  local r1 = r2 - d
  local cx, cy = x + b / 2, oben + r2 + 2 * s
  Z.bogen(cx, cy, r1, r2, 225, 495, C.rand)
  if a and a > 0 then Z.bogen(cx, cy, r1, r2, 225, 225 + 270 * min(1, a), fb) end
  Z.wert(L, cx, cy - 2 * s, wert, 24, fw, CENTERED, r1 * 1.8)
  if zweit then Z.text(L, cx, cy + r1 * 0.55, zweit, 12, C.dim, CENTERED, r1 * 1.6) end
end

-- Feld: Beschriftung oben, Wert darunter
local function feld(L, Z, x, y, b, h, titel, wert, fw)
  local C, s = Z.C, L.s
  Z.feld(x, y, b, h, 6 * s, C.rand, C.panel, 1)
  Z.text(L, x + b / 2, y + h * 0.3, titel, 13, C.dim, CENTERED, b - 10 * s)
  Z.wert(L, x + b / 2, y + h * 0.68, wert, 22, fw or C.text, CENTERED, b - 10 * s)
end

-- Akkuname der Seite 2 (gross) in der Schreibweise der übrigen Titel
local NAME = { ["EMPFÄNGER"] = "Empfänger", ["ZÜNDUNG"] = "Zündung", ["ANLASSER"] = "Anlasser", ["ECU-AKKU"] = "ECU-Akku", ["AKKU"] = "Akku" }
local function titel(t)
  return (t:gsub("[%a\128-\255%-]+", function(wd) return NAME[wd] end))
end

-- Farbe nach Warnung (orange) und Alarm (rot), sonst normal
local function stand(C, wert, warn, alarm, unter, normal)
  if wert == nil then return normal end
  local function ueber(gw) if gw == nil then return false end if unter then return wert < gw end return wert >= gw end
  if ueber(alarm) then return C.rot end
  if ueber(warn) then return C.orange end
  return normal
end

function K.zeichne(w, L, Z)
  local C, W, H, s, v, g, c, tk = Z.C, L.W, L.H, L.s, w.v, w.g, w.cfg, w.tk
  local gp = max(3, floor(5 * s))
  local sb = floor(36 * s)
  leiste(w, L, Z, sb)

  -- Ringe
  local y1 = sb + gp
  local hr = floor((H - y1 - 3 * gp) * 0.52)
  local br = (W - 5 * gp) / 4
  -- 1 Drehzahl
  local rf = stand(C, v.rpm, g.rpmWarn, g.rpmAlarm, false, C.text)
  ring(L, Z, gp, y1, br, hr, "Drehzahl", v.rpm and Z.tausend(v.rpm), "U/min", rf, anteil(v.rpm, 0, g.rpmSkala),
    rf == C.text and C.hblau or rf, rf == C.rot and C.rot or nil)
  -- 2 heissester Zylinder
  local zmax, zi
  for i = 1, w.nZyl or 2 do
    local x = v["cht" .. i]
    if x and (zmax == nil or x > zmax) then zmax, zi = x, i end
  end
  local zf = stand(C, zmax, g.chtWarn, g.chtAlarm, false, C.text)
  ring(L, Z, 2 * gp + br, y1, br, hr, "Zylinder max", zmax and (Z.zahl(zmax, 0) .. "°"), zi and ("Z" .. zi),
    zf, anteil(zmax, g.chtVon, g.chtBis), zf == C.text and C.gruen or zf, zf == C.rot and C.rot or nil)
  -- 3 Tank (ohne Tankinhalt: Verbrauch ohne Bogen)
  local tf = stand(C, tk.proz, g.tankRes, g.tankLeer, true, C.text)
  if g.tank then
    ring(L, Z, 3 * gp + 2 * br, y1, br, hr, "Tank", tk.proz and (Z.zahl(tk.proz, 0) .. " %"),
      tk.restMin and (Z.zahl(tk.restMin, 0) .. " min") or (Z.zahl(tk.rest or 0, 0) .. " ml"),
      tf, tk.proz and tk.proz / 100 or 0, tf == C.text and C.gruen or tf, tf == C.rot and C.rot or nil)
  else
    ring(L, Z, 3 * gp + 2 * br, y1, br, hr, "Verbrauch", Z.zahl(tk.verbr or 0, 0), "ml", C.text, 0, C.gruen)
  end
  -- 4 erster Akku, der einen Wert liefert (tiefste Zelle oder Mittelwert je Zelle); sonst Empfängerspannung,
  -- sonst der erste zugewiesene Akku (zeigt dann einen Strich)
  local ai
  for i = 1, 3 do if c["lipo" .. i] ~= nil and ai == nil and w.akku[i].tief then ai = i end end
  if ai == nil and not v.rxBatt then
    for i = 1, 3 do if c["lipo" .. i] ~= nil and ai == nil then ai = i end end
  end
  if ai then
    local a = w.akku[ai]
    local af = (a.alarm and C.rot) or (a.warn and C.orange) or C.text
    local lo, hi = g.zLeerA and g.zLeerA[ai] or g.zLeer, g.zVollA and g.zVollA[ai] or g.zVoll
    ring(L, Z, 4 * gp + 3 * br, y1, br, hr, titel((g.aName and g.aName[ai]) or ("Akku " .. ai)),
      a.tief and (Z.zahl(a.tief, 2) .. " V"), a.summe and (Z.zahl(a.summe, 1) .. " V"), af, anteil(a.tief, lo, hi),
      af == C.text and C.gruen or af, af == C.rot and C.rot or nil)
  else
    ring(L, Z, 4 * gp + 3 * br, y1, br, hr, "RxBatt", v.rxBatt and (Z.zahl(v.rxBatt, 2) .. " V"), nil, C.text, 0, C.gruen)
  end

  -- Felder: zwei Reihen zu vier; ECU-Werte nur, wenn ein Sensor gewählt ist
  local y2 = y1 + hr + gp
  local hf = floor((H - y2 - 2 * gp) / 2)
  local felder = {}
  local function add(t, wert, fw) felder[#felder + 1] = { t, wert, fw } end
  if c.druck then
    add("Druck", v.druck and (Z.zahl(v.druck, w.dz.druck or 1) .. " " .. (w.eh.druck or "")),
      stand(C, v.druck, g.druckVon, g.druckAlarm, true, C.text))
  end
  if c.ecuV then
    add("ECU", v.ecuV and (Z.zahl(v.ecuV, w.dz.ecuV or 1) .. " V"), stand(C, v.ecuV, g.ecuWarn, g.ecuAlarm, true, C.text))
  end
  add("Zyl.-Diff", v.chtDiff and (Z.zahl(v.chtDiff, 0) .. "°"), v.diffWarn and C.orange or C.text)
  add("Durchfluss", tk.fluss and (Z.zahl(tk.fluss, 0) .. " ml/min"))
  add("Verbrauch", Z.zahl(tk.verbr or 0, 0) .. " ml")
  add("Gas", v.gas and (Z.zahl(v.gas, 0) .. " %"))
  add("Höhe", v.hoehe and (Z.zahl(v.hoehe, 0) .. " " .. (w.eh.hoehe or "")))
  add("Steigen", v.vario and ((v.vario > 0 and "+" or "") .. Z.zahl(v.vario, w.dz.vario or 1) .. " " .. (w.eh.vario or "")))
  add("Speed", v.speed and (Z.zahl(v.speed, 0) .. " " .. (w.eh.speed or "")))
  add("RxBatt", v.rxBatt and (Z.zahl(v.rxBatt, 2) .. " V"))
  for i = 1, 8 do
    local e = felder[i]
    local sp, zl = (i - 1) % 4, floor((i - 1) / 4)
    feld(L, Z, gp + sp * (br + gp), y2 + zl * (hf + gp), br, hf, e[1], e[2], e[3])
  end
end

K.leiste = leiste
return K
