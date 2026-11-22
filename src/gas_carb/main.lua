-- Gas Engine Carb: Telemetrie-Vollbild für Ethos (Widget, Seite 1 Motor, Seite 2 Elektrik).
-- Diese Datei meldet nur das Widget an. Die Arbeit steckt in kern.lua und wird erst beim ersten Gebrauch geladen.
local NAME = "Gas Engine Carb"
local INFO = "Vollbild-Telemetrie für Vergasermotoren mit FrSky AES: Motor, Elektrik und Flug-Übersicht mit Warnungen und Ansagen."
local PAKET_KEY = "local.gasengine.carb"   -- Schlüssel der Suite, nie ändern
local VERSION = "0.12.3"
local K = nil
local gemeldet = {}
local instanzen = 0   -- lebende Widget-Objekte (Speicher freigeben, sobald keines mehr da ist)

local function kern()
  if K == nil then
    local f, e = loadfile("kern.lua")
    if not f then error(e, 0) end
    K = f()
    K.VERSION = VERSION
  end
  return K
end

-- Speicher freigeben: Ethos 26.2 meldet Widgets kein «close». Nach dem Modellwechsel lässt Ethos das Widget-Objekt
-- los; räumt die Müllabfuhr es weg, ruft Lua __gc. Ist dann kein Objekt mehr da, fallen der Kern und alle von ihm
-- geladenen Teile (Zeichnen, Seiten, Studio, Übersetzung) weg. Beim nächsten create lädt kern() alles neu.
local WEG = {
  __gc = function()
    instanzen = instanzen - 1
    if instanzen <= 0 then
      instanzen = 0
      K = nil
      gemeldet = {}
    end
  end,
}

local function merke(w)
  if getmetatable(w) == nil then
    instanzen = instanzen + 1
    setmetatable(w, WEG)
  end
  return w
end

-- Ein Fehler im Skript darf die Funke nicht stören: melden (einmal pro Stelle) und weiterlaufen.
local function ruf(name, w, ...)
  local ok, a = pcall(function(...) return kern()[name](w, ...) end, ...)
  if ok then return a end
  if not gemeldet[name] then
    gemeldet[name] = true
    print("Gas Engine Carb: Fehler in " .. name .. ": " .. tostring(a))
  end
  if type(w) == "table" then w.fehler = name .. ": " .. tostring(a) end
  return nil
end

local function create()
  local ok, w = pcall(function() return kern().neu() end)
  if ok and type(w) == "table" then return merke(w) end
  print("Gas Engine Carb: Fehler in create: " .. tostring(w))
  return { fehler = "create: " .. tostring(w) }
end

-- Nach einem Neuladen der Skripte ruft Ethos die Widgets kurz ohne Widget-Objekt auf: dann nichts tun.
local function paint(w)
  if type(w) ~= "table" then return end
  if w.fehler and not w.cfg then
    lcd.color(lcd.RGB(239, 68, 68))
    lcd.font(FONT_S)
    local ok, n = pcall(model.name)
    lcd.drawText(8, 8, ((ok and type(n) == "string" and n ~= "") and n or "-") .. ": " .. w.fehler)
    return
  end
  ruf("zeichne", w)
end

local function init()
  system.registerWidget({
    key = "gascarb",
    name = NAME,
    create = create,
    wakeup = function(w) if type(w) == "table" and w.cfg then ruf("wecke", w) end end,
    paint = paint,
    event = function(w, kat, wert, x, y) if type(w) == "table" and w.cfg then return ruf("ereignis", w, kat, wert, x, y) end end,
    configure = function(w) if type(w) == "table" and w.cfg then ruf("menue", w) end end,
    read = function(w) if type(w) == "table" and w.cfg then ruf("lies", w) end end,
    write = function(w) if type(w) == "table" and w.cfg then ruf("schreibe", w) end end,
    title = false,
  })
end

return { init = init }
