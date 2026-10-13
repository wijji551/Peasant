extends SceneTree
## Version 7.7: ten ranks to every book, honing past the tenth, and four books to a peasant (five with the Index).
## Run:  godot --headless --path godot -s res://tests/ranks_test.gd

var R: Rules
var m: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func at(b: int, r: int) -> void:
	for i in m.books.size(): m.books[i] = 0
	m.books[b] = r


func _init() -> void:
	seed(77)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	R.weather = "clear"
	# ---------- ten ranks, and what it takes to get there
	ok("every book has ten ranks, each written down", D.BOOKS.all(func(b): return b.ranks.size() == 10 and b.ranks.all(func(t): return t.length() > 10)))
	ok("each rank takes longer than the one before", range(1, 9).all(func(r): return Rules.need_xp(4, r + 1) > Rules.need_xp(4, r)))
	m.books[4] = 1; m.xp[4] = 0.0
	R.add_xp(m, 4, 1e7)
	R.add_xp(m, 4, 600.0)
	ok("a book stops at ten, and the rest is spare", m.books[4] == 10 and m.spare > 0, [m.books[4], m.spare])
	# ---------- what the new ranks do (a few of each book)
	at(0, 7); var c7 := Rules.cap(m); at(0, 8)
	ok("Woodcutter VIII: carry 60", c7 == 50 and Rules.cap(m) == 60)
	at(6, 7); var p7 := R.posse_max(m); at(6, 8)
	ok("Leader VIII: a posse four larger than it began", R.posse_max(m) == p7 + 1 and R.posse_max(m) == R.pm + 4)
	at(4, 8)
	ok("Art of Hitting VIII: twenty more health again", Rules.max_hp(m) == D.PLAYER_HP + 40)
	at(1, 10)
	ok("Field, Hook and Pot X: meals heal 80", Rules.meal_hp(m) == 80.0)
	at(7, 8)
	ok("Ledger VIII: a 38-second charge", Rules.charge_len(m) == 38.0)
	at(2, 8)
	ok("Barricades VIII: towers cost half their upkeep", Rules.upkeep(m) == {"wood": 2, "iron": 1} or Rules.upkeep(m).wood == 2, Rules.upkeep(m))
	var wall: E.Struct = R.structs[0]
	wall.built = true; wall.mhp = 260; wall.hp = 100
	at(2, 9)
	R.shore(m, wall)
	ok("Barricades IX: what you repair is a quarter stronger until dawn", wall.mhp == 325 and wall.hp == 325, [wall.mhp, wall.hp])
	at(8, 9)
	ok("Relics IX: searching twice as fast at night", absf(Rules.search_time(m, true) * 2 - Rules.search_time(m, false)) < 0.01)
	at(3, 8)
	m.head = 19
	var cut8 := Rules.gear_cut(m)
	at(3, 0)
	ok("Hammer and Tongs VIII: armour stops a tenth more", cut8 < Rules.gear_cut(m), [cut8, Rules.gear_cut(m)])
	m.head = -1
	at(3, 10)
	ok("Hammer and Tongs X: rune can be forged now (given runes)", Rules.can_forge(m, D.tier_item(1, "rune")) and Rules.forge_why(m, D.tier_item(1, "rune")) == "")
	at(10, 8)
	ok("Holy Book VIII: the lasting blessing costs half", Rules.rune_bless(m) == D.RUNE_BLESS / 2)
	var helped := 0
	for i in 3000:
		if R.help_me(m, true): helped += 1
	ok("and the hasty prayer works two times in three", helped > 1850 and helped < 2150, helped)
	# the hasty prayer, against the Steward's slam
	m.state = "ok"; m.room = ""; m.x = 0; m.z = -30; m.prot = 0
	var x0 := m.x
	var kept := 0
	for i in 60:
		m.x = x0; m.z = -30; m.tp = 0
		R.shove(m, 1, 0, 5)
		if absf(m.x - x0) < 0.01: kept += 1
	ok("a reader at rank VIII is often not thrown at all", kept > 25 and kept < 55, kept)
	at(10, 7)
	m.x = x0
	R.shove(m, 1, 0, 5)
	ok("one below it always is", absf(m.x - x0) > 3, m.x - x0)
	at(7, 10)
	m.charge = 5.0; m.x = x0
	R.shove(m, 1, 0, 5)
	ok("Ledger X: charging, nothing knocks you back", absf(m.x - x0) < 0.01)
	m.charge = 0
	# ---------- honing
	at(4, 10)
	m.spare = 25.0
	while m.pages.size() < D.BOOKS.size(): m.pages.append(0)
	var d0 := Rules.dmg_of(m, D.IT[1], 1.0)
	ok("ten spare points hone a page into a book at rank X", R.hone(m, 4) and m.pages[4] == 1 and absf(m.spare - 15.0) < 0.01)
	ok("and it does two in the hundred more", absf(Rules.dmg_of(m, D.IT[1], 1.0) / d0 - 1.02) < 0.005, [d0, Rules.dmg_of(m, D.IT[1], 1.0)])
	ok("not into a book below rank X", not R.hone(m, 5))
	m.spare = 100
	for i in 6: R.hone(m, 4)
	ok("five pages at most", m.pages[4] == 5)
	m.spare = 5
	m.pages[4] = 0
	ok("and not without ten spare points", not R.hone(m, 4))
	var sv := R.save_data()
	m.pages[4] = 3
	sv = R.save_data()
	var R2 := Rules.new()
	R2.load_game(sv, [{"id": 1, "name": "Matt", "col": 0}])
	ok("the pages are saved", R2.players[0].pages.size() > 4 and int(R2.players[0].pages[4]) == 3)
	# ---------- four books, and a fifth with the Index
	for i in m.books.size(): m.books[i] = 0
	m.xslot = false
	m.books[0] = 4; m.books[1] = 4; m.books[4] = 4
	ok("three books at rank 4 open a fourth", Rules.book_slots(m) == 1)
	m.books[5] = 1
	ok("four is all, without the Index", Rules.book_slots(m) == 0)
	m.xslot = true
	ok("the Index of Further Reading opens a fifth", Rules.book_slots(m) == 1)
	# ---------- the hip flask
	at(7, 9)
	m.flask = true; m.cg = 0
	R.do_act(m, "flask")
	ok("Ledger IX: the hip flask is drunk wherever you are", not m.flask and m.cg > 0, m.cg)
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
