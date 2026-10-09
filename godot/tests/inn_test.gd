extends SceneTree
## Inside the Thorny Rose: a room to walk into, the bar, three locals, and the gambler's three games.
## Run:  godot --headless --path godot -s res://tests/inn_test.gd

var R: Rules
var m: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func fast(sec: float, f: Callable = Callable()) -> float:
	var t := 0.0
	while t < sec:
		if f.is_valid() and f.call() == false: return t
		R.step(STEP); R.ev.clear(); t += STEP
	return t


func at(id: String) -> void:
	var st := D.station(id)
	m.x = st.x; m.z = st.z


func _init() -> void:
	seed(4321)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	var M: Dictionary = D.ROOMS.inn
	m.x = M.door[0] + 0.6; m.z = M.door[1]
	var it = R.find_interact(m)
	ok("the door of the Rose, on the square, by day", it != null and it.get("type") == "enter" and it.room == "inn" and it.ok, it)
	m.eHold = true; fast(1.0); m.eHold = false
	ok("holding E goes in", m.room == "inn" and absf(m.x - M.x) < M.hw and absf(m.z - M.z) < M.hd, [m.room, m.x, m.z])
	# the bar: the innkeeper's old business, now inside
	at("inn")
	it = R.find_interact(m)
	ok("the bar is in there", it != null and it.get("type") == "station" and it.st.id == "inn", it)
	var d := Notices.data(R, "inn", m, "")
	ok("the innkeeper hires out a mercenary, takes food for ale, and pours after dark", d.o.any(func(o): return o.get("a", "") == "merc") and d.o.any(func(o): return o.get("a", "") == "ale") and d.o.any(func(o): return o.get("a", "") == "innin" and not o.ok))
	m.food = 5
	R.do_act(m, "ale")
	ok("food for the barrel, at the bar", R.ale == 5 and m.food == 0)
	# the locals
	at("local0")
	d = Notices.data(R, "local0", m, "")
	ok("Old Marge can be asked three things", d.title == "Old Marge" and d.o.filter(func(o): return str(o.get("page", "")).begins_with("t")).size() == 3)
	d = Notices.data(R, "local0", m, "t0")
	ok("and answers", d.intro.begins_with("“") and d.intro.length() > 30, d.intro)
	m.coin = 20; m.food = 0
	R.do_act(m, "treat", 0)
	ok("a drink for Marge: a pie", m.coin == 20 - D.TREAT and m.food == 3 and (m.treated & 1) == 1)
	R.do_act(m, "treat", 0)
	ok("once a day", m.coin == 20 - D.TREAT and m.food == 3)
	at("local1")
	R.chest = {"x": 80.0, "z": 30.0, "from": 0, "road": 1, "seen": false, "open": false, "rot": 0.0}
	R.do_act(m, "treat", 1)
	ok("a drink for Tam: he has seen the lost chest, and now it is on the map", R.chest.seen and R.ev.any(func(e): return e[0] == "tip"))
	R.ev.clear()
	at("local2")
	R.do_act(m, "treat", 2)
	ok("a drink for the stranger: how to deal with the next of the household", R.ev.any(func(e): return e[0] == "tip" and "Steward" in str(e[3])), R.ev)
	R.ev.clear()
	d = Notices.data(R, "shelf", m, "")
	ok("the bookshelf has the Jester's book, for later", d.o.any(func(o): return "JESTER" in str(o.get("text", ""))))
	# ---------- the gambler
	at("gambler")
	m.coin = 100
	R.do_act(m, "gstart", "21:7")
	ok("he does not take odd stakes", m.game.is_empty() and m.coin == 100)
	var wins := 0
	var ties := 0
	var losses := 0
	for i in 400:                                        # twenty-one, played plainly: draw to 17
		m.coin = 1000; m.gwon = 0
		R.do_act(m, "gstart", "21:12")
		var guard := 0
		while not m.game.done and guard < 12:
			guard += 1
			if Rules.total21(m.game.me) < 17: R.do_act(m, "ghit")
			else: R.do_act(m, "gstand")
		var back := int(m.game.win)
		if back > 12: wins += 1
		elif back == 12: ties += 1
		else: losses += 1
		if m.coin != 1000 - 12 + back: ok("twenty-one pays what it says", false, [m.coin, back])
		R.do_act(m, "gend")
	ok("twenty-one: you win some, he wins a few more", wins > 120 and losses > 150 and wins < losses + 40, [wins, ties, losses])
	ok("a hand of cards counts as it should", Rules.total21([0, 12]) == 21 and Rules.total21([0, 0, 9]) == 12 and Rules.total21([10, 11, 4]) == 25)
	m.coin = 100; m.gwon = 0
	R.do_act(m, "gstart", "hl:12")
	var pays := Rules.hl_pays(int(m.game.card), 12)
	ok("higher or lower pays less for the safer guess", Rules.hl_pays(1, 12)[0] < Rules.hl_pays(10, 12)[0] and Rules.hl_pays(0, 12)[1] == 0 and Rules.hl_pays(12, 12)[0] == 0, [Rules.hl_pays(1, 12), Rules.hl_pays(10, 12)])
	R.do_act(m, "ghi" if pays[0] > 0 and (pays[1] == 0 or pays[0] < pays[1]) else "glo")
	ok("and is settled on the next card", m.game.done and int(m.game.next) >= 0 and (m.coin == 88 or m.coin == 88 + int(m.game.win)), [m.coin, m.game])
	var net := 0
	for i in 600:
		m.coin = 1000; m.gwon = 0
		R.do_act(m, "gend"); R.do_act(m, "gstart", "hl:12")
		var pp := Rules.hl_pays(int(m.game.card), 12)
		R.do_act(m, "ghi" if pp[0] > 0 and (pp[1] == 0 or pp[0] < pp[1]) else "glo")
		net += m.coin - 1000
	ok("over a long evening the house comes out ahead", net < 0 and net > -600 * 12 * 0.35, net)
	# the cups: no luck in it
	R.do_act(m, "gend")
	m.coin = 100; m.gwon = 0; m.gstreak = 0
	R.do_act(m, "gstart", "cups:24")
	var G: Dictionary = m.game
	ok("the cups: he shows the pea and shuffles", G.g == "cups" and G.swaps.size() >= 5 and float(G.t) > 2.0 and m.coin == 76, G)
	R.do_act(m, "gcup", 0)
	ok("no picking while his hands are moving", not m.game.done)
	fast(float(G.t) + 0.3)
	var where := Rules.cups_end(int(m.game.ball), m.game.swaps)
	ok("the pea goes with its cup", Rules.cups_end(0, [[0, 1], [1, 2]]) == 2 and Rules.cups_end(2, [[0, 1]]) == 2 and where >= 0 and where < 3)
	R.do_act(m, "gcup", where)
	ok("follow it and he pays your stake again", m.game.done and m.coin == 76 + 48 and m.gstreak == 1 and m.gwon == 24, [m.coin, m.gstreak, m.gwon])
	R.do_act(m, "gend"); R.do_act(m, "gstart", "cups:24")
	ok("and moves them faster next time", float(m.game.sp) < float(G.sp) and m.game.swaps.size() > G.swaps.size(), [m.game.sp, m.game.swaps.size()])
	fast(float(m.game.t) + 0.3)
	R.do_act(m, "gcup", (Rules.cups_end(int(m.game.ball), m.game.swaps) + 1) % 3)
	ok("the wrong cup loses the stake", m.game.done and int(m.game.win) == 0 and m.gstreak == 0)
	R.do_act(m, "gend")
	m.gwon = D.GAMBLE_DAY
	R.do_act(m, "gstart", "cups:6")
	ok("when he has lost enough for one day he packs up", m.game.is_empty())
	m.gwon = 0
	R.do_act(m, "gstart", "21:6")
	m.x = M.x - 6; m.z = M.z + 4
	fast(0.2)
	ok("walking away from the table forfeits the game", m.game.is_empty())
	# ---------- out again, and the night
	m.x = M.at[0]; m.z = M.at[1] - 0.6
	m.eHold = true; fast(1.0); m.eHold = false
	ok("the door goes back out to the square", m.room == "" and D.d2(m.x, m.z, M.door[0], M.door[1]) < 9, [m.x, m.z])
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.boss = -1
	R.enter_room(m, "inn"); at("inn")
	R.do_act(m, "innin")
	ok("after dark you can sit down at the bar to drink, as before", m.state == "inn" and m.room == "inn")
	R.do_act(m, "innout")
	ok("and leaving the bar puts you outside the door", m.state == "ok" and m.room == "" and D.d2(m.x, m.z, D.INN.dx, D.INN.dz) < 4)
	R.innHp = 0
	m.x = M.door[0] + 0.6; m.z = M.door[1]
	it = R.find_interact(m)
	ok("with the door in pieces the Rose is shut", it != null and it.get("type") == "enter" and not it.ok, it)
	var fails := 0
	for l in lines:
		if l.begins_with("FAIL"): fails += 1
		print(l)
	print("%d passed, %d failed" % [lines.size() - fails, fails])
	quit()
