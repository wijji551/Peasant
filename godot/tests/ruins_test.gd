extends SceneTree
## Daytime danger and daytime luck: the Previous Tenant in the outer ruins, the chest that never arrived, and the
## library card.  Run:  godot --headless --path godot -s res://tests/ruins_test.gd

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


func morning() -> void:
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()
	var t := 0.0
	while R.phase == "night" and t < 30:
		R.step(STEP); t += STEP
	R.ev.clear()


func _init() -> void:
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	var L := Map.ruin_layout(R.gseed, R.day)
	var spot := -1
	for i in L.spots.size():
		if L.spots[i].ruin > 0: spot = i
	var sp: Dictionary = L.spots[spot]
	m.x = sp.x + 1; m.z = sp.z
	for i in 300:                                       # day 1: never
		R.spots[spot] = 5; R.do_search(m, spot)
	ok("nothing worse than a shambler on the first day", not R.undead.any(func(u): return u.k == D.U_TENANT))
	R.undead.clear(); R.ev.clear()
	morning()
	L = Map.ruin_layout(R.gseed, R.day)
	for i in L.spots.size():
		if L.spots[i].ruin > 0: spot = i
	sp = L.spots[spot]
	m.x = sp.x + 1; m.z = sp.z; m.hp = 100; m.coin = 0
	var tries := 0
	var woke := false
	while tries < 600 and not R.undead.any(func(u): return u.k == D.U_TENANT):
		R.undead.clear(); R.spots[spot] = 5; R.do_search(m, spot); tries += 1
		if R.ev.any(func(e): return e[0] == "tenant"): woke = true
	var t: E.Undead = null
	for u in R.undead:
		if u.k == D.U_TENANT: t = u
	ok("from the second day, searching the outer ruins can wake the Previous Tenant", t != null and woke, tries)
	ok("he is a good deal tougher than a shambler", t != null and t.hp >= 5 * D.UN[0].hp, t.hp if t else 0)
	for i in 300:
		R.spots[spot] = 5; R.do_search(m, spot)
	ok("but only one a day", R.undead.filter(func(u): return u.k == D.U_TENANT).size() == 1)
	R.undead = [t]; R.ev.clear()
	m.state = "hide"                                     # nobody about: he stays by his ruin
	t.tauntT = 0
	fast(12.0)
	ok("left alone, he keeps to his ruin by day", D.d2(t.x, t.z, sp.x, sp.z) < 16 and R.keepHp == D.KEEP_HP, [t.x, t.z, sp.x, sp.z])
	m.state = "ok"; m.x = t.x + 9; m.z = t.z
	var d0 := D.d2(t.x, t.z, m.x, m.z)
	fast(2.0)
	ok("he sees a peasant from further off than most, and comes", D.d2(t.x, t.z, m.x, m.z) < d0 - 4, [d0, D.d2(t.x, t.z, m.x, m.z)])
	R.hit_u(t, 99999, {"p": m})
	ok("putting him down pays: his back rent", t.dead and m.coin >= 36, m.coin)
	R.undead.clear()
	# ---------- the chest that never arrived
	var cd := Rules.chest_day(R.gseed, 1, 30)
	ok("a chest goes astray once a week (week 1: day 2 to 5)", cd >= 2 and cd <= 5 and Rules.chest_day(R.gseed, 3, 30) >= 16 and Rules.chest_day(R.gseed, 3, 30) <= 19, cd)
	R.chest = {}
	while R.day < cd: morning()
	if R.chest.is_empty():
		R.day = cd; R.new_chest()
	var C: Dictionary = R.chest
	ok("it lies outside the village, on the map", not C.is_empty() and not D.inside_village(C.x, C.z) and C.x > D.X0 and C.x < D.X1 and C.z < D.Z1 and not C.seen and not C.open, C)
	ok("the dawn notice says who sent it, and roughly where", R.dawn.lines.any(func(l): return "chest" in l) or R.day != cd, R.dawn.lines)
	m.x = C.x + 30; m.z = C.z
	fast(0.2)
	ok("not on the map until someone comes near", not R.chest.seen)
	m.x = C.x + 1.6; m.z = C.z
	fast(0.2)
	ok("then it is", R.chest.seen)
	var it = R.find_interact(m)
	ok("hold to open it", it != null and it.get("type") == "chest", it)
	m.coin = 0; m.inv = []
	var relics0 := R.relics.size()
	m.eHold = true
	fast(2.5)
	m.eHold = false
	ok("a good sum inside, and it is the finder's", R.chest.open and m.coin >= 96, m.coin)
	ok("and sometimes a relic or a library card", m.inv.size() <= 1 and (m.inv.is_empty() or m.inv[0] == D.I_CARD or D.IT[m.inv[0]].tier == "relic") or R.relics.size() > relics0, m.inv)
	var sv := R.save_data()
	var R2 := Rules.new()
	R2.load_game(JSON.parse_string(JSON.stringify(sv)), [{"id": 1, "name": "Matt", "col": 0}])
	ok("the chest is saved", not R2.chest.is_empty() and R2.chest.open and is_equal_approx(R2.chest.x, C.x))
	# ---------- the library card
	m.inv = [D.I_CARD]
	m.books[0] = 4; m.xp[0] = float(Rules.need_xp(0, 3)); m.books[4] = 2
	var lib := D.station("library")
	m.x = 60; m.z = 30
	R.do_act(m, "card", 0)
	ok("a library card is no use away from the library", m.books[0] == 4 and m.inv == [D.I_CARD])
	R.do_act(m, "eq", 0)
	ok("and it cannot be worn", m.inv == [D.I_CARD])
	m.x = lib.x; m.z = lib.z
	var d := Notices.data(R, "library", m, "")
	ok("the library offers to take it", d.o.any(func(o): return o.get("page", "") == "card"))
	d = Notices.data(R, "library", m, "card")
	ok("and lists the books to give up", d.o.filter(func(o): return o.get("a", "") == "card").size() == 2)
	R.do_act(m, "card", 0)
	ok("handing it in gives up the book", m.books[0] == 0 and m.xp[0] == 0.0 and m.inv.is_empty() and m.card_rank == 3, [m.books, m.card_rank])
	R.do_act(m, "book", 6)
	ok("and the next book starts a rank behind the old one", m.books[6] == 3 and m.card_rank == 0 and m.xp[6] >= Rules.need_xp(6, 2), [m.books[6], m.xp[6]])
	# a card dropped for a friend
	m.inv = [D.I_CARD]
	R.do_act(m, "dropi", 0)
	ok("it can be dropped for somebody else", R.drops.any(func(dr): return dr.it == D.I_CARD) and m.inv.is_empty())   # (other finds may be lying about)
	var fails := 0
	for l in lines:
		if l.begins_with("FAIL"): fails += 1
		print(l)
	print("%d passed, %d failed" % [lines.size() - fails, fails])
	quit()
