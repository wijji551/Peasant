extends SceneTree
## Version 7.5: the wall moved forward, the four watch towers behind it, and the west and east gates, which the dead now use.
## Run:  godot --headless --path godot -s res://tests/tower_test.gd

var R: Rules
var m: E.Player
var f: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func fast(sec: float, fn: Callable = Callable()) -> void:
	var t := 0.0
	while t < sec:
		if fn.is_valid() and fn.call() == false: return
		R.step(STEP); R.ev.clear(); t += STEP


func hold(p: E.Player, sec: float, fn: Callable = Callable()) -> void:      # holding E
	var t := 0.0
	while t < sec:
		if fn.is_valid() and fn.call() == false: break
		p.eHold = true
		R.step(STEP); R.ev.clear(); t += STEP
	p.eHold = false
	R.step(STEP)


func site(i: int) -> E.Struct:
	for s in R.structs:
		if s.site == i: return s
	return null


func posse(p: E.Player, n: int) -> Array:       # give a player n of the villagers, standing beside them
	var out := []
	for q in R.peasants:
		if out.size() < n and q.kind == 0 and q.owner == 0 and q.state != "body":
			q.owner = p.id; q.state = "follow"; q.x = p.x + 1.0; q.z = p.z + 1.0; q.plat = 0
			out.append(q)
	return out


func _init() -> void:
	seed(75)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	m = R.players[0]; f = R.players[1]
	R.weather = "clear"
	# ---------- the wall and the sites
	ok("the north wall has moved forward three paces", D.VN == -25.0 and R.structs.filter(func(s): return s.slot >= 0).all(func(s): return s.z == D.VN))
	ok("four tower sites behind it, and the two side gateways, all empty", range(6).all(func(i): return site(i) != null and not site(i).built)
		and range(4).all(func(i): return site(i).k == "tower" and site(i).z > D.VN + 3) and site(4).k == "gate" and site(5).k == "gate")
	ok("one in each corner, one either side of the gate", site(0).x < -20 and site(3).x > 20 and site(1).x < 0 and site(1).x > -12 and site(2).x > 0 and site(2).x < 12)
	ok("the watch platform is no longer placed by hand", not D.BUILDS.has("platform"))
	# ---------- building one
	var t1 := site(1)
	m.x = t1.x; m.z = t1.z + 2.4; m.wood = 0; m.stone = 0
	var it = R.find_interact(m)
	ok("at a tower site, the offer to build one, and what it costs", it != null and it.type == "found" and it.target == t1 and not it.ok and it.label.contains("25 wood"), it.label if it else null)
	m.wood = 25; m.stone = 8
	hold(m, 1.6, func(): return not t1.built)
	ok("twenty-five wood and eight stone put it up", t1.built and m.wood == 0 and m.stone == 0 and t1.kept, [t1.built, m.wood, m.stone])
	ok("it stands in the way of the dead (they can break it) and of people", D.BLOCKERS.has("tower") and R.blocking_struct(t1.x, t1.z, 0.4) == t1)
	it = R.find_interact(m)
	ok("beside it, its notice", it != null and it.type == "station" and it.st.id == "tower1", it)
	var pg := Notices.data(R, "tower1", m, "")
	ok("which has the two choices on it, and nobody to send yet", pg.o[0].a == "tup" and not pg.o[0].ok and pg.o[1].a == "tdown" and not pg.o[1].ok, pg.o.slice(0, 2))
	# ---------- six to a tower, from anybody's posse
	var mine := posse(m, 4)
	f.x = t1.x + 1.0; f.z = t1.z + 2.4
	var his := posse(f, 4)
	for i in 4: R.do_act(m, "tup", 1)
	for i in 4: R.do_act(f, "tup", 1)
	var crew := R.tower_crew(t1)
	ok("six of them, from both posses, and no more", crew.size() == 6 and crew.filter(func(q): return q.owner == 1).size() == 4 and crew.filter(func(q): return q.owner == 2).size() == 2, crew.size())
	pg = Notices.data(R, "tower1", f, "")
	ok("then it says it is full", not pg.o[0].ok and pg.o[0].sub.contains("full"), pg.o[0].sub)
	R.do_act(f, "tdown", 1)
	ok("one of yours can be coaxed down", R.tower_crew(t1).filter(func(q): return q.owner == 2).size() == 1)
	R.do_act(f, "tdown", 1)
	R.do_act(f, "tdown", 1)
	ok("but nobody else's", R.tower_crew(t1).filter(func(q): return q.owner == 1).size() == 4 and R.tower_crew(t1).size() == 4, R.tower_crew(t1).size())
	fast(1.0)
	var merc := R.mk_peasant(0, f.x + 1.0, f.z + 1.0, f.x, f.z, f.id); merc.kind = 2; merc.armed = 1; merc.state = "follow"; R.peasants.append(merc)
	R.do_act(f, "tup", 1)
	ok("a hired sword can be sent up too", merc.plat == t1.id)
	merc.plat = 0; R.peasants.erase(merc)
	ok("they set off for it straight away, even by day (version 7.22)", mine.all(func(q): return q.state == "post" or q.state == "follow"))
	# ---------- at night
	R.dusk_falls()
	fast(8.0, func(): return not mine.all(func(q): return q.state == "post"))
	ok("and climb up", mine.all(func(q): return q.state == "post" and R.in_box(q.x, q.z, 0.0, t1)), mine.map(func(q): return [q.state, snappedf(q.x, 0.1), snappedf(q.z, 0.1)]))
	var spots := {}
	for q in mine: spots[Vector2(snappedf(q.x, 0.01), snappedf(q.z, 0.01))] = true
	ok("each in their own place on it", spots.size() == mine.size(), spots.size())
	R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()
	var u := R.spawn_undead(0, t1.x, D.VN - 7.0)                 # about twelve paces from the tower, outside the wall
	u.state = "walk"; u.stun = 99; u.hp = 900; u.mhp = 900
	var far := R.spawn_undead(0, t1.x, t1.z - 18.0)
	far.state = "walk"; far.stun = 99; far.hp = 900; far.mhp = 900
	var shots := 0
	var t := 0.0
	while t < 4.0:
		R.step(STEP); t += STEP
		shots += R.ev.filter(func(e): return e[0] == "shot").size()
		R.ev.clear()
	ok("they throw stones over the wall, all of them", shots >= 8 and u.hp < 900, [shots, u.hp])
	ok("out to about fifteen paces, and not past it", far.hp == 900, far.hp)
	R.undead.clear()
	# ---------- the dead can break it
	var hp0 := t1.hp
	var b := R.spawn_undead(0, t1.x, t1.z - 1.8)
	b.state = "walk"; b.hp = 9000; b.mhp = 9000
	fast(4.0)
	ok("one of the dead that gets inside will set about it", t1.hp < hp0, [t1.hp, hp0])
	R.undead.clear()
	# ---------- dawn: the upkeep
	R.end_night()
	ok("at dawn it wants seeing to", not t1.kept and R.dawn.lines.any(func(l): return l.contains("seeing to")), R.dawn.lines)
	R.dusk_falls()
	fast(8.0)
	ok("and if nobody does, nobody climbs it", mine.all(func(q): return q.state != "post"), mine.map(func(q): return q.state))
	R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()
	R.end_night()
	m.x = t1.x; m.z = t1.z + 2.4; m.wood = 4; m.iron = 1
	R.do_act(m, "tkeep", 1)
	ok("four wood and one iron sees to it", t1.kept and m.wood == 0 and m.iron == 0)
	m.wood = 10
	R.do_act(m, "troof", 1)
	ok("ten wood roofs it", t1.re and m.wood == 0)
	# ---------- the save
	var sv := R.save_data()
	var R2 := Rules.new()
	R2.load_game(sv, [{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	var t2: E.Struct = null
	for s in R2.structs:
		if s.site == 1: t2 = s
	ok("the tower, its roof, its upkeep and its crew are saved", t2 != null and t2.built and t2.re and t2.kept and R2.peasants.filter(func(o): return o.plat == t2.id).size() == 4)
	ok("and the other sites, still empty", R2.structs.filter(func(s): return s.site >= 0).size() == 6)
	var old := sv.duplicate(true)                                # a save from before 7.5: no sites, and the wall where it was
	old.structs = old.structs.filter(func(s): return int(s.get("site", -1)) < 0)
	for s in old.structs:
		s.erase("site"); s.erase("kept")
		if int(s.slot) >= 0: s.z = -22.0
	var R3 := Rules.new()
	R3.load_game(old, [{"id": 1, "name": "Matt", "col": 0}])
	ok("an old save gets the sites, and its wall moves forward", R3.structs.filter(func(s): return s.site >= 0).size() == 6 and R3.structs.filter(func(s): return s.slot >= 0).all(func(s): return s.z == D.VN))
	# ---------- taking it down
	m.wood = 0; m.stone = 0
	R.do_act(m, "tdis", 1)
	ok("taken down, it gives back half, and everyone comes off it", not t1.built and m.wood == 12 and m.stone == 4 and R.tower_crew(t1).is_empty() and site(1) == t1, [m.wood, m.stone])
	t1.built = true; t1.hp = t1.mhp; t1.kept = true
	R.do_act(m, "tup", 1)
	R.destroy_struct(t1)
	ok("knocked down, the site stays for next time, and nobody is left up it", site(1) == t1 and not t1.built and R.tower_crew(t1).is_empty())
	# ---------- the side gates
	R.day = 1
	ok("in the first week, one side gate a night: east, then west", R.side_gates() == [1] and (func(): R.day = 2; return R.side_gates()).call() == [-1])
	R.day = 16
	ok("from the third week, both", R.side_gates() == [-1, 1])
	R.day = 3
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	ok("the dawn notice says so", R.tonight_lines().any(func(l): return l.contains("east gate")), R.tonight_lines())
	var cnt := [0, 0]                                            # (a lambda gets copies of plain numbers, so an array)
	fast(90.0, func():
		for o in R.undead:
			if not o.has_meta("seen"):
				o.set_meta("seen", true); cnt[1] += 1
				if o.side == 1: cnt[0] += 1
				elif o.side == -1: cnt[0] -= 1000
		return cnt[1] < 60)
	var sides: int = cnt[0]
	var tot: int = cnt[1]
	ok("a fifth or so of the horde goes round to tonight's side gate, and none to the other", sides > tot * 0.08 and sides < tot * 0.4, [sides, tot])
	R.undead.clear(); R.night.q = []
	var eg := site(5)
	eg.built = true; eg.hp = eg.mhp
	var g := R.spawn_undead(0, D.VW + 6.0, D.GATE_Z)
	g.side = 1; g.state = "walk"; g.hp = 9000; g.mhp = 9000
	fast(6.0)
	ok("a gate built on the east gateway stops them, and they batter at it", eg.hp < eg.mhp and g.x > D.VW - 0.5, [eg.hp, g.x])
	R.undead.clear()
	eg.hp = eg.mhp
	var w := R.spawn_undead(D.U_WOLF, D.VW + 1.0, D.GATE_Z)
	w.cd = 0
	R.hit_struct(w, D.UN[D.U_WOLF], eg)
	ok("the werewolf takes a quarter of it at a blow, as with the north gate, not all of it", absf(eg.hp - eg.mhp * (1 - D.HOWL.wall)) < 1, eg.hp)
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
