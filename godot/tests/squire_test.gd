extends SceneTree
## Version 7.30: the library as a room, Sir Aldous and his sword, the lane and the cabin, the squire's notebook, and the
## Knight's Squire: greatswords in both hands, Challenge!, and the ranks.
## Run:  godot --headless --path godot -s res://tests/squire_test.gd

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


func go_in(p: E.Player, k: String) -> void:     # through the door, as the rules would have it
	var M: Dictionary = D.ROOMS[k]
	if M.has("parent"):
		if p.room != M.parent: go_in(p, M.parent)
	else:
		R.leave_room(p); R.leave_room(p)
	p.x = M.door[0]; p.z = M.door[1]; p.eLock = false
	var it = R.find_interact(p)
	if it and it.type == "enter" and it.room == k and it.ok: R.enter_room(p, k)


func to(p: E.Player, st: String) -> void:
	var s := D.station(st)
	p.x = s.x; p.z = s.z


func shown(id: String, p: E.Player, page: String = "") -> Dictionary:
	return Notices.data(R, id, p, page)


func short_sword(tier: String) -> int:
	return 1 if tier == "forged" else D.crude_of(1) if tier == "crude" else D.steel_of(1) if tier == "steel" else D.tier_item(1, tier)


func _init() -> void:
	seed(730)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	m = R.players[0]; f = R.players[1]
	R.weather = "clear"
	ok("seventeen books, the Knight's Squire the last, with ten ranks and a power", D.BOOKS.size() == 17 and D.BOOKS[D.B_SQUIRE].name == "The Knight’s Squire" and D.BOOKS[16].ranks.size() == 10 and D.POWERS[16].n == "Challenge!")
	ok("the greatswords keep to the end of the list", D.great_of("forged") == 104 and D.IT[104].two and D.IT[105].tier == "crude" and D.IT[106].wear == 2 and D.IT[107].tier == "steel" and D.IT[108].tier == "mithril" and D.IT[109].tier == "rune" and D.IT[D.I_OATH].tier == "relic" and D.IT.size() == 111)
	ok("the relic is a two-handed sword, below the Tithe Collector", D.IT[D.I_OATH].two and D.IT[D.I_OATH].holy and D.IT[D.I_OATH].dmg < D.IT[D.I_TITHE].dmg and D.RELICS.has(D.I_OATH))
	# ---------- the library is a room
	m.x = 14.0; m.z = 20.4
	var it = R.find_interact(m)
	ok("at the library's door: go in", it != null and it.type == "enter" and it.room == "library" and it.ok, it.label if it else null)
	R.enter_room(m, "library")
	ok("and you are inside", m.room == "library")
	to(m, "library")
	it = R.find_interact(m)
	ok("the Peasants' Section is where the books are", it != null and it.type == "station" and it.st.id == "library", it.label if it else null)
	var lib := shown("library", m)
	ok("its notice lists the shelf, and the Knight's Squire is out on loan", lib.title == "The Peasants’ Section" and lib.o.any(func(o): return o.get("label", "").begins_with("The Knight’s Squire") and not o.ok and o.sub.contains("Sir Aldous")))
	R.do_act(m, "book", 4)
	ok("a book taken up, inside", m.books[4] == 1)
	R.do_act(m, "book", D.B_SQUIRE)
	ok("the Knight's Squire cannot be taken from the shelf", m.books[D.B_SQUIRE] == 0)
	ok("one ordinary book: no room for another", Rules.book_slots(m) == 0)
	R.do_act(m, "book", D.B_HOLY)
	ok("the Holy Book does not count: it can still be taken", m.books[D.B_HOLY] == 1 and Rules.book_slots(m) == 0)
	R.leave_room(m)
	ok("out of the library: west of its door, in the village", m.room == "" and m.x < 14.0 and absf(m.z - 20.4) < 1.0, [m.x, m.z])
	R.phase = "night"
	m.x = 14.0; m.z = 20.4
	it = R.find_interact(m)
	ok("shut at night", it != null and it.type == "enter" and not it.ok and it.label.contains("shut"), it.label if it else null)
	R.phase = "day"
	go_in(m, "library")
	R.start_night()
	ok("and nobody is left in it when night falls", m.room == "")
	R.new_game([{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	m = R.players[0]; f = R.players[1]
	# ---------- Sir Aldous and his sword
	ok("he wants a different sword of each player", R.sq_want(m) != R.sq_want(f))
	go_in(m, "library"); to(m, "knight")
	it = R.find_interact(m)
	ok("Sir Aldous, behind the rope", it != null and it.type == "station" and it.st.id == "knight", it.label if it else null)
	var want: String = D.SQ_TIERS[R.sq_want(m)]
	var wrong: String = D.SQ_TIERS[(R.sq_want(m) + 1) % 4]
	m.wpn = short_sword(wrong)
	var k := shown("knight", m)
	ok("his notice offers the sword in your hand", k.o.any(func(o): return o.get("a", "") == "sqsword" and o.arg == "w"))
	R.do_act(m, "sqsword", "w")
	ok("the wrong one: handed back, with a hint", m.wpn == short_sword(wrong) and m.sq == 0 and m.sqsay.contains("not") and (m.sqsay.contains("finer") or m.sqsay.contains("humbler")), m.sqsay)
	m.inv = [short_sword("rune")]
	R.do_act(m, "sqsword", "i0")
	ok("a rune sword: taken off you at swordpoint, and no use", m.inv.is_empty() and m.sq == 0 and m.sqsay.contains("far too powerful for the hands of a peasant"))
	m.inv = [17]
	R.do_act(m, "sqsword", "i0")
	ok("the Silvered Sword: he will not touch a relic", m.inv == [17] and m.sq == 0)
	m.inv = [short_sword(want)]
	R.do_act(m, "sqsword", "i0")
	ok("the right one: he keeps it, and wants the notebook", m.inv.is_empty() and m.sq == 1 and m.sqsay == D.SQ_RIGHT)
	R.do_act(m, "sqbook")
	ok("no notebook yet, no book", m.books[D.B_SQUIRE] == 0)
	# ---------- the lane, the clearing and the cabin
	R.leave_room(m)
	m.x = -122.0; m.z = 2.0
	it = R.find_interact(m)
	ok("at the hedge, on the west road: the lane", it != null and it.type == "enter" and it.room == "woods" and it.ok, it.label if it else null)
	R.enter_room(m, "woods")
	ok("in the woods, at the top of the lane", m.room == "woods" and absf(m.x - D.ROOMS.woods.at[0]) < 1.0)
	m.x = 140.0; m.z = 416.2; R.collide_friend(m, 0.3)
	ok("the thicket keeps you to the lane", m.z > 416.0, m.z)
	var cd: Array = D.ROOMS.cabin.door
	m.x = cd[0]; m.z = cd[1] + 0.4; m.eLock = false
	it = R.find_interact(m)
	ok("the cabin door", it != null and it.type == "enter" and it.room == "cabin", it.label if it else null)
	R.enter_room(m, "cabin")
	ok("inside the cabin", m.room == "cabin")
	var code := Rules.sq_code(R.gseed)
	var all_ok := true
	for i in 3:
		to(m, "paint%d" % i)
		it = R.find_interact(m)
		var pg := shown("paint%d" % i, m)
		if it == null or it.st.id != "paint%d" % i or not pg.o[0].text.contains("%d %s" % [code[i], D.SQ_PAINT[i][0]]): all_ok = false
	ok("three paintings, each with its count and its numeral", all_ok)
	to(m, "sqchest")
	R.do_act(m, "sqopen")
	ok("the chest is locked", m.sq == 1)
	for i in 3:
		for t in code[i]: R.do_act(m, "sqdial", "%d+" % i)
	R.do_act(m, "sqdial", "0+"); R.do_act(m, "sqdial", "0-")
	ok("the dials turn, and back", m.sqd == code[0] * 100 + code[1] * 10 + code[2], m.sqd)
	R.do_act(m, "sqopen")
	ok("with the paintings' numbers: the notebook", m.sq == 2)
	R.leave_room(m)
	ok("out of the cabin, into the clearing", m.room == "woods")
	R.start_night()
	ok("night: back up the lane to the village", m.room == "" and m.x < -100, [m.x, m.z])
	R.phase = "day"; R.timeLeft = 300
	go_in(m, "library"); to(m, "knight")
	ok("he will take the notebook", shown("knight", m).o.any(func(o): return o.get("a", "") == "sqbook"))
	m.wpn = 0
	R.do_act(m, "sqbook")
	ok("he reads you some: the Knight's Squire at rank I", m.books[D.B_SQUIRE] == 1 and m.sq == 3)
	ok("and his squire's practice blade, a crude greatsword, in your hand", m.wpn == D.I_GREAT + 1, m.wpn)
	ok("it does not count against your books", Rules.book_slots(m) == 1)
	ok("Challenge! is on the bar", R.can_book_power(m, D.B_SQUIRE))
	# ---------- two hands
	m.inv = [25]
	R.do_act(m, "eq", 0)
	ok("a shield taken up puts the greatsword away", m.off == 25 and m.wpn == 0 and m.inv.has(D.I_GREAT + 1), [m.wpn, m.off, m.inv])
	R.do_act(m, "eq", m.inv.find(D.I_GREAT + 1))
	ok("and the greatsword taken up puts the shield away", m.wpn == D.I_GREAT + 1 and m.off == -1 and m.inv.has(25), [m.wpn, m.off, m.inv])
	ok("nobody else can swing one", not Rules.can_use(f, D.I_GREAT) and Rules.can_use(m, D.I_GREAT))
	m.books[3] = 2
	ok("no greatswords from the smithy before rank III", not Rules.can_forge(m, D.I_GREAT) and Rules.forge_why(m, D.I_GREAT).contains("rank 3"))
	m.books[D.B_SQUIRE] = 3
	ok("from rank III, the smithy forges them", Rules.can_forge(m, D.I_GREAT) and Rules.forge_why(m, D.I_GREAT) == "")
	ok("and lists them", shown("smithy", m, "forged").o.any(func(o): return o.get("arg", -1) == D.I_GREAT))
	R.leave_room(m)
	# ---------- Challenge!
	R.phase = "night"; R.undead.clear()
	m.x = 0.0; m.z = 0.0; m.r = 0.0; m.state = "ok"
	var small := R.spawn_undead(0, 2.0, 3.0); small.state = "walk"; small.t = 0
	var big_ := R.spawn_undead(7, -3.0, 2.0); big_.state = "walk"; big_.t = 0
	R.book_power(m, D.B_SQUIRE)
	ok("the strongest nearby is challenged, and turns on you", big_.chal > 0 and big_.chalby == m.id and big_.taunt == m.id and small.chal <= 0)
	var h0 := big_.hp
	R.hit_u(big_, 10.0, {"p": m, "farm": false})
	var by_me := h0 - big_.hp
	h0 = big_.hp
	R.hit_u(big_, 10.0, {"p": f, "farm": false})
	var by_f := h0 - big_.hp
	ok("it takes a fifth more from your blows, not from anybody else's", absf(by_me - by_f * 1.2) < 0.01, [by_me, by_f])
	m.trk = -1; m.wpn = D.I_OATH; m.books[D.B_SQUIRE] = 3
	h0 = big_.hp
	R.hit_u(big_, 10.0, {"p": f, "farm": false})
	ok("with the relic in your hands, a fifth more from everybody", absf((h0 - big_.hp) - by_f * 1.2) < 0.01, h0 - big_.hp)
	R.undead.clear()
	var boss := R.spawn_undead(D.U_STEWARD, 2.0, 2.0); boss.state = "walk"; boss.t = 0
	m.pwCd[D.B_SQUIRE] = 0.0
	R.book_power(m, D.B_SQUIRE)
	ok("a boss cannot be challenged before rank IX", boss.chal <= 0)
	m.books[D.B_SQUIRE] = 9; m.pwCd[D.B_SQUIRE] = 0.0
	R.book_power(m, D.B_SQUIRE)
	ok("at rank IX it can, for half as long", absf(boss.chal - D.POWERS[16].t * 0.5) < 0.01, boss.chal)
	R.undead.clear()
	# ---------- the ranks
	var q0: E.Peasant = null
	for q in R.peasants:
		if q.kind == 0 and q.owner == 0 and q.state != "body": q0 = q; break
	q0.owner = m.id; q0.state = "follow"; q0.x = m.x + 1.0; q0.z = m.z; q0.nv = 100.0; m.posse = 1
	m.books[6] = 0
	m.books[D.B_SQUIRE] = 1
	R.nerve_hit(q0, 20.0)
	var lost1 := 100.0 - q0.nv
	q0.nv = 100.0; m.books[D.B_SQUIRE] = 2
	R.nerve_hit(q0, 20.0)
	ok("rank II: your posse near you keeps its nerve better", 100.0 - q0.nv < lost1 - 1.0, [lost1, 100.0 - q0.nv])
	m.books[D.B_SQUIRE] = 5; m.swind = false; m.hp = 30.0; m.state = "ok"; m.parry = 0.0; m.braced = 0.0
	R.hurt_friend(m, 10.0 / Rules.gear_cut(m), true, null, true)
	ok("rank V: brought below a quarter, a second wind", m.swind and m.hp > Rules.max_hp(m) * 0.25 + 10.0, m.hp)
	var hp1 := m.hp
	R.hurt_friend(m, (hp1 - 15.0) / Rules.gear_cut(m), true, null, true)
	ok("but only once a night", m.hp < Rules.max_hp(m) * 0.25, m.hp)
	m.hp = Rules.max_hp(m)
	m.books[D.B_SQUIRE] = 6
	ok("rank VI: the merchants a tenth cheaper", Rules.price_for(m, 100) == 90 and Rules.price_for(f, 100) == 100)
	m.books[D.B_SQUIRE] = 7; m.wpn = D.I_GREAT; m.atkCd = 0.0; m.sqx = true
	var dummy := R.spawn_undead(7, m.x, m.z + 1.5); dummy.state = "walk"; dummy.t = 0; dummy.hp = 9999.0; dummy.mhp = 9999.0
	R.do_attack(m)
	var first := 9999.0 - dummy.hp
	dummy.hp = 9999.0; m.atkCd = 0.0; m.combo = 0
	R.do_attack(m)
	ok("rank VII: after a parry, the next blow is twice as hard", absf(first - (9999.0 - dummy.hp) * 2.0) < 0.5, [first, 9999.0 - dummy.hp])
	R.undead.clear()
	# ---------- rank X: knighted
	var pm0 := R.posse_max(m)
	m.books[D.B_SQUIRE] = 10
	ok("rank X: a posse one larger", R.posse_max(m) == pm0 + 1)
	f.x = m.x + 2.0; f.z = m.z; f.hp = 100.0; f.state = "ok"
	var fh := f.hp
	R.hurt_friend(f, 10.0, true, null, true)
	var near_k := fh - f.hp
	f.x = m.x + 30.0; fh = f.hp
	R.hurt_friend(f, 10.0, true, null, true)
	ok("and the living near you take a tenth less", absf(near_k - (fh - f.hp) * 0.9) < 0.01, [near_k, fh - f.hp])
	R.phase = "day"
	go_in(m, "library"); to(m, "knight")
	ok("Sir Aldous offers to dub you", shown("knight", m).o.any(func(o): return o.get("a", "") == "sqdub"))
	R.do_act(m, "sqdub", 2)
	ok("Dame Matt", m.kn == 2 and m.dn == "Dame Matt", m.dn)
	ok("the Squire's title", Rules.title_of(m).contains("Squire"), Rules.title_of(m))
	# ---------- kept in the save
	var sv := R.save_data()
	R.load_game(sv, [{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	var m2: E.Player = R.players[0]
	ok("the save keeps the errand, the book and the knighthood", m2.sq == 3 and m2.kn == 2 and m2.books[D.B_SQUIRE] == 10 and m2.dn == "Dame Matt", [m2.sq, m2.kn, m2.dn])
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
