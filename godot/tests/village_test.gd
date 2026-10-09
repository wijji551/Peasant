extends SceneTree
## Build 5, stage 1: Robert Bailiff at his window, the village bell, the training dummies, peasants talking.
## Run:  godot --headless --path godot -s res://tests/village_test.gd

var R: Rules
var m: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func at(id: String) -> void:
	var st := D.station(id)
	m.x = st.x; m.z = st.z


func _init() -> void:
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	# ---------- Robert Bailiff
	at("window")
	R.do_act(m, "btalk")
	ok("Robert Bailiff talks from his window", R.bail_line != "" and R.bail_t > 0, R.bail_line)
	R.do_act(m, "bknock")
	ok("knocking gets an answer (and a knock)", D.BAILIFF_KNOCK.has(R.bail_line) and R.ev.any(func(e): return e[0] == "knock"))
	var fee0 := R.guard_fee()
	R.do_act(m, "bjeer"); R.do_act(m, "bjeer")
	ok("jeering makes his guards a shilling dearer each time", R.guard_fee() == fee0 + 24 and D.BAILIFF_JEER.has(R.bail_line), R.guard_fee())
	at("bailiff"); m.coin = 500
	R.do_act(m, "guard")
	ok("and he charges it", m.coin == 500 - fee0 - 24, m.coin)
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP); R.night.q = []; R.night.boss = -1; R.undead.clear(); R.step(STEP); R.ev.clear()
	ok("by the next day he has forgotten", R.bail_mood == 0 and R.guard_fee() == D.GUARD_FEE)
	# ---------- the bell
	at("bell"); m.state = "ok"
	var it = R.find_interact(m)
	ok("the village bell can be rung", it != null and it.type == "bell")
	m.eHold = true
	var rang := 0
	for i in 60:
		R.step(STEP)
		for e in R.ev: if e[0] == "bellring": rang += 1
		R.ev.clear()
	m.eHold = false
	ok("it rings, though not every moment", rang >= 1 and rang <= 2, rang)
	# ---------- the training dummies
	m.books[4] = 1; m.xp[4] = 0.0; m.wpn = 1
	var dm: Array = D.DUMMIES[1]
	m.x = dm[0]; m.z = dm[1] - 1.5; m.r = 0
	var hits := 0
	for i in 50:
		m.atkCd = 0
		R.do_attack(m)
		for e in R.ev: if e[0] == "dummy": hits += 1
		R.ev.clear()
	ok("hitting a dummy is practice", hits == 50 and m.xp[4] > 0, [hits, m.xp[4]])
	ok("but only so much a day", m.xp[4] == D.DRILL_MAX, m.xp[4])
	m.books[5] = 1; m.xp[5] = 0.0; m.wpn = 12; m.drill = 0
	m.x = dm[0]; m.z = dm[1] - 8; m.r = 0; m.atkCd = 0
	R.do_attack(m)
	ok("a sling can practise too", m.xp[5] > 0)
	# ---------- peasants talk
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	for q in R.peasants:
		q.owner = m.id; q.state = "follow"
	R.ev.clear()
	R.dusk_falls()
	ok("at dusk somebody in the posse says something", R.ev.any(func(e): return e[0] == "bark" and D.BARK_DUSK.has(e[2])))

	var fails := lines.filter(func(l): return l.begins_with("FAIL")).size()
	for l in lines: print(l)
	print("%d passed, %d failed" % [lines.size() - fails, fails])
	quit(1 if fails else 0)
