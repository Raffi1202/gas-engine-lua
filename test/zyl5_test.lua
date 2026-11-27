-- Zylinder 5 (ab ECU 1.14.0 / Carb 0.14.0), ohne Simulator.
-- Aufruf aus dem Projektordner:
--   /opt/homebrew/opt/lua@5.4/bin/lua test/zyl5_test.lua <felder.lua der Vorversion ECU> <felder.lua der Vorversion Carb>
-- Der Widget-Speicher wird nachgebildet wie Ethos ihn liest: nach Reihenfolge der Aufrufe, nicht nach Namen.
-- 1. Update: Die Vorversion schreibt Widget-Speicher (alle Quellen belegt, Studio-Wahl) und Einstellungsdatei
--    (alle Zahlen, Ja/Nein, Auswahlen geändert, «Anzahl Zylinder» = 4); die neue Version liest beides:
--    alle Quellen und Werte gleich, Studio-Wahl gleich, «Zylinder 5 Temp.» leer.
-- 2. Rundlauf: 5 Zylinder mit Quelle für Zylinder 5 werden geschrieben und wieder gelesen.
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
-- Widget-Speicher: Schreiben hängt an, Lesen holt den nächsten Wert in Aufruf-Reihenfolge (Name egal)
local SP, LP = {}, 0
storage = {
  write = function(_, v) SP[#SP + 1] = v end,
  read = function() LP = LP + 1; return SP[LP] end,
}
local function neuerSpeicher() SP, LP = {}, 0 end
local function zumLesen() LP = 0 end
local function quelle(n) return { value = function() return n end, name = "Q" .. n } end
for i, d in ipairs({ "gas_ecu", "gas_carb" }) do
  DATEI = {}
  neuerSpeicher()
  local alt, neu = dofile(arg[i]), dofile("src/" .. d .. "/felder.lua")
  -- 1. Vorversion schreibt
  local wa = { tk = { verbr = 77.5 }, ue = {}, schlepps = {}, nSchlepp = 0, wahl = "1:Test" }
  wa.cfg = alt.standard()
  local erwartet, gespeichert, nq = {}, {}, 0
  for _, k in ipairs(alt.folge) do gespeichert[k] = true end
  for _, g in ipairs(alt.gruppen) do for _, f in ipairs(g[2]) do
    local v
    if f[2] == "q" then nq = nq + 1; v = quelle(nq)
    elseif f[2] == "b" then v = not f[4]
    elseif f[2] == "z" then v = (f[4] == f[6]) and f[5] or f[6]
    elseif f[2] == "w" then v = f[5][#f[5]][2]; if v == f[4] then v = f[5][1][2] end
    elseif f[2] == "t" then v = "Test" end
    if v ~= nil and gespeichert[f[1]] then wa.cfg[f[1]] = v; erwartet[f[1]] = v end
  end end
  pruefe(d .. " Vorversion kennt cht5 nicht", alt.feld("cht5") == nil)
  pruefe(d .. " Vorversion: Anzahl Zylinder = 4 gespeichert", wa.cfg.zylAnz == 4)
  alt.schreibe(wa)
  pruefe(d .. " Vorversion schreibt Datei", alt.schreibeDatei(wa))
  zumLesen()
  local wn = { tk = {}, ue = {}, schlepps = {} }
  pruefe(d .. " Update: gelesen", neu.lies(wn))
  local n, falsch, nqn = 0, {}, 0
  for k, v in pairs(erwartet) do
    n = n + 1
    if type(v) == "table" then nqn = nqn + 1 end
    if wn.cfg[k] ~= v then falsch[#falsch + 1] = k end
  end
  pruefe(d .. " Update: alle " .. n .. " Werte gleich, davon " .. nqn .. " Quellen (" .. table.concat(falsch, ",") .. ")",
    #falsch == 0 and n > 50 and nqn > 30)
  pruefe(d .. " Update: Anzahl Zylinder bleibt 4", wn.cfg.zylAnz == 4)
  pruefe(d .. " Update: Zylinder 5 leer", wn.cfg.cht5 == nil)
  pruefe(d .. " Update: Studio-Wahl gleich", wn.wahl == "1:Test")
  pruefe(d .. " Update: Verbrauch gleich", wn.tk.verbr == 77.5)
  -- 2. Rundlauf mit 5 Zylindern
  wn.cfg.zylAnz, wn.cfg.cht5 = 5, quelle(999)
  wn.wahl = "2:Fuenf"
  neuerSpeicher()
  neu.schreibe(wn)
  pruefe(d .. " neue Version schreibt Datei", neu.schreibeDatei(wn))
  zumLesen()
  local w2 = { tk = {}, ue = {}, schlepps = {} }
  pruefe(d .. " Rundlauf: gelesen", neu.lies(w2))
  pruefe(d .. " Rundlauf: Anzahl Zylinder 5", w2.cfg.zylAnz == 5)
  pruefe(d .. " Rundlauf: Zylinder 5 Quelle", w2.cfg.cht5 == wn.cfg.cht5)
  pruefe(d .. " Rundlauf: Zylinder 1 Quelle", w2.cfg.cht1 == wn.cfg.cht1)
  pruefe(d .. " Rundlauf: Studio-Wahl", w2.wahl == "2:Fuenf")
  pruefe(d .. " Feld im Menü direkt unter Zylinder 4", (function()
    local g = neu.gruppen[1][2]
    for j, f in ipairs(g) do if f[1] == "cht4" then return g[j + 1][1] == "cht5" and g[j + 1][2] == "q" end end
  end)())
  pruefe(d .. " Feld am Ende der Speicherfolge", neu.folge[#neu.folge] == "cht5")
  pruefe(d .. " FORMAT um eins erhöht", neu.FORMAT == alt.FORMAT + 1)
end
print(("ERGEBNIS: %d Fälle, %s"):format(faelle, fehler == 0 and "kein Fehler" or (fehler .. " Fehler")))
os.exit(fehler == 0 and 0 or 1)
