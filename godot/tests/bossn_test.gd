extends SceneTree
## Version 7.36: the bosses with company. A third more health for each player past the first, tricks that come round
## sooner and reach further, and more of what they bring. Run:  godot --headless --path godot -s res://tests/bossn_test.gd

var lines := []

func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))

func game(n: int) -> Rules:
	var R := Rules.new()
	var inf := []
	for i in n: inf.append({"id": i + 1, "name": "P%d" % i, "col": i})
	R.new_game(inf)
	R.phase = "night"
	return R

func count(R: Rules, k: int) -> int:
	return R.undead.filter(func(u): return u.k == k).size()

func _init() -> void:
	var R1 := game(1)
	var R8 := game(8)
	R1.spawn_boss(D.U_STEWARD); R8.spawn_boss(D.U_STEWARD)
	ok("health: a third more for each of you (8 players: 3.45 times)", absf(R8.boss.hp / R1.boss.hp - 3.45) < 0.01, R8.boss.hp / R1.boss.hp)
	ok("tricks come round sooner, and reach further, with eight", absf(R8.bpace() - 1.0 / 1.49) < 0.001 and absf(R8.breach() - 1.28) < 0.001 and R1.bpace() == 1.0 and R1.breach() == 1.0)
	ok("the Steward brings lamp-bearers with company (none alone, three with eight)", count(R1, 1) == 0 and count(R8, 1) == 3, [count(R1, 1), count(R8, 1)])
	for R in [R1, R8]: R.undead.clear(); R.boss = null
	R1.spawn_boss(D.U_WOLF); R8.spawn_boss(D.U_WOLF)
	ok("the Gamekeeper brings a hound for every two of you", count(R1, D.U_HOUND) == 0 and count(R8, D.U_HOUND) == 4, [count(R1, D.U_HOUND), count(R8, D.U_HOUND)])
	for R in [R1, R8]: R.undead.clear(); R.boss = null
	var R4 := game(4)
	R4.spawn_boss(D.U_CAPTAIN); R8.spawn_boss(D.U_CAPTAIN)
	var sides4 := {}
	for u in R4.undead: if u.k == D.U_GUARD: sides4[u.side] = true
	var sides8 := {}
	for u in R8.undead: if u.k == D.U_GUARD: sides8[u.side] = true
	ok("the Captain's guard: one gate with four of you, two gates with eight", sides4.size() == 1 and sides8.size() == 2, [sides4.keys(), sides8.keys()])
	for R in [R4, R8]: R.undead.clear(); R.boss = null
	# the Cook's ladle: one pool alone, three at once with eight (when there are three to aim at)
	R1.spawn_boss(D.U_COOK); R8.spawn_boss(D.U_COOK)
	for R in [R1, R8]:
		var c: E.Undead = R.boss
		c.x = 0; c.z = 0; c.sp1 = 0.0; c.state = "walk"
		for i in R.players.size():
			var p: E.Player = R.players[i]
			p.x = -3.0 + i; p.z = 4.0; p.state = "ok"; p.room = ""
		R.pools = []
		R.boss_trick(c, D.UN[c.k], 0.1)
	ok("the Cook ladles out one pool alone, three at once with eight", R1.pools.size() == 1 and R8.pools.size() == 3, [R1.pools.size(), R8.pools.size()])
	ok("and comes round for the next a third sooner with eight", R8.boss.sp1 < R1.boss.sp1 * 0.7, [R1.boss.sp1, R8.boss.sp1])
	# the Coachman's stampede: a coffin bursts off the back with five or more
	var R5 := game(5)
	for R in [R1, R5]:
		R.undead.clear(); R.boss = null
		R.spawn_boss(D.U_COACH)
		var co: E.Undead = R.boss
		co.z = D.VN - 30.0; co.x = 0.0; co.march = true; co.sp1 = 0.0
		R.hearse_step(co, D.UN[co.k], 0.05, E.Box.new(0, -50, 0.1, 0.1))
	ok("the Coachman: a pallbearer off the back of the hearse at each stampede, with five or more", count(R1, D.U_PALL) == 0 and count(R5, D.U_PALL) == 1, [count(R1, D.U_PALL), count(R5, D.U_PALL)])
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
