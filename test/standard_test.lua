-- Standard-Layout für alle Modelle (ab ECU 1.13.0 / Carb 0.13.0), ohne Simulator.
-- Aufruf aus dem Projektordner:  /opt/homebrew/opt/lua@5.4/bin/lua test/standard_test.lua
-- S3: Wahl im Menü (Speicherwert «1:Falsch») ergibt den Pfad der gewählten Datei, die Standard-Datei bleibt aussen vor.
-- S4: .funke.lua und Info-Datei hängen am Modell (Kennung), nicht an der Standard-Datei.
-- Menü: Standard-Datei erscheint als «Standard (alle Modelle)», andere Dateien mit Ort.
local fehler, faelle = 0, 0
local function pruefe(name, ok)
  faelle = faelle + 1
  if not ok then fehler = fehler + 1; io.write("FEHLER: ", name, "\n") end
end
local modell = "ECU DEMO"
model = { name = function() return modell end, path = function() return "DEMO/demo.bin" end }
system = { listFiles = function(o) if o == "SCRIPTS:/studio/" then
  return { "Standard.LUA.lua", "Falsch.LUA.lua", "ECU_ZWEI.LUA.funke.lua" } end return {} end }
for _, lua in ipairs({ "gas_ecu", "gas_carb" }) do
  local S = dofile("src/" .. lua .. "/studio.lua")
  local l0 = system.listFiles
  system.listFiles = function(o) local r = {} for i, n in ipairs(l0(o)) do r[i] = n:gsub("LUA", lua) end return r end
  modell = "ECU DEMO"
  pruefe(lua .. " S3 Wahl im Menü", S.wahlPfad("1:Falsch") == "SCRIPTS:/studio/Falsch." .. lua .. ".lua")
  local a, f = S.pfade()
  pruefe(lua .. " S4 .funke.lua Modell 1", f:find("ECU_DEMO%." .. lua .. "%.funke%.lua$") ~= nil)
  modell = "ECU ZWEI"
  local _, f2 = S.pfade()
  pruefe(lua .. " S4 .funke.lua Modell 2 getrennt", f2:find("ECU_ZWEI%." .. lua .. "%.funke%.lua$") ~= nil and f2 ~= f)
  local liste, std, falsch = S.liste(), nil, nil
  for _, e in ipairs(liste) do
    if e[1] == "1:Standard" then std = e end
    if e[1] == "1:Falsch" then falsch = e end
  end
  pruefe(lua .. " Menü Standard-Eintrag", std and std[2] == "Standard (alle Modelle)" and std[3] == true)
  pruefe(lua .. " Menü andere Datei mit Ort", falsch and falsch[2]:find("^Falsch %(") and not falsch[3])
  pruefe(lua .. " Menü ohne .funke.lua", #liste == 2)
  system.listFiles = l0
end
for _, lua in ipairs({ "gas_ecu", "gas_carb" }) do   -- Reihenfolge im Code: Standard nur ohne Wahl und ohne Modelldatei
  local k = io.open("src/" .. lua .. "/kern.lua"):read("a")
  pruefe(lua .. " Standard nur ohne Wahl/Modelldatei", k:find('if not d and grund == "fehlt" and not wp and S.kennung() ~= "Standard" then', 1, true) ~= nil)
end
print(("ERGEBNIS: %d Fälle, %s"):format(faelle, fehler == 0 and "kein Fehler" or (fehler .. " Fehler")))
os.exit(fehler == 0 and 0 or 1)
