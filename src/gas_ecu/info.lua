-- Gas Engine ECU: Info-Datei für das Lua-Studio (Format v1, Abschnitt 14): SCRIPTS:/studio/<Kennung>.gas_ecu.info.json.
-- Nur das Studio liest sie. Das Lua schreibt sie nach jedem Modellwechsel, sobald die Sensorliste fertig ist, und nur,
-- wenn sich der Inhalt geändert hat. Die Sensorliste entsteht über mehrere Aufrufe (je 20 Sensoren, höchstens 100).
-- Aufruf je wakeup: I.schritt(w, version) gibt true zurück, wenn fertig.
local I = {}

local function rufe(q, f)
  local ok, v = pcall(q[f], q)
  if ok then return v end
  return nil
end

local function js(t)
  t = tostring(t or "")
  t = t:gsub('[%c"\\]', function(c)
    if c == '"' then return '\\"' elseif c == "\\" then return "\\\\" elseif c == "\n" then return "\\n" end
    return string.format("\\u%04X", c:byte())
  end)
  return '"' .. t .. '"'
end

function I.schritt(w, version, S)
  local z = w.infoZ
  if z == nil then
    z = { i = 1, sensoren = {} }
    local ok, l = pcall(system.getSources, CATEGORY_TELEMETRY_SENSOR)   -- am Sender nur mit der Zahl (Tabelle: leer)
    z.liste = (ok and type(l) == "table") and l or {}
    w.infoZ = z
    return false
  end
  local bis = math.min(#z.liste, z.i + 9, 100)          -- je Aufruf 10 Sensoren (Befehlsgrenze)
  for i = z.i, bis do
    local q = z.liste[i]
    local a, sub, ph = rufe(q, "appId"), rufe(q, "subId"), rufe(q, "physId")
    if type(a) == "number" then
      local function ganz(x) return math.tointeger(tonumber(x)) or 0 end
      local e = '{ "appId": ' .. string.format("%d", ganz(a)) .. ', "sub": ' .. string.format("%d", ganz(sub)) ..
        ', "phys": ' .. string.format("%d", ganz(ph)) .. ', "name": ' .. js(rufe(q, "name"))
      local u = rufe(q, "stringUnit")
      if type(u) == "string" and u ~= "" then e = e .. ', "einheit": ' .. js(u) end
      z.sensoren[#z.sensoren + 1] = e .. " }"
    end
  end
  z.i = bis + 1
  if z.i <= math.min(#z.liste, 100) then return false end
  -- alles da: Datei bauen
  local okN, name = pcall(model.name)
  local okP, pfad = pcall(model.path)
  local brett, ethos = "", ""
  local okV, ver = pcall(system.getVersion)
  if okV and type(ver) == "table" then
    brett = ver.board or ""
    ethos = ver.version or ((ver.major or "") .. "." .. (ver.minor or "") .. "." .. (ver.revision or ""))
  end
  local fe = {}
  for _, f in ipairs(w.fenster or {}) do fe[#fe + 1] = '{ "breite": ' .. f[1] .. ', "hoehe": ' .. f[2] .. ' }' end
  local st = w.studioStatus or "fehlt"
  local sd = js(st) .. ((st == "geladen" and w.studio and w.studio.st) and (', "fehler": ' .. w.studio.st.fehler) or "")
  local t = '{\n "format": 1,\n "lua": ' .. js(S.LUA) .. ',\n "luaVersion": ' .. js(version) .. ',\n "formate": [1],\n "beiMotorAus": true,\n' ..
    ' "modell": ' .. js(okN and name or "") .. ',\n "kennung": ' .. js(S.kennung()) .. ',\n' ..
    ((okP and type(pfad) == "string" and pfad ~= "") and (' "modellPfad": ' .. js(pfad) .. ',\n') or "") ..
    ' "funke": ' .. js(brett) .. ',\n "ethos": ' .. js(ethos) .. ',\n "fenster": [ ' .. table.concat(fe, ", ") .. ' ],\n' ..
    ' "studioDatei": ' .. sd .. ',\n "sensoren": [\n  ' .. table.concat(z.sensoren, ",\n  ") .. '\n ],\n' ..
    ' "studioQuelle": ' .. js(w.studioQuelle or "") .. ',\n "studioWahl": ' .. js(w.studioWahl or "auto") .. ',\n' ..
    ' "ansichtGenutzt": ' .. js(w.ansichtGenutzt or "") .. ',\n "angepasst": ' .. (w.angepasst and "true" or "false") .. ',\n' ..
    ' "hinweis": ' .. js(w.studioFehl or w.anpText or "") .. '\n}\n'
  w.infoZ = nil
  if t == w.infoAlt then return true end
  local _, _, _, pi = S.pfade()
  if os.mkdir then pcall(os.mkdir, "SCRIPTS:/studio") end
  local ok, f = pcall(io.open, pi, "w")
  if ok and f then
    local okW = pcall(f.write, f, t)
    pcall(f.close, f)
    if okW then w.infoAlt = t else print("Gas Engine ECU: Info-Datei nicht geschrieben") end
  else
    print("Gas Engine ECU: Info-Datei nicht geschrieben")
  end
  return true
end

return I
