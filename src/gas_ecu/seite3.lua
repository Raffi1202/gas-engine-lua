-- Gas Engine ECU: Seite 3 «Übersicht» (Eckwerte und Flüge seit dem letzten Zurücksetzen).
-- Werte ohne zugewiesenen Sensor werden ausgeblendet. Der Knopf «ÜBERSICHT ZURÜCKSETZEN» fragt immer nach.
local S = {}
local floor, max, min, abs = math.floor, math.max, math.min, math.abs

local function vz(x, d) -- mit Vorzeichen
  local t = (S.Z).zahl(abs(x), d)
  if x > 0 then return "+" .. t elseif x < 0 then return "-" .. t end
  return t
end

-- Eckwerte als Liste { Titel, Text }; nur Werte mit zugewiesenem Sensor. d: h, ml, steig, sink, fl, t (Motorlaufzeit s),
-- cht, zel, rpm, ecu. Gilt für «Gesamt» und für einen einzelnen Flug.
local KURZ = { ["Verbrauch gesamt"] = "Verbrauch", ["Max. Durchfluss"] = "Max. Fluss", ["Mittl. Durchfluss"] = "Mittl. Fluss",
  ["Tiefste ECU-Spannung"] = "Tiefste ECU" }
function S.eckwerte(Z, c, kl, d, mlTitel)
  local E = {}
  local quelle = c.impulse or c.fluss
  local function add(bed, titel, wert) if bed then E[#E + 1] = { kl and KURZ[titel] or titel, wert } end end
  add(c.hoehe, "Max. Höhe", d.h and (Z.zahl(d.h, 0) .. " m"))
  add(quelle, mlTitel, d.ml and (Z.zahl(d.ml, 0) .. " ml"))
  add(c.vario, "Max. Steigen", (d.steig and d.steig > 0) and (vz(d.steig, 1) .. " m/s") or nil)
  add(quelle, "Max. Durchfluss", d.fl and (Z.zahl(d.fl, 0) .. " ml/min"))
  add(c.vario, "Max. Sinken", (d.sink and d.sink < 0) and (vz(d.sink, 1) .. " m/s") or nil)
  add(quelle, "Mittl. Durchfluss", (d.ml and d.t and d.t >= 30) and (Z.zahl(d.ml / (d.t / 60), 0) .. " ml/min") or nil)
  add(c.cht1 or c.cht2 or c.cht3 or c.cht4 or c.cht5, "Max. Zylinder", d.cht and (Z.zahl(d.cht, 0) .. " °C"))
  add(c.lipo1 or c.lipo2 or c.lipo3, "Tiefste Zelle", d.zel and (Z.zahl(d.zel, 2) .. " V"))
  add(c.rpm, "Max. Drehzahl", d.rpm and (Z.tausend(d.rpm) .. " U/min"))
  add(c.ecuV, "Tiefste ECU-Spannung", d.ecu and (Z.zahl(d.ecu, 1) .. " V"))
  return E
end

-- Eckwerte zweispaltig in ein Rechteck verteilen.
function S.raster(L, Z, E, x0, y0, b, h, gr)
  local s, C = L.s, Z.C
  local zh = h / max(floor((#E + 1) / 2), 1)
  local sb = b / 2
  for i, e in ipairs(E) do
    local sp, ze = (i - 1) % 2, floor((i - 1) / 2)
    local x, y = x0 + sp * sb, y0 + zh * ze
    Z.text(L, x, y + zh * 0.25, e[1], 13, C.dim, LEFT, sb - 8 * s)
    Z.wert(L, x, y + zh * 0.62, e[2], gr, C.text, LEFT, sb - 8 * s)
  end
end

function S.zeichne(w, L, Z)
  S.Z = Z
  local C, W, H, top, gp, s, c, ue = Z.C, L.W, L.H, L.top, L.gp, L.s, w.cfg, w.ue
  local kh = 36 * s
  local unten = H - gp - kh - 8 * s
  local h = unten - top
  local kl = L.klein
  local bL = (W - 3 * gp) * (kl and 0.46 or 0.56)
  local bR = W - 3 * gp - bL
  local xR = 2 * gp + bL

  -- links: Eckwerte (nur, wenn der Sensor zugewiesen ist)
  Z.feld(gp, top, bL, h, 10 * s, C.rand, C.panel)
  Z.text(L, gp + 14 * s, top + 18 * s, "GESAMT", 14, C.dim, LEFT)
  local E = S.eckwerte(Z, c, kl, { h = ue.hMax, ml = ue.verbr, steig = ue.steigMax, sink = ue.sinkMax, fl = ue.flussMax,
    t = ue.laufS, cht = ue.chtMax, zel = ue.zelleMin, rpm = ue.rpmMax, ecu = ue.ecuMin }, "Verbrauch gesamt")
  if #E == 0 then
    Z.text(L, gp + bL / 2, top + h / 2, "Keine Sensoren gewählt", 18, C.dim, CENTERED, bL - 20 * s)
  else
    S.raster(L, Z, E, gp + 14 * s, top + 36 * s, bL - 28 * s, h - 40 * s, kl and 18 or 24)
  end

  -- rechts: Flüge
  Z.feld(xR, top, bR, h, 10 * s, C.rand, C.panel)
  Z.text(L, xR + 14 * s, top + 18 * s, "FLÜGE", 14, C.dim, LEFT)
  if w.schlepps[1] or w.sl then
    Z.text(L, xR + bR - 14 * s, top + 18 * s, "antippen = Werte", 12, C.dim, RIGHT, bR * 0.55)
  end
  -- je Zeile nur «Flug n»; die Werte zeigt das Detailfenster
  local liste = w.schlepps
  local fuss = 36 * s
  local zh = max(40 * s, 30)                                  -- gross genug zum Tippen, auch auf 480x320
  local y0 = top + 34 * s
  local platz = max(1, floor((top + h - fuss - 4 * s - y0) / zh))
  local zeilen = {}
  for i, sd in ipairs(liste) do zeilen[i] = { "Flug " .. tostring(sd.nr or i), nil, "zs" .. i } end
  if w.sl then
    zeilen[#zeilen + 1] = { "Flug " .. tostring((w.nSchlepp or 0) + 1), w.sl.pause and "Pause" or "läuft", "zsl" }
  end
  local ab = max(1, #zeilen - platz + 1)                      -- die neuesten zeigen
  local y = y0
  for i = ab, #zeilen do
    local r = zeilen[i]
    local f = r[2] and C.hblau or C.text
    Z.feld(xR + 10 * s, y + 3 * s, bR - 20 * s, zh - 6 * s, 8 * s, r[2] and C.hblau or C.rand, C.bg, 1)
    Z.text(L, xR + 22 * s, y + zh / 2, r[1], 18, f, LEFT, bR * 0.5)
    if r[2] then Z.text(L, xR + bR - 44 * s, y + zh / 2, r[2], 16, C.hblau, RIGHT, bR * 0.3) end
    Z.text(L, xR + bR - 24 * s, y + zh / 2, ">", 18, C.dim, CENTERED)
    if not w.dialog then Z.ziel(w, r[3], xR + 10 * s, y, bR - 20 * s, zh) end
    y = y + zh
  end
  if #liste == 0 and not w.sl then
    Z.text(L, xR + bR / 2, top + h / 2, "Noch kein Flug", 16, C.dim, CENTERED, bR - 20 * s)
  end
  if #liste > 0 then
    local summe = 0
    for _, sd in ipairs(liste) do summe = summe + (sd.ml or 0) end
    Z.rechteck(xR + 12 * s, top + h - fuss, bR - 24 * s, 1, C.rand)
    Z.text(L, xR + 14 * s, top + h - fuss / 2, "Ø " .. Z.zahl(summe / #liste, 0) .. " ml pro Flug", 16, C.hblau, LEFT, bR - 28 * s)
  end

  -- unten: Hinweis und Knopf
  local kb = kl and W * 0.6 or min(260 * s, W * 0.4)
  if not L.klein then
    Z.text(L, gp + 14 * s, H - gp - kh / 2, "Höchst- und Tiefstwerte und Flüge seit dem letzten Zurücksetzen", 13, C.dim,
      LEFT, W - kb - 4 * gp - 20 * s)
  end
  Z.knopf(w, L, "zuruecksetzen", W - gp - kb, H - gp - kh, kb, kh, "ÜBERSICHT ZURÜCKSETZEN", C.text, false, 14)
end

-- Detailfenster eines Flugs (w.detail = Nummer in der Liste oder "sl" für den laufenden).
function S.detail(w, L, Z)
  S.Z = Z
  local C, s, W, H, kl = Z.C, L.s, L.W, L.H, L.klein
  local d = w.detail == "sl" and w.sl or w.schlepps[w.detail]
  lcd.color(lcd.RGB(0, 0, 0, 0.6))
  lcd.drawFilledRectangle(0, 0, W, H)
  local b, h = W - 40 * s, H - L.top - 10 * s
  local x, y = (W - b) / 2, L.top
  Z.feld(x, y, b, h, 14 * s, C.hblau, C.bg, max(2, floor(2 * s)))
  local titel = "Flug"
  if d and w.detail == "sl" then titel = d.pause and "Flug (Pause)" or "Laufender Flug"
  elseif d then titel = "Flug " .. tostring(d.nr or w.detail) end
  Z.text(L, x + 20 * s, y + 26 * s, titel, 22, C.text, LEFT, b * 0.6)
  local kb, kh = max((kl and 150 or 190) * s, 120), max(40 * s, 32)
  Z.knopf(w, L, "schliessen", x + b - kb - 16 * s, y + h - kh - 14 * s, kb, kh, "SCHLIESSEN", C.text, false, 15)
  if d then                               -- wie Heli RF: auch der laufende oder pausierte Eintrag ist löschbar
    local nr = w.detail == "sl" and ((w.nSchlepp or 0) + 1) or (d.nr or w.detail)
    local lb = max(kb * 1.5, 200 * s)
    Z.knopf(w, L, "loeschen", x + b - kb - lb - 32 * s, y + h - kh - 14 * s, lb, kh, "FLUG " .. tostring(nr) .. " LÖSCHEN",
      C.rot, false, 15)
  end
  local E = d and S.eckwerte(Z, w.cfg, kl, d, "Sprit") or {}
  if #E == 0 then
    Z.text(L, W / 2, y + h / 2, d and "Keine Werte" or "Kein Flug", 18, C.dim, CENTERED, b - 30 * s)
  else
    S.raster(L, Z, E, x + 20 * s, y + 46 * s, b - 40 * s, h - 46 * s - kh - 22 * s, kl and 18 or 24)
  end
end

return S
