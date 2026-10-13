extends SceneTree
## Version 7.2, the harder dead: more health, three new kinds from the first night, and a horde that gets
## harder in its make-up as the month goes on.
## Run:  godot --headless --path godot -s res://tests/dead_test.gd

var R: Rules
var m: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func one(k: int, x: float, z: float) -> E.Undead:
	var u := R.spawn_undead(k, x, z)
	u.state = "walk"; u.t = 0; u.stun = 99; u.hp = 900; u.mhp = 900
	return u


func shares(md: int) -> Array:
	var w := Rules.mix(md, [])
	var s := [0.0, 0.0, 0.0]
	for k in w.size():
		s[0 if D.MIX_EASY.has(k) else 2 if D.MIX_HARD.has(k) else 1] += w[k]
	return s


func _init() -> void:
	seed(4242)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	# ---------- health
	ok("twice the health in the first week, three times after (each week's own rise on top)", D.DEAD_HP == [2.0, 4.5, 6.3, 8.4])
	ok("so a shambler has 100 in the first week and 420 in the last", is_equal_approx(D.UN[0].hp * D.DEAD_HP[0], 100.0) and is_equal_approx(D.UN[0].hp * D.DEAD_HP[3], 420.0))
	# ---------- the new kinds come from the first night
	var p1: Dictionary = Rules.night_plan(1, 1)
	ok("the first night brings the bloated dead, pallbearers and grave hounds", p1.c[D.U_BLOAT] >= 1 and p1.c[D.U_PALL] >= 1 and p1.c[D.U_HOUND] >= 1, [p1.c[D.U_BLOAT], p1.c[D.U_PALL], p1.c[D.U_HOUND]])
	ok("and the dusk notice names them", R.tonight_lines().any(func(l): return l is String and l.contains("bloated") and l.contains("pallbearers") and l.contains("grave hounds")))
	# ---------- the mix, week by week
	var s1 := shares(3)
	var s2 := shares(10)
	var s3 := shares(17)
	var s4 := shares(25)
	ok("the first week: three quarters easy, a quarter middling, nothing hard", absf(s1[0] - 0.75) < 0.01 and absf(s1[1] - 0.25) < 0.01 and s1[2] == 0.0, s1)
	ok("the second week: half easy; nothing hard comes yet, so its share goes to the middling", absf(s2[0] - 0.5) < 0.01 and absf(s2[1] - 0.5) < 0.01 and s2[2] == 0.0, s2)
	ok("the third week: a third of each", absf(s3[0] - 0.333) < 0.01 and absf(s3[1] - 0.333) < 0.01 and absf(s3[2] - 0.334) < 0.01, s3)
	ok("the fourth week: a sixth easy, half hard", absf(s4[0] - 0.167) < 0.01 and absf(s4[2] - 0.5) < 0.01, s4)
	var e1: int = Rules.night_plan(3, 1).c[0]
	var e4: int = Rules.night_plan(25, 1).c[0]
	ok("there are fewer shamblers on a late night than an early one would suggest", float(e4) / Rules.night_plan(25, 1).c.reduce(func(a, b): return a + b) < float(e1) / Rules.night_plan(3, 1).c.reduce(func(a, b): return a + b), [e1, e4])
	# ---------- the night
	R.weather = "clear"
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()
	m.x = 0; m.z = -30; m.r = 0; m.hp = 100
	# ---------- a pallbearer: the lid takes the blows from the front
	var pb := one(D.U_PALL, 0, -26)
	pb.r = PI                                              # facing the player, who is to the south (-z)... (facing is sin r, cos r)
	m.z = -28
	var h := pb.hp
	R.hit_u(pb, 40, Rules.src_of(m, D.IT[1]))             # a short sword, from in front
	var front := h - pb.hp
	m.z = -24; h = pb.hp
	R.hit_u(pb, 40, Rules.src_of(m, D.IT[1]))             # and from behind
	var back := h - pb.hp
	m.z = -28; h = pb.hp
	R.hit_u(pb, 40, Rules.src_of(m, D.IT[5]))             # a warhammer, from in front
	var heavy := h - pb.hp
	ok("a blow from the front does a quarter", is_equal_approx(front, 40 * D.LID), front)
	ok("from behind, all of it", is_equal_approx(back, 40.0), back)
	ok("and something heavy goes through the lid anyway", heavy >= 40.0, heavy)
	R.undead.clear()
	# ---------- a grave hound goes for the posse first
	var q: E.Peasant = R.peasants[0]
	q.owner = m.id; q.state = "follow"; q.x = 5.0; q.z = -30.0
	m.x = -3.0; m.z = -30.0
	var hd := one(D.U_HOUND, 1.0, -24.0)                  # about as far from each of them
	var sh := one(0, -2.0, -24.5)
	hd.stun = 0; sh.stun = 0
	R.step(STEP)
	ok("a grave hound picks the peasant over the player", hd.tg == 0 and D.d2(hd.x, hd.z, q.x, q.z) < D.d2(1.0, -24.0, q.x, q.z), [hd.tg, hd.x, hd.z])
	ok("a shambler in the same place picks the player", sh.tg == m.id, sh.tg)
	R.undead.clear()
	# ---------- the bloated dead go off
	q.x = 40.0; q.z = 40.0
	m.x = 0; m.z = -30; m.hp = 100
	var bl := one(D.U_BLOAT, 1.0, -30.0)
	var nb := one(0, 2.2, -30.0)
	var far := one(0, 8.0, -30.0)
	var nh := nb.hp
	R.ev.clear()
	R.hit_u(bl, 99999, {"p": m})
	ok("put down, a bloated one bursts", bl.dead and R.ev.any(func(e): return e[0] == "burst"))
	ok("and hurts the player beside it", m.hp < 100, m.hp)
	ok("and the dead beside it", is_equal_approx(nh - nb.hp, D.BURST.dead), nh - nb.hp)
	ok("but nothing further off", far.hp == 900)
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
