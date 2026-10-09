extends SceneTree
## Build 4, stage 4: contraptions.
## Run:  godot --headless --path godot -s res://tests/contr_test.gd

var R: Rules
var m: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func fast(sec: float) -> void:
	var t := 0.0
	while t < sec:
		R.step(STEP)
		R.ev.clear()
		t += STEP


func night() -> void:
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = [{"k": 0, "t": 9999.0}]; R.night.boss = -1; R.undead.clear()
	m.state = "ok"; m.x = 85; m.z = 45                 # out of the way, but still up
	for q in R.peasants:
		if q.state != "body": q.state = "gone"


func one(k: int, x: float, z: float) -> E.Undead:
	var u := R.spawn_undead(k, x, z)
	u.state = "walk"; u.t = 0
	return u


func rich() -> void:
	m.wood = 50; m.stone = 50; m.iron = 50; m.food = 50


func place(k: String, x: float, z: float) -> E.Struct:
	rich(); m.x = x + 2; m.z = z + 2
	var n := R.structs.size()
	R.try_place(m, k, x, z, 0)
	return R.structs[-1] if R.structs.size() > n else null


func _init() -> void:
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	ok("six contraptions", D.CONTRAPTIONS.size() == 6 and D.CONTRAPTIONS.all(func(k): return D.COST.has(k) and D.SHP.has(k) and D.SDIM.has(k)))
	ok("none without Barricades for Beginners", not D.CONTRAPTIONS.any(func(k): return Rules.can_contr(m, k)))
	ok("and placing one without it fails", place("chicken", 40, 0) == null)
	m.books[2] = 1
	ok("rank 1: the chicken decoy", Rules.can_contr(m, "chicken") and not Rules.can_contr(m, "pitfall"))
	m.books[2] = 7
	ok("rank 7: all of them but the trough", D.CONTRAPTIONS.all(func(k): return Rules.can_contr(m, k) == (k != "trough")))
	m.holy = 1
	ok("the trough needs holy water: a class of holy studies", Rules.can_contr(m, "trough"))
	m.books[2] = 0; m.holy = 0; m.cogs = 1
	ok("a box of cogs builds one without the book", Rules.can_contr(m, "thresher"))
	var th := place("thresher", 40, 0)
	ok("and is used up", th != null and m.cogs == 0 and not Rules.can_contr(m, "thresher"))
	m.books[2] = 7; m.holy = 1

	# ---------- the log roller goes north of the wall
	ok("a log roller cannot go inside the village", place("logs", 0, 5) == null)
	var lr := place("logs", 4, -40)
	ok("but can go up the road", lr != null and lr.tick == 1.0)

	# ---------- chicken
	night()
	var ch := place("chicken", 40, 10)
	m.x = 85; m.z = 45
	var u := one(0, 46, 10)
	fast(4)
	ok("the dead cannot ignore a chicken", ch.hp < D.SHP.chicken or not R.structs.has(ch), [Vector2(u.x - 40, u.z - 10).length(), ch.hp])
	R.undead.clear()

	# ---------- pitfall
	var pf := place("pitfall", 40, -6)
	m.x = 85; m.z = 45
	var fallers := []
	for i in 6:
		var f := one(0, 40 + (i % 2) * 0.3, -14 - i * 1.5)
		f.lane = 40; fallers.append(f)
	var kills0: int = R.stats.kills
	for i in 300:
		for f in fallers:
			if not f.dead:
				var dz: float = -6.0 - f.z
				f.z += signf(dz) * minf(absf(dz), 0.2); f.x = 40
		fast(STEP)
	ok("a pitfall swallows four, then is full", R.stats.kills - kills0 == 4 and not R.structs.has(pf), [R.stats.kills - kills0, R.structs.has(pf)])
	R.undead.clear()

	# ---------- tar
	var walk := func() -> float:                  # inside the wall, straight down the avenue to the keep
		var w := one(0, 0, -13.0)
		w.lane = 0
		var z0 := w.z
		fast(2)
		var d := w.z - z0
		R.undead.erase(w)
		return d
	m.x = 85; m.z = 45
	var free: float = walk.call()
	var tp := place("tar", 0, -11.5)
	m.x = 85; m.z = 45
	var tarred: float = walk.call()
	ok("the dead wade slowly through tar", tarred < free * 0.75, [free, tarred])
	R.structs.erase(tp)

	# ---------- trough
	var tr := place("trough", 40, -6)
	m.x = 85; m.z = 45
	var wr := one(D.U_WRAITH, 40, -6)
	wr.hp = 500; wr.stun = 99
	fast(2)
	ok("holy water burns what crosses it, a wraith too", wr.hp < 500 and tr.hp < D.SHP.trough, [wr.hp, tr.hp])
	R.undead.clear(); R.structs.erase(tr)

	# ---------- thresher
	var tz := one(0, th.x + 1.5, th.z)
	tz.hp = 999; tz.stun = 99
	fast(2)
	ok("the Thresher does nothing with nobody at the handle", tz.hp == 999)
	m.x = th.x - 1.5; m.z = th.z
	fast(2)
	ok("someone near, and it spins", tz.hp < 999, tz.hp)
	R.undead.clear()

	# ---------- the log roller
	m.x = 85; m.z = 45
	var crowd := []
	for i in 6:
		var c := one(0, lr.x + (i % 3 - 1) * 0.6, lr.z + 6 + i * 0.6)
		c.hp = 200; c.stun = 99; crowd.append(c)
	fast(0.2)
	ok("a crowd past the log roller gets flattened", crowd.all(func(c): return c.hp < 200 or c.dead) and lr.tick == 0.0)
	for c in crowd: c.hp = 200
	fast(0.2)
	ok("once a night", crowd.all(func(c): return c.dead or c.hp == 200))
	R.undead.clear()
	var ram := one(D.U_RAM, lr.x, lr.z + 10)
	ram.stun = 99
	R.night.q = []; fast(0.3)
	R.dusk_falls()
	ok("stacked again at dusk", lr.tick == 1.0)
	R.undead.clear()
	night()
	var ram2 := one(D.U_RAM, lr.x, lr.z + 10)
	ram2.stun = 99; ram2.hp = 500
	fast(0.2)
	ok("and a coffin ram alone sets it off", ram2.hp < 500, [ram2.hp, R.structs.has(lr), lr.tick, R.phase, ram2.x, ram2.z, lr.x, lr.z, ram2.state])

	# ---------- saved
	var sv := R.save_data()
	ok("contraptions are saved", sv.structs.any(func(s): return s.k == "logs") and sv.structs.any(func(s): return s.k == "thresher"))

	var fails := lines.filter(func(l): return l.begins_with("FAIL")).size()
	for l in lines: print(l)
	print("%d passed, %d failed" % [lines.size() - fails, fails])
	quit(1 if fails else 0)
