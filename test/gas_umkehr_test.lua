-- «Gas umkehren» (ab ECU 1.13.1 / Carb 0.13.1), ohne Simulator.
-- Aufruf aus dem Projektordner:
--   /opt/homebrew/opt/lua@5.4/bin/lua test/gas_inv_test.lua <felder.lua der Vorversion ECU> <felder.lua der Vorversion Carb>
-- 1. Update: Die Vorversion schreibt die Einstellungsdatei (alle Zahlen, Ja/Nein, Auswahlen geändert), die neue Version
--    liest sie: alle Werte gleich, «Gas umkehren» aus.
-- 2. Rundlauf: «Gas umkehren» an wird geschrieben und wieder gelesen.
-- Die Rechnung selbst (Kanal unten = 100 % bei «an») prüft der Simulatorlauf, siehe test/LIESMICH.md.
local fehler, faelle = 0, 0
local function pruefe(name, ok)
  faelle = faelle + 1
  if not ok then fehler = fehler + 1; io.write("FEHLER: ", name, "\n") end
end
local DATEI = {}
io.open = function(p, m)
  if m == "w" then
    local t = {}
    return { write = function(_, s) t[#t + 1] = s end, close = function() DATEI[p] = table.concat(t) end }
  end
  local s, pos = DATEI[p], 1
  if not s then return nil end
  return { read = function(_, n) local r = s:sub(pos, pos + n - 1); pos = pos + n; return r end, close = function() end }
end
model = { path = function() return "DEMO/test.bin" end, name = function() return "TEST" end }
storage = nil
local function lade(p) return dofile(p) end
for i, d in ipairs({ "gas_ecu", "gas_carb" }) do
  DATEI = {}
  local alt, neu = lade(arg[i]), lade("src/" .. d .. "/felder.lua")
  -- 1. Vorversion schreibt: jeden Wert vom Werkwert weg verändern
  local wa = { tk = { verbr = 123.4 }, ue = {}, schlepps = {}, nSchlepp = 0 }
  wa.cfg = alt.standard()
  local erwartet, gespeichert = {}, {}
  for _, k in ipairs(alt.folge) do gespeichert[k] = true end
  for _, g in ipairs(alt.gruppen) do for _, f in ipairs(g[2]) do
    local v
    if f[2] == "b" then v = not f[4]
    elseif f[2] == "z" then v = (f[4] == f[6]) and f[5] or f[6]
    elseif f[2] == "w" then v = f[5][#f[5]][2]; if v == f[4] then v = f[5][1][2] end
    elseif f[2] == "t" then v = "Test" end
    if v ~= nil and gespeichert[f[1]] then wa.cfg[f[1]] = v; erwartet[f[1]] = v end
  end end
  pruefe(d .. " Vorversion kennt gasInv nicht", alt.feld("gasInv") == nil)
  pruefe(d .. " Vorversion schreibt", alt.schreibeDatei(wa))
  local wn = { tk = {}, ue = {}, schlepps = {} }
  neu.lies(wn)
  local n, falsch = 0, {}
  for k, v in pairs(erwartet) do n = n + 1; if wn.cfg[k] ~= v then falsch[#falsch + 1] = k end end
  pruefe(d .. " Update: alle " .. n .. " Werte gleich (" .. table.concat(falsch, ",") .. ")", #falsch == 0 and n > 50)
  pruefe(d .. " Update: Verbrauch gleich", wn.tk.verbr == 123.4)
  pruefe(d .. " Update: Gas umkehren aus", wn.cfg.gasInv == false)
  -- 2. Rundlauf mit an
  wn.cfg.gasInv = true
  pruefe(d .. " neue Version schreibt", neu.schreibeDatei(wn))
  local w2 = { tk = {}, ue = {}, schlepps = {} }
  neu.lies(w2)
  pruefe(d .. " Rundlauf: Gas umkehren an", w2.cfg.gasInv == true)
  pruefe(d .. " Feld im Menü direkt unter Gas (Kanal)", (function()
    local g = neu.gruppen[1][2]
    for j, f in ipairs(g) do if f[1] == "gas" then return g[j + 1][1] == "gasInv" and g[j + 1][2] == "b" and g[j + 1][4] == false end end
  end)())
  pruefe(d .. " Feld in der Speicherfolge", (function() for _, k in ipairs(neu.folge) do if k == "gasInv" then return true end end end)())
  pruefe(d .. " FORMAT nicht kleiner", neu.FORMAT >= alt.FORMAT)   -- ab ECU 1.14.0 / Carb 0.14.0 +1 wegen Zylinder 5
end
print(("ERGEBNIS: %d Fälle, %s"):format(faelle, fehler == 0 and "kein Fehler" or (fehler .. " Fehler")))
os.exit(fehler == 0 and 0 or 1)
