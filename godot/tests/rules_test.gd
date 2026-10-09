extends SceneTree
## The rules test, solo: the same checks as the web version's test/rules.js.
## The bot is moved straight to places (this tests the rules, not walking).
## Run:  godot --headless --path godot -s res://tests/rules_test.gd

var R: Rules
var m: E.Player
var keys := {}
var clock := 0.0
var lines := []
var saved = null
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))

func tick() -> void:
	clock += STEP
	m.eHold = R.live() and keys.get("interact", false) and (m.state == "ok" or m.state == "hide")
	if R.live() and m.state == "ok":
		var mx := (1.0 if keys.get("right") else 0.0) - (1.0 if keys.get("left") else 0.0)
		var mz := (1.0 if keys.get("down") else 0.0) - (1.0 if keys.get("up") else 0.0)
		var e := R.move_player(m, mx, mz, STEP, clock)
		if e != "": edge = e
	R.step(STEP)
	R.ev.clear()

var edge := ""

func fast(sec: float, f: Callable = Callable()) -> float:
	var t := 0.0
	while t < sec:
		if f.is_valid() and f.call() == false:
			return t
		tick()
		t += STEP
	return t

func at(x: float, z: float) -> void:
	m.x = x; m.z = z

func hold(sec: float, stop: Callable = Callable()) -> void:
	keys.interact = true
	fast(sec, func(): return not (stop.is_valid() and stop.call()))
	keys.interact = false
	fast(0.1)

func clear_u() -> void:
	R.undead.clear()

func mob(n: int, k: int = 0, away: float = 1.6) -> Array:
	var a := []
	for i in n:
		var u := R.spawn_undead(k, m.x + sin(m.r) * away + (i - (n - 1) / 2.0) * 0.7, m.z + cos(m.r) * away)
		u.state = "walk"; u.t = 0
		a.append(u)
	return a

func in_keep(e) -> bool:
	return absf(e.x) < D.KEEP_H + 0.3 and absf(e.z) < D.KEEP_H + 0.3

func dist(a, b) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _init() -> void:
	R = Rules.new()
	R.save_hook = func(d): saved = d
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	run()
	for l in lines: print(l)
	var fails := lines.filter(func(l): return not l.begins_with("PASS")).size()
	print("\n%d passed, %d failed" % [lines.size() - fails, fails])
	quit(1 if fails else 0)


func run() -> void:
	var X := R
	# ---------- the morning
	ok("day 1, saved, sites at their first places", R.day == 1 and R.phase == "day" and saved != null and R.sites == [0, 0, 0])
	ok("keep is smaller", D.KEEP_H < 4)
	ok("nobody starts inside the keep", not R.peasants.any(in_keep) and not in_keep(m))
	var bad := 0
	for s in 8:
		for j in 8:
			if in_keep(Rules.home_spot(s, j, 7)): bad += 1
	ok("no cottage lines its people up inside the keep", bad == 0, bad)
	ok("pitchfork, empty pack, ten books", m.wpn == 0 and m.inv.is_empty() and m.books.size() == 10 and D.BOOKS.size() == 10 and D.BOOKS.all(func(b): return b.ranks.size() == 7))

	# ---------- books: ten of them, seven ranks
	at(13.4, 20.4)
	X.do_act(m, "book", 4); ok("took The Art of Hitting Things", m.books[4] == 1 and Rules.book_slots(m) == 0)
	X.add_xp(m, 4, Rules.need_xp(4, 1)); ok("rank 2 opens a second book", m.books[4] == 2 and Rules.book_slots(m) == 1)
	X.do_act(m, "book", 6); X.add_xp(m, 6, Rules.need_xp(6, 2)); ok("leadership rank 3", m.books[6] == 3 and Rules.book_slots(m) == 0)
	X.add_xp(m, 4, Rules.need_xp(4, 2)); ok("two books at rank 3 open the third", m.books[4] == 3 and Rules.book_slots(m) == 1)
	X.do_act(m, "book", 9); ok("three books, no fourth", m.books[9] == 1 and Rules.book_slots(m) == 0)
	X.do_act(m, "book", 0); ok("a fourth is refused", m.books[0] == 0)
	X.add_xp(m, 4, 99999); ok("a book stops at rank 7", m.books[4] == 7)
	ok("posse grows with leadership", X.posse_max(m) == 6, X.posse_max(m))

	# ---------- gathering at today's sites
	at(R.QUARRY.x - R.QUARRY.hw - 1, R.QUARRY.z); hold(8, func(): return m.stone >= 2); ok("stone at the outcrop", m.stone >= 2, m.stone)
	at(R.MINE.x - R.MINE.dir * 0.8, R.MINE.z); hold(9, func(): return m.iron >= 2); ok("iron at the mine", m.iron >= 2, m.iron)
	at(R.JETTY.x, R.JETTY.z - 0.6)
	var fi = X.find_interact(m); ok("fishing at the jetty", fi != null and fi.get("kind") == "fish", fi.type if fi else null)
	at(60, -8); keys.up = true; fast(0.2); keys.up = false; ok("walking out of the outcrop pushes you clear", not Rules.in_box(m.x, m.z, 0.3, R.QUARRY), "%.1f,%.1f" % [m.x, m.z])

	# ---------- searching the ruins
	var RL := Map.ruin_layout(R.gseed, R.day)
	ok("eight heaps of rubble to search", RL.spots.size() == 8 and R.spots.all(func(n): return n == 2))
	at(RL.spots[0].x + 0.8, RL.spots[0].z)
	var si = X.find_interact(m); ok("prompt to search the old ruins", si != null and si.type == "search" and si.ok, si.label if si else null)
	hold(5, func(): return R.spots[0] < 2); ok("a search uses the heap up", R.spots[0] == 1, R.spots[0])
	hold(5, func(): return R.spots[0] < 1)
	var si2 = X.find_interact(m); ok("heap is empty after two searches", R.spots[0] == 0 and si2 != null and not si2.ok, si2.label if si2 else null)
	var coin0 := m.coin
	var lurk := 0
	for i in 200:
		R.spots[3] = 2
		var n := R.undead.size()
		X.do_search(m, 3)
		if R.undead.size() > n: lurk += 1
		clear_u()
		m.inv = m.inv.slice(0, 3)
	ok("searching finds coins and things", m.coin > coin0 and (m.inv.size() > 0 or m.wpn > 0), "coin %d, pack %s" % [m.coin, m.inv])
	ok("the outer ruins are not empty (lurkers by day about 3 times in 10)", lurk > 30 and lurk < 95, lurk)
	ok("armour found goes straight on", m.head >= 0 or m.body >= 0 or m.off >= 0, [m.head, m.body, m.off])
	ok("relics are rare by day", R.relics.size() <= 14, R.relics.size())
	var spots1: Array = RL.spots.duplicate(true)
	var l2 := Map.ruin_layout(R.gseed, 2)
	ok("the outer ruins are different tomorrow, the old ruins the same", l2.spots[0].x == spots1[0].x and (l2.spots[3].x != spots1[3].x or l2.spots[3].z != spots1[3].z))
	Map.ruin_layout(R.gseed, R.day)

	# ---------- pack, arms rack, forge
	m.inv = [6, 10]; m.wpn = 0; m.head = -1; m.body = -1; m.off = -1; m.trk = -1; R.relics.clear()
	X.do_act(m, "eq", 0); ok("club taken in hand from the pack", m.wpn == 6 and m.inv == [10], m.inv)
	at(12.9, 10.6); X.do_act(m, "puti", 0); ok("dagger put on the arms rack", R.items == [10] and m.inv.is_empty())
	X.do_act(m, "pute", "wpn"); ok("club put on the rack from the hand", R.items == [10, 6] and m.wpn == 0)
	X.do_act(m, "takei", 1); ok("club taken back, straight into the hand", m.wpn == 6 and R.items == [10])
	m.iron = 20; m.wood = 20; at(12.4, -4.7); X.do_act(m, "forge", 1); ok("forged a short sword; the club went into the pack", m.wpn == 1 and m.inv == [6], m.inv)
	X.do_act(m, "forge", 13); ok("forged a bow but cannot use it yet", m.wpn == 1 and m.inv.has(13))
	X.do_act(m, "forge", 19); ok("iron cap goes on", m.head == 19)
	X.do_act(m, "forge", 4); ok("heavy arms still need Hammer and Tongs rank 2", m.wpn == 1)

	# ---------- every weapon's trick
	at(40, 0); m.r = 0
	var res := []
	for id in 18:
		clear_u(); m.wpn = id; m.abCd = 0; m.atkCd = 0; m.r = 0; m.parry = 0
		var ms := mob(3, 0, 6.0 if D.IT[id].rng else 1.5)
		var hp0 := ms.map(func(u): return u.hp)
		X.do_ability(m)
		var hurt := 0
		var st := 0
		for i in 3:
			if ms[i].hp < hp0[i] or ms[i].dead: hurt += 1
			if ms[i].stun > 0 or ms[i].pin > 0 or ms[i].vuln > 0 or ms[i].tauntT > 0: st += 1
		res.append("%s:%d/%d%s" % [D.IT[id].ab, hurt, st, "P" if m.parry > 0 else ""])
		if not (hurt > 0 or st > 0 or m.parry > 0) or not (m.abCd > 0): ok("trick of " + D.IT[id].n, false, res[-1])
	ok("all eighteen weapons have a working trick", true, " ".join(res))
	clear_u(); m.wpn = 1; m.abCd = 0; X.do_ability(m)
	var pu: E.Undead = mob(1, 0, 1)[0]
	var hpP := m.hp
	X.hurt_friend(m, 10, true, pu, false); ok("parry turns the blow and staggers the attacker", m.hp == hpP and pu.stun > 0 and pu.hp < D.UN[0].hp)
	clear_u(); m.wpn = 7; m.abCd = 0
	var bu: E.Undead = mob(1, 0, 1.4)[0]
	bu.hp = 10; X.do_ability(m); ok("the spade buries a wounded shambler", bu.dead)
	clear_u(); m.wpn = 12; m.atkCd = 0; m.r = 0
	var far: E.Undead = mob(1, 0, 8)[0]
	far.hp = 9999
	var hits := 0
	for i in 12:
		m.atkCd = 0
		var h := far.hp
		X.do_attack(m)
		if far.hp < h: hits += 1
	ok("a sling hits from a distance, mostly", hits >= 7, hits)
	clear_u(); m.wpn = 1; m.atkCd = 0
	var farS: E.Undead = mob(1, 0, 8)[0]
	X.do_attack(m); ok("a sword does not", farS.hp == D.UN[0].hp)

	# ---------- the priest and holy studies
	clear_u(); at(13.6, -10.6); m.coin = 30; m.wpn = 1; m.bless = 0
	X.do_act(m, "bless", "w"); ok("the priest blesses a sword for two shillings", (m.bless & 1) == 1 and m.coin == 6, m.coin)
	var hu: E.Undead = mob(1, 0, 1.4)[0]
	m.atkCd = 0; m.r = 0; m.combo = 0; X.do_attack(m)
	var holy_dmg: float = D.UN[0].hp - hu.hp
	clear_u(); m.bless = 0
	var pu2: E.Undead = mob(1, 0, 1.4)[0]
	m.atkCd = 0; m.combo = 0; X.do_attack(m)
	var plain: float = D.UN[0].hp - pu2.hp
	clear_u()
	ok("a blessed blow does half as much again", absf(holy_dmg / plain - 1.5) < 0.02, "%.1f vs %.1f" % [holy_dmg, plain])
	X.do_act(m, "bless", "w"); ok("no blessing without the fee", m.bless == 0 and m.coin == 6)
	at(13.6, -10.6); X.do_act(m, "study"); fast(46); ok("one class of holy studies", m.holy == 1 and not m.study, "%d %.1f" % [m.holy, m.holyT])
	at(40, 0); X.do_act(m, "bless", "w"); ok("after a class, bless your own weapon anywhere for nothing", (m.bless & 1) == 1 and m.coin == 6)
	at(13.6, -10.6); X.do_act(m, "study"); fast(20); at(40, 0); fast(1); ok("walking out stops the class but keeps the progress", not m.study and m.holyT > 15 and m.holy == 1, m.holyT)
	at(13.6, -10.6); X.do_act(m, "study"); fast(30); ok("second class finished", m.holy == 2)

	# ---------- barricades: blessed bodies, and the evening rot
	m.wood = 30; at(40, 5); m.r = 0
	var placed := X.try_place(m, "barricade", 40, 8, 0)
	var bar: E.Struct = R.structs.filter(func(s): return s.k == "barricade")[0] if placed else null
	ok("barricade placed", placed and bar and bar.mhp == 90)
	m.bodies = 1; m.iron = 0; X.do_act(m, "bless", "b"); ok("blessed a body", m.bbod == 1)
	at(40, 9.2)
	var bi = X.find_interact(m); ok("prompt to build the blessed body in", bi != null and bi.type == "blessre", bi.type if bi else null)
	hold(2, func(): return bar.bl)
	ok("blessed body strengthens the barricade by half", bar.bl and bar.mhp == 135 and m.bodies == 0 and m.bbod == 0, bar.mhp)
	X.try_place(m, "barricade", 46, 8, 0)
	var bar2: E.Struct = R.structs.filter(func(s): return s.k == "barricade")[1]
	X.dusk_falls(); ok("a new barricade does not rot on its first evening", bar2.mhp == 90 and R.phase == "dusk")
	R.phase = "day"; R.timeLeft = 300; bar2.age = 1; bar.age = 1; bar.re = true; X.dusk_falls()
	ok("an old barricade loses half each evening; a braced one does not", bar2.mhp == 45 and bar2.hp == 45 and bar.mhp == 135, "%d %d" % [bar2.mhp, bar.mhp])
	R.phase = "day"; X.dusk_falls(); R.phase = "day"; X.dusk_falls(); ok("and falls apart in the end", not R.structs.has(bar2), bar2.mhp)
	R.phase = "day"; R.timeLeft = 300

	# ---------- posse: orders, nerve, toilet break, the bucket
	at(-7.5, 5.9)
	for q in R.peasants.slice(0, 4):
		q.owner = m.id; q.state = "follow"
	fast(0.5)
	ok("posse of four", m.posse == 4, m.posse)
	X.do_order(m); ok("orders: hold", m.order == 1)
	var q0: E.Peasant = R.peasants[0]
	var px := q0.x
	var pz := q0.z
	at(-7.5, -16); fast(4)
	ok("a holding posse stays where it was put", Vector2(q0.x - px, q0.z - pz).length() < 1.5, "%.1f" % Vector2(q0.x - px, q0.z - pz).length())
	X.do_order(m); X.do_order(m); ok("orders cycle back to follow", m.order == 0)
	fast(6)
	ok("a following posse comes along", dist(q0, m) < 7, "%.1f" % dist(q0, m))
	m.r = PI
	var us := mob(4, 0, 4)
	m.tbCd = 0; X.do_toilet(m); ok("emergency toilet break: the dead run", us.all(func(u): return u.fear > 0) and m.tbCd > 50, m.tbCd)
	var y0: float = us[0].z
	fast(2); ok("they run away from the posse", us[0].z < y0 - 1, "%.1f" % (us[0].z - y0))
	clear_u()
	m.trk = 28; m.bless |= 2; us = mob(3, 0, 5)
	var uh: float = us[0].hp
	X.do_use(m); ok("a blessed slop bucket scares and burns, and is used up", us.all(func(u): return u.fear > 0) and us[0].hp < uh and m.trk == -1 and not (m.bless & 2))
	clear_u()
	m.trk = 26; m.useCd = 0; us = mob(3, 0, 4); X.do_use(m); ok("the Chapel Handbell stuns", us.all(func(u): return u.stun > 2) and m.useCd > 30)
	clear_u()
	for q in R.peasants.slice(0, 4): q.nv = 100
	m.books[6] = 0; m.books[9] = 1
	var vic: E.Peasant = R.peasants[3]
	X.hurt_friend(vic, 999, false, null, false); ok("a death shakes the others", vic.state == "body" and R.peasants.slice(0, 3).all(func(q): return q.nv < 100))
	R.peasants[0].nv = 5; X.hurt_friend(R.peasants[1], 999, false, null, false); ok("a peasant with no nerve left runs for the keep", R.peasants[0].state == "hide", R.peasants[0].state)
	m.head = 20
	var q2: E.Peasant = R.peasants[2]
	q2.nv = 5; X.hurt_friend(q2, 5, false, null, false); ok("the Helm of the Unbothered keeps the posse steady", q2.state != "hide" and q2.nv == 5)
	m.head = -1; m.books[6] = 3; m.books[9] = 3
	q2.hp = 75; X.hurt_friend(q2, 999, false, null, false); ok("Granny’s Remedies rank 3: a posse member survives one fatal blow", q2.state != "body" and q2.saved and q2.hp > 0)
	X.hurt_friend(q2, 999, false, null, false); ok("but not two", q2.state == "body")
	m.books[9] = 1

	# ---------- the Thorny Rose
	R.phase = "day"; R.timeLeft = 300; clear_u(); at(-13.1, -4.7); m.food = 12
	X.do_act(m, "ale"); X.do_act(m, "ale"); ok("food becomes ale", R.ale == 10 and m.food == 2)
	X.do_act(m, "innin"); ok("the Rose is shut by day", m.state == "ok")
	X.dusk_falls(); fast(21); ok("night has fallen", R.phase == "night")
	R.night.q = [{"k": 0, "t": 1e9}]; clear_u()
	R.peasants[4].owner = m.id; R.peasants[4].state = "follow"; at(-13.1, -4.7)
	X.do_act(m, "innin"); ok("inside, door barred, posse with you", m.state == "inn" and R.peasants.any(func(q): return q.state == "inn"))
	var du0: E.Undead = mob(1, 0, 1)[0]
	var h0 := m.hp
	X.hurt_friend(m, 10, true, du0, false); clear_u(); ok("nothing can reach a drinker", m.hp == h0)
	X.do_act(m, "drink"); fast(1); X.do_act(m, "drink"); fast(2.5); ok("one tankard at a time", m.cg == 25 and R.ale == 9, "%d %d" % [m.cg, R.ale])
	X.do_act(m, "drink"); fast(3.2); X.do_act(m, "drink"); fast(3.2); ok("three tankards: 75%", m.cg == 75 and m.state == "inn", m.cg)
	X.do_act(m, "drink"); fast(3.2); ok("the fourth sends you out charging", m.state == "ok" and m.charge > 15 and m.cg == 0 and R.peasants.any(func(q): return q.state == "follow"), "%s %.1f" % [m.state, m.charge])
	m.r = 0
	var cu: E.Undead = mob(1, 0, 1.4)[0]
	m.wpn = 1; m.bless = 0; m.atkCd = 0; m.combo = 0; X.do_attack(m); ok("a charging blow is far stronger", (D.UN[0].hp - cu.hp) > plain * 1.5, "%.1f" % (D.UN[0].hp - cu.hp))
	clear_u()
	fast(21); ok("then the hangover", m.charge == 0 and m.hang > 5, m.hang)
	fast(11); ok("which passes", m.hang == 0)
	at(-13.1, -4.7); X.do_act(m, "innin"); ok("back inside", m.state == "inn")
	var du := X.spawn_undead(0, -8.0, -4.7)
	du.state = "walk"; fast(40, func(): return not (R.innHp <= 0))
	ok("the dead break the door down and everyone is thrown out", R.innHp == 0 and m.state == "ok", "%d %s" % [R.innHp, m.state])
	clear_u()
	X.do_act(m, "innin"); ok("no going back in tonight", m.state == "ok")

	# ---------- dawn: trees, sites, relics dropped
	var tr0: E.Trunk = R.trees.filter(func(t): return t.alive and t.x < -34)[0]
	at(tr0.x + 1.4, tr0.z); m.wood = 0; R.phase = "night"
	var felled: E.Trunk = X.find_interact(m).target
	hold(30, func(): return not felled.alive); ok("a felled tree leaves a stump", felled.st == 1 and not felled.alive)
	var tx0 := felled.x
	var tz0 := felled.z
	m.inv = [15, 6]; m.wpn = 17; m.trk = -1; R.relics = [15, 17]; m.state = "dead"
	var sites0: Array = R.sites.duplicate()
	var key0 := str(Map.ruin_layout(R.gseed, R.day).spots.slice(2))
	R.night.q = []; clear_u(); fast(1)
	ok("dawn of day 2", R.day == 2 and R.phase == "day", "%d %s" % [R.day, R.phase])
	ok("a dead player loses gear but relics lie where they fell", m.wpn == 0 and m.inv.is_empty() and R.drops.size() == 2 and R.drops.all(func(x): return D.IT[x.it].tier == "relic"))
	ok("the stump has rotted and a sapling has come up beside it", felled.st == 2 and not felled.alive and (felled.x != tx0 or felled.z != tz0 or (not felled.dx and not felled.dz)), "%d moved %.1f" % [felled.st, Vector2(felled.x - tx0, felled.z - tz0).length()])
	ok("stone, iron and fishing have all moved", R.sites != sites0 and range(3).all(func(i): return R.sites[i] != sites0[i]), "%s -> %s" % [sites0, R.sites])
	ok("today’s sites are where the game says", R.QUARRY.x == D.SITES[0][R.sites[0]].x and R.JETTY.x == D.SITES[2][R.sites[2]].x)
	ok("the outer ruins fell down differently, and the heaps are full again", str(Map.ruin_layout(R.gseed, R.day).spots.slice(2)) != key0 and R.spots.all(func(n): return n == 2))
	ok("dawn notice says where things are", " ".join(R.dawn.lines).contains("stone is"), R.dawn.lines[-1])
	ok("the posse lines up outside the door, not in the keep", not R.peasants.any(func(q): return q.state != "body" and in_keep(q)))
	at(R.drops[0].x, R.drops[0].z + 0.5); hold(1, func(): return R.drops.size() < 2); ok("a relic can be picked up again", R.drops.size() == 1 and (m.wpn >= 15 or m.inv.size() == 1))
	var sv = saved
	ok("the save holds the new things", sv != null and sv.v == 3 and sv.sites == R.sites and sv.trees.size() >= 1 and sv.drops.size() == 2 and sv.players[0].books.size() == 10)
	# a save survives the trip to text and back
	var back = JSON.parse_string(JSON.stringify(sv))
	var R2 := Rules.new()
	R2.load_game(back, [{"id": 1, "name": "Matt", "col": 0}])
	ok("a saved game loads", R2.day == R.day and R2.players[0].books == sv.players[0].books and R2.structs.size() == sv.structs.size() and R2.drops.size() == 2 and R2.peasants.size() == sv.peasants.size())
	# next dawns: the sapling matures 1 to 2 days after it came up
	var skip := func():
		X.dusk_falls(); fast(21); R.night.q = []; clear_u(); fast(1)
	skip.call()
	var d3 := felled.st
	skip.call()
	ok("the sapling is a tree again by day 3 or 4", felled.st == 0 and felled.alive and R.day == 4, "day 3: %d, day 4: %d" % [d3, felled.st])

	# ---------- the horde
	var tot := func(dd: int, n: int) -> int:
		var c: Array = Rules.night_plan(dd, n).c
		var t := 0
		for v in c: t += v
		return t
	ok("hordes are bigger, most of all in co-op", tot.call(1, 1) >= 28 and tot.call(1, 4) >= 100 and tot.call(7, 4) >= 320, [tot.call(1, 1), tot.call(7, 1), tot.call(1, 4), tot.call(7, 4), tot.call(7, 8)])
	clear_u()
	var xs := []
	for i in 200: xs.append(X.spawn_undead(0).x)
	clear_u()
	var mid := xs.filter(func(x): return absf(x) < 10).size()
	ok("the dead rise across the whole graveyard", xs.min() < -26 and xs.max() > 26 and mid < 90, "%d..%d, middle third %d" % [xs.min(), xs.max(), mid])
	var nq := X.night_queue(Rules.night_plan(5, 4))
	var gaps := []
	for i in range(1, nq.size()): gaps.append(nq[i].t - nq[i - 1].t)
	var third := floori(gaps.size() / 3.0)
	var avg := func(a: Array) -> float:
		var s := 0.0
		for v in a: s += v
		return s / a.size()
	ok("no waves: the dead rise in one unbroken stream", nq.size() == tot.call(5, 4) and gaps.max() < 3 and nq[0].t < 6, "longest gap %.2fs over %ds" % [gaps.max(), nq[-1].t])
	ok("and faster as the night goes on", avg.call(gaps.slice(0, third)) > avg.call(gaps.slice(-third)) * 1.5)
	# one archer against a stone wall must not keep a dead village waiting half the night
	clear_u()
	for s in R.structs:
		if s.slot >= 0:
			s.built = true; s.re = true; s.mhp = 780; s.hp = 780
	R.keepHp = 1000; X.dusk_falls(); fast(21); R.night.q = []; m.state = "dead"
	for q in R.peasants:
		if q.state != "body": q.state = "gone"
	var ar := X.spawn_undead(2, 6.0, -30.0)
	ar.state = "walk"
	var took := fast(900, func(): return not (R.phase != "night"))
	ok("with everyone dead, the night is settled quickly", R.phase == "lost" and took < 200, "%s after %ds" % [R.phase, took])
	R.phase = "day"; R.timeLeft = 300; R.keepHp = 1000; m.state = "ok"; clear_u()
	# a lurker from the west ruins must find its way to the keep
	at(80, 40); m.state = "hide"
	var lu := X.spawn_undead(0, -58.0, 46.0)
	lu.state = "walk"
	var reached := {"v": false}
	fast(170, func():
		if Vector2(lu.x, lu.z).length() < D.KEEP_H + 2.5:
			reached.v = true
			return false
		return null)
	ok("something from the west ruins reaches the keep through the west gateway", reached.v, "%.1f,%.1f" % [lu.x, lu.z])
	clear_u(); m.state = "ok"
	at(91.9, 0); keys.right = true; fast(0.5); keys.right = false; ok("the hedge stops you, and says so", m.x <= 92 and edge == "hedge", m.x)
	# ---------- bows: the book lets you use one, and comes with a sling
	m.state = "ok"; R.phase = "day"; R.timeLeft = 300
	m.books = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; m.xp = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]; m.inv = [13]; m.wpn = 0; at(13.4, 20.4)
	X.do_act(m, "eq", 0); ok("no bow without the book", m.wpn == 0 and m.inv == [13])
	X.do_act(m, "book", 5); ok("Slings, Bows and Thrown Turnips comes with a sling", m.books[5] == 1 and m.inv.has(12), m.inv)
	X.do_act(m, "eq", 0); ok("with the book, the bow goes in the hand", m.wpn == 13 and not m.inv.has(13), "%d / %s" % [m.wpn, m.inv])
	at(40, 0); m.r = 0; clear_u()
	var bt: E.Undead = mob(1, 0, 10)[0]
	bt.hp = 9999
	var bh := 0
	for i in 10:
		m.atkCd = 0
		var h := bt.hp
		X.do_attack(m)
		if bt.hp < h: bh += 1
	ok("and it shoots", bh >= 6, bh)
	clear_u()
	m.inv = [14]; X.do_act(m, "eq", 0); ok("a crossbow needs rank 3", m.wpn == 13)
	m.books[5] = 3; X.do_act(m, "eq", 0); ok("and works at rank 3", m.wpn == 14)
	# ---------- spare learning: past rank VII, learning is kept and sold for coin
	m.books[4] = 7; m.spare = 0.0; m.coward = false
	X.add_xp(m, 4, D.BOOKS[4].base * 2.5)
	ok("learning past rank VII is kept as spare points", absf(m.spare - 2.5) < 0.01 and m.books[4] == 7, m.spare)
	var c0 := m.coin
	var paid := X.sell_spare(m)
	ok("whole spare points sell for coin, the rest is kept", paid == 2 * D.SPARE_PAY and m.coin == c0 + paid and absf(m.spare - 0.5) < 0.01, [paid, m.spare])
	ok("and spare learning is saved", X.save_data().players[0].has("spare"))
	# ---------- the outer ruins wander between clearings, and are found by going near them
	var moved := 0
	var in_clearing := true
	var c1: Array = Map.ruin_layout(R.gseed, 1).centres
	for dd in range(2, 8):
		var cd: Array = Map.ruin_layout(R.gseed, dd).centres
		if cd[1] != c1[1] or cd[2] != c1[2]: moved += 1
		for k in [1, 2]: if not D.RUIN_SITES.has(cd[k]): in_clearing = false
		ok("two different clearings on day %d" % dd, cd[1] != cd[2]) if dd == 2 else null
	ok("the outer ruins move to other clearings on other nights", moved >= 4 and in_clearing, moved)
	ok("no tree grows in a clearing", R.trees.all(func(t): return D.RUIN_SITES.all(func(c): return absf(t.x - c.x) >= 10 or absf(t.z - c.z) >= 6.5)))
	Map.ruin_layout(R.gseed, R.day)
	R.ruins_seen = [true, false, false]
	var cn: Dictionary = Map.ruin_layout(R.gseed, R.day).centres[1]
	m.state = "ok"; at(cn.x + 30, cn.z); X.step(STEP)
	ok("an outer ruin is not found from far away", not R.ruins_seen[1])
	at(cn.x + 10, cn.z); X.step(STEP)
	ok("walking near it finds it, for everyone", R.ruins_seen[1])
