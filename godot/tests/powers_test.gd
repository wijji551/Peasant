extends SceneTree
## Version 7.8: a power for every book, the third power of the apprentice priest (Consecrate), and what each does.
## Run:  godot --headless --path godot -s res://tests/powers_test.gd

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


func only(b: int, r: int = 1) -> void:
	for i in m.books.size(): m.books[i] = 0
	m.books[b] = r
	m.pwCd = []
	m.state = "ok"; m.frozen = 0


func one(k: int, x: float, z: float) -> E.Undead:
	var u := R.spawn_undead(k, x, z)
	u.state = "walk"; u.stun = 99; u.hp = 900; u.mhp = 900
	return u


func _init() -> void:
	seed(78)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	m = R.players[0]; f = R.players[1]
	R.weather = "clear"
	ok("every book but the Holy Book has a power of its own (that one has its calling's three)", range(10).all(func(b): return not D.POWERS[b].is_empty() and D.POWERS[b].cd > 0) and D.CLASSES[0].powers.size() == 3)
	only(0, 0)
	ok("no power without the book", not R.can_book_power(m, 0))
	only(0, 1)
	ok("from its first rank", R.can_book_power(m, 0))
	# ---------- Many Hands
	var g0 := Rules.gather_time(m, "tree")
	R.book_power(m, 0)
	ok("Many Hands: gathering twice as fast", absf(Rules.gather_time(m, "tree") * 2 - g0) < 0.01 and m.many > 19)
	R.book_power(m, 0)
	ok("and then a wait before it can be used again", m.pwCd[0] > 80)
	# ---------- Pot Luck
	only(1)
	m.x = 30; m.z = 30; f.x = 31; f.z = 30; f.state = "ok"; f.room = ""
	m.hp = 10; f.hp = 10; m.food = 1
	R.book_power(m, 1)
	ok("Pot Luck: one food heals everyone near", m.food == 0 and m.hp > 25 and f.hp > 25, [m.hp, f.hp])
	only(1)
	m.food = 0; m.hp = 10
	R.book_power(m, 1)
	ok("but not without the food", m.hp == 10 and float(m.pwCd[1] if m.pwCd.size() > 1 else 0.0) == 0.0)
	# ---------- Shore It Up
	only(2)
	var w: E.Struct = R.structs[0]
	w.built = true; w.mhp = 300; w.hp = 30
	m.x = w.x; m.z = w.z + 3
	R.book_power(m, 2)
	ok("Shore It Up: a defence near you mended by a third", absf(w.hp - 130) < 1, w.hp)
	# ---------- The Whetstone
	only(3)
	m.x = 30; m.z = 30
	var d0 := Rules.dmg_of(f, D.IT[1])
	R.book_power(m, 3)
	ok("The Whetstone: everyone near hits a fifth harder", absf(Rules.dmg_of(f, D.IT[1]) / d0 - 1.2) < 0.01 and m.whet > 0)
	# ---------- Red Mist
	only(4)
	R.book_power(m, 4)
	var x0 := m.x
	R.shove(m, 1, 0, 5)
	ok("Red Mist: nothing knocks you back", absf(m.x - x0) < 0.01 and m.mist > 7)
	# ---------- night, for the rest
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()
	m.x = 0; m.z = -40; m.r = PI; m.mist = 0; m.whet = 0
	# The Marked Man
	only(5)
	var near_ := one(0, 0, -44)
	var far_ := one(0, 3, -50)
	m.r = PI
	R.book_power(m, 5)
	ok("The Marked Man: the nearest ahead is marked", near_.mark > 10 and R.marked == near_)
	var h0 := near_.hp
	R.hit_u(near_, 10, {"x": 0, "z": 0, "farm": false})
	ok("and takes a quarter more", absf((h0 - near_.hp) - 12.5) < 0.01, h0 - near_.hp)
	m.wpn = 13; m.books[5] = 1
	near_.x = -6; near_.z = -42
	m.r = PI; m.atkCd = 0
	var hit := R.shoot(m, D.IT[13], 1.0)
	ok("and the shots go to it first, wherever it is in reach", hit == near_, hit)
	m.wpn = 0
	R.undead.clear(); R.marked = null
	# War Cry
	only(6)
	var q: E.Peasant = null
	for o in R.peasants:
		if o.kind == 0 and o.state != "body" and q == null: q = o
	q.owner = m.id; q.state = "follow"; q.nv = 40; q.x = m.x; q.z = m.z + 1
	R.book_power(m, 6)
	ok("War Cry: the posse's nerve is whole", q.nv == 100 and m.cry > 0)
	R.nerve_hit(q, 50)
	ok("and stays so while it lasts", q.nv == 100)
	# A Round on Me
	only(7)
	m.cg = 0; f.x = m.x + 1; f.z = m.z; f.cg = 80; f.charge = 0
	R.book_power(m, 7)
	ok("A Round on Me: courage for everyone near, and a charge for anyone it fills up", m.cg >= 29 and f.charge > 0, [m.cg, f.cg, f.charge])
	# Smelling Salts
	only(9)
	f.state = "down"; f.hp = 0; f.downT = 10
	R.book_power(m, 9)
	ok("Smelling Salts: whoever is down near you gets up", f.state == "ok" and f.hp >= 30)
	# Hone
	only(8)
	R.day = 3
	R.roll_day(false)
	var lay := Map.ruin_layout(R.gseed, R.day)
	R.relics = []
	R.book_power(m, 8)
	ok("Hone: it picks a heap of rubble that still has searching in it", m.hone_i >= 0 and R.spots[m.hone_i] > 0 and m.hone_t > 50, [m.hone_i, m.hone_t])
	var i := m.hone_i
	var inv0 := R.relics.size()
	R.do_search(m, i)
	ok("and the relic is in it", R.relics.size() == inv0 + 1 and m.hone_i == -1)
	# Consecrate
	only(10, 10)
	m.holy = 2
	m.x = 0; m.z = -30; m.p3Cd = 0
	R.do_power(m, 2)
	ok("Consecrate, at rank X of the Holy Book: ground round you", R.holy_ground.size() == 1)
	var u := R.spawn_undead(0, 0, -36)
	u.state = "walk"; u.hp = 900; u.mhp = 900
	var closest := 99.0
	for k in 150:
		R.step(STEP); R.ev.clear()
		closest = minf(closest, sqrt(D.d2(u.x, u.z, 0, -30)))
	ok("that the dead will not cross", closest > 3.4, closest)
	fast(4.0)
	ok("for eight seconds", R.holy_ground.is_empty())
	# all of it travels to a joined game
	ok("the powers' timers are sent to joined games", ["pwCd", "p3Cd", "many", "whet", "mist", "cry", "hone_i", "hone_t"].all(func(x): return Net.PF.has(x)))
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
