-- TESTHAKEN Vergaser (nur im Simulator eingefügt)
do
  local SZ = "@SZ@"
  local EN = SZ:sub(-3) == "_en"          -- Szenario mit «_en»: Anzeige auf Englisch
  if EN then SZ = SZ:sub(1, -4) end
  local NAME = SZ == "langname" and "VERGASER DEMO MIT LANGEM NAMEN" or "VERGASER DEMO"
  if model then model.name = function() return NAME end end   -- neutraler Modellname für Bilder
  local GROESSE = @GR@
  local function Q(wert, einh, lo, hi, dez)
    return { value = function(self, opt) if type(wert) == "function" then return wert(opt) end return wert end,
      minimum = function() return lo end, maximum = function() return hi end,
      stringUnit = function() return einh or "" end, decimals = function() return dez or 0 end, category = function() return 99 end }
  end
  local function lipo(z)
    return Q(function(opt)
      local o = type(opt) == "table" and opt.options or nil
      if o == nil then local s = 0 for _, x in ipairs(z) do s = s + x end return s end
      if o == OPTION_CELL_COUNT then return #z end
      for i = 1, #z do if o == OPTION_CELL_INDEX(i) then return z[i] end end
      return nil end, "V", 0, 20, 2)
  end
  local neuAlt = K.neu
  function K.neu()
    local w = neuAlt()
    local c = w.cfg
    if SZ == "aes2" or SZ == "aes4" or SZ == "teleweg" or SZ == "fluege" or SZ == "flugdetail" or SZ == "dreh"
      or SZ == "akkus" or SZ == "alt" or SZ == "spannung" or SZ == "zyl3" or SZ == "langname" or SZ == "m3" or SZ == "m4" or SZ == "rbfs" or SZ == "rbok" or SZ == "arten" or SZ == "rbtext" or SZ == "rbtextok" or SZ == "gesamt" then
      c.zylAnz = SZ == "aes4" and 4 or SZ == "zyl3" and 3 or 2
      c.cht1 = Q(128, "°C", 0, 300); c.cht2 = Q(121, "°C", 0, 300); c.cht3 = Q(133, "°C", 0, 300); c.cht4 = Q(117, "°C", 0, 300)
      c.rpm = Q(5400, "rpm", 0, 10000); c.gas = Q(300, "", -1024, 1024); c.motorSw = Q(0, "", -100, 100)
      c.fluss = Q(42, "ml/min", 0, 500); c.hoehe = Q(180, "m", 0, 1000); c.vario = Q(2.4, "m/s", -10, 10, 1)
      c.speed = Q(84, "km/h", 0, 300); c.rssi = Q(92, "%", 0, 100); c.rx1R24 = Q(92, "%", 0, 100); c.rx1Vfr = Q(100, "%", 0, 100)
      c.rxBatt = Q(7.9, "V", 0, 20, 2); c.lipo1 = lipo({ 4.02, 4.01, 4.03, 4.02 }); c.lipo2 = Q(8.1, "V", 0, 20, 2)
      c.tank = 1500; c.chtKalt = 80; c.chtWarn = 160; c.chtAlarm = 180; c.chtDiff = 25; c.laeuftAb = 1500
      w.schlepps = { { nr = 1, ml = 210, h = 420, steig = 3.1 }, { nr = 2, ml = 188, h = 390, steig = 2.8 } }; w.nSchlepp = 2
      w.sl = { ml = 64, h = 180, steig = 2.4, pause = false }
      -- ab 0.3.0: Akkus mit Rollen und Zellenzahl, Schalternamen, alter Zündakku
      if SZ == "akkus" or SZ == "alt" then
        c.lipo1 = lipo({ 4.12, 4.11, 4.12, 4.10, 4.11, 4.12 }); c.a1Rolle = 1
        c.lipo2 = lipo({ 4.08, 4.09, 4.07, 4.08, 4.06, 4.08 }); c.a2Rolle = 1
        c.lipo3 = lipo({ 3.81, 3.80, 3.62, 3.79, 3.80, 3.81 }); c.a3Rolle = 2
        c.z1Warn, c.z2Warn, c.z3Warn, c.z3Alarm, c.zDiff = 370, 370, 370, 340, 15
        c.rx2R24 = Q(94, "%", 0, 100)
        c.winde = Q(100, "", -100, 100); c.bremse = Q(100, "", -100, 100); c.sw1Name = "Rückholer"; c.sw2Name = "Licht"
        if SZ == "alt" then c.lipo3 = nil; c.a3Rolle = nil; c.zuendAkku = Q(7.4, "V", 0, 20, 2) end
      elseif SZ == "m3" or SZ == "m4" then   -- drei Akkus je 3S bzw. 4S, alle Zellen fast voll
        local zz = SZ == "m3" and { 4.12, 4.11, 4.10 } or { 4.12, 4.11, 4.12, 4.10 }
        c.lipo1 = lipo(zz); c.a1Rolle = 1; c.lipo2 = lipo(zz); c.a2Rolle = 1; c.lipo3 = lipo(zz); c.a3Rolle = 2
      elseif SZ == "rbfs" or SZ == "rbok" then   -- Stromweiche: Kanal 3 gestört + Rx1 Failsafe, bzw. nur Lost Frame
        c.bat1V = Q(8.2, "V", 0, 20, 2); c.bat1A = Q(1.4, "A", 0, 50, 1); c.rbK1 = Q(0.8, "A", 0, 20, 1)
        c.rbState = Q(SZ == "rbfs" and 0x00080004 or 0x00100000, "", 0, 4294967295)
      elseif SZ == "rbtext" or SZ == "rbtextok" then   -- Ethos 26.2: Zustand als Text in zwei Sensoren
        c.bat1V = Q(8.2, "V", 0, 20, 2); c.rbK1 = Q(0.8, "A", 0, 20, 1)
        c.rbState = Q(SZ == "rbtext" and "RX1 Failsafe+RX1 Lost Frame" or "RX1 Lost Frame", "", 0, 0)
        c.rbChState = Q(SZ == "rbtext" and "+K2+K3 KO" or "OK", "", 0, 0)
      elseif SZ == "gesamt" then   -- nur Gesamtspannung: 3S mit Zellenzahl, LiFe 2S mit Zellenzahl, 4S ohne Zellenzahl
        c.lipo1 = Q(11.4, "V", 0, 30, 2); c.a1S = 3
        c.lipo2 = Q(6.5, "V", 0, 30, 2); c.a2S = 2; c.a2Typ = 2; c.z2Warn, c.z2Alarm = 310, 290; c.a2Rolle = 1
        c.lipo3 = Q(15.2, "V", 0, 30, 2)
      elseif SZ == "arten" then   -- LiPo 3S, LiFe 2S, NiMH 5 Zellen, Grenzen wie nach Wahl der Art im Menü
        c.lipo1 = lipo({ 3.95, 3.94, 3.95 }); c.a1Typ = 1
        c.lipo2 = lipo({ 3.28, 3.27 }); c.a2Typ = 2; c.z2Warn, c.z2Alarm = 310, 290; c.a2Rolle = 1
        c.lipo3 = lipo({ 1.26, 1.25, 1.24, 1.26, 1.25 }); c.a3Typ = 3; c.z3Warn, c.z3Alarm = 115, 105; c.a3Rolle = 2
      elseif SZ == "spannung" then
        c.lipo1 = Q(24.3, "V", 0, 30, 2); c.a1S = 6; c.a1Rolle = 2; c.z1Warn = 370; c.lipo2 = nil
      elseif SZ == "langname" then
        c.winde = Q(100, "", -100, 100); c.sw1Name = "Winde"
      end
    elseif SZ == "ein1" then
      c.zylAnz = 1; c.cht1 = Q(112, "°C", 0, 300); c.rpm = Q(7200, "rpm", 0, 12000)
      c.rxBatt = Q(5.1, "V", 0, 20, 2); c.rssi = Q(88, "%", 0, 100); c.rx1R24 = Q(88, "%", 0, 100)
    end
    c.sprache = EN and 2 or 1
    if EN and c.sw1Name then c.sw1Name, c.sw2Name = "Retract", "Light" end
    w.qTele = Q(1); K.grenzen(w)
    return w
  end
  K.lies = function(w) w.autoOffen = false; w.studioZ = { art = "start" }; w.fenster = {} end   -- Studio wie nach dem Modellwechsel
  K.schreibe = function() end
  local weckeAlt = K.wecke
  local t0
  function K.wecke(w)
    t0 = t0 or os.clock()
    if SZ == "teleweg" then   -- Telemetrie 3 s da, 4 s weg, dann wieder da
      local tt = os.clock() - t0
      w.qTele = { value = function() return (tt >= 3 and tt < 7) and 0 or 1 end }
    end
    if (SZ == "fluege" or SZ == "flugdetail") and not w.tF then w.tF = true   -- drei Beispielflüge für Seite 3
      w.schlepps = { { nr = 1, ml = 182, h = 380, steig = 3.4, sink = -2.8, fl = 96, t = 640, cht = 168, zel = 3.86, rpm = 8150 },
        { nr = 2, ml = 205, h = 410, steig = 3.6, sink = -3.1, fl = 101, t = 700, cht = 171, zel = 3.84, rpm = 8240 },
        { nr = 3, ml = 174, h = 355, steig = 3.2, sink = -2.6, fl = 94, t = 610, cht = 165, zel = 3.85, rpm = 8090 } }
      w.nSchlepp = 3
      w.ue.verbr, w.ue.hMax, w.ue.steigMax, w.ue.sinkMax, w.ue.chtMax, w.ue.rpmMax, w.ue.flussMax = 570, 410, 3.6, -3.1, 171, 8240, 101   -- Gesamt passend zu den Flügen
    end
    if SZ == "flugdetail" and not w.tD and os.clock() - t0 > 4 then w.tD = true; w.seite = 3; w.dialog, w.detail = "detail", 2 end
    local r = weckeAlt(w)
    if SZ == "dreh" and not w.tR and (os.clock() - t0) > 2 then w.tR = true   -- Drehrad: rechts, rechts, rechts, links
      local f = {}
      for _, k in ipairs({ KEY_ROTARY_RIGHT, KEY_ROTARY_RIGHT, KEY_ROTARY_RIGHT, KEY_ROTARY_LEFT }) do
        local ok = K.ereignis(w, EVT_KEY, k, 0, 0); f[#f + 1] = tostring(ok) .. ":" .. w.seite end
      print("TEST dreh", table.concat(f, " "), "andere Taste", tostring(K.ereignis(w, EVT_KEY, KEY_ENTER_FIRST or 99, 0, 0)))
    end
    if GROESSE == 2 then lcd.getWindowSize = function() return 480, 320 end end
    if GROESSE == 3 then lcd.getWindowSize = function() return 784, 316 end end   -- Kompakt X20/X18RS
    if GROESSE == 4 then lcd.getWindowSize = function() return 472, 210 end end   -- Kompakt X18
    if GROESSE == 5 then lcd.getWindowSize = function() return 630, 258 end end   -- Kompakt X14
    if os.clock() - t0 > 1 and not w.tP then w.tP = true
      print("TEST", SZ, "fehler", w.fehler, "zustand", w.zustand, "nZyl", w.nZyl, "rxBatt", w.v.rxBatt, "diff", w.v.chtDiff)
      local ak = {}
      for i = 1, 3 do local x = w.akku[i]; ak[#ak + 1] = (w.g.aName[i] or "?") .. "/" .. (w.g.aWav[i] or "?") .. "/n" .. tostring(x.n) .. "/t" .. tostring(x.tief and math.floor(x.tief * 100)) .. "/m" .. tostring(x.mittel and math.floor(x.mittel * 100)) end
      print("TEST akkus", table.concat(ak, " "), "zuendAlt", tostring(w.cfg.zuendAkku ~= nil), "rolle3", tostring(w.cfg.a3Rolle), "rbFehler", tostring(w.rbFehler), "kopf", w.kopfText[w.kopfName or 2])
      collectgarbage(); print("TEST lua-kb", math.floor(collectgarbage("count")))
    end
    return r
  end
end
