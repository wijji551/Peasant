extends SceneTree
## Build 5, stage 2: the smithy's three grades (crude, refined, steel), wear, and the old steel mine.
## Run:  godot --headless --path godot -s res://tests/smithy_test.gd

var R: Rules
var m: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func dawn(fight: bool) -> void:
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()
	if fight: m.fought = true
	R.step(STEP); R.ev.clear()


func _init() -> void:
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	var st := D.station("smithy")
	m.x = st.x; m.z = st.z; m.iron = 30; m.wood = 30
	var cs := D.crude_of(2)
	ok("a crude spear is a spear, weaker", D.IT[cs].base == 2 and D.IT[cs].dmg < D.IT[2].dmg and D.IT[cs].tier == "crude", D.IT[cs].n)
	ok("and cheaper", D.IT[cs].cost.iron < D.IT[2].cost.iron)
	R.do_act(m, "forge", cs)
	ok("anyone can forge one", m.wpn == cs)
	dawn(false)
	ok("a night without fighting does not wear it", m.wpn == cs)
	dawn(true)
	ok("a night's fighting chips it", m.wpn == cs + 1 and D.IT[m.wpn].n.begins_with("chipped"), D.IT[m.wpn].n)
	dawn(true)
	ok("a second, and it falls apart", m.wpn == 0 and R.dawn.lines.any(func(l): return l.contains("fallen to bits")))
	ok("the smithy will not make a chipped one", not Rules.can_forge(m, cs + 1))
	# ---------- steel
	var ss := D.steel_of(2)
	ok("a steel spear hits harder than a refined one", D.IT[ss].dmg > D.IT[2].dmg and D.IT[ss].cost.has("steel"))
	m.books[3] = 3
	ok("steel needs rank 4 of Hammer and Tongs", not Rules.can_forge(m, ss))
	m.books[3] = 4
	ok("at rank 4 it can be forged", Rules.can_forge(m, ss))
	m.steel = 0
	m.x = st.x; m.z = st.z
	R.do_act(m, "forge", ss)
	ok("but needs steel", m.wpn != ss)
	var sa := D.steel_of(22)
	ok("steel armour is better than iron", D.IT[sa].cut > D.IT[22].cut)
	# ---------- the old steel mine
	m.x = R.STEELM.x + 1.0; m.z = R.STEELM.z; m.state = "ok"
	var it = R.find_interact(m)
	ok("the old steel mine is mined for steel", it != null and it.type == "gather" and it.kind == "steel")
	R.gather_one("steel", null, m)
	ok("which you carry", m.steel == 1)
	m.steel = 10
	m.x = st.x; m.z = st.z
	R.do_act(m, "forge", ss)
	ok("and forge", m.wpn == ss and m.steel < 10)
	var mk := D.station("market")
	m.x = mk.x; m.z = mk.z; m.steel = 5; var c0 := m.coin
	R.do_act(m, "sell", "steel")
	ok("the market pays well for steel", m.coin - c0 == 5 * D.STEEL_SELL)
	m.coin = 100
	R.do_act(m, "buy", "steel")
	ok("but sells none", m.steel == 0)
	ok("steel is saved", R.save_data().players[0].has("steel") and R.save_data().store.has("steel"))

	var fails := lines.filter(func(l): return l.begins_with("FAIL")).size()
	for l in lines: print(l)
	print("%d passed, %d failed" % [lines.size() - fails, fails])
	quit(1 if fails else 0)
