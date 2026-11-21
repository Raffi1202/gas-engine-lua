# Simulator-Ablauf für ein Widget von Gas Engine Lua (fensterloser Ethos-Simulator X18RS, Treiber sim.cjs aus dem Ethos-Lua-Baukasten, Pfad in ETHOS_LUA_TOOLS).
# Aufruf:  python3 test/lauf.py <einspritzer|vergaser> <szenario> <bild.png|-> [sekunden=8] [gross=1|2] [seite=1]
#   szenario Einspritzer: normal alarm chokewarn kalt tank teil unsinn schleppx schleppy schleppz teleweg, oder «echt» (ohne Testhaken)
#   szenario Vergaser:    ein1 aes2 aes4 teleweg, oder «echt»
# Der Testhaken (haken_*.lua) wird nur im Simulator an kern.lua angehängt; die Quellen in src/ bleiben unverändert.
# Ausgegeben werden Fehler- und TEST-Zeilen des Simulators. Bilder kommen nur dorthin, wo sie verlangt werden.
import json, sys, subprocess, os, shutil, tempfile
T = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(T)
WERKZEUG = os.environ.get("ETHOS_LUA_TOOLS")   # Ordner mit sim.cjs (Simulator-Treiber auf Basis des Ethos-WASM-Simulators)
if not WERKZEUG or not os.path.exists(os.path.join(WERKZEUG, "sim.cjs")):
    sys.exit("Simulator-Treiber fehlt: Umgebungsvariable ETHOS_LUA_TOOLS auf den Ordner mit sim.cjs setzen.")
SIM = os.path.join(WERKZEUG, "sim.cjs")
if len(sys.argv) < 4 or sys.argv[1] not in ("einspritzer", "vergaser"):
    print(__doc__ or open(__file__).read().split("\nimport")[0]); sys.exit(2)
art, sz, bild = sys.argv[1], sys.argv[2], sys.argv[3]
warte = float(sys.argv[4]) if len(sys.argv) > 4 else 8
gr = sys.argv[5] if len(sys.argv) > 5 else "1"
seite = int(sys.argv[6]) if len(sys.argv) > 6 else 1
ordner = "gas_ecu" if art == "einspritzer" else "gas_carb"
tmp = tempfile.mkdtemp(prefix="gas-engine-lauf-")
modell = os.path.join(tmp, "modell.json")
# Testmodell liegt bewusst NICHT im Repo (enthält Daten der eigenen Funke), sondern lokal:
QUELLE = os.environ.get("MOTOREN_TESTMODELL", "")
if not QUELLE or not os.path.exists(QUELLE):
    sys.exit("Testmodell fehlt: %s\n(Simulator-Abbild mit Vollbild-Widget Gas Engine ECU; Pfad in der Umgebungsvariable MOTOREN_TESTMODELL)" % QUELLE)
shutil.copy(QUELLE, modell)   # Arbeitskopie, das Original bleibt unverändert
plan = {"skripte": [[os.path.join(REPO, "src", ordner), ordner]], "modell": modell, "ersetze": [], "schritte": [],
        "abbild": os.environ.get("ABBILD") == "1"}
# Lua-Studio: Ordner mit Studio-Dateien als SCRIPTS:/studio/ mitgeben (Umgebungsvariable STUDIO_ORDNER)
if os.environ.get("STUDIO_ORDNER"):
    plan["skripte"].append([os.environ["STUDIO_ORDNER"], "studio"])
if sz != "echt":
    haken = open(os.path.join(T, "haken_%s.lua" % art)).read().replace("@SZ@", sz).replace("@GR@", gr)
    if art == "vergaser":
        # Das Testmodell hat das Vollbild-Widget mit dem Schlüssel des Einspritzers eingerichtet
        plan["ersetze"].append(["scripts/gas_carb/main.lua", 'key = "gascarb"', 'key = "gasecu"'])
    plan["ersetze"].append(["scripts/%s/kern.lua" % ordner, "\nreturn K\n", "\n" + haken + "\nreturn K\n"])
t = 1800
sch = plan["schritte"]
sch += [{"t": t, "tipp": [705, 390]}, {"t": t + 1200, "wisch": [700, 250, 100, 250]}, {"t": t + 2400, "wisch": [700, 250, 100, 250]}]
t += 3900
for i in range(seite - 1):
    sch.append({"t": t, "wisch": [600, 250, 200, 250]}); t += 1000
t += int(warte * 1000)
if bild != "-": sch.append({"t": t, "bild": os.path.abspath(bild)})
sch.append({"t": t + 300, "ende": True})
p = os.path.join(tmp, "plan.json")
json.dump(plan, open(p, "w"))
r = subprocess.run(["node", SIM, p], capture_output=True, text=True)
for z in (r.stdout + r.stderr).splitlines():
    if any(k in z for k in ("Gas Engine", "rror", "TEST", "/audio", "ERSETZE", "playNumber")):
        print(sz, "|", z[:260])
shutil.rmtree(tmp)
