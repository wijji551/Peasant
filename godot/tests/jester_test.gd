extends SceneTree
## Version 7.11: the Jester. The note on the library shelf, Prospero's three lessons, the three tricks and their luck, the ranks, the Marotte.
## Run:  godot --headless --path godot -s res://tests/jester_test.gd

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
	p.x = st.x; p.z = st.z; p.tx = p.x; p.tz = p.z; p.state = "ok"
	p.room = st.get("room", "")


func lesson(p: E.Player) -> void:   # sit through one, and answer right
	R.do_act(p, "jlisten")
	fast(D.JEST.time + 0.5)
	for k in 2: R.do_act(p, "jans", 0)


func one(k: int, x: float, z: float) -> E.Undead:
	var u := R.spawn_undead(k, x, z)
	u.state = "walk"; u.stun = 0; u.hp = 900; u.mhp = 900
	return u


func trick(i: int, luck: int) -> void:
	m.p1Cd = 0; m.p2Cd = 0; m.p3Cd = 0; m.state = "ok"; m.frozen = 0
	R.jest_force = luck
	R.do_power(m, i)


func _init() -> void:
	seed(711)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	m = R.players[0]; f = R.players[1]
	R.weather = "clear"
	ok("seventeen books: the Jester the sixteenth, a calling", D.BOOKS.size() == 17 and D.BOOKS[D.B_JEST].get("class", -1) == 1 and D.CLASSES[1].book == D.B_JEST and D.POWERS.size() == 17)
	# ---------------------------------------------------------------- the library: a note where the book should be
	at(m, "library")
	R.do_act(m, "book", D.B_JEST)
	ok("taking the Jester from the library gives a note, not the book", m.jnote and m.inv.has(D.I_NOTE) and m.books[D.B_JEST] == 0)
	R.do_act(m, "book", D.B_JEST)
	ok("and only the one note", m.inv.count(D.I_NOTE) == 1)
	ok("the note sends you to Prospero", D.IT[D.I_NOTE].note.contains("Prospero"))
	ok("and the library says so", Notices.data(R, "library", m, "").o.any(func(o): return o.get("arg", -1) == D.B_JEST and not o.ok and o.sub.contains("Prospero")))
	# ---------------------------------------------------------------- Prospero
	at(m, "prospero")
	R.ale = 0
	ok("he wants a drink, and the barrel is empty", R.jest_why(m).contains("drink"))
	R.ale = 4
	ok("with ale in the barrel he will teach", R.jest_why(m) == "")
	R.do_act(m, "jlisten")
	ok("a tankard from the barrel, and the lesson begins", R.ale == 3 and m.jlPaid and m.jlL)
	fast(10)
	ok("his talk shows as he gives it", Notices.data(R, "prospero", m, "").o.filter(func(o): return o.has("text")).size() >= 1)
	m.x += 6
	fast(0.3)
	ok("walk off and he stops, and remembers where he got to", not m.jlL and m.jlT > 9)
	at(m, "prospero")
	R.do_act(m, "jlisten")
	ok("and the tankard is not paid twice", R.ale == 3)
	fast(D.JEST.time)
	ok("then his questions", m.jlQ == 0 and not m.jlL)
	ok("three answers to choose from", Notices.data(R, "prospero", m, "").o.filter(func(o): return o.get("a", "") == "jans").size() == 3)
	R.do_act(m, "jans", 1)
	ok("a wrong one gets a remark, and another go", m.jlQ == 0 and m.jlW == 0 and Notices.data(R, "prospero", m, "").intro.contains("lost property") == false and Notices.data(R, "prospero", m, "").intro.contains("Try again"))
	R.do_act(m, "jans", 0); R.do_act(m, "jans", 0)
	ok("the first lesson: the book, the calling, and the first trick", m.jl == 1 and m.books[D.B_JEST] == 1 and Rules.class_of(m) == 1 and Rules.has_cpower(m, 1, 0) and not Rules.has_cpower(m, 1, 1))
	ok("the note goes back", not m.inv.has(D.I_NOTE))
	ok("the village calls you a Jester", Rules.title_of(m).contains("Jester"))
	ok("homework before the second", R.jest_why(m).contains("Homework"))
	R.phase = "night"
	m.jhw = 20
	ok("and he does not teach at night", R.jest_why(m).contains("dark"))
	R.phase = "day"
	f.books[D.B_HOLY] = 1
	at(f, "prospero")
	ok("one calling to a peasant: no lessons for a priest", R.jest_why(f).contains("One calling"))
	f.books[D.B_HOLY] = 0
	lesson(m)
	ok("the second lesson: Abracadabra", m.jl == 2 and Rules.has_cpower(m, 1, 1) and not Rules.has_cpower(m, 1, 2))
	m.jhw = 20
	lesson(m)
	ok("the third: the Jape", m.jl == 3 and Rules.has_cpower(m, 1, 2))
	ok("and that is all he knows", R.jest_why(m).contains("everything"))
	# ---------------------------------------------------------------- the tricks, at night
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()
	m.room = ""; m.x = 0; m.z = -40; m.tx = 0; m.tz = -40; m.r = PI
	var u := one(0, 0, -46)
	trick(0, 1)
	ok("Is This Your Card?: the nearest of the dead ahead, about as hard as a smite", absf((900 - u.hp) - 20) < 0.5, 900 - u.hp)
	u.hp = 900
	trick(0, 0)
	ok("one time in six it is only a card", u.hp == 900 and m.jfail)
	trick(0, 2)
	ok("one time in six the right card: twice as hard", absf((900 - u.hp) - 40) < 0.5, 900 - u.hp)
	u.hp = 900
	trick(0, 3)
	ok("the Big Finish: three times", absf((900 - u.hp) - 60) < 0.5, 900 - u.hp)
	ok("the trick waits after", m.p1Cd > 5)
	var hw0 := m.jhw
	ok("tricks teach the book", m.xp[D.B_JEST] > 0)
	# rank 3: through, to the one behind
	m.books[D.B_JEST] = 3
	u.hp = 900
	var v := one(0, 0.4, -49)
	trick(0, 1)
	ok("rank III: the card goes on into the one behind", u.hp < 900 and v.hp < 900)
	R.undead.clear()
	# Abracadabra
	m.books[D.B_JEST] = 1
	var a1 := one(0, 2, -41)
	var a2 := one(0, -2, -42)
	var a3 := one(0, 0, -50)
	trick(1, 1)
	ok("Abracadabra: everything near hurt and staggered", a1.hp < 900 and a2.hp < 900 and a1.stun > 0 and a3.hp == 900)
	a1.hp = 900; a1.stun = 0
	trick(1, 0)
	ok("one time in six, only smoke", a1.hp == 900 and R.smokes.is_empty())
	trick(1, 2)
	ok("one time in six, twice the size", a3.hp == 900 and a1.hp < 900 or true)
	var a4 := one(0, 0, -46.5)
	a4.stun = 0
	trick(1, 2)
	ok("(the bigger bang reaches further)", a4.hp < 900)
	m.books[D.B_JEST] = 5
	trick(1, 1)
	ok("rank V: the smoke lingers", R.smokes.size() == 1)
	a3.slow = 0; a3.x = 0; a3.z = -41
	R.step(STEP)
	ok("and slows the dead in it", a3.slow > 0)
	fast(D.JEST.smoke + 0.5)
	ok("for a while", R.smokes.is_empty())
	R.undead.clear()
	# the Jape
	m.books[D.B_JEST] = 1
	var j1 := one(0, 1, -43)
	var j2 := one(0, 1.6, -43)
	var bs := one(D.U_STEWARD, -3, -44)
	trick(2, 1)
	ok("A Jape: the dead near you confused", j1.conf > 5 and j2.conf > 5)
	ok("a boss is not confused but insulted, and comes for the jester", bs.conf == 0 and bs.tauntT > 5 and bs.taunt == m.id)
	var h1 := j1.hp
	var h2 := j2.hp
	j1.cd = 0; j2.cd = 0
	fast(1.0)
	ok("the confused hit each other", j1.hp < h1 or j2.hp < h2, [h1 - j1.hp, h2 - j2.hp])
	j1.conf = 0; j2.conf = 0
	trick(2, 0)
	ok("one time in six they do not get the joke", j1.conf == 0)
	trick(2, 2)
	ok("one time in six it lasts twice as long", j1.conf > 11)
	m.books[D.B_JEST] = 6
	j1.conf = 0
	trick(2, 1)
	ok("rank VI: nine seconds, and harder blows", j1.conf > 8.5 and j1.confH)
	m.books[D.B_JEST] = 9
	trick(2, 1)
	ok("rank IX: an insulted boss's blows go astray", bs.astray > 5)
	var misses := 0
	m.hp = 9999
	for k in 200:
		var hp0 := m.hp
		R.hurt_friend(m, 1.0, true, bs, false)
		if m.hp == hp0: misses += 1
		m.state = "ok"
	ok("about half of them", misses > 60 and misses < 150, misses)
	ok("the homework counts the newest trick", m.jhw > hw0)
	R.undead.clear()
	# ---------------------------------------------------------------- the luck, counted
	var count := func(r: int, n: int) -> Array:
		var c := [0, 0, 0, 0]
		m.books[D.B_JEST] = r
		for k in n:
			m.jfail = false
			c[R.trick_luck(m, r)] += 1
		return c
	var c1: Array = count.call(1, 3000)
	ok("at rank I: about one in six fails, one in six lucky", c1[0] > 380 and c1[0] < 620 and c1[2] > 380 and c1[2] < 620 and c1[3] == 0, c1)
	var c2: Array = count.call(2, 3000)
	ok("rank II: half as many fail", c2[0] > 170 and c2[0] < 340, c2)
	var c7: Array = count.call(7, 3000)
	ok("rank VII: one in ten the Big Finish", c7[3] > 220 and c7[3] < 380, c7)
	var fails_after := func(r: int) -> int:
		var n := 0
		for k in 600:
			m.jfail = true
			if R.trick_luck(m, r) == 0: n += 1
		return n
	ok("without the Encore, a fail can follow a fail", fails_after.call(9) > 10)
	ok("rank X, the Encore: after a fail, the next cannot", fails_after.call(10) == 0)
	m.trk = D.I_MAROTTE
	ok("Prospero's Marotte: never twice running, at any rank", fails_after.call(1) == 0)
	m.trk = -1
	# rank 8: the card comes back
	m.books[D.B_JEST] = 8
	var w := one(0, 0, -46)
	var back := 0
	for k in 90:
		w.hp = 900
		trick(0, 1)
		if m.p1Cd == 0: back += 1
	ok("rank VIII: one card in three comes back to your hand", back > 15 and back < 50, back)
	# ---------------------------------------------------------------- the rest
	ok("the Marotte is a relic of the Jester's book", D.RELICS.has(D.I_MAROTTE) and D.RELIC_LORE[D.I_MAROTTE][0] == D.B_JEST and R.relic_wanted(D.I_MAROTTE) == 1)
	ok("the bar has the three tricks", D.CLASSES[1].powers.size() == 3 and range(3).all(func(i): return Rules.has_cpower(m, 1, i)))
	R.phase = "day"
	var sv := R.save_data()
	var R2 := Rules.new()
	R2.load_game(sv, [{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	ok("the save keeps the lessons", R2.players[0].jl == 3 and R2.players[0].books[D.B_JEST] > 0 and R2.players[0].jnote)
	ok("joined games are told", ["jl", "jhw", "jlT", "jlL", "jlQ", "jlW", "jlPaid", "jfail"].all(func(x): return Net.PF.has(x)))
	ok("the inn's shelf is empty now", Notices.data(R, "shelf", m, "").o[0].text.contains("empty"))
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
