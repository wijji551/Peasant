extends SceneTree
## Version 7.4: the last night. The Lord's shadow, his entrance, his attacks, the dead he throws, and the jump.
## Run:  godot --headless --path godot -s res://tests/lord_test.gd

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


func reset_me(x: float, z: float) -> void:
	m.state = "ok"; m.room = ""; m.hp = 100; m.x = x; m.z = z; m.hurtT = 99; m.frozen = 0; m.prot = 0; m.parry = 0; m.jumpT = 0; m.jumpCd = 0


func _init() -> void:
	seed(303)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	ok("the Lord has 10,000 health, before counting players", D.UN[D.U_LORD].hp == 10000.0 and D.UN[D.U_SHADOW].hp == 2500.0)
	# ---------- the jump
	reset_me(0, 5)
	var x0 := m.x
	ok("the space bar jumps the way you are going", R.jump(m, 1.0, 0.0))
	for i in 15: R.move_player(m, 0.0, 0.0, STEP)
	ok("a leap of about three paces, even with nothing pressed", absf(m.x - x0 - D.JUMP.dist) < 0.3, m.x - x0)
	ok("and not again at once", not R.jump(m, 1.0, 0.0))
	m.jumpCd = 0; m.frozen = 1.0
	ok("nor when frozen", not R.jump(m, 1.0, 0.0))
	m.frozen = 0
	m.jumpCd = 0; m.r = PI; m.x = 0.0; m.z = -40.0          # on the castle road, facing north; jump south, backwards, and keep facing north
	var z0 := m.z; x0 = m.x
	R.jump(m, 0.0, 1.0)
	for i in 15: R.move_player(m, 0.0, 0.0, STEP)
	ok("a jump backwards goes backwards, still facing forwards", absf(m.z - z0 - D.JUMP.dist) < 0.3 and absf(m.r - PI) < 0.01, [m.z - z0, m.r])
	m.jumpCd = 0; x0 = m.x
	R.jump(m, -1.0, 0.0)
	for i in 15: R.move_player(m, 0.0, 0.0, STEP)
	ok("and to the side goes to the side", absf(x0 - m.x - D.JUMP.dist) < 0.3, x0 - m.x)
	m.jumpCd = 0; x0 = m.x; z0 = m.z
	ok("with nothing pressed, a jump on the spot", R.jump(m, 0.0, 0.0) and m.jumpT > 0)
	for i in 15: R.move_player(m, 0.0, 0.0, STEP)
	ok("which goes nowhere", absf(m.x - x0) < 0.01 and absf(m.z - z0) < 0.01)
	m.jumpCd = 0
	# ---------- the last night begins with his shadow
	R.day = 30
	R.weather = "clear"
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	for q in R.peasants: q.x = 60; q.z = 60
	reset_me(0, 10)
	fast(7.0)
	var sh: E.Undead = R.boss
	reset_me(60, 60)
	fast(1.5)                                              # (it rises out of the road first)
	ok("six seconds into the last night, the Lord's shadow comes down", sh != null and sh.k == D.U_SHADOW, sh.k if sh else -1)
	ok("and the Lord himself is not yet on the field", not R.undead.any(func(u): return u.k == D.U_LORD))
	var hp0 := sh.hp
	R.hit_u(sh, 50, {"p": m, "dot": true})
	ok("fire does nothing to it: it is simply elsewhere", sh.hp == hp0)
	var tx := sh.x
	var tz := sh.z
	R.hit_u(sh, 50, {"p": m, "x": tx, "z": tz + 1.0, "holy": 1.5})
	ok("holy things hurt it, and drive it back", sh.hp < hp0 and absf(sh.z - tz) >= 2.9, [sh.hp, sh.z - tz])
	# it throws one of the dead
	R.undead = R.undead.filter(func(u): return u == sh)
	var o := R.spawn_undead(0, sh.x + 1.0, sh.z)
	o.state = "walk"; o.t = 0
	reset_me(sh.x + 4.0, sh.z + 4.0)
	sh.rt = 0.0; sh.sp1 = 99.0; sh.sd = 99.0
	R.ev.clear()
	R.step(STEP)
	ok("it picks up one of the dead and throws it at a player", R.lobs.size() == 1 and not R.undead.has(o) and R.ev.any(func(e): return e[0] == "lob"), R.lobs.size())
	var lx: float = R.lobs[0][1] if R.lobs.size() else 0.0
	fast(1.2)
	ok("it lands where the player was, a second later, and gets up", R.undead.has(o) and absf(o.x - lx) < 0.5 and m.hp < 100, [o.x, lx, m.hp])
	# the Lord waits for the shadow and for half the horde
	R.night.kills = 0
	R.kill_undead(sh)
	fast(0.2)
	ok("with the shadow beaten but not half the horde, the Lord waits", not R.undead.any(func(u): return u.k == D.U_LORD))
	R.night.kills = R.night.total
	R.ev.clear()
	fast(0.2)
	var lord: E.Undead = R.boss
	ok("with half the horde beaten too, the Lord comes", lord != null and lord.k == D.U_LORD)
	if lord == null: lord = R.spawn_undead(D.U_LORD, 0, D.VN - 7.0)
	ok("the field is cleared for him, and the rising stops", R.undead.size() == 1 and R.night.q.is_empty(), R.undead.size())
	ok("and his entrance is shown", R.ev.any(func(e): return e[0] == "lord"))
	reset_me(60, 60)
	fast(1.5)                                              # (he rises out of the road first)
	# ---------- his sweep: jump away and it misses
	reset_me(lord.x, lord.z + 3.0)
	lord.sp1 = 0.0; lord.sd = 99.0; lord.rt = 99.0; lord.sk = ""
	R.ev.clear()
	R.step(STEP)
	ok("close to him, he draws back his cloak, and the ground shows where it will go", lord.sk == "sweep" and R.ev.any(func(e): return e[0] == "cone"), lord.sk)
	fast(0.8)
	ok("stand there and it lands", m.hp < 100, m.hp)
	reset_me(lord.x, lord.z + 3.0)
	lord.sp1 = 0.0; lord.sk = ""
	R.step(STEP)
	R.jump(m, 0.0, 1.0)                                    # straight away from him
	for i in 24:
		R.move_player(m, 0.0, 0.0, STEP); R.step(STEP)
	ok("jump away from him and it misses", m.hp == 100, [m.hp, m.z - lord.z])
	# ---------- his bats, along a line
	reset_me(lord.x, lord.z + 10.0)
	lord.sp1 = 0.0; lord.sk = ""
	R.ev.clear()
	R.step(STEP)
	ok("further off, he lines up a rush of bats", lord.sk == "bats" and R.ev.any(func(e): return e[0] == "line"), lord.sk)
	fast(1.2)
	ok("and they come along the line", m.hp < 100, m.hp)
	# ---------- he vanishes, and is behind whoever is furthest
	reset_me(lord.x + 12.0, lord.z + 6.0)
	lord.sd = 0.0; lord.sk = ""; lord.sp1 = 99.0
	R.step(STEP)
	ok("he vanishes and comes back right behind you", D.d2(lord.x, lord.z, m.x, m.z) < 9.0 and lord.sk == "sweep", sqrt(D.d2(lord.x, lord.z, m.x, m.z)))
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
