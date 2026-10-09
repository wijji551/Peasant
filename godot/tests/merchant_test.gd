extends SceneTree
## Build 4, stage 3: travelling merchants and their jobs, village guards and mercenaries.
## Run:  godot --headless --path godot -s res://tests/merchant_test.gd

var R: Rules
var m: E.Player
var o: E.Player
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


func at_station(p: E.Player, id: String) -> void:
	var st := D.station(id)
	p.x = st.x; p.z = st.z


func day_with(id: String) -> void:   # a merchant's day, with that merchant
	R.phase = "day"; R.timeLeft = 300
	for k in D.MERCHANTS.size():
		if D.MERCHANTS[k].id == id: R.merchant = k
	R.job = {"work": 0.0, "done": false}
	R.make_wares()
	for p in R.players:
		p.job = false; p.jobT = 0.0; p.merc = false


func _init() -> void:
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Wat", "col": 1}])
	m = R.players[0]
	o = R.players[1]

	# ---------- when they come
	var days := []
	var who := {}
	for d in range(1, 31):
		var k := Rules.merchant_on(R.gseed, d, 30)
		if k >= 0:
			days.append(d); who[k] = true
	ok("merchants come on about six days of the month", days.size() == 6, days)
	ok("all five come at least once", who.size() == 5, who.keys())
	ok("nobody on the first day", Rules.merchant_on(R.gseed, 1, 30) == -1)
	var sd := []
	for d in range(1, 8):
		if Rules.merchant_on(R.gseed, d, 7) >= 0: sd.append(d)
	ok("three in the short game", sd.size() == 3, sd)
	var lined := false
	R.day = days[0] - 1
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP); R.night.q = []; R.night.boss = -1; R.undead.clear(); R.step(STEP); R.ev.clear()
	ok("the dawn notice says a merchant has come", R.merchant >= 0 and " ".join(R.dawn.lines).contains("merchant"), R.dawn.lines[-1])

	# ---------- buying
	day_with("armourer")
	at_station(m, "cart"); m.coin = 100
	var i_sword := -1
	for i in R.wares.size():
		if R.wares[i].give == "it" and R.wares[i].it == 1: i_sword = i
	R.do_act(m, "mbuy", str(i_sword))
	ok("the armourer sells a forged sword for coin, no smithy needed", m.wpn == 1 and m.coin == 76, [m.wpn, m.coin])
	R.do_act(m, "mbuy", str(i_sword))
	ok("and he only had the one", m.coin == 76)
	m.x = 40; m.z = 0
	R.do_act(m, "mbuy", "0")
	ok("you have to be at the cart", m.coin == 76)
	day_with("tinker")
	at_station(m, "cart"); m.coin = 100; m.cogs = 0
	R.do_act(m, "mbuy", str(R.wares.size() - 1))
	ok("the tinker sells boxes of cogs", m.cogs == 1)
	day_with("bookseller")
	at_station(m, "cart"); m.coin = 200; m.books[4] = 2; m.xp[4] = Rules.need_xp(4, 1)
	var x0: float = m.xp[4]
	R.do_act(m, "mbuy", "0:4")
	ok("the bookseller's loose page advances a book", m.xp[4] > x0, [x0, m.xp[4]])
	R.do_act(m, "mbuy", "1")
	ok("and he sells An Index of Further Reading", m.xslot)
	day_with("pedlar")
	at_station(m, "cart"); m.coin = 500
	var real_i := -1
	for i in R.wares.size():
		if R.wares[i].real >= 0: real_i = i
	ok("the relic pedlar has three, one of them real", R.wares.size() == 3 and real_i >= 0)
	var fake_i := (real_i + 1) % 3
	var inv0 := m.inv.size()
	R.do_act(m, "mbuy", str(fake_i))
	ok("a fake is rubbish", m.inv.size() == inv0 and m.coin == 500 - 36)
	R.do_act(m, "mbuy", str(real_i))
	ok("the real one is a relic", R.relics.size() == 1 and (m.inv.size() > inv0 or D.IT[m.wpn].tier == "relic" or m.head == 20 or m.body == 23 or m.trk >= 26))
	day_with("brewer")
	at_station(m, "cart"); m.coin = 100; var ale0 := R.ale
	R.do_act(m, "mbuy", "1")
	ok("the brewer's ale goes straight to the Thorny Rose", R.ale == ale0 + 5)
	R.phase = "dusk"
	R.do_act(m, "mbuy", "0")
	ok("he leaves at dusk", m.coin == 90)

	# ---------- the job
	day_with("brewer")
	at_station(m, "cart"); m.books[0] = 1; m.xp[0] = 0.0
	R.do_act(m, "job")
	ok("taking the job", m.job)
	fast(60)
	ok("working on it, near the cart", R.job.work > 55 and m.jobT > 55, [R.job.work, m.jobT])
	R.add_xp(m, 0, 5)
	ok("no learning from a book on a job day", m.xp[0] == 0.0)
	var trunk: E.Trunk = R.trees[0]
	ok("and no gathering while on the job", not R.gather_one("tree", trunk, m))
	at_station(o, "cart")
	R.do_act(o, "job")
	var w0: float = R.job.work
	fast(30)
	ok("a team-mate helping makes it go twice as fast", R.job.work - w0 > 55, R.job.work - w0)
	fast(60)
	ok("the job gets done", R.job.done and not m.job and not o.job, R.job.work)
	ok("and pays: the Brewer's Reserve for tonight", R.reserve and R.ale >= 10)
	ok("the helper gets a shilling", o.coin >= 12, o.coin)
	R.do_act(m, "job")
	ok("a job is only done once", not m.job)
	m.cg = 0; m.state = "inn"; m.drinkT = 0.01; R.phase = "dusk"; R.timeLeft = 20
	var p0 := m.cg
	fast(0.2)
	ok("with the Reserve a tankard counts double", m.cg >= D.TANKARD * 2 - 0.01 and m.cg <= 100, m.cg)
	m.state = "ok"; R.phase = "day"
	day_with("tinker")
	at_station(m, "cart")
	R.do_act(m, "job")
	fast(10)
	ok("the tinker's job is at the rocky outcrop, not the cart", m.job and R.job.work == 0.0)
	m.x = R.QUARRY.x + 3; m.z = R.QUARRY.z
	fast(10)
	ok("so you go there", R.job.work > 9, R.job.work)
	R.job.work = D.JOB_WORK - 1; var cg0 := m.cogs
	fast(2)
	ok("and get boxes of cogs", m.cogs >= cg0 + 2, m.cogs)

	# ---------- village guards
	day_with("tinker")
	R.merchant = -1
	at_station(m, "bailiff"); m.coin = 1000
	for i in 7: R.do_act(m, "guard")
	var gs := R.peasants.filter(func(q): return q.kind == 1)
	ok("Robert Bailiff hires out six guards and no more, for 8 shillings each", gs.size() == 6 and m.coin == 1000 - 6 * 96, [gs.size(), m.coin])
	ok("two at each gate", gs.filter(func(q): return absf(q.px) < 1).size() == 2 and gs.filter(func(q): return q.px < -20).size() == 2)
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP); R.night.q = [{"k": 0, "t": 9999.0}]; R.night.boss = -1   # one still to rise, much later: the night goes on
	m.state = "hide"
	for q in R.peasants:
		if q.kind == 0 and q.state != "body": q.state = "gone"
	var g: E.Peasant = gs[0]
	var u := R.spawn_undead(0, g.px, g.pz - 4.0)
	u.state = "walk"; u.t = 0; u.hp = 999
	fast(4)
	ok("a guard fights what comes to his gate", u.hp < 999, u.hp)
	R.undead.clear()
	fast(4)
	ok("and goes back to his post", R.phase == "night" and Vector2(g.x - g.px, g.z - g.pz).length() < 1.2, Vector2(g.x - g.px, g.z - g.pz).length())
	R.night.q = []; R.undead.clear(); fast(0.2)
	ok("at dawn the guards go home", R.phase == "day" and R.peasants.filter(func(q): return q.kind == 1).is_empty() and R.guards == 0)

	# ---------- mercenaries
	m.state = "ok"; at_station(m, "inn"); m.coin = 200
	var n0 := R.peasants.filter(func(q): return q.owner == m.id).size()
	R.do_act(m, "merc"); R.do_act(m, "merc")
	var mercs := R.peasants.filter(func(q): return q.kind == 2)
	ok("a mercenary joins your posse, one a day", mercs.size() == 1 and mercs[0].owner == m.id and m.coin == 104, [mercs.size(), m.coin])
	ok("tougher than a villager", Rules.q_max(mercs[0]) > D.PEASANT_HP)
	var paid := 0
	var robbed := 0
	for i in 140:                                  # many dawns: about one in seven turns nasty
		R.peasants = R.peasants.filter(func(q): return q.kind != 2)
		m.merc = false; m.coin = 200; m.inv = [6]; R.phase = "day"; at_station(m, "inn")
		R.do_act(m, "merc")
		var c0 := m.coin
		R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP); R.night.q = []; R.night.boss = -1; R.undead.clear(); R.step(STEP); R.ev.clear()
		if m.coin == c0 - 24 + (6 + 0): paid += 1
		elif m.coin < c0: paid += 1
		if R.day >= 29:
			R.day = 5
	ok("about one mercenary in seven demands more at dawn", paid > 8 and paid < 40, paid)
	R.peasants = R.peasants.filter(func(q): return q.kind != 2)
	m.merc = false; m.coin = 96; m.inv = [6]; R.phase = "day"; at_station(m, "inn")
	R.do_act(m, "merc")
	var robbed_once := false
	for i in 60:
		if robbed_once: break
		m.coin = 0; m.inv = [6]
		var mm := R.peasants.filter(func(q): return q.kind == 2)
		if mm.is_empty():
			m.merc = false; m.coin = 96; R.phase = "day"; at_station(m, "inn"); R.do_act(m, "merc"); m.coin = 0
		R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP); R.night.q = []; R.night.boss = -1; R.undead.clear(); R.step(STEP); R.ev.clear()
		if m.inv.is_empty() and " ".join(R.dawn.lines).contains("good hiding"): robbed_once = true
		if R.day >= 29: R.day = 5
	ok("one who cannot pay is beaten and loses something", robbed_once)

	var fails := lines.filter(func(l): return l.begins_with("FAIL")).size()
	for l in lines: print(l)
	print("%d passed, %d failed" % [lines.size() - fails, fails])
	quit(1 if fails else 0)
