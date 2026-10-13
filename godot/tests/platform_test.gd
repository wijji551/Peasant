extends SceneTree
## The moons of the month. (The watch platform that used to be tested here is now the watch tower: tower_test.)
## Run:  godot --headless --path godot -s res://tests/platform_test.gd

var R: Rules
var m: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func fast(sec: float, f: Callable = Callable()) -> void:
	var t := 0.0
	while t < sec:
		if f.is_valid() and f.call() == false: return
		R.step(STEP); R.ev.clear(); t += STEP


func hold(sec: float, f: Callable = Callable()) -> void:      # the player holds E
	var t := 0.0
	while t < sec:
		if f.is_valid() and f.call() == false: break
		m.eHold = true
		R.step(STEP); R.ev.clear(); t += STEP
	m.eHold = false
	R.step(STEP)


func _init() -> void:
	seed(7)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	R.weather = "clear"
	# the watch platform became the watch tower in version 7.5: see tower_test
	# ---------- the moons
	ok("five moons a month: harvest, full, frost, blood, full", [9, 15, 19, 23, 28].map(func(d): return Rules.moon_of(d, D.MONTH)) == ["harvest", "full", "frost", "blood", "full"])
	ok("none in the short game, and none on other nights", Rules.moon_of(15, D.WEEK) == "" and Rules.moon_of(16, D.MONTH) == "")
	ok("both full moons are full-moon weather; the frost moon is snow", Rules.weather_of(5, 15, D.MONTH) == "moon" and Rules.weather_of(5, 28, D.MONTH) == "moon" and Rules.weather_of(5, 19, D.MONTH) == "snow" and Rules.weather_of(99, 19, D.MONTH) == "snow")
	ok("no moon falls on a boss's night, but the werewolf's full moon", D.MOONS.keys().all(func(d): return not D.BOSS_NIGHTS.has(d) or (d == 28 and D.BOSS_NIGHTS[d] == D.U_WOLF)))
	ok("and the bells never ring under a moon", range(1, 300).all(func(sd): return D.MOONS.keys().all(func(d): return not Rules.bells_night(sd, d, D.MONTH))))
	var weeks_ok := true
	for sd in range(1, 60):
		var n := 0
		for d in range(1, 31):
			if Rules.bells_night(sd, d, D.MONTH): n += 1
		if n != 3: weeks_ok = false
	ok("there are still three nights of the bells, whatever the seed", weeks_ok)
	var heads := func(d: int) -> float:
		var c: Array = Rules.night_plan(d, 1, D.MONTH).c
		var s := 0.0
		for k in c.size(): s += c[k] * D.UN[k].cost
		return s * Rules.night_plan(d, 1, D.MONTH).crowd
	ok("the blood moon is the usual number of the dead", heads.call(23) / D.BLOOD_MOON > heads.call(22) * 0.9 and heads.call(23) / D.BLOOD_MOON < heads.call(24) * 1.1 and Rules.night_plan(23, 1, D.MONTH).c == Rules.night_plan(23, 1, D.MONTH).c, [heads.call(22), heads.call(23) / D.BLOOD_MOON, heads.call(24)])
	ok("each of them two and a half times the trouble", is_equal_approx(Rules.night_plan(23, 1, D.MONTH).crowd, 2.5) and is_equal_approx(Rules.night_plan(22, 1, D.MONTH).crowd, 1.0))
	var RBm := Rules.new()
	RBm.new_game([{"id": 1, "name": "Matt", "col": 0}])
	RBm.day = 23; RBm.weather = "clear"
	RBm.dusk_falls(); RBm.timeLeft = 0.01; RBm.step(STEP)
	var bu := RBm.spawn_undead(0, 0, -60)
	ok("so a shambler has 2.5 times a fourth-week shambler's health, and hits 1.9 times as hard", absf(bu.mhp - D.UN[0].hp * D.DEAD_HP[3] * 2.5) < 0.5 and is_equal_approx(RBm.crowd_d, 1.9), [bu.mhp, RBm.crowd_d])
	# the harvest moon: they mend
	var RH := Rules.new()
	RH.new_game([{"id": 1, "name": "Matt", "col": 0}])
	RH.day = 9; RH.weather = Rules.weather_of(RH.gseed, 9, D.MONTH)
	RH.dusk_falls(); RH.timeLeft = 0.01; RH.step(STEP)
	RH.night.q = [[0, 999.0]] if RH.night.q.size() and RH.night.q[0] is Array else RH.night.q
	var hu := RH.spawn_undead(0, 60, -40)
	hu.state = "walk"; hu.stun = 999
	var full := hu.mhp
	hu.hp = full * 0.5
	for i in int(10.0 / STEP):
		RH.step(STEP); RH.ev.clear()
		if RH.phase != "night": break
	ok("under the harvest moon one of the dead mends, slowly", RH.phase == "night" and hu.hp > full * 0.5 + full * D.HARVEST_MEND * 8 and hu.hp < full * 0.5 + full * D.HARVEST_MEND * 12, [RH.phase, hu.hp, full])
	hu.hp = full * 0.5; hu.burn = 99.0; hu.bt = 99.0
	var before := hu.hp
	for i in int(3.0 / STEP):
		RH.step(STEP); RH.ev.clear()
	ok("but not while it is alight", hu.hp <= before, [before, hu.hp])
	var RN := Rules.new()
	RN.new_game([{"id": 1, "name": "Matt", "col": 0}])
	RN.day = 10; RN.weather = "clear"
	RN.dusk_falls(); RN.timeLeft = 0.01; RN.step(STEP)
	var nu := RN.spawn_undead(0, 60, -40)
	nu.state = "walk"; nu.stun = 999; nu.hp = nu.mhp * 0.5
	var nb := nu.hp
	for i in int(3.0 / STEP):
		RN.step(STEP); RN.ev.clear()
	ok("and on an ordinary night nothing mends", nu.hp <= nb, [nb, nu.hp])
	# ---------- Robert Bailiff at dusk, and his window
	var RD := Rules.new()
	RD.new_game([{"id": 1, "name": "Matt", "col": 0}])
	RD.ev.clear()
	RD.dusk_falls()
	ok("at dusk Robert Bailiff shouts at everybody to defend his village", RD.bail_t > 5.0 and D.BAILIFF_DUSK.has(RD.bail_line) and RD.ev.any(func(e): return e[0] == "bshout") and RD.ev.any(func(e): return e[0] == "msg" and str(e[1]).begins_with("Robert Bailiff")), RD.bail_line)
	RD.day = 23; RD.dusk_falls()
	ok("under the blood moon he has something to say about the moon", RD.bail_line == D.BAILIFF_DUSK_BLOOD)
	RD.day = 7; RD.dusk_falls()
	ok("and on a boss's night about the boss", RD.bail_line == D.BAILIFF_DUSK_BOSS)
	var ws := D.station("window")
	var inn_east := -17.5 + 3.0 + 0.55                      # the east eaves of the Thorny Rose, which stands in front of his house
	ok("his window is east of the inn's eaves, where it can be seen from the square", D.BAILIFF_AT.x > inn_east + 1.0 and D.BAILIFF_AT.x < -10.6, [D.BAILIFF_AT.x, inn_east])
	ok("and you can stand under it", not RD.colliders.any(func(c): return RD.in_box(ws.x, ws.z, 0.45, c)), [ws.x, ws.z])
	var pw: E.Player = RD.players[0]
	pw.x = ws.x; pw.z = ws.z; RD.phase = "day"
	var iw = RD.find_interact(pw)
	ok("and call up to him from there", iw != null and iw.get("type", "") == "station" and iw.get("id", iw.get("station", "")) == "window" or (iw != null and str(iw.get("label", "")).contains("window")), iw)
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
