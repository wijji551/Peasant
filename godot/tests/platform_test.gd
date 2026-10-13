extends SceneTree
## The watch platform (one of the posse posted on it throws stones over the wall), and the moons of the month.
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
	# ---------- building one
	ok("the watch platform is one of the things anyone can build", D.BUILDS.has("platform") and D.COST.platform.wood == 20 and D.SNAME.platform == "watch platform")
	var px := -8.0
	var pz := D.VN + 5.0
	m.x = px; m.z = pz + 2.0; m.wood = 0
	ok("not without the wood", not R.try_place(m, "platform", px, pz, 0.0))
	m.wood = 20
	ok("twenty wood, just inside the north wall", R.try_place(m, "platform", px, pz, 0.0) and m.wood == 0, m.wood)
	var plat: E.Struct = null
	for s in R.structs:
		if s.k == "platform": plat = s
	ok("it stands, and is not something the dead stop to break", plat != null and plat.built and not D.BLOCKERS.has("platform"))
	# ---------- posting somebody
	var it = R.find_interact(m)
	ok("with no posse there is nobody to post", it == null or it.get("type", "") != "post", it)
	var q: E.Peasant = null
	for o in R.peasants:
		if o.kind == 0 and o.owner == 0 and o.state != "body" and q == null: q = o
	q.owner = m.id; q.state = "follow"; q.x = m.x + 1.0; q.z = m.z
	it = R.find_interact(m)
	ok("with one, the platform offers the post", it != null and it.get("type", "") == "post", it)
	hold(1.2, func(): return q.plat == 0)
	ok("holding E posts them", q.plat == plat.id and q.state != "post", [q.plat, q.state])
	fast(1.0)
	ok("by day they carry on as usual", q.state == "follow" or q.state == "chop", q.state)
	it = R.find_interact(m)
	ok("and can be called down", it != null and it.get("type", "") == "unpost", it)
	# ---------- at night
	R.dusk_falls()
	fast(6.0, func(): return q.state != "post")
	ok("at dusk they climb up", q.state == "post" and absf(q.x - plat.x) < 0.1 and absf(q.z - plat.z) < 0.1, [q.state, q.x, q.z])
	R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()
	var u := R.spawn_undead(0, px + 2.0, D.VN - 6.0)
	u.state = "walk"; u.stun = 99; u.hp = 500; u.mhp = 500
	var shots := 0
	var t := 0.0
	while t < 6.0:
		R.step(STEP); t += STEP
		shots += R.ev.filter(func(e): return e[0] == "shot").size()
		R.ev.clear()
	ok("and throw stones over the wall at whatever is in reach", shots >= 3 and u.hp < 500, [shots, u.hp])
	var far := R.spawn_undead(0, px + 40.0, D.VN - 6.0)
	far.state = "walk"; far.stun = 99; far.hp = 500; far.mhp = 500
	fast(3.0)
	ok("but not at what is out of reach", far.hp == 500)
	R.undead.erase(far)
	# the dead cannot get at them
	u.stun = 0; u.x = plat.x + 0.8; u.z = plat.z + 0.5
	var hp0 := q.hp
	fast(4.0)
	ok("a shambler at the foot of the platform cannot reach them", q.hp == hp0 and q.state == "post", [q.hp, hp0])
	R.kill_undead(u)
	var ar := R.spawn_undead(2, plat.x, plat.z - 7.0)
	ar.state = "walk"; ar.hp = 9000; ar.mhp = 9000
	fast(8.0, func(): return q.hp == hp0)
	ok("an archer can", q.hp < hp0, [q.hp, hp0])
	# a roof
	m.x = plat.x; m.z = plat.z + 2.0; m.wood = 10
	plat.re = false
	it = R.find_interact(m)
	ok("ten wood roofs it", it != null and it.get("type", "") == "reinf" and it.label.contains("roof it"), it)
	hold(3.0, func(): return not plat.re)
	ok("and it is roofed", plat.re and m.wood == 0, [plat.re, m.wood])
	fast(0.5)
	var hp1 := q.hp
	fast(6.0)
	ok("under a roof the archer's arrows do nothing", q.hp >= hp1 and q.roof, [q.hp, hp1])
	R.undead.clear()
	# ---------- the save
	var sv := R.save_data()
	var R2 := Rules.new()
	R2.load_game(sv, [{"id": 1, "name": "Matt", "col": 0}])
	var p2: E.Struct = null
	for s in R2.structs:
		if s.k == "platform": p2 = s
	ok("the platform, its roof and its sentry are saved", p2 != null and p2.re and R2.peasants.any(func(o): return o.plat == p2.id and o.owner == 1), R2.peasants.map(func(o): return o.plat))
	# ---------- knocked down
	R.destroy_struct(plat)
	fast(0.3)
	ok("if the platform goes, they come down and rejoin the posse", q.plat == 0 and q.state != "post", [q.plat, q.state])
	# ---------- the moons
	ok("five moons a month: harvest, full, frost, blood, full", [9, 15, 19, 23, 28].map(func(d): return Rules.moon_of(d, D.MONTH)) == ["harvest", "full", "frost", "blood", "full"])
	ok("none in the short game, and none on other nights", Rules.moon_of(15, D.WEEK) == "" and Rules.moon_of(16, D.MONTH) == "")
	ok("both full moons are full-moon weather; the frost moon is snow", Rules.weather_of(5, 15, D.MONTH) == "moon" and Rules.weather_of(5, 28, D.MONTH) == "moon" and Rules.weather_of(5, 19, D.MONTH) == "snow" and Rules.weather_of(99, 19, D.MONTH) == "snow")
	ok("no moon falls on a boss's night", D.MOONS.keys().all(func(d): return not D.BOSS_NIGHTS.has(d)))
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
