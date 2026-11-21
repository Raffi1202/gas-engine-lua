-- Update-Test: Widget-Speicher mit einer Vorversion schreiben und mit der aktuellen Fassung lesen.
-- Ethos liest den Speicher nach Reihenfolge der Aufrufe (nicht nach Namen); das bildet der Test nach.
-- Aufruf: lua test/update_test.lua <felder.lua der Vorversion> <felder.lua aktuell>
local alt, neu = arg[1], arg[2]
local band, pos = {}, 0
storage = {
  write = function(_, v) band[#band + 1] = v end,
  read = function(_) pos = pos + 1; return band[pos] end,
}
model = { path = function() return "test" end, name = function() return "test" end }
io = { open = function() return nil end }   -- keine Datei: nur der Widget-Speicher zählt hier
local function quelle(name) return { value = function() return 1 end, name = name } end

local MA = dofile(alt)
local w = { cfg = {}, tk = {} }
local namen = {}
for _, n in ipairs(MA.folge) do local f = MA.feld(n); if f and f[2] == "q" then w.cfg[n] = quelle(n); namen[#namen + 1] = n end end
MA.schreibe(w)

local MN = dofile(neu)
local w2 = { tk = {} }
pos = 0
local okLies = MN.lies(w2)
local fehlt = {}
for _, n in ipairs(namen) do
  local q = w2.cfg[n]
  if not (q and q.name == n) then fehlt[#fehlt + 1] = n end
end
print(string.format("Update %s -> %s: %d Quellen alt, %d fehlen nach dem Lesen", alt:match("[^/]+$"), neu:match("[^/]+$"), #namen, #fehlt))
if #fehlt > 0 then print("FEHLT: " .. table.concat(fehlt, ", ")) end

-- Rundlauf der aktuellen Fassung (schreiben und wieder lesen)
band, pos = {}, 0
local w3 = { cfg = {}, tk = {} }
local alle = {}
for _, n in ipairs(MN.folge) do local f = MN.feld(n); if f and f[2] == "q" then w3.cfg[n] = quelle(n); alle[#alle + 1] = n end end
w3.wahl = "2:Mein_Layout"           -- Wahl «Studio-Layout» (ab ECU 1.12.0 / Carb 0.12.0 am Ende des Speichers)
MN.schreibe(w3)
local nWerte, nByte = #band, 0
for _, v in ipairs(band) do nByte = nByte + (type(v) == "string" and #v or 4) end
local w4 = { tk = {} }
pos = 0
MN.lies(w4)
local fehlt2 = 0
for _, n in ipairs(alle) do if not (w4.cfg[n] and w4.cfg[n].name == n) then fehlt2 = fehlt2 + 1 end end
print(string.format("Rundlauf aktuell: %d Quellen, %d fehlen", #alle, fehlt2))
print(string.format("Wahl alt -> neu: %s (erwartet nil = automatisch); Rundlauf Wahl: %s; Speicher: %d Werte, rund %d Byte",
  tostring(w2.wahl), tostring(w4.wahl), nWerte, nByte))
if w2.wahl ~= nil or w4.wahl ~= "2:Mein_Layout" then fehlt2 = fehlt2 + 1 end
print((#fehlt == 0 and fehlt2 == 0) and "ERGEBNIS: kein Fehler" or "ERGEBNIS: FEHLER")
