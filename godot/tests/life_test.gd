extends SceneTree
## Version 7.10: village life. The windmill's banquet, the Herder and riding sheep, and strays.
## Run:  godot --headless --path godot -s res://tests/life_test.gd

var R: Rules
var m: E.Player
var f: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func fast(sec: float) -> void:
	var t := 0.0
	while t < sec:
		R.step(STEP); R.ev.clear(); t += STEP


func at(p: E.Player, id: String) -> void:
	var st := D.station(id)
	p.x = st.x; p.z = st.z; p.tx = p.x; p.tz = p.z; p.state = "ok"; p.room = ""


func posse(p: E.Player) -> Array:
	return R.peasants.filter(func(q): return q.owner == p.id and q.kind == 0 and q.state != "body")


func hold(p: E.Player, sec: float) -> String:   # hold E for this long; what it was offering at the start
	var it = R.find_interact(p)
	p.eHold = true
	fast(sec)
	p.eHold = false
	return it.type if it else ""


func _init() -> void:
	seed(710)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	m = R.players[0]; f = R.players[1]
	R.weather = "clear"
	for st in ["mill", "plate", "herder"]:
		ok("a place to stand: " + st, not D.station(st).is_empty() and Notices.data(R, st, m, "").o.size() > 0)
	# give each a posse of three
	for p in [m, f]:
		var n := 0
		for q in R.peasants:
			if q.kind == 0 and q.owner == 0 and n < 3:
				q.owner = p.id; q.state = "follow"; n += 1
	# ---------------------------------------------------------------- the banquet, at the mill
	at(m, "mill"); m.food = 30
	R.do_act(m, "banq", "mill")
	ok("ten food at the windmill pays for a banquet for your posse tonight", m.food == 20 and m.banq == R.day)
	R.do_act(m, "banq", "mill")
	ok("and only once a day", m.food == 20)
	# ---------------------------------------------------------------- and from the plate
	var fq: Array = posse(f)
	for q in fq: q.x = 20; q.z = 5
	at(f, "plate"); f.food = 20; f.coin = 10
	R.do_act(f, "banq", "plate")
	var runner: E.Peasant = null
	for q in fq:
		if q.errand: runner = q
	ok("13 food and 5d on the offering plate, and one of the posse sets off with it", f.food == 7 and f.coin == 5 and runner != null and f.banqP and f.banq != R.day)
	R.do_act(f, "banq", "plate")
	ok("not twice while he is on his way", f.food == 7)
	var t := 0.0
	while runner.errand and t < 60:
		R.step(STEP); R.ev.clear(); t += STEP
		f.x = 24.6; f.z = 5.4; f.tx = f.x; f.tz = f.z
	ok("he gets to the windmill, and the banquet counts once he has", not runner.errand and f.banq == R.day and not f.banqP, t)
	fast(20)
	ok("and then he comes back to his leader", D.d2(runner.x, runner.z, f.x, f.z) < 36, [runner.x, runner.z])
	var none_left := Rules.new()
	none_left.new_game([{"id": 1, "name": "Solo", "col": 0}])
	var s0: E.Player = none_left.players[0]
	at(s0, "plate"); s0.food = 30; s0.coin = 30
	none_left.do_act(s0, "banq", "plate")
	ok("the plate needs somebody in the posse to carry it", s0.food == 30 and not s0.banqP)
	# ---------------------------------------------------------------- at night it mends them, and only them
	var mq: E.Peasant = posse(m)[0]
	var other: E.Peasant = posse(f)[0]
	R.players.append(R.mk_player(3, "Ned", 2, 2))   # a third player, who has not paid
	var ned: E.Player = R.players[2]
	var nq: E.Peasant = null
	for q in R.peasants:
		if q.kind == 0 and q.owner == 0 and nq == null: nq = q
	nq.owner = ned.id; nq.state = "follow"
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()
	var keeper := R.spawn_undead(0, 100, -55); keeper.state = "walk"; keeper.stun = 99; keeper.hp = 9000; keeper.mhp = 9000   # so the night goes on
	for p in R.players: p.x = 0; p.z = 8
	for q in [mq, other, nq]: q.hp = 20; q.x = 0; q.z = 9
	m.hp = 40
	fast(10)
	ok("the banquet mends a posse slowly through the night", mq.hp > 28 and mq.hp < 60 and other.hp > 28, [mq.hp, other.hp])
	ok("not the players", m.hp <= 40.5, m.hp)
	ok("and a posse whose share was not paid goes without", nq.hp <= 20.5, nq.hp)
	R.players.erase(ned); nq.owner = 0
	R.undead.clear(); R.end_night()
	ok("it is paid afresh each day", m.banq != R.day and f.banq != R.day)
	# ---------------------------------------------------------------- the Herder
	at(m, "herder"); m.food = 5
	R.do_act(m, "tame")
	ok("no sheep before the lesson", not m.sheep)
	R.do_act(m, "hlisten")
	ok("he starts his lesson", m.herdL)
	fast(D.HERD_TIME * 0.5)
	ok("it takes a while, stood beside him", m.herdL and m.herdQ == -1 and m.herdT > 10)
	var said := Notices.data(R, "herder", m, "")
	ok("and what he says shows as he says it", said.o.filter(func(o): return o.has("text")).size() >= 2)
	m.x += 20
	fast(0.5)
	ok("walk off and the lesson stops (he remembers where he got to)", not m.herdL and m.herdT > 10)
	at(m, "herder")
	R.do_act(m, "hlisten")
	fast(D.HERD_TIME * 0.6)
	ok("then his questions", m.herdQ == 0 and not m.herdL)
	var qd := Notices.data(R, "herder", m, "")
	var answers: Array = qd.o.filter(func(o): return o.get("a", "") == "hans")
	ok("three answers to choose from", answers.size() == 3)
	R.do_act(m, "hans", 2)
	ok("a wrong answer gets a dry remark, and another go", m.herdQ == 0 and m.herdW == 0 and not m.herd and Notices.data(R, "herder", m, "").intro.contains("Try again"))
	R.do_act(m, "hans", 0)
	R.do_act(m, "hans", 0)
	ok("two right, and the lesson is learned", m.herd and m.herdQ == -1)
	R.do_act(m, "tame")
	ok("a sheep of your own, for one food", m.sheep and m.food == 4 and R.sheep_of(m) != null)
	# ---------------------------------------------------------------- riding
	m.x = 0; m.z = 10; m.tx = 0; m.tz = 10
	fast(4)
	var sh := R.sheep_of(m)
	ok("it trots after you", D.d2(sh.x, sh.z, m.x, m.z) < 16, [sh.x, sh.z])
	ok("and is not one of the posse", m.posse == posse(m).size())
	R.ride(m, true)
	ok("on its back (fed today already)", m.ride and m.food == 4 and sh.state == "ride")
	R.weather = "clear"
	m.x = 50; m.z = 16
	var x0 := m.x
	R.move_player(m, 1, 0, 1.0)
	ok("a quarter quicker than walking", absf((m.x - x0) - D.PLAYER_SPEED * 1.25) < 0.05, m.x - x0)
	R.ride(m, false); m.feet = D.I_FLEET; R.ride(m, true)
	m.x = 50; m.z = 16
	x0 = m.x
	R.move_player(m, 1, 0, 1.0)
	ok("and boots do nothing for a sheep", absf((m.x - x0) - D.PLAYER_SPEED * 1.25) < 0.05, m.x - x0)
	m.feet = -1
	var it = R.find_interact(m)
	ok("from its back, holding E only gets you off", it != null and it.type == "dismount")
	m.atkCd = 0; var ac0 := m.ac
	R.do_attack(m)
	ok("and you cannot attack", m.ac == ac0 and m.atkCd == 0)
	m.x = 0; m.z = 10
	hold(m, 0.5)
	ok("off again", not m.ride and sh.state == "graze")
	R.day += 1                                       # the next day: hungry
	m.food = 0
	R.ride(m, true)
	ok("a hungry sheep will not be ridden", not m.ride)
	m.food = 3
	R.ride(m, true)
	ok("one food, and it will", m.ride and m.food == 2 and m.sheepFed == R.day)
	R.dusk_falls()
	ok("at dusk it is put away, and you are off it", not m.ride and R.sheep_of(m) == null)
	R.ride(m, true)
	ok("and it will not come out at night", not m.ride)
	R.timeLeft = 0.01; R.step(STEP); R.night.q = []; R.night.boss = -1; R.undead.clear()
	R.end_night()
	fast(0.2)
	ok("in the morning it is out again", R.sheep_of(m) != null and R.phase == "day")
	# ---------------------------------------------------------------- strays
	var got := false
	for i in 40:
		R.day = 3
		if R.strays_morning() or R.peasants.any(func(q): return q.stray and q.owner == 0): got = true; break
	var st_: Array = R.peasants.filter(func(q): return q.stray and q.owner == 0)
	ok("now and then a stray is out there, hiding", got and st_.size() >= 1)
	var sq: E.Peasant = st_[0]
	ok("round the farms or in the forest", sq.x < -40)
	ok("a little weaker than a villager", Rules.q_max(sq) < D.PEASANT_HP and sq.hp == D.STRAY.hp)
	var pm0 := R.posse_max(m)
	var before := m.posse
	m.x = sq.x + 1; m.z = sq.z; m.tx = m.x; m.tz = m.z; m.ride = false
	var kind := hold(m, D.STRAY.talk + 0.3)
	ok("talked round by holding E", kind == "rally" and sq.owner == m.id, kind)
	fast(0.1)
	ok("and over and above the posse's usual size", R.posse_max(m) == pm0 + 1 and m.posse == before + 1)
	R.strays_morning()
	var more: Array = R.peasants.filter(func(q): return q.stray and q.owner == 0)
	if more.is_empty():
		var q2 := R.mk_peasant(1, m.x + 1, m.z, m.x + 1, m.z, 0); q2.stray = true; R.peasants.append(q2); more = [q2]
	m.x = more[0].x + 1; m.z = more[0].z
	var it2 = R.find_interact(m)
	ok("one a week at most", it2 != null and it2.type == "rally" and not it2.ok)
	# a stray may run off at dusk: one in the hundred for every player
	var runs := 0
	var coin_ok := true
	for i in 600:
		for q in R.peasants.filter(func(q): return q.stray and q.owner == m.id): R.peasants.erase(q)
		var s := R.mk_peasant(2, m.x, m.z, m.x, m.z, m.id); s.stray = true; s.kit = 58
		R.peasants.append(s)
		m.coin = 30
		R.phase = "day"; R.village_dusk()
		if not R.peasants.has(s):
			runs += 1
			if m.coin != 30 - D.STRAY.fee: coin_ok = false
	ok("each evening a stray may run away (about 2 in the hundred, with two players)", runs >= 3 and runs <= 30, runs)
	ok("taking a shilling of his leader's coin, and his kit", coin_ok)
	var reg: E.Peasant = posse(m).filter(func(q): return not q.stray)[0]
	ok("ordinary posse members do not desert this way", R.peasants.has(reg))
	# ---------------------------------------------------------------- it is all kept, and sent
	R.phase = "day"
	var sv := R.save_data()
	var R2 := Rules.new()
	R2.load_game(sv, [{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	var m2: E.Player = R2.players[0]
	ok("the save keeps the lesson, the sheep and the strays", m2.herd and m2.sheep and R2.peasants.any(func(q): return q.stray))
	ok("but not the sheep itself, which comes out again", not sv.peasants.any(func(q): return int(q.kind) == 4))
	ok("joined games are told", ["ride", "sheep", "herd", "herdT", "herdQ", "banq", "banqP"].all(func(x): return Net.PF.has(x)) and Net.QSTATE.has("ride"))
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
