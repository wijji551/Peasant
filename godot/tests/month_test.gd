extends SceneTree
## Build 4, stage 1: the month. Every kind of dead, the bosses, the weather, and thirty nights to the end.
## Run:  godot --headless --path godot -s res://tests/month_test.gd

var R: Rules
var m: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func fast(sec: float, f: Callable = Callable()) -> float:
	var t := 0.0
	while t < sec:
		if f.is_valid() and f.call() == false:
			return t
		R.step(STEP)
		R.ev.clear()
		t += STEP
	return t


func night_of(d: int) -> void:   # straight to night d, with nothing in the queue
	R.day = d; R.weather = "clear"
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()


func one(k: int, x: float, z: float) -> E.Undead:
	var u := R.spawn_undead(k, x, z)
	u.state = "walk"; u.t = 0
	return u


func peace() -> void:   # nobody about to distract the dead
	m.state = "hide"
	for q in R.peasants:
		if q.state != "body": q.state = "gone"


func _init() -> void:
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	ok("a new game is the month", R.last_day == D.MONTH)

	# ---------- who comes, and when
	var arrive := {}
	for d in range(1, 31):
		var c: Array = Rules.night_plan(d, 1).c
		for k in c.size():
			if c[k] > 0 and not arrive.has(k): arrive[k] = d
	ok("ghouls first come on night 8", arrive.get(D.U_GHOUL) == 8, arrive.get(D.U_GHOUL))
	ok("gravediggers on 10, bats on 12", arrive.get(D.U_DIGGER) == 10 and arrive.get(D.U_BATS) == 12)
	ok("the Lord's guard on 15, wraiths on 18, the coffin ram on 20", arrive.get(D.U_GUARD) == 15 and arrive.get(D.U_WRAITH) == 18 and arrive.get(D.U_RAM) == 20)
	ok("the bosses: the Steward 7, the Coachman 14, the Captain 21, the Lord 30",
		Rules.boss_of(7, 30) == D.U_STEWARD and Rules.boss_of(14, 30) == D.U_COACH and Rules.boss_of(21, 30) == D.U_CAPTAIN and Rules.boss_of(30, 30) == D.U_LORD and Rules.boss_of(13, 30) == -1)
	var size := func(d: int, n: int) -> float:
		var P: Dictionary = Rules.night_plan(d, n)
		var t := 0.0
		for k in P.c.size(): t += P.c[k] * D.UN[k].cost
		return t * P.crowd                              # a capped horde is fewer and tougher: the same weight
	ok("the horde keeps growing through the month", size.call(14, 4) > size.call(7, 4) and size.call(30, 4) > size.call(21, 4), [roundi(size.call(7, 4)), roundi(size.call(14, 4)), roundi(size.call(21, 4)), roundi(size.call(30, 4))])
	ok("and eases off at the start of a week", size.call(8, 1) < size.call(7, 1))
	ok("nights get longer, but not endless", Rules.night_plan(30, 1).dur > Rules.night_plan(7, 1).dur and Rules.night_plan(30, 1).dur < 300, Rules.night_plan(30, 1).dur)
	ok("the short game has every kind and the Lord on its 7th night", Rules.boss_of(7, 7) == D.U_LORD and Rules.night_plan(6, 1, 7).c[D.U_RAM] > 0 and Rules.night_plan(3, 1, 7).c[D.U_GHOUL] > 0)
	R.day = 1; R.start_night()
	var s1 := R.spawn_undead(0)
	R.day = 15; R.start_night()
	var s3 := R.spawn_undead(0)
	ok("the dead are tougher in later weeks", s3.hp > s1.hp, [s1.hp, s3.hp])
	R.undead.clear()

	# ---------- weather
	ok("night 15 is the full moon", Rules.weather_of(R.gseed, 15, 30) == "moon")
	var seen := {}
	for sd in [R.gseed, 11, 12345]:
		for d in range(2, 31): seen[Rules.weather_of(sd, d, 30)] = true
	ok("rain, fog and snow all come round", seen.has("rain") and seen.has("fog") and seen.has("snow"), seen.keys())
	var no_early_snow := true
	for d in range(1, 8): if Rules.weather_of(R.gseed, d, 30) == "snow": no_early_snow = false
	ok("no snow in the first week", no_early_snow)
	night_of(9); peace()
	var walk := func(w: String) -> float:
		R.weather = w
		var u := one(0, 0.0, -50.0)
		var z0 := u.z
		fast(2)
		R.undead.clear()
		return u.z - z0
	var dry: float = walk.call("clear")
	var mud: float = walk.call("rain")
	var moon: float = walk.call("moon")
	ok("rain makes mud: the dead wade slower", mud < dry * 0.92, [dry, mud])
	ok("the full moon makes them quicker", moon > dry * 1.08, [dry, moon])
	m.state = "ok"; R.weather = "snow"; m.x = 40; m.z = 0
	R.move_player(m, 1, 0, 1.0)
	var snowy := m.x - 40
	R.weather = "clear"; m.x = 40
	R.move_player(m, 1, 0, 1.0)
	ok("snow slows everyone", snowy < (m.x - 40) * 0.9, [snowy, m.x - 40])

	# ---------- ghouls go over barricades, not walls
	night_of(9); peace()
	var bar := R.mk_struct("barricade", 0.0, -9.0, 0, true, 90, 90, -1)
	R.structs.append(bar)
	var g := one(D.U_GHOUL, 0.0, -14.0)
	g.lane = 0
	fast(4, func(): return g.z < -7.5)
	ok("a ghoul climbs over a barricade without stopping to break it", g.z > -8.0 and bar.hp == 90, [g.z, bar.hp])
	R.structs.erase(bar); R.undead.clear()
	for s in R.structs:
		if s.slot >= 0: s.built = true; s.hp = s.mhp; s.mhp = D.SHP[s.k]; s.hp = s.mhp
	var g2 := one(D.U_GHOUL, 6.0, -30.0)
	fast(12)
	ok("but a wall stops it", g2.z < D.VN, g2.z)
	R.undead.clear()

	# ---------- gravediggers come up inside
	var dg := one(D.U_DIGGER, -6.0, -40.0)
	var dug := {"v": false, "in": false}
	fast(40, func():
		if dg.state == "dig": dug.v = true
		if dg.z > D.VN + 1 and dg.state != "dig": dug.in = true
		return not dug.in)
	ok("a gravedigger tunnels under the north wall and comes up inside", dug.v and dug.in and D.inside_village(dg.x, dg.z), [dg.state, dg.x, dg.z])
	ok("without breaking the wall", R.structs.filter(func(s): return s.slot >= 0 and s.built).size() == 7)
	R.undead.clear()

	# ---------- bats fly over everything, for the keep
	var bt := one(D.U_BATS, 0.0, -40.0)
	var kp := R.keepHp
	fast(30, func(): return R.keepHp >= kp)
	ok("a bat swarm flies over the walls and goes for the keep", R.keepHp < kp and R.structs.filter(func(s): return s.slot >= 0 and s.built).size() == 7, R.keepHp)
	m.state = "ok"; m.x = bt.x; m.z = bt.z - 1.4; m.r = 0; m.wpn = 1; m.atkCd = 0
	bt.hp = 999; bt.stun = 5
	R.do_attack(m)
	var swung := 999 - bt.hp
	bt.hp = 999; m.wpn = 12; m.atkCd = 0; m.x = bt.x; m.z = bt.z - 6
	var shot := 0.0
	for i in 10:
		m.atkCd = 0
		var h := bt.hp
		R.do_attack(m)
		shot = maxf(shot, h - bt.hp)
	ok("a sword barely touches them; a sling does", swung > 0 and swung < 10 and shot >= 9, [swung, shot])
	R.undead.clear(); m.state = "hide"

	# ---------- the Lord's guard: farm tools bounce off, a mace does not
	var gd := one(D.U_GUARD, 40.0, 10.0)
	gd.stun = 99
	m.state = "ok"; m.x = 40; m.z = 8.6; m.r = 0
	var hit_with := func(w: int) -> float:
		gd.hp = 999; gd.x = 40; gd.z = 10; m.wpn = w; m.atkCd = 0; m.bless = 0
		R.do_attack(m)
		return 999 - gd.hp
	var fork: float = hit_with.call(0)
	var sword: float = hit_with.call(1)
	var mace: float = hit_with.call(3)
	ok("the Lord's guard shrugs off a pitchfork", fork < D.IT[0].dmg * 0.5, fork)
	ok("a mace dents it properly", mace > sword and mace > D.IT[3].dmg, [sword, mace])
	R.undead.clear()

	# ---------- wraiths: through walls, and only holy things hurt them
	m.state = "hide"
	var wr := one(D.U_WRAITH, 6.0, -30.0)
	fast(14, func(): return wr.z < D.VN + 2)
	ok("a wraith drifts straight through the north wall", wr.z > D.VN + 1, wr.z)
	wr.stun = 99; m.state = "ok"; m.x = wr.x; m.z = wr.z - 1.4; m.r = 0
	wr.hp = 50; m.wpn = 1; m.bless = 0; m.atkCd = 0; R.do_attack(m)
	var plain := 50 - wr.hp
	m.bless = 1; m.atkCd = 0; R.do_attack(m)
	ok("an ordinary sword passes through it; a blessed one does not", plain == 0 and wr.hp < 50, [plain, wr.hp])
	R.undead.clear(); m.bless = 0

	# ---------- the coffin ram: at the gate, and four skeletons when it breaks
	m.state = "hide"
	var gate: E.Struct = R.structs.filter(func(s): return s.slot == 3)[0]
	gate.built = true; gate.mhp = D.SHP.gate; gate.hp = gate.mhp
	var ram := one(D.U_RAM, 12.0, -40.0)
	var g0 := gate.hp
	fast(40, func(): return gate.hp >= g0)
	ok("a coffin ram goes for the north gate and hits it hard", gate.hp < g0 and g0 - gate.hp >= 60, [g0, gate.hp])
	ram.hp = 1
	R.hit_u(ram, 5, {"x": ram.x, "z": ram.z + 2})
	ok("broken, it lets out the skeletons carrying it", ram.dead and R.undead.filter(func(u): return u.k == 1 and not u.dead).size() == 4)
	m.state = "ok"; m.wpn = 5; m.x = 30; m.z = 30; m.r = 0
	var r2 := one(D.U_RAM, 30.0, 31.4)
	r2.stun = 99; r2.hp = 999; m.atkCd = 0; R.do_attack(m)
	ok("a warhammer does double against it", 999 - r2.hp >= D.IT[5].dmg * 1.9, 999 - r2.hp)
	R.undead.clear()

	# ---------- the Coachman: through wood, stopped by stone, at the keep and back again
	night_of(14); peace()
	for s in R.structs:
		if s.slot >= 0: s.built = true; s.re = false; s.mhp = D.SHP[s.k]; s.hp = s.mhp
	R.spawn_boss(D.U_COACH)
	var co: E.Undead = R.boss
	ok("the Coachman comes down on night 14", co != null and co.k == D.U_COACH)
	var kp2 := R.keepHp
	fast(40, func(): return R.keepHp >= kp2)
	ok("the hearse drives through the wooden gate and hits the keep", not gate.built and R.keepHp < kp2, [gate.built, R.keepHp])
	fast(4)
	ok("and turns round for another run", not co.march, co.z)
	R.undead.clear(); R.boss = null
	for s in R.structs:
		if s.slot >= 0: s.built = true; s.re = true; s.mhp = D.SHP[s.k] * 3; s.hp = s.mhp
	R.spawn_boss(D.U_COACH)
	co = R.boss
	m.state = "ok"; m.x = 85; m.z = 45                 # someone still up and about, so the dead do not lose patience
	fast(20)
	ok("stone and iron stop him (for a while)", co.z < D.VN and gate.built, [co.z, gate.built])
	R.undead.clear(); R.boss = null

	# ---------- the Captain brings his guard
	night_of(21); peace()
	R.spawn_boss(D.U_CAPTAIN)
	var guards := R.undead.filter(func(u): return u.k == D.U_GUARD)
	ok("the Captain of the Guard comes down with his guard behind him", R.boss.k == D.U_CAPTAIN and guards.size() >= 5 and guards.all(func(u): return u.side == R.boss.side))
	R.undead.clear(); R.boss = null

	# ---------- the Lord, in three stages
	night_of(30); peace()
	R.spawn_boss(D.U_LORD)
	var lord: E.Undead = R.boss
	lord.x = 0; lord.z = -35
	var n0 := R.undead.size()
	fast(10)
	ok("at first the Lord watches from the road and calls down his bats", lord.stage == 0 and R.undead.filter(func(u): return u.k == D.U_BATS).size() > 0, R.undead.size() - n0)
	R.undead = [lord]
	R.hit_u(lord, lord.mhp * 0.4, {"holy": 1.0})
	ok("hurt, he comes down himself", lord.stage == 1, lord.stage)
	R.hit_u(lord, lord.mhp * 0.3, {"holy": 1.0})
	ok("and at the last he goes for the keep door", lord.stage == 2, lord.stage)
	var kp3 := R.keepHp
	fast(40, func(): return R.keepHp >= kp3)
	ok("straight through the wall to it", R.keepHp < kp3, R.keepHp)
	R.undead.clear(); R.boss = null

	# ---------- the whole month: thirty nights, then the end
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	var days := 0
	while R.phase == "day" and days < 40:
		R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
		R.night.q = []; R.night.boss = -1; R.undead.clear()
		R.step(STEP); R.ev.clear()
		days += 1
	ok("the month is thirty nights, then it is won", R.phase == "won" and days == 30, [R.phase, days])
	R.new_game([{"id": 1, "name": "Matt", "col": 0}], D.WEEK)
	days = 0
	while R.phase == "day" and days < 10:
		R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
		R.night.q = []; R.night.boss = -1; R.undead.clear()
		R.step(STEP); R.ev.clear()
		days += 1
	ok("the short game is seven", R.phase == "won" and days == 7, [R.phase, days])
	var sv := R.save_data()
	ok("the length of the game is saved", sv.last == 7)

	# ---------- one to eight players
	var heads := func(d: int, n: int) -> int:
		var t := 0
		for v in Rules.night_plan(d, n).c: t += v
		return t
	ok("alone, a night is never cut down", Rules.night_plan(30, 1).crowd == 1.0 and heads.call(30, 1) < D.NIGHT_HEADS)
	var p8: Dictionary = Rules.night_plan(30, 8)
	ok("eight players, the last night: about 420 rise, each several times as tough", absi(heads.call(30, 8) - D.NIGHT_HEADS) < 12 and p8.crowd > 3.0 and p8.crowd < 3.6, [heads.call(30, 8), p8.crowd])
	ok("and every kind still comes", p8.c[D.U_RAM] >= 1 and p8.c[D.U_WRAITH] >= 1)
	var X := Rules.new()
	X.new_game([{"id": 1, "name": "A", "col": 0}, {"id": 2, "name": "B", "col": 1}])
	ok("a pair start with four followers each", X.pm == 4 and X.peasants.size() == 8, [X.pm, X.peasants.size()])
	X.new_game([{"id": 1, "name": "A", "col": 0}, {"id": 2, "name": "B", "col": 1}, {"id": 3, "name": "C", "col": 2}, {"id": 4, "name": "D", "col": 3}])
	ok("four start with three each, and build twice as stout", X.pm == 3 and is_equal_approx(X.stout(), 2.0), [X.pm, X.stout()])
	var wl: E.Struct = X.structs[0]
	wl.built = true; wl.hp = wl.mhp
	X.day = 1; X.start_night(); X.night.q = []
	var sh := X.spawn_undead(0, wl.x, wl.z - 1.0)
	sh.state = "walk"; sh.cd = 0
	X.hit_struct(sh, D.UN[0], wl)
	ok("a blow on their wall does half what it would alone", is_equal_approx(wl.mhp - wl.hp, D.UN[0].sdmg / 2.0), wl.mhp - wl.hp)
	X.day = 7; X.start_night()
	var st := X.spawn_undead(D.U_STEWARD, 0.0, D.SPAWN_Z)
	ok("the Steward is worth the name, and bigger for four", st.hp == roundf(D.UN[D.U_STEWARD].hp * 2.5) and D.UN[D.U_STEWARD].hp >= 800, st.hp)

	var fails := lines.filter(func(l): return l.begins_with("FAIL")).size()
	for l in lines: print(l)
	print("%d passed, %d failed" % [lines.size() - fails, fails])
	quit(1 if fails else 0)
