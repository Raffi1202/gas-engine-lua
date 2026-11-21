-- Gas Engine Carb: Einstellungen im Ethos-Menü (Widget lange drücken › Widget konfigurieren).
-- Gruppen als aufklappbare Felder; oben der Knopf zum automatischen Zuweisen der Sensoren.
return function(w, F, fertig, suche, zurueck, waehlen)
  local c = w.cfg
  local T = w.uebers or function(t) return t end   -- Englisch: Menütexte übersetzen
  local function leer(v)
    if v == nil then return true end
    if CATEGORY_NONE then
      local ok, k = pcall(v.category, v)
      if ok and k == CATEGORY_NONE then return true end
    end
    return false
  end

  -- Physical ID / AppID eines zugewiesenen Telemetriesensors, damit gleichnamige unterscheidbar sind
  local function kennung(q)
    if q == nil or not CATEGORY_TELEMETRY_SENSOR then return "" end
    local okk, k = pcall(q.category, q)
    if not okk or k ~= CATEGORY_TELEMETRY_SENSOR then return "" end
    local oka, a = pcall(q.appId, q)
    local okp, p = pcall(q.physId, q)
    if not (oka and type(a) == "number") then return "" end
    return string.format(" [%s/%04X]", (okp and type(p) == "number") and string.format("%02X", p) or "--", a)
  end

  local kopf = form.addLine(T("Sensoren automatisch suchen"))
  local info = T("füllt nur leere Felder")
  if form.addButton then
    form.addButton(kopf, nil, { text = T("Suchen"), press = function()
      local ok = pcall(suche)
      info = ok and T("Suche läuft") or T("Fehler bei der Suche")
    end })
  end
  form.addStaticText(form.addLine("Gas Engine Carb " .. tostring(w.version or "")), nil, info)
  -- Lua-Studio: Stand anzeigen und Änderungen an der Funke verwerfen
  local mitStudio = w.studio and w.studio.st
  local zl = form.addLine(T(mitStudio and "Studio-Datei geladen" or "Einstellungen"))
  if form.addButton and zurueck then
    form.addButton(zl, nil, { text = T(mitStudio and "Zurück auf Studio-Stand" or "Zurück auf Standard"), press = function()
      if not form.openDialog then return end              -- ohne Rückfrage nichts verwerfen
      pcall(form.openDialog, {
        title = T(mitStudio and "Zurück auf Studio-Stand?" or "Zurück auf Standard?"),
        message = T(mitStudio and "Änderungen an der Funke werden verworfen." or "Alle Einstellungen gehen auf den Werkwert. Sensoren bleiben."),
        buttons = {      -- Ethos zeigt den letzten Knopf links und wählt ihn vor: ABBRECHEN zuletzt
          { label = T("JA, ZURÜCKSETZEN"), action = function() pcall(zurueck) return true end },
          { label = T("ABBRECHEN"), action = function() return true end },
        },
      })
    end })
  end
  -- Studio-Layout wählen (R2.2): Liste baut K.menue beim Öffnen; 0 = automatisch (Modellname)
  if form.addChoiceField and w.studioListe and waehlen then local okW, eW = pcall(function()
    local l = { { T("automatisch (Modellname)"), 0 } }
    for i, e in ipairs(w.studioListe) do l[#l + 1] = { e[2], i } end
    form.addChoiceField(form.addLine(T("Studio-Layout")), nil, l, function()
      for i, e in ipairs(w.studioListe) do if e[1] == w.wahl then return i end end
      return 0
    end, function(v)
      local e = w.studioListe[v]
      pcall(waehlen, e and e[1] or nil)
    end)
  end) if not okW then print("Studio-Layout menu: " .. tostring(eW)) end end
  -- Kurze Zeilen: links nur das Feld, rechts die Anzahl; lange Texte überlappten sonst den rechten Teil (X18RS)
  local hw = w.suchHinweise or {}
  local en = w.sp == 2
  if #hw > 0 then
    form.addLine(en and "Several sensors match, please check:" or "Mehrere Sensoren passen, bitte prüfen:")
  end
  for _, h in ipairs(hw) do
    local f = F.feld(h[1])
    form.addStaticText(form.addLine(f and T(f[3]) or h[1]), nil, tostring(h[2]) .. (en and " sensors" or " Sensoren"))
    form.addStaticText(form.addLine(""), nil, (en and "chosen: " or "gewählt: ") .. h[3])
  end

  for _, g in ipairs(F.gruppen) do
    local panel = form.addExpansionPanel(T(g[1]))
    pcall(panel.open, panel, false)
    for _, f in ipairs(g[2]) do
      if not f.versteckt or c[f[1]] ~= nil then   -- versteckt nur, solange nicht belegt
      local name, art = f[1], f[2]
      local line = form.addLine(T(f[3]) .. (art == "q" and kennung(c[name]) or ""), panel)
      local function get() return c[name] end
      if f.alle then   -- «alle»: an, wenn jeder Haken der Gruppe an ist; setzt alle Haken der Gruppe
        get = function() for _, h in ipairs(g[2]) do if h.studio and c[h[1]] == false then return false end end return true end
      end
      local function set(v)
        if f.alle then
          for _, h in ipairs(g[2]) do if h.studio then c[h[1]] = v == true end end
          fertig() return
        end
        if art == "q" and leer(v) then v = nil end
        c[name] = v
        -- Akkuart gewechselt: Grenzen dieses Akkus auf die Werte der Art setzen
        if f.art and F.ART_GRENZE and F.ART_GRENZE[v] then
          c["z" .. f.art .. "Warn"], c["z" .. f.art .. "Alarm"] = F.ART_GRENZE[v][1], F.ART_GRENZE[v][2]
        end
        fertig()
      end
      if art == "q" then
        -- nur echte Quellen (userdata) ans Feld geben: eine Lua-Tabelle (Testsensoren) lässt Ethos mit «true» abbrechen
        form.addSourceField(line, nil, function() local v = c[name] if type(v) == "userdata" then return v end return nil end, set)
      elseif art == "b" then
        form.addBooleanField(line, nil, get, set)
      elseif art == "w" then
        local wahl = {}
        for i, a in ipairs(f[5]) do wahl[i] = { T(a[1]), a[2] } end
        form.addChoiceField(line, nil, wahl, get, set)
      elseif art == "z" then
        local fe = form.addNumberField(line, nil, f[5], f[6], get, set)
        if fe then
          if f[7] and f[7] > 0 then pcall(fe.decimals, fe, f[7]) end
          if f[8] then pcall(fe.suffix, fe, f[8]) end
          if f[9] then pcall(fe.step, fe, f[9]) end
        end
      elseif art == "t" and form.addTextField then
        form.addTextField(line, nil, function() return c[name] or f[4] end,
          function(v) c[name] = F.text(v) or f[4]; fertig() end)
      end
      end
    end
  end
end
