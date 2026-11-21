-- Gas Engine ECU: Zeichen-Baukasten (Farben, Schriften, Grundformen, Statusleiste). Zeichnet nur, rechnet nichts aus.
local Z = {}
local floor, max, min = math.floor, math.max, math.min

Z.C = nil       -- Farben
local SCHRIFT   -- vorhandene Schriften mit gemessener Höhe, klein nach gross

local function farben()
  local R = lcd.RGB
  Z.C = {
    bg = R(14, 17, 22), panel = R(22, 27, 34), rand = R(48, 54, 61), text = R(230, 237, 243), dim = R(139, 148, 158),
    grau = R(75, 85, 99), blau = R(59, 130, 246), gruen = R(34, 197, 94), orange = R(245, 158, 11), rot = R(239, 68, 68),
    dunkel = R(11, 13, 16), dgruen = R(31, 61, 42), drot = R(74, 29, 29), dorange = R(84, 58, 16), hblau = R(96, 165, 250), weiss = R(255, 255, 255),
    neutral = R(100, 116, 139),
  }
end

local function schriften()
  SCHRIFT = {}
  local kand = { FONT_XXS, FONT_XS, FONT_S, FONT_STD, FONT_L, FONT_XL, FONT_XXL }
  for i = 1, 7 do
    local f = kand[i]
    if f ~= nil then
      lcd.font(f)
      local _, h = lcd.getTextSize("0")
      local n = #SCHRIFT
      if n == 0 or h > SCHRIFT[n][2] then SCHRIFT[n + 1] = { f, h } end
    end
  end
end

-- Aufteilung für eine Fenstergrösse. Alle Masse gehen vom Entwurf 800 x 480 aus und werden mit s verkleinert.
function Z.layout(W, H)
  if not Z.C then farben() end
  if not SCHRIFT then schriften() end
  -- Kompaktansicht: Ethos-Layout mit Kopf- und Fussleiste (X18RS gemessen 784 x 316). Erkannt am Seitenverhältnis:
  -- Vollbild hat bei allen Sendern mindestens 0,56 (480 x 272), mit Leisten ist das Fenster flacher als 0,5.
  local kompakt = H < W * 0.5
  local s = kompakt and min(W / 784, H / 316) or min(W / 800, H / 480)
  local L = { W = W, H = H, s = s, klein = W < 600, kompakt = kompakt }
  L.sb = floor(44 * s)             -- Statusleiste
  L.top = L.sb + floor(6 * s)      -- Oberkante der Felder
  L.fuss = floor(62 * s)           -- Fussleiste
  L.unten = H - L.fuss - floor(6 * s)
  L.gp = floor(6 * s)
  L.fi = {}                        -- Schriftwahl je Entwurfsgrösse
  return L
end

-- Schrift für eine Entwurfsgrösse (Schriftgrad im Entwurf 800 x 480) wählen; gibt die Stufe zurück.
local function stufe(L, gr)
  local i = L.fi[gr]
  if i then return i end
  local ziel = gr * 1.25 * L.s + 0.5
  i = 1
  for k = 2, #SCHRIFT do
    if SCHRIFT[k][2] <= ziel then i = k end
  end
  L.fi[gr] = i
  return i
end

-- Text mit senkrechter Mitte ym. ausr: LEFT / RIGHT / CENTERED. maxB: passt der Text nicht, wird die Schrift kleiner.
-- Rückgabe: Textbreite.
-- Texte, die der User selbst eingibt (Modellname, Schalternamen), werden nie übersetzt.
Z.roh = {}
function Z.text(L, x, ym, t, gr, farbe, ausr, maxB)
  if Z.tr and not Z.roh[t] then t = Z.tr(t) end
  local i = stufe(L, gr)
  lcd.font(SCHRIFT[i][1])
  local b = lcd.getTextSize(t)
  if maxB then
    while b > maxB and i > 1 do
      i = i - 1
      lcd.font(SCHRIFT[i][1])
      b = lcd.getTextSize(t)
    end
  end
  lcd.color(farbe)
  lcd.drawText(floor(x), floor(ym - SCHRIFT[i][2] / 2), t, ausr or LEFT)
  return b
end

-- Textbreite in der Schrift einer Entwurfsgrösse.
function Z.breite(L, t, gr)
  if Z.tr and not Z.roh[t] then t = Z.tr(t) end
  lcd.font(SCHRIFT[stufe(L, gr)][1])
  return (lcd.getTextSize(t))
end

function Z.rechteck(x, y, b, h, farbe)
  if b < 1 or h < 1 then return end
  lcd.color(farbe)
  lcd.drawFilledRectangle(floor(x), floor(y), floor(b + 0.5), floor(h + 0.5))
end

-- Rechteck mit runden Ecken (Ethos kennt keines: zwei Rechtecke und vier Kreise).
function Z.rund(x, y, b, h, r, farbe)
  x, y, b, h, r = floor(x), floor(y), floor(b), floor(h), floor(r)
  if b < 1 or h < 1 then return end
  lcd.color(farbe)
  if r * 2 + 1 > h then r = floor((h - 1) / 2) end
  if r * 2 + 1 > b then r = floor((b - 1) / 2) end
  if r < 2 then
    lcd.drawFilledRectangle(x, y, b, h)
    return
  end
  lcd.drawFilledRectangle(x + r, y, b - 2 * r, h)
  lcd.drawFilledRectangle(x, y + r, b, h - 2 * r)
  lcd.drawFilledCircle(x + r, y + r, r)
  lcd.drawFilledCircle(x + b - r - 1, y + r, r)
  lcd.drawFilledCircle(x + r, y + h - r - 1, r)
  lcd.drawFilledCircle(x + b - r - 1, y + h - r - 1, r)
end

-- Gefülltes Feld mit Rand. d = Randstärke.
function Z.feld(x, y, b, h, r, rand, fuell, d)
  d = d or 1
  Z.rund(x, y, b, h, r, rand)
  Z.rund(x + d, y + d, b - 2 * d, h - 2 * d, r - d, fuell)
end

-- Pille mit Text; voll = gefüllt, sonst nur Rand.
function Z.pille(L, x, y, b, h, t, farbe, voll, gr)
  local C = Z.C
  if voll then
    Z.rund(x, y, b, h, h / 2, farbe)
  else
    Z.feld(x, y, b, h, h / 2, farbe, C.panel, max(1, floor(2 * L.s)))
  end
  Z.text(L, x + b / 2, y + h / 2, t, gr, voll and C.dunkel or farbe, CENTERED, b - h * 0.3)
end

-- Kreisbogen; Winkel in Grad, 0 = oben, im Uhrzeigersinn. Geht auch über 360 hinaus.
function Z.bogen(cx, cy, r1, r2, a0, a1, farbe)
  if a1 <= a0 then return end
  lcd.color(farbe)
  cx, cy, r1, r2 = floor(cx), floor(cy), floor(r1), floor(r2)
  if a0 >= 360 then a0, a1 = a0 - 360, a1 - 360 end
  if a1 > 360 then
    lcd.drawAnnulusSector(cx, cy, r1, r2, a0, 360)
    lcd.drawAnnulusSector(cx, cy, r1, r2, 0, a1 - 360)
  else
    lcd.drawAnnulusSector(cx, cy, r1, r2, a0, a1)
  end
end

-- Pfeil nach oben (r > 0) oder unten (r < 0), sonst waagrechter Strich. g = Grösse.
function Z.pfeil(x, ym, g, r, farbe)
  lcd.color(farbe)
  x, ym, g = floor(x), floor(ym), floor(g)
  if r > 0 then
    lcd.drawFilledTriangle(x, ym + g, x + 2 * g, ym + g, x + g, ym - g)
  elseif r < 0 then
    lcd.drawFilledTriangle(x, ym - g, x + 2 * g, ym - g, x + g, ym + g)
  else
    lcd.drawFilledRectangle(x, ym - 1, 2 * g, max(2, floor(g / 3)))
  end
end

-- Zahl mit Komma, dez Stellen.
function Z.zahl(x, dez)
  if x == nil then return "--" end
  local t = string.format("%." .. (dez or 0) .. "f", x)
  if dez and dez > 0 then
    local a, b = t:match("^(-?%d+)%.(%d+)$")
    if a and not Z.punkt then t = a .. "," .. b end
  end
  return t
end

-- Ganze Zahl mit Tausender-Hochkomma: 6850 -> 6'850.
function Z.tausend(x)
  if x == nil then return "--" end
  local n = floor(x + 0.5)
  local v = n < 0 and "-" or ""
  if n < 0 then n = -n end
  if n < 1000 then return v .. n end
  return v .. floor(n / 1000) .. (Z.punkt and "," or "'") .. string.format("%03d", n % 1000)
end

-- Sekunden als m:ss oder h:mm:ss.
function Z.zeit(sek)
  if sek == nil then return "--" end
  local n = floor(sek)
  if n < 0 then n = 0 end
  if n >= 3600 then return string.format("%d:%02d:%02d", n // 3600, (n % 3600) // 60, n % 60) end
  return string.format("%d:%02d", n // 60, n % 60)
end

function Z.grund(L)
  lcd.color(Z.C.bg)
  lcd.drawFilledRectangle(0, 0, L.W, L.H)
end

-- Hinweis, wenn das Feld für die Anzeige zu klein ist.
function Z.zuKlein(L, name)
  local C = Z.C
  Z.text(L, L.W / 2, L.H / 2 - 12, name or "-", 26, C.text, CENTERED, L.W - 8)
  Z.text(L, L.W / 2, L.H / 2 + 12, "nur im Vollbild", 20, C.dim, CENTERED, L.W - 8)
end

-- Feld mit Titel.
function Z.kasten(L, x, y, b, h, titel, farbe)
  local C = Z.C
  Z.feld(x, y, b, h, 10 * L.s, C.rand, C.panel)
  if titel then Z.text(L, x + b / 2, y + 16 * L.s, titel, 14, farbe or C.dim, CENTERED, b - 12 * L.s) end
end

local ZUSTAND_FARBE = { ["WARMLAUF"] = "blau", ["LÄUFT"] = "gruen", ["WARNUNG"] = "orange", ["ALARM"] = "rot" }
function Z.zustandFarbe(z) return Z.C[ZUSTAND_FARBE[z] or "grau"] end

-- Kurzer waagrechter Strich für «kein Wert» (Ethos-Schrift hat keinen Gedankenstrich). gr = Entwurfsgrösse.
function Z.strich(L, x, ym, gr, farbe, ausr)
  local b = floor(gr * 0.7 * L.s + 0.5)
  local d = max(2, floor(gr * 0.09 * L.s + 0.5))
  if ausr == CENTERED then x = x - b / 2 elseif ausr == RIGHT then x = x - b end
  Z.rechteck(x, ym - d / 2, b, d, farbe or Z.C.grau)
  return b
end

-- Text oder, wenn t nil ist, ein Strich.
function Z.wert(L, x, ym, t, gr, farbe, ausr, maxB)
  if t == nil then return Z.strich(L, x, ym, gr, Z.C.grau, ausr) end
  return Z.text(L, x, ym, t, gr, farbe, ausr, maxB)
end

-- Statusleiste und Meldezeile (auf allen Seiten gleich).
-- Grossbuchstaben auch für Umlaute (string.upper kennt nur ASCII)
local function gross(t)
  return (string.upper(t):gsub("ä", "Ä"):gsub("ö", "Ö"):gsub("ü", "Ü"))
end

function Z.kopf(w, L)
  local C, s, W, v = Z.C, L.s, L.W, w.v
  local sb, klein = L.sb, L.klein
  Z.rechteck(0, 0, W, sb, C.panel)
  -- Pillen: Schrift so gross, wie die Pille hoch ist (sonst gehen die Umlaut-Punkte von Ä/Ü in der kleinen Schrift unter)
  local ph = max(22, floor(28 * s))
  local py = floor((sb - ph) / 2)
  local gr = ph * 0.92 / (1.25 * s)
  local function bp(t) return Z.breite(L, t, gr) + 24 * s end

  local zf = C[ZUSTAND_FARBE[w.zustand] or "grau"]
  local voll = not (w.stufe == 2 and w.blink)        -- Alarm blinkt: gefüllt / nur Rand
  local zb = max(112 * s, bp(w.zustand))
  Z.pille(L, 8 * s, py, zb, ph, w.zustand, zf, voll, gr)
  local x = 8 * s + zb + 8 * s

  -- Schalter-Felder (nur wenn die Quelle gewählt ist)
  local felder, n = {}, 0
  if v.zuend ~= nil then
    n = n + 1
    felder[n] = { v.zuend and (klein and "ZÜND. EIN" or "ZÜNDUNG EIN") or (klein and "ZÜND. AUS" or "ZÜNDUNG AUS"),
      v.zuend and C.rot or C.grau, false }
  end
  if v.choke then
    n = n + 1
    felder[n] = { w.chokeWarn and "CHOKE AUS!" or "CHOKE", w.chokeWarn and C.orange or C.blau, w.chokeWarn }
  end
  -- zwei frei benannte Schalter (Name im Menü), nur wenn eingeschaltet
  local c = w.cfg
  if v.winde then n = n + 1; felder[n] = { gross(c.sw1Name or "SCHALTER 1"), C.gruen, false }; if c.sw1Name then Z.roh[felder[n][1]] = true end end
  if v.bremse then n = n + 1; felder[n] = { gross(c.sw2Name or "SCHALTER 2"), C.gruen, false }; if c.sw2Name then Z.roh[felder[n][1]] = true end end
  if w.kopfName and w.kopfText[w.kopfName] then Z.roh[w.kopfText[w.kopfName]] = true end

  -- rechts: Seitenanzeige, ECU, Empfang (in dieser Wichtigkeit), solange Platz ist
  local t, kn = w.kopfText, w.kopfN or 0
  local tb, lz = {}, 18 * s
  local rechts = 0
  for i = 1, kn do tb[i] = Z.breite(L, t[i], 16) end
  local belegt = x
  for i = 1, n do belegt = belegt + bp(felder[i][1]) + 8 * s end
  local zeige = 0
  for i = 1, kn do
    local neu = rechts + tb[i] + (i > 1 and lz or 0)
    if i == w.kopfName and belegt + neu + 10 * s > W then
      -- Modellname zu lang: Zeichen für Zeichen kürzen (nie mitten in einem Umlaut), bis er Platz hat
      local frei = W - 10 * s - belegt - rechts - lz
      local k = t[i]:gsub("%.$", "")
      while #k > 3 and Z.breite(L, k .. ".", 16) > frei do
        local p = #k                                -- Anfang des letzten Zeichens (UTF-8) suchen
        while p > 1 and k:byte(p) >= 0x80 and k:byte(p) < 0xC0 do p = p - 1 end
        k = k:sub(1, p - 1)
      end
      t[i] = k:gsub("%s+$", "") .. "."
      Z.roh[t[i]] = true
      tb[i] = Z.breite(L, t[i], 16)
      neu = rechts + tb[i] + lz
    end
    if belegt + neu + 10 * s <= W then
      rechts, zeige = neu, i
    else
      break
    end
  end
  for i = 1, n do
    local f = felder[i]
    local b = bp(f[1])
    if x + b > W - 10 * s - rechts then break end
    Z.pille(L, x, py, b, ph, f[1], f[2], f[3], gr)
    x = x + b + 8 * s
  end
  -- von rechts: Seitenanzeige, dann die übrigen in umgekehrter Reihenfolge (sichtbar: ECU, Empfang, Seite)
  local rx = W - 10 * s
  for k = 1, zeige do
    local i = (k == 1) and 1 or (zeige - k + 2)
    local farbe = (w.kopfRot == i) and C.orange or ((w.kopfLeer and w.kopfLeer[i]) and C.dim or C.text)
    Z.text(L, rx, sb / 2, t[i], 16, farbe, RIGHT)
    rx = rx - tb[i] - lz
  end

  -- Meldezeile über den Feldtiteln: aktive Warnungen aller Seiten, oder ein kurzer Hinweis
  local mt, mf, tf
  if w.hinweis then
    mt, mf, tf = w.hinweis, C.blau, C.weiss
  elseif w.nAktiv > 0 then
    mt, mf, tf = w.meldText, w.stufe == 2 and C.rot or C.orange, C.dunkel
  end
  if mt then
    local mh = floor(26 * s)
    Z.rund(L.gp, L.top, W - 2 * L.gp, mh, 8 * s, mf)
    Z.text(L, W / 2, L.top + mh / 2, mt, 16, tf, CENTERED, W - 2 * L.gp - 16 * s)
  end
end

-- Antippbare Fläche merken (beim Zeichnen); der Kern prüft damit die Berührungen.
function Z.ziel(w, id, x, y, b, h)
  local n = (w.nZiele or 0) + 1
  w.nZiele = n
  local z = w.ziele[n] or {}
  z.id, z.x, z.y, z.b, z.h = id, x, y, b, h
  w.ziele[n] = z
end

-- Knopf mit Rand oder gefüllt; meldet seine Fläche als Ziel.
function Z.knopf(w, L, id, x, y, b, h, t, farbe, voll, gr)
  local C = Z.C
  if voll then
    Z.rund(x, y, b, h, 8 * L.s, farbe)
  else
    Z.feld(x, y, b, h, 8 * L.s, farbe, C.panel, max(1, floor(2 * L.s)))
  end
  Z.text(L, x + b / 2, y + h / 2, t, gr, voll and C.dunkel or farbe, CENTERED, b - 12 * L.s)
  Z.ziel(w, id, x, y, b, h)
end

-- Rückfrage über der Seite. Nur «JA, …» ändert etwas.
-- { Titel, Zeile, Text Ja, Ziel Ja, Text links, Ziel links }
local DIALOG = {
  tank = { "Wirklich vollgetankt?", nil, "JA, VOLLGETANKT", "ja_tank", "ABBRECHEN", "abbrechen" },
  reset = { "Übersicht zurücksetzen?", "Höchstwerte und Flugliste werden gelöscht. Der Tank bleibt.",
    "JA, ZURÜCKSETZEN", "ja_reset", "ABBRECHEN", "abbrechen" },
  schlepp = { "Flug beendet?", nil, "JA, BEENDET", "ja_schlepp", "NEIN, NUR PAUSE", "nein_schlepp" },
  loeschen = { "Eintrag löschen?", "Tank und Gesamtwerte bleiben.", "JA, LÖSCHEN", "ja_loeschen", "NEIN", "abbrechen" },
}

function Z.dialog(w, L)
  local d = DIALOG[w.dialog]
  if d == nil then return end
  local C, s, W, H = Z.C, L.s, L.W, L.H
  -- Seite abdunkeln
  lcd.color(lcd.RGB(0, 0, 0, 0.6))
  lcd.drawFilledRectangle(0, 0, W, H)
  local b, h = min(W - 40 * s, 460 * s), 200 * s
  local x, y = (W - b) / 2, (H - h) / 2
  Z.feld(x, y, b, h, 14 * s, C.hblau, C.bg, max(2, floor(2 * s)))
  local titel = d[1]
  if w.dialog == "loeschen" then
    local e = type(w.detail) == "number" and w.schlepps[w.detail]
    local nr = w.detail == "sl" and ((w.nSchlepp or 0) + 1) or (e and e.nr or "")
    titel = "Flug " .. tostring(nr) .. " löschen?"
  end
  Z.text(L, W / 2, y + 42 * s, titel, 26, C.text, CENTERED, b - 30 * s)
  local zeile = d[2]
  if w.dialog == "tank" then
    local g = w.g
    zeile = g.tank and ("Der Tank wird auf 100 % (" .. floor(g.tank) .. " ml) gesetzt.") or "Der Verbrauch wird auf 0 gesetzt."
  elseif w.dialog == "schlepp" and w.sl then
    zeile = "Dieser Flug: " .. Z.zahl(w.sl.ml or 0, 0) .. " ml Sprit"
  end
  if zeile then Z.text(L, W / 2, y + 82 * s, zeile, 15, C.dim, CENTERED, b - 30 * s) end
  local kb, kh = (b - 3 * 22 * s) / 2, 46 * s
  local ky = y + h - kh - 22 * s
  Z.knopf(w, L, d[6], x + 22 * s, ky, kb, kh, d[5], C.dim, false, 15)
  Z.knopf(w, L, d[4], x + 44 * s + kb, ky, kb, kh, d[3], C.gruen, true, 15)
end

-- Kleines Fehlerzeichen oben rechts in der Meldezeile, wenn ein Teil des Skripts einen Fehler hatte.
function Z.fehlerZeichen(L)
  local s = L.s
  local g = floor(9 * s)
  local x, y = L.W - 3 * g, L.sb + floor(3 * s)
  lcd.color(Z.C.rot)
  lcd.drawFilledTriangle(x, y + 2 * g, x + 2 * g, y + 2 * g, x + g, y)
  Z.rechteck(x + g - 1, y + floor(0.7 * g), 2, floor(0.8 * g), Z.C.dunkel)
  Z.rechteck(x + g - 1, y + floor(1.65 * g), 2, 2, Z.C.dunkel)
end

return Z
