extends SceneTree
## Version 7.3: the bosses. More health, three more of them, and something each does that moves the players about.
## Run:  godot --headless --path godot -s res://tests/boss_test.gd

var R: Rules
var m: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func fast(sec: float) -> void:
	var t := 0.0
	while t < sec:
		R.step(STEP); t += STEP


func boss(k: int, x: float, z: float) -> E.Undead:
	R.undead.clear(); R.pools.clear(); R.ev.clear()
	var u := R.spawn_undead(k, x, z)
	u.state = "walk"; u.t = 0; u.sp1 = 0.0; u.sd = 99.0
	return u


func reset_me(x: float, z: float) -> void:
	m.state = "ok"; m.room = ""; m.hp = 100; m.x = x; m.z = z; m.hurtT = 99; m.frozen = 0; m.prot = 0; m.head = -1; m.parry = 0


func _init() -> void:
	seed(777)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	# ---------- who, when, and how much
	ok("seven bosses: nights 7, 11, 14, 18, 21, 28 and 30", D.BOSS_NIGHTS == {7: D.U_STEWARD, 11: D.U_CHAPLAIN, 14: D.U_COACH, 18: D.U_COOK, 21: D.U_CAPTAIN, 28: D.U_WOLF, 30: D.U_LORD})
	ok("the old ones have far more health", D.UN[D.U_STEWARD].hp == 3000.0 and D.UN[D.U_COACH].hp == 4500.0 and D.UN[D.U_CAPTAIN].hp == 6000.0)
	ok("the new ones: 3,800, 5,200 and 6,700", D.UN[D.U_CHAPLAIN].hp == 3800.0 and D.UN[D.U_COOK].hp == 5200.0 and D.UN[D.U_WOLF].hp == 6700.0)
	ok("each new one has a letter from the Lord afterwards", Rules.letter_ix("chaplain") >= 0 and Rules.letter_ix("cook") >= 0 and Rules.letter_ix("wolf") >= 0)
	var h27 := 0
	var h28 := 0
	for v in Rules.night_plan(27, 2).c: h27 += v
	for v in Rules.night_plan(28, 2).c: h28 += v
	ok("the werewolf's night is mostly the werewolf: a quarter of a horde", h28 < h27 * 0.4 and h28 > 0, [h27, h28])
	# ---------- into the night
	R.weather = "clear"
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1
	for q in R.peasants: q.x = 60; q.z = 60
	# ---------- the Steward serves notice
	reset_me(0, -30)
	var st := boss(D.U_STEWARD, 0, -27.5)
	fast(0.3)
	ok("the Steward winds up when a player is near, and warns of it", st.sk == "slam")
	var d0 := D.d2(m.x, m.z, st.x, st.z)
	fast(1.0)
	ok("then slams his ledger: the player is thrown back, and hurt", D.d2(m.x, m.z, st.x, st.z) > d0 + 9 and m.hp < 100, [sqrt(d0), sqrt(D.d2(m.x, m.z, st.x, st.z)), m.hp])
	# ---------- the Chaplain's sermon
	reset_me(0, -38)
	var ch := boss(D.U_CHAPLAIN, 0, -29)
	var sh := R.spawn_undead(0, 2.0, -27.0)
	sh.state = "walk"; sh.t = 0; sh.stun = 99; sh.hp = sh.mhp * 0.5
	var far0 := D.d2(m.x, m.z, ch.x, ch.z)
	fast(2.0)
	ok("the Chaplain preaches", ch.sk == "sermon")
	ok("and the player is drawn in", D.d2(m.x, m.z, ch.x, ch.z) < far0 - 4.0, [sqrt(far0), sqrt(D.d2(m.x, m.z, ch.x, ch.z))])
	ok("and the dead near him mend", sh.hp > sh.mhp * 0.5 + 1, [sh.hp, sh.mhp])
	R.hit_u(ch, 20, {"p": m})
	ok("a light blow does not stop him", ch.sk == "sermon")
	R.hit_u(ch, 60, {"p": m})
	ok("a hard one makes him lose his place", ch.sk == "" and R.ev.any(func(e): return e[0] == "lostplace"))
	# ---------- the Cook
	reset_me(0, -36)
	var ck := boss(D.U_COOK, 0, -28)
	fast(0.2)
	ok("the Cook ladles stew where a player stands", R.pools.size() == 1 and absf(R.pools[0][0] - m.x) < 0.5 and absf(R.pools[0][1] - m.z) < 0.5, R.pools)
	ck.sp1 = 99
	var hp0 := m.hp
	fast(0.5)
	ok("it is not hot at once", m.hp == hp0, m.hp)
	fast(1.5)
	ok("then it scalds whoever is standing in it", m.hp < hp0, m.hp)
	R.pools.clear()
	reset_me(0, -30)
	ck.x = 0; ck.z = -28; ck.sd = 0
	fast(1.2)
	ok("and the cauldron, swung round, throws players a long way", D.d2(m.x, m.z, ck.x, ck.z) > 25 and m.hp < 100, [sqrt(D.d2(m.x, m.z, ck.x, ck.z)), m.hp])
	# ---------- the Captain's charge
	reset_me(0, -38)
	var cp := boss(D.U_CAPTAIN, 0, -30)
	fast(0.2)
	ok("the Captain lines up a charge at a player some way off", cp.sk == "charge" and R.ev.any(func(e): return e[0] == "line"))
	fast(2.0)
	ok("and comes down the line, knocking the player aside", m.hp < 100 and absf(m.x) > 2.0, [m.x, m.z, m.hp])
	reset_me(5.0, -38)
	var cp2 := boss(D.U_CAPTAIN, 0, -30)
	fast(0.2)
	var aim := Vector2(cp2.ax, cp2.az)
	m.x = 9.0                                              # he aimed at where you were: step out of the line
	fast(2.0)
	ok("stepping out of the line before he comes saves you", m.hp == 100 and aim.length() > 0.9, m.hp)
	# ---------- the werewolf
	reset_me(0, -36)
	var wf := boss(D.U_WOLF, 0, -26)
	fast(0.1)
	ok("the howl freezes a player who hears it", m.frozen > 2.0, m.frozen)
	var x0 := m.x
	R.move_player(m, 1.0, 0.0, STEP)
	ok("frozen, a player cannot move", m.x == x0)
	m.atkCd = 0; var ac0 := m.ac
	R.do_attack(m)
	ok("or strike", m.ac == ac0)
	reset_me(0, -36); m.prot = 5.0
	wf.sp1 = 0; fast(0.1)
	ok("being prayed over keeps you from freezing", m.frozen == 0)
	reset_me(0, -36); m.head = 20
	wf.sp1 = 0; fast(0.1)
	ok("and so does the Helm of the Unbothered", m.frozen == 0)
	m.head = -1
	var wall: E.Struct = null
	for s in R.structs:
		if s.slot >= 0: wall = s; break
	wall.built = true; wall.hp = wall.mhp
	wf.cd = 0
	R.hit_struct(wf, D.UN[D.U_WOLF], wall)
	ok("a swipe takes a quarter of a wall", absf(wall.hp - wall.mhp * 0.75) < 0.5, [wall.hp, wall.mhp])
	m.wood = 50; m.x = 0; m.z = -6
	var placed := R.try_place(m, "barricade", 0.0, -9.0, 0.0)
	var bar: E.Struct = null
	for s in R.structs:
		if s.k == "barricade": bar = s
	if bar: bar.built = true; bar.hp = bar.mhp
	wf.cd = 0
	if bar: R.hit_struct(wf, D.UN[D.U_WOLF], bar)
	ok("and a barricade goes at a single blow", placed and bar != null and not R.structs.has(bar), [placed, bar != null])
	# ---------- the Coachman's horses
	R.undead.clear()
	var co := R.spawn_undead(D.U_COACH, 0, -40)
	co.state = "walk"; co.t = 0; co.march = true; co.sp1 = 0.0
	fast(0.1)
	ok("the Coachman whips the horses into a stampede", co.sp2 > 0 and co.sp1 > 5)
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
