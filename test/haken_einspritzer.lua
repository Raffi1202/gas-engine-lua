-- TESTHAKEN (nur im Simulator eingefügt): künstliche Quellen je Szenario, automatische Prüfungen als TEST-Zeilen.
do
  local SZ = "@SZ@"
  local EN = SZ:sub(-3) == "_en"          -- Szenario mit «_en»: Anzeige auf Englisch
  if EN then SZ = SZ:sub(1, -4) end
  if model then model.name = function() return "ECU DEMO" end end   -- neutraler Modellname für Bilder
  local GROESSE = @GR@
  local function Q(wert, einh, lo, hi, dez)
    return {
      value = function(self, opt) if type(wert) == "function" then return wert(opt) end return wert end,
      minimum = function() return lo end, maximum = function() return hi end,
      stringUnit = function() return einh or "" end, decimals = function() return dez or 0 end,
      category = function() return 99 end,
    }
  end
  local d = { sw0 = 0, z1 = 142, z2 = 138, m1 = 151, m2 = 146, rpm = 6850, rpmMax = 7420, gas = 64, druck = 3.1, verbr = 712,
    fluss = 38, hoehe = 320, hoeheMax = 410, vario = 1.2, speed = 92, ecu = 15.2, rssi = 98, sw = 0, lauf = 754, imp = nil }
  local function setze(t) for k, x in pairs(t) do d[k] = x end end
  if SZ == "kalt" then
    setze({ sw = 100, z1 = 61, z2 = 58, m1 = 61, m2 = 58, rpm = 2150, rpmMax = 2400, gas = 12, verbr = 3, fluss = 9,
      hoehe = 0, hoeheMax = 0, vario = 0, speed = 0, lauf = 12 })
  elseif SZ == "chokewarn" then
    setze({ sw = 100, z1 = 118, z2 = 115, m1 = 118, m2 = 115, rpm = 3900, rpmMax = 4100, gas = 35, verbr = 30, fluss = 16,
      hoehe = 0, hoeheMax = 0, vario = 0, speed = 0, lauf = 135 })
  elseif SZ == "alarm" then
    setze({ z2 = 204, m2 = 204, druck = 1.4, verbr = 2090 })
  elseif SZ == "motoraus" then   -- ab 1.8.1: Motor läuft mit Choke, dann Kill über den Motorschalter (Entscheide 21.11.)
    setze({ sw = 100, z2 = 110, m2 = 110, druck = 1.0, verbr = 2090 })
  elseif SZ:sub(1, 7) == "schlepp" then
    setze({ sw = -100 })
  elseif SZ == "unsinn" then
    setze({ z1 = 0 / 0, z2 = math.huge, rpm = -5, druck = 1e30, gas = 0 / 0, ecu = -math.huge, hoehe = "x", vario = nil, fluss = 1e9 })
  end
  local zeit0 = nil
  local neuAlt = K.neu
  function K.neu()
    local w = neuAlt()
    local c = w.cfg
    if SZ ~= "teil" and SZ ~= "leer" then
      c.cht1 = Q(function() return d.z1 end, "°C", 0, 300); c.cht2 = Q(function() return d.z2 end, "°C", 0, 300)
      c.rpm = Q(function() return d.rpm end, "rpm", 0, 10000)
      c.druck = Q(function() return d.druck end, "bar", 0, 5, 1); c.ecuV = Q(function() return d.ecu end, "V", 0, 20, 1)
      c.gas = Q(function() return d.gas * 20.48 - 1024 end, "", -1024, 1024)
      c.motorSw = Q(function() return d.sw end, "", -100, 100)
      c.hoehe = Q(function() return d.hoehe end, "m", 0, 1000); c.vario = Q(function() return d.vario end, "m/s", -10, 10, 1)
      c.speed = Q(function() return d.speed end, "km/h", 0, 300)
      c.rssi = Q(function() return d.rssi end, "%", 0, 100)
      if SZ:sub(1, 7) == "schlepp" then   -- zwei 4S-Akkus mit Zellenoption
        local function lipo(z)
          return Q(function(opt)
            local o = type(opt) == "table" and opt.options or nil
            if o == nil then local s = 0 for _, x in ipairs(z) do s = s + x end return s end
            if o == OPTION_CELL_COUNT then return #z end
            for i = 1, #z do if o == OPTION_CELL_INDEX(i) then return z[i] - (d.zab or 0) * (i == 3 and 1 or 0) end end
            return nil end, "V", 0, 20, 2)
        end
        c.lipo1 = lipo({ 4.05, 4.04, 4.06, 4.05 }); c.lipo2 = lipo({ 3.98, 3.97, 3.99, 3.96 })
      end
      c.fluss = Q(function() return d.fluss end, "ml/min", 0, 500)
      c.impulse = Q(function() return d.imp end, "", 0, 1e6)
      c.winde = Q(-100, "", -100, 100); c.bremse = Q(SZ == "normal" and 100 or -100, "", -100, 100)
      c.laeuftAb = 800; c.chtKalt = 90; c.chtWarn = 170; c.chtAlarm = 190; c.chtDiff = 25; c.rpmWarn = 7500; c.rpmAlarm = 8200
      c.druckVon = 22; c.druckBis = 40; c.druckAlarm = 18; c.ecuWarn = 110; c.ecuAlarm = 100
      c.tank = 2550; c.tankRes = 20; c.tankLeer = 8; c.chokeTemp = 100; c.chokeGas = 30
      -- ab 1.2.0: Akkus mit Rollen und Zellenzahl, Zylinder 3/4, Schalternamen, alter Zündakku
      local function zellen(z)
        return Q(function(opt)
          local o = type(opt) == "table" and opt.options or nil
          if o == nil then local s = 0 for _, x in ipairs(z) do s = s + x end return s end
          if o == OPTION_CELL_COUNT then return #z end
          for i = 1, #z do if o == OPTION_CELL_INDEX(i) then return z[i] end end
          return nil end, "V", 0, 30, 2)
      end
      if SZ == "akkus" or SZ == "alt" then
        c.lipo1 = zellen({ 4.12, 4.11, 4.12, 4.10, 4.11, 4.12 }); c.a1Rolle = 1
        c.lipo2 = zellen({ 4.08, 4.09, 4.07, 4.08, 4.06, 4.08 }); c.a2Rolle = 1
        c.lipo3 = zellen({ 3.81, 3.80, 3.62, 3.79, 3.80, 3.81 }); c.a3Rolle = 3
        c.z1Warn, c.z2Warn, c.z3Warn, c.z3Alarm, c.zDiff = 370, 370, 370, 340, 15
        c.rxBatt = Q(8.1, "V", 0, 20, 2); c.rx1R24 = Q(98, "%", 0, 100); c.rx2R24 = Q(94, "%", 0, 100); c.rx1Vfr = Q(100, "%", 0, 100)
        c.winde = Q(100, "", -100, 100); c.bremse = Q(100, "", -100, 100); c.sw1Name = "Rückholer"; c.sw2Name = "Licht"
        if SZ == "alt" then c.lipo3 = nil; c.zuendAkku = Q(7.9, "V", 0, 20, 2) end
      elseif SZ == "altvoll" then   -- alter Zündakku, aber alle drei Akkus belegt: eigene Karte bleibt
        c.lipo1 = zellen({ 4.1, 4.1 }); c.lipo2 = zellen({ 4.0, 4.0 }); c.lipo3 = zellen({ 3.9, 3.9 })
        c.zuendAkku = Q(7.9, "V", 0, 20, 2); c.rbK1 = Q(1.2, "A", 0, 20, 1); c.rbK2 = Q(0.4, "A", 0, 20, 1)
      elseif SZ == "spannung" then
        c.lipo1 = Q(24.3, "V", 0, 30, 2); c.a1S = 6; c.a1Rolle = 4; c.z1Warn = 370
      elseif SZ == "zyl1" or SZ == "zyl2" or SZ == "zyl3" or SZ == "zyl4" or SZ == "zyl5" or SZ == "zyl5heiss" then
        c.zylAnz = tonumber(SZ:sub(4, 4))
        c.cht3 = Q(function() return d.z1 + 6 end, "°C", 0, 300); c.cht4 = Q(function() return d.z2 - 3 end, "°C", 0, 300)
        c.cht5 = Q(function() if SZ == "zyl5heiss" and zeit0 then return os.clock() - zeit0 < 6 and 180 or 238 end return d.z1 - 8 end,
          "°C", 0, 300)   -- zyl5heiss: über «Warnung» (170), nach 6 s über «Alarm» (190); Unterschied zu Zyl. 2 > 25
      end
    elseif SZ == "teil" then
      -- nur ein Teil zugewiesen: Zylinder, Drehzahl, Höhe; Drehzahl-Sensor fällt nach 8 s weg
      c.cht1 = Q(function() return d.z1 end, "°C", 0, 300); c.cht2 = Q(function() return d.z2 end, "°C", 0, 300)
      c.rpm = Q(function() if zeit0 and os.clock() - zeit0 > 8 then return nil end return d.rpm end, "rpm", 0, 10000)
      c.hoehe = Q(function() return d.hoehe end, "m", 0, 1000)
    end
    if SZ == "motoraus" then c.tankMin = 15 end
    c.sprache = EN and 2 or 1
    if EN and c.sw1Name then c.sw1Name, c.sw2Name = "Retract", "Light" end
    w.qTele = Q(1)
    w.testInit = true
    return w
  end
  K.lies = function(w) w.autoOffen = false; w.studioZ = { art = "start" }; w.fenster = {} end   -- Studio wie nach dem Modellwechsel
  K.schreibe = function() print("TEST schreibe aufgerufen, verbr", K.w and K.w.tk.verbr) end
  local schritt = 0
  local weckeAlt = K.wecke
  function K.wecke(w)
    local now = os.clock()
    if w.testInit then
      w.testInit = nil
      K.w = w
      zeit0 = now
      K.grenzen(w)
      w.hoch.cht1, w.hoch.cht2, w.hoch.rpm, w.hoch.hoehe = d.m1, d.m2, d.rpmMax, d.hoeheMax
      w.tk.verbr = d.verbr
      if d.fluss and d.fluss < 1000 then w.tk.pn = 1; w.tk.pt[1] = now - 60; w.tk.pv[1] = d.verbr - d.fluss end
      if d.lauf > 0 then w.lauf = true; w.laufSeit = now - d.lauf; w.laufSumme = d.lauf end
    end
    if SZ == "teleweg" then   -- Telemetrie 3 s da, 4 s weg, dann wieder da
      w.qTele = Q(function() local tt = now - zeit0 return (tt >= 3 and tt < 7) and 0 or 1 end)
    end
    if GROESSE == 2 then lcd.getWindowSize = function() return 480, 320 end end
    if GROESSE == 3 then lcd.getWindowSize = function() return 784, 316 end end   -- Kompakt X20/X18RS
    if GROESSE == 4 then lcd.getWindowSize = function() return 472, 210 end end   -- Kompakt X18
    if GROESSE == 5 then lcd.getWindowSize = function() return 630, 258 end end   -- Kompakt X14
    if GROESSE == 6 then lcd.getWindowSize = function() return 640, 360 end end   -- Vollbild 640 x 360
    if GROESSE == 7 then lcd.getWindowSize = function() return 480, 272 end end   -- Vollbild 480 x 272
    local r = weckeAlt(w)
    local t = now - zeit0
    if SZ == "wechsel" and t > 2 and (w.nW or 0) < 10 and t - (w.tW or 0) > 1.5 then   -- Modellwechsel 10x (Studio neu laden)
      w.tW, w.nW = t, (w.nW or 0) + 1
      K.lies(w)
      collectgarbage(); collectgarbage()
      print("TEST wechsel", w.nW, "lua-kb", math.floor(collectgarbage("count")), "studio", tostring(w.studioStatus))
    end
    if SZ == "dreh" and not w.tR and t > 2 then w.tR = true   -- Drehrad: rechts, rechts, rechts, links
      local f = {}
      for _, k in ipairs({ KEY_ROTARY_RIGHT, KEY_ROTARY_RIGHT, KEY_ROTARY_RIGHT, KEY_ROTARY_LEFT }) do
        local ok = K.ereignis(w, EVT_KEY, k, 0, 0); f[#f + 1] = tostring(ok) .. ":" .. w.seite end
      print("TEST dreh", table.concat(f, " "), "andere Taste", tostring(K.ereignis(w, EVT_KEY, KEY_ENTER_FIRST or 99, 0, 0)))
    end
    -- Ablauf der Prüfungen
    if schritt == 0 and t > 6 then
      schritt = 1
      local akt = {}
      for i = 1, w.nAktiv do akt[#akt + 1] = w.aktiv[i].wav .. "/" .. w.aktiv[i].stufe end
      print("TEST zustand", w.zustand, "stufe", w.stufe, "aktiv", table.concat(akt, ","))
      print("TEST werte", w.v.cht1, w.v.cht2, w.v.rpm, w.v.druck, w.v.gas, w.v.ecuV, w.v.hoehe, "zuend", w.v.zuend, "choke", w.v.choke)
      print("TEST tank verbr", w.tk.verbr, "rest", w.tk.rest, "proz", w.tk.proz, "restMin", w.tk.restMin, "fluss", w.tk.fluss)
      print("TEST fehler", w.fehler, "ziele", w.nZiele)
      local ak = {}
      for i = 1, 3 do local x = w.akku[i]; ak[#ak + 1] = (w.g.aName[i] or "?") .. "/" .. (w.g.aWav[i] or "?") .. "/n" .. tostring(x.n) .. "/t" .. tostring(x.tief and math.floor(x.tief * 100)) .. "/m" .. tostring(x.mittel and math.floor(x.mittel * 100)) end
      print("TEST akkus", table.concat(ak, " "), "zuendAlt", tostring(w.cfg.zuendAkku ~= nil), "nZyl", w.nZyl, "diff", w.v.chtDiff)
      local m = system.getMemoryUsage and system.getMemoryUsage()
      collectgarbage()
      print("TEST lua-kb", math.floor(collectgarbage("count")), "frei", m and m.luaRamAvailable)
    end
    if SZ == "tank" then
      -- Impulszähler: 6 s lang 50 Impulse pro 0,1 s, dann Neustart des Sensors (Rücksprung auf 0), dann weiter
      if t < 12 then d.imp = (d.imp or 0) + 5 elseif t < 12.2 then d.imp = 0 else d.imp = d.imp + 5 end
      if schritt == 1 and t > 14 then
        schritt = 2
        print("TEST tank nach Impulsen verbr", w.tk.verbr, "quelle", w.tk.quelle)
        local z
        for i = 1, w.nZiele do if w.ziele[i].id == "vollgetankt" then z = w.ziele[i] end end
        if z then local x, y = math.floor(z.x + z.b / 2), math.floor(z.y + z.h / 2)
          print("TEST tippe vollgetankt", x, y, K.ereignis(w, EVT_TOUCH, TOUCH_START, x, y), K.ereignis(w, EVT_TOUCH, TOUCH_END, x, y)) end
      elseif schritt == 2 and t > 24 then
        schritt = 3
        print("TEST nach 1x tippen dialog", w.dialog, "verbr", w.tk.verbr)
        for i = 1, w.nZiele do if w.ziele[i].id == "ja_tank" then
          local z = w.ziele[i]; local x, y = math.floor(z.x + z.b / 2), math.floor(z.y + z.h / 2)
          -- zuerst ein Wisch über den Knopf: darf nichts auslösen
          K.ereignis(w, EVT_TOUCH, TOUCH_START, x, y); K.ereignis(w, EVT_TOUCH, TOUCH_MOVE, x + 40, y); K.ereignis(w, EVT_TOUCH, TOUCH_END, x + 40, y)
          print("TEST nach Wisch ueber JA dialog", w.dialog, "verbr", w.tk.verbr)
          K.ereignis(w, EVT_TOUCH, TOUCH_START, x, y); K.ereignis(w, EVT_TOUCH, TOUCH_END, x, y) end end
      elseif schritt == 3 and t > 25.5 then
        schritt = 4
        print("TEST nach JA dialog", w.dialog, "verbr", w.tk.verbr, "hinweis", w.hinweis)
      end
    end
    if SZ:sub(1, 7) == "schlepp" then
      local function tippe(id)
        for i = 1, w.nZiele do if w.ziele[i].id == id then local z = w.ziele[i]
          local x, y = math.floor(z.x + z.b / 2), math.floor(z.y + z.h / 2)
          K.ereignis(w, EVT_TOUCH, TOUCH_START, x, y); K.ereignis(w, EVT_TOUCH, TOUCH_END, x, y); return true end end
        return false
      end
      local function zeig(was) print("TEST", was, "dialog", w.dialog, "sl", w.sl and (math.floor(w.sl.ml) .. (w.sl.pause and " pause" or " aktiv")), "liste", #w.schlepps, w.schlepps[1] and math.floor(w.schlepps[1].ml), "tank", math.floor(w.tk.verbr), "ueVerbr", w.ue.verbr and math.floor(w.ue.verbr)) end
      if schritt >= 2 and schritt <= 6 then d.hoehe = 100 + t * 20; d.vario = (t < 14) and 3.5 or -2.5; d.zab = 0.3; d.z1 = 150 + t; d.z2 = 146 + t end
      if schritt == 1 and t > 7 then schritt = 2; d.sw = 0; zeig("Ein")
      elseif schritt == 2 and t > 10 then schritt = 3; d.sw = -100; zeig("Aus")
      elseif schritt == 3 and t > 11 then schritt = 4; zeig("nach Aus"); print("TEST tippe nein", tippe("nein_schlepp")); zeig("nach Nein")
      elseif schritt == 4 and t > 13 then schritt = 5; d.sw = 0; zeig("wieder Ein")
      elseif schritt == 5 and t > 16 then schritt = 6; d.sw = -100
      elseif schritt == 6 and t > 17 then schritt = 7; zeig("Aus 2"); print("TEST tippe ja", tippe("ja_schlepp")); zeig("nach Ja")
      elseif schritt == 7 and t > 18 then schritt = 8; d.sw = 0
      elseif schritt == 8 and t > 19 then schritt = 9; d.sw = -100
      elseif schritt == 9 and t > 20 then schritt = 10; zeig("Aus 3 ohne Antwort"); d.sw = 0
      elseif schritt == 10 and t > 21 then schritt = 11; zeig("wieder Ein ohne Antwort")
        w.seite = 3; w.tB = 0
      elseif schritt == 11 and t > 21.2 and (SZ == "schleppx" or SZ == "schleppy" or SZ == "schleppz") then schritt = 31
        w.schlepps = { { nr = 1, ml = 5 }, { nr = 2, ml = 7, h = 300 }, { nr = 3, ml = 9 } }; w.nSchlepp = 3
        print("TEST x vorher tank", math.floor(w.tk.verbr), "ue", w.ue.verbr and math.floor(w.ue.verbr))
      elseif schritt == 31 and t > 21.6 then schritt = 32; print("TEST x zeile2", tippe("zs2"), w.dialog, w.detail)
      elseif schritt == 32 and t > 22.0 then schritt = 33; print("TEST x laufend loeschbar?", "-")
        print("TEST x loeschen", tippe("loeschen"), w.dialog)
      elseif schritt == 33 and t > 22.4 then schritt = 34
        if os.getenv == nil or true then end
        if SZ == "schleppy" then return r end
        print("TEST x ja", tippe("ja_loeschen"), w.dialog)
        local n = {} for _, e in ipairs(w.schlepps) do n[#n + 1] = e.nr .. ":" .. e.ml end
        print("TEST x nachher", table.concat(n, " "), "nSchlepp", w.nSchlepp, "tank", math.floor(w.tk.verbr), "ue", w.ue.verbr and math.floor(w.ue.verbr))
      elseif schritt == 34 and t > 22.8 then schritt = 35; print("TEST x zsl", tippe("zsl"), w.dialog, w.detail)
      elseif schritt == 35 and t > 23.2 and SZ ~= "schleppz" then schritt = 36; print("TEST x loeschen laufend", tippe("loeschen"), w.dialog)
      elseif schritt == 36 and t > 23.6 then schritt = 37; print("TEST x ja laufend", tippe("ja_loeschen"), w.dialog, "sl", w.sl, "liste", #w.schlepps, "nSchlepp", w.nSchlepp, "tank", math.floor(w.tk.verbr))
      elseif schritt == 11 and t > 21.2 and SZ ~= "schleppl" then schritt = 21
        local s1 = w.schlepps[1]
        print("TEST schlepp1", s1 and s1.nr, s1 and s1.ml, s1 and s1.h, s1 and s1.steig, s1 and s1.sink, s1 and s1.fl, s1 and s1.t, s1 and s1.cht, s1 and s1.zel, s1 and s1.rpm, s1 and s1.ecu)
        print("TEST tippe zeile1", tippe("zs1"), "dialog", w.dialog, "detail", w.detail)
      elseif schritt == 21 and t > 21.6 and SZ ~= "schleppd" then schritt = 22
        print("TEST tippe reset hinter detail", tippe("zuruecksetzen"), "dialog", w.dialog)
        print("TEST tippe schliessen", tippe("schliessen"), "dialog", w.dialog)
      elseif schritt == 22 and t > 22 then schritt = 23
        print("TEST tippe laufend", tippe("zsl"), "dialog", w.dialog, "detail", w.detail)
      elseif schritt == 23 and t > 22.4 and SZ ~= "schleppd" then schritt = 11.5
        print("TEST tippe schliessen", tippe("schliessen"), "dialog", w.dialog)
      elseif schritt == 11.5 and t > 22.8 then schritt = 12; print("TEST tippe reset", tippe("zuruecksetzen")); zeig("Reset gefragt")
      elseif schritt == 12 and t > 23.5 then schritt = 13; print("TEST tippe ja reset", tippe("ja_reset")); zeig("nach Reset")
      end
    end
    if SZ == "motoraus" then
      local function aktiv(was)
        local akt = {}
        for i = 1, w.nAktiv do akt[#akt + 1] = w.aktiv[i].wav .. "/" .. w.aktiv[i].stufe end
        print("TEST motoraus", was, "lauf", tostring(w.lauf), "zuend", tostring(w.v.zuend), "restMin", tostring(w.tk.restMin),
          "aktiv", table.concat(akt, ","))
      end
      if schritt == 1 and t > 7 then schritt = 2; aktiv("Motor ein"); d.sw, d.rpm, d.fluss = -100, 0, 0
      elseif schritt == 2 and t > 14 then schritt = 3; aktiv("Motor aus") end
    end
    if SZ == "teil" and schritt == 1 and t > 12 then
      schritt = 2
      print("TEST teil nach wegfall rpm", w.v.rpm, "zustand", w.zustand, "fehler", w.fehler)
    end
    return r
  end
end
