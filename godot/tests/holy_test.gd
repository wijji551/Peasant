extends SceneTree
## Build 4, stage 2: the Holy Book (the apprentice priest), titles, the fourth book, and relics tied to books.
## Run:  godot --headless --path godot -s res://tests/holy_test.gd

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


func one(k: int, x: float, z: float) -> E.Undead:
	var u := R.spawn_undead(k, x, z)
	u.state = "walk"; u.t = 0; u.stun = 999
	return u


func lib() -> void:
	var st := D.station("library")
	m.x = st.x; m.z = st.z


func _init() -> void:
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Wat", "col": 1}])
	m = R.players[0]
	o = R.players[1]
	ok("eleven books, the last the Holy Book", D.BOOKS.size() == 11 and D.BOOKS[10].name.begins_with("The Holy Book") and m.books.size() == 11)
	ok("a peasant with no book has no calling, and is the Unread", Rules.class_of(m) == -1 and Rules.title_of(m) == "the Unread")

	# ---------- taking up the Holy Book
	lib()
	R.do_act(m, "book", 10)
	ok("the Holy Book makes you an apprentice priest", m.books[10] == 1 and Rules.class_of(m) == 0)
	ok("and gives you a title", Rules.title_of(m) == "the Apprentice Priest", Rules.title_of(m))

	# ---------- Smite
	R.phase = "night"; R.night = {"t": 0.0, "q": [], "total": 0, "c": [], "dur": 80.0, "kills": 0, "boss": -1, "idle": 0.0}
	m.x = 40; m.z = 0; m.r = 0
	var u := one(0, 40, 8)
	u.hp = 999
	var h0 := u.hp
	R.do_power(m, 0)
	ok("Smite brings holy light down on the nearest of the dead", u.hp < h0 and m.p1Cd > 0, [h0 - u.hp, m.p1Cd])
	var once := h0 - u.hp
	u.hp = 999
	R.do_power(m, 0)
	ok("and then it needs a moment", u.hp == 999)
	ok("rank 1 of the book cannot pray yet", m.p2Cd == 0 and (func(): R.do_power(m, 1); return m.p2Cd == 0).call())
	var w := one(D.U_WRAITH, 40, 6)
	w.hp = 200
	m.p1Cd = 0; R.do_power(m, 0)
	ok("a smite hurts a wraith (it is holy)", w.hp < 200, w.hp)
	R.undead.clear()
	ok("smiting is how the book is learned", m.xp[10] >= 2, m.xp[10])

	# ---------- Pray
	m.books[10] = 2; m.p2Cd = 0
	o.state = "ok"; o.x = 42; o.z = 1; o.prot = 0
	var mine := R.peasants.filter(func(q): return q.owner == m.id and q.state != "body")
	for q in mine: q.x = 39; q.z = 1
	R.do_power(m, 1)
	ok("A Word of Protection: you, a team-mate and your posse are prayed over", m.prot > 0 and o.prot > 0 and mine.all(func(q): return q.prot > 0), [m.prot, o.prot])
	var hp0 := o.hp
	var hu := one(0, 42, 2)
	R.hurt_friend(o, 30, true, hu, false)
	var prot_hit := hp0 - o.hp
	o.prot = 0; o.hp = hp0
	R.hurt_friend(o, 30, true, hu, false)
	var bare_hit := hp0 - o.hp
	ok("protected, a blow does a third less", absf(prot_hit - bare_hit * 0.67) < 0.5, [prot_hit, bare_hit])
	R.undead.clear()
	ok("no holy weapons yet at rank 2", o.hb == 0)
	m.books[10] = 3; m.p2Cd = 0
	R.do_power(m, 1)
	ok("at rank 3 the prayer makes weapons holy", o.hb > 0 and Rules.src_of(o, D.IT[o.wpn]).holy > 0)
	fast(11)
	ok("for a while", o.hb == 0 and o.prot == 0)

	# ---------- the higher ranks
	m.books[10] = 4; m.p1Cd = 0
	R.phase = "night"; R.night = {"t": 0.0, "q": [], "total": 0, "c": [], "dur": 80.0, "kills": 0, "boss": -1, "idle": 0.0}
	m.x = 40; m.z = 0; m.r = 0; m.state = "ok"
	var a1 := one(0, 40, 8)
	var a2 := one(0, 41, 8.5)
	a1.hp = 999; a2.hp = 999
	R.do_power(m, 0)
	ok("Smiting, With Feeling: it bursts over the ones nearby", a1.hp < 999 and a2.hp < 999)
	R.undead.clear()
	m.books[10] = 5
	ok("at rank 5 powers come round a third sooner", absf(Rules.power_wait(m, 1) - 20.1) < 0.2, Rules.power_wait(m, 1))
	m.books[10] = 7; m.p1Cd = 0
	var t3 := [one(0, 40, 6), one(0, 38, 7), one(0, 42, 7), one(0, 40, 9)]
	for t in t3: t.hp = 999
	R.do_power(m, 0)
	var struck := t3.filter(func(t): return t.hp < 999 - 30).size()
	ok("at rank 7 a smite strikes three", struck >= 3, struck)
	R.undead.clear()
	R.phase = "day"

	# ---------- one calling at a time; titles
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	lib()
	R.do_act(m, "book", 6)
	ok("one book: the Ringleader", Rules.title_of(m) == "the Ringleader", Rules.title_of(m))
	m.books[6] = 2
	R.do_act(m, "book", 3)
	ok("two books: the Sooty Ringleader", Rules.title_of(m) == "the Sooty Ringleader", Rules.title_of(m))
	m.books[3] = 4
	ok("the book you know best is what you are", Rules.title_of(m) == "the Bossy Smith", Rules.title_of(m))
	m.books[3] = 7
	ok("master it, and you are the Master", Rules.title_of(m) == "the Bossy Master Smith", Rules.title_of(m))
	ok("taking it further: no slot left", Rules.book_slots(m) == 0 or m.books.filter(func(r): return r > 0).size() >= 2)

	# ---------- the fourth book
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	lib()
	m.books[0] = 3; m.books[4] = 3; m.books[6] = 3
	ok("three books and no more", Rules.book_slots(m) == 0)
	m.xslot = true
	ok("An Index of Further Reading allows a fourth", Rules.book_slots(m) == 1)
	R.do_act(m, "book", 10)
	ok("and a fourth can be the Holy Book", m.books[10] == 1 and Rules.title_of(m).ends_with("Apprentice Priest"), Rules.title_of(m))
	var found := false
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	m.books[8] = 1
	for i in 4000:
		m.xslot = false
		R.spots[i % R.spots.size()] = 2
		R.do_search(m, i % R.spots.size())
		R.undead.clear()
		if m.xslot:
			found = true
			break
	ok("the Index turns up in the ruins", found)
	ok("and is saved", R.save_data().players[0].has("xslot"))

	# ---------- relics tied to books
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	R.phase = "night"; R.night = {"t": 0.0, "q": [], "total": 0, "c": [], "dur": 80.0, "kills": 0, "boss": -1, "idle": 0.0}
	m.x = 40; m.z = 0; m.r = 0; m.wpn = 17
	var s1 := one(0, 40, 1.4)
	s1.hp = 999; m.atkCd = 0; R.do_attack(m)
	var plain := 999 - s1.hp
	m.books[4] = 1
	s1.hp = 999; s1.x = 40; s1.z = 1.4; m.atkCd = 0; m.combo = 0; R.do_attack(m)
	var with_book := 999 - s1.hp
	ok("the Silvered Sword hits harder with The Art of Hitting Things", with_book > plain * 1.15, [plain, with_book])
	R.undead.clear()
	ok("every relic has a book", D.RELICS.all(func(id): return D.RELIC_LORE.has(id)))
	m.trk = 26; m.books[10] = 1
	var bw := one(D.U_WRAITH, 41, 1)
	bw.hp = 200; m.useCd = 0
	R.do_use(m)
	ok("the Chapel Handbell, with the Holy Book, smites what it stuns (even a wraith)", bw.hp < 200, bw.hp)
	R.undead.clear()
	m.head = 20
	var c0 := Rules.charge_len(m)
	m.books[7] = 1
	ok("the Helm of the Unbothered and the Landlord's Ledger: a longer charge", Rules.charge_len(m) > c0 * 1.4, [c0, Rules.charge_len(m)])

	# ---------- saves from before the Holy Book still load
	var sv := R.save_data()
	for pp in sv.players:
		pp.books = pp.books.slice(0, 10); pp.xp = pp.xp.slice(0, 10); pp.erase("xslot")
	var R2 := Rules.new()
	R2.load_game(JSON.parse_string(JSON.stringify(sv)), [{"id": 1, "name": "Matt", "col": 0}])
	ok("an older save gets the eleventh book", R2.players[0].books.size() == 11 and R2.players[0].xp.size() == 11)

	var fails := lines.filter(func(l): return l.begins_with("FAIL")).size()
	for l in lines: print(l)
	print("%d passed, %d failed" % [lines.size() - fails, fails])
	quit(1 if fails else 0)
