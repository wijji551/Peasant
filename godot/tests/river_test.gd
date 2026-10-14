extends SceneTree
## Version 7.12: the raft to the Riverside. The raft, the crossing and swimming, the far ruin, the two merchants, the
## Rune Cave, the druid and Granny's potions, and the Tithe Collector in its cave.
## Run:  godot --headless --path godot -s res://tests/river_test.gd

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


func put(p: E.Player, x: float, z: float) -> void:
	p.x = x; p.z = z; p.tx = x; p.tz = z


func hold(p: E.Player, sec: float) -> String:
	var it = R.find_interact(p)
	p.eHold = true
	fast(sec)
	p.eHold = false
	fast(0.1)
	return it.type if it else ""


func at(p: E.Player, id: String) -> void:
	var st := D.station(id)
	put(p, st.x, st.z); p.room = st.get("room", ""); p.state = "ok"


func posse(p: E.Player) -> Array:
	return R.peasants.filter(func(q): return q.owner == p.id and q.kind == 0 and q.state != "body")


func _init() -> void:
	seed(712)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	m = R.players[0]; f = R.players[1]
	R.weather = "clear"
	var M: Dictionary = D.ROOMS.riverside
	var n := 0
	for q in R.peasants:
		if q.kind == 0 and q.owner == 0 and n < 2:
			q.owner = m.id; q.state = "follow"; n += 1
	# ---------------------------------------------------------------- the raft
	put(m, M.door[0], M.door[1] - 1.0)
	m.wood = 60
	var it = R.find_interact(m)
	ok("at the riverbank: a raft to be built", it != null and it.type == "raftw")
	hold(m, 1.2)
	ok("wood goes into it, more than one player can carry", R.raftW == 60 and m.wood == 0 and not R.raft)
	put(f, M.door[0], M.door[1] - 1.0); f.wood = 50
	hold(f, 1.2)
	ok("the second load finishes it, and only what was needed is taken", R.raft and R.raftW == 100 and f.wood == 10)
	# ---------------------------------------------------------------- across
	put(m, M.door[0], M.door[1] - 1.0)
	ok("by day it crosses", R.find_interact(m).type == "enter")
	hold(m, 1.0)
	ok("across to the Riverside", m.room == "riverside" and m.rafted and m.z > M.z - M.hd)
	fast(1.0)
	ok("the posse comes too, on the raft", posse(m).all(func(q): return Rules.room_at(q.x, q.z) == "riverside"), posse(m).map(func(q): return [q.x, q.z]))
	put(m, m.x + 4, m.z + 4); fast(2.0)
	ok("and follows about over there", posse(m).all(func(q): return D.d2(q.x, q.z, m.x, m.z) < 49))
	ok("no undead come there", R.undead.is_empty())
	# ---------------------------------------------------------------- the far ruin
	put(m, D.RIVER_SPOTS[0][0] + 1, D.RIVER_SPOTS[0][1])
	it = R.find_interact(m)
	ok("ten heaps of rubble in the far ruin", D.RIVER_SPOTS.size() == 10 and it != null and it.type == "search" and it.i == 100)
	var c0 := m.coin + m.wood + m.stone + m.iron + m.inv.size() + m.food
	hold(m, it.dur + 0.3)
	ok("searched", R.spots2[0] == D.SEARCHES - 1)
	fast(1.0)
	ok("and nothing in it bites", R.undead.is_empty())
	# ---------------------------------------------------------------- the merchants
	at(m, "rmerch"); m.coin = 2000; m.iron = 0
	R.do_act(m, "rbuy", "iron")
	ok("the merchant who never leaves: materials, at three times the price", m.iron == 5 and m.coin == 2000 - D.RESIDENT.iron)
	var rs := D.tier_item(1, "rune")
	m.wpn = 0
	R.do_act(m, "rbuy", rs)
	ok("and rune arms, for two gold pieces", m.wpn == rs and m.coin == 2000 - D.RESIDENT.iron - D.RESIDENT.weapon)
	ok("the travelling merchant is never the one in the village", R.merch2 >= 0 and R.merch2 != R.merchant)
	var ws := R.wares_of(R.merch2)
	ok("and charges half as much again", R.wares2.size() == ws.size() and range(ws.size()).all(func(i): return R.wares2[i].price == ceili(ws[i].price * D.TRAVEL_MUL)))
	at(m, "tmerch"); m.coin = 2000
	var cheap := -1
	for i in R.wares2.size():
		if R.wares2[i].give != "page" and R.wares2[i].give != "index" and cheap < 0: cheap = i
	if cheap >= 0:
		var left0: int = R.wares2[cheap].left
		R.do_act(m, "mbuy", "t:%d" % cheap)
		ok("you can buy from him", R.wares2[cheap].left == left0 - 1 and m.coin == 2000 - R.wares2[cheap].price)
	else:
		ok("you can buy from him (only pages today)", true)
	ok("his notice lists his wares", Notices.data(R, "tmerch", m, "").o.size() >= 2)
	# ---------------------------------------------------------------- the Rune Cave
	at(m, "rcave"); m.wood = 30
	var RC: Dictionary = D.ROOMS.rcave
	put(m, RC.door[0], RC.door[1])
	var ci = R.find_interact(m)
	ok("the Rune Cave is boarded up until the shady fellow is paid", ci != null and ci.type == "enter" and ci.room == "rcave" and not ci.ok, ci.label if ci else null)
	at(m, "rcave")
	R.do_act(m, "rcfix")
	ok("20 wood to the shady fellow, once, makes it fit to explore", R.rcave and m.wood == 10)
	put(m, RC.door[0], RC.door[1])
	ok("then you can go in", R.find_interact(m).ok)
	hold(m, 1.0)
	ok("into the cave: a room of its own", m.room == "rcave" and absf(m.x - RC.x) < RC.hw and Rules.far_bank(m))
	put(m, D.RUNE_SEAMS[0][0], D.RUNE_SEAMS[0][1]); m.rune = 0
	var k := hold(m, D.RUNE_TIME + 0.3)
	ok("then runes, from its seams", k == "rune2" and m.rune == 1 and R.runes2[0] == D.RUNE_PER_SEAM - 1)
	put(m, RC.at[0], RC.at[1])
	hold(m, 1.0)
	ok("and out again, into the Riverside at the cave's mouth, not home", m.room == "riverside" and D.d2(m.x, m.z, RC.door[0], RC.door[1]) < 16.0, [m.room, m.x, m.z])
	m.books[3] = 10; m.steel = 20; m.rune = 10; m.wood = 10
	ok("and a master smith can forge rune", Rules.forge_why(m, D.tier_item(2, "rune")) == "")
	# ---------------------------------------------------------------- the druid and Granny's potions
	at(m, "druid"); m.coin = 500
	R.do_act(m, "recipe", 0)
	ok("no recipes without Granny's Remedies", m.recipes == 0)
	m.books[9] = 1
	R.do_act(m, "recipe", 0)
	ok("a recipe, for five shillings", m.recipes == 1 and m.coin == 500 - D.POT.recipe)
	ok("he sets his price for each potion once a day", R.brew.size() == 4 and R.brew.all(func(c): return c.size() >= 1 and c.size() <= 3))
	var good := true
	var rng := RandomNumberGenerator.new()
	for s in 400:
		rng.seed = s
		for kk in 4:
			var c: Dictionary = Rules.druid_price(rng, kk)
			if c.size() < 1 or c.size() > 3: good = false
			for key in c:
				var v: int = c[key]
				if key in ["wood", "stone", "iron", "food"] and (v < 5 or v > 10): good = false
				if key in ["steel", "mith", "rune"] and (v < 1 or v > 2): good = false
			if kk == 3 and not c.has("frock"): good = false
	ok("by his rules: three kinds at most, five to ten of a common thing, one or two of a rare one, and a fire rock for the Last Warning", good)
	for key in R.brew[0]: m.set(key, 20)
	R.do_act(m, "brew", 0)
	ok("he brews it", m.pot_a == 1)
	R.do_act(m, "brew", 1)
	ok("but not without its recipe", m.pot_s == 0)
	put(m, D.CAMPFIRE.x + 1, D.CAMPFIRE.z)
	var rocks := 0
	for i in 20:
		m.frock = 0
		hold(m, 3.2)
		rocks += m.frock
	ok("fire rocks, raked out of the campfire, now and then", rocks >= 3 and rocks <= 16, rocks)
	# drinking
	R.drink(m, 0)
	ok("Pick-Me-Up: two minutes", m.pot_a == 0 and absf(m.potA - D.POT.t) < 0.1)
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()
	var keeper := R.spawn_undead(0, 100, -55); keeper.state = "walk"; keeper.stun = 9999; keeper.hp = 90000; keeper.mhp = 90000   # so the night goes on
	m.room = ""; put(m, 0, -40); m.r = PI; m.wpn = 0; m.state = "ok"
	var u := R.spawn_undead(0, 0, -41.5); u.state = "walk"; u.stun = 99; u.hp = 900; u.mhp = 900
	var src := Rules.src_of(m, D.IT[0])
	var d0 := 900.0
	R.hit_u(u, 10, src)
	ok("you hit a quarter harder", absf((d0 - u.hp) - 12.5) < 0.6, d0 - u.hp)
	m.potA = 0
	m.pot_d = 1; R.drink(m, 2)
	m.hp = 100
	var hp0 := m.hp
	R.hurt_friend(m, 20, true, null, true)
	var plain := 20.0 * Rules.gear_cut(m)
	ok("Thick Skin: a quarter less harm", absf((hp0 - m.hp) - plain * 0.75) < 0.6 or (hp0 - m.hp) == 0.0, hp0 - m.hp)
	m.potD = 0
	m.pot_s = 1; R.drink(m, 1)
	var x0 := m.x
	R.move_player(m, 1, 0, 1.0)
	ok("Get-a-Move-On: a fifth faster", absf((m.x - x0) - D.PLAYER_SPEED * 1.2 * Rules.stride(m)) < 0.3, m.x - x0)
	m.potS = 0
	m.pot_i = 1; R.drink(m, 3)
	ok("Last Warning: fifteen to twenty seconds", m.potI >= 15 and m.potI <= 20)
	put(m, u.x + 1, u.z); u.burn = 0
	fast(0.6)
	ok("the dead near you catch fire, and you do not", u.burn > 0 and m.hp > 0)
	m.potI = 0
	ok("potions go through the storehouse", D.STORE_RES.has("pot_a") and R.store.has("pot_i"))
	# ---------------------------------------------------------------- swimming
	R.undead = [keeper]
	put(m, M.door[0], M.door[1] - 1.0); m.hp = 80
	it = R.find_interact(m)
	ok("after dark the raft does not cross: you swim", it != null and it.type == "swim")
	hold(m, 1.0)
	ok("into the river", m.state == "swim" and m.swimTo == "riverside")
	fast(D.RAFT.swim + 0.5)
	ok("twenty seconds later, the far bank, with half your health", m.room == "riverside" and m.state == "ok" and absf(m.hp - 40) < 2, m.hp)
	ok("and tired for a while after", m.tired > 40)
	ok("and the posse did not follow", posse(m).all(func(q): return Rules.room_at(q.x, q.z) == ""))
	var tx0 := m.x
	R.move_player(m, 1, 0, 1.0)
	ok("tired: slow", absf((m.x - tx0) - D.PLAYER_SPEED * D.RAFT.tired_spd) < 0.3, m.x - tx0)
	u = R.spawn_undead(0, 0, -41.5); u.state = "walk"; u.stun = 99; u.hp = 900; u.mhp = 900
	R.hit_u(u, 10, Rules.src_of(m, D.IT[0]))
	ok("and a quarter weaker", absf((900 - u.hp) - 7.5) < 0.6, 900 - u.hp)
	R.undead = [keeper]
	ok("nobody can swim before there is a raft", (func():
		var R2 := Rules.new(); R2.new_game([{"id": 1, "name": "X", "col": 0}]); var p2: E.Player = R2.players[0]
		R2.phase = "night"; p2.x = M.door[0]; p2.z = M.door[1] - 1.0
		var i2 = R2.find_interact(p2); return i2 == null or i2.type != "swim").call())
	# ---------------------------------------------------------------- the Tithe Collector
	at(m, "keeper"); m.coin = 500
	ok("its owner charges a shilling a search, more each week", R.tithe_fee() == 12 * Rules.week_of(R.mday()))
	ok("Garrick stands by the mouth of his cave", D.d2(D.station("keeper").x, D.station("keeper").z, D.ROOMS.tcave.door[0], D.ROOMS.tcave.door[1]) < 36.0)
	put(m, D.TITHE_RUBBLE.x, D.TITHE_RUBBLE.z + 1.4); m.room = "tcave"
	it = R.find_interact(m)
	ok("the rubble, in the cave, wants paying for first", it != null and it.type == "tithe" and not it.ok, it)
	at(m, "keeper")
	R.do_act(m, "tpay")
	ok("paid", m.tpaid and m.coin == 500 - R.tithe_fee())
	put(m, D.TITHE_RUBBLE.x, D.TITHE_RUBBLE.z + 1.4); m.room = "tcave"
	ok("a search takes a whole minute", R.find_interact(m).dur == 60.0)
	m.room = "riverside"
	var found := 0
	for i in 400:
		m.tpaid = true; m.tithe = false
		R.do_tithe(m)
		if m.tithe: found += 1
	ok("it is not found every time: about one in eight after dark", found > 25 and found < 80, found)
	m.inv = []; m.tithe = false; m.tpaid = true
	while not m.tithe:
		m.tpaid = true; R.do_tithe(m)
	m.inv = m.inv.filter(func(x): return x == D.I_TITHE)
	if m.wpn != D.I_TITHE: m.inv.erase(D.I_TITHE); m.wpn = D.I_TITHE
	ok("the Tithe Collector: holy and burning at once, a wide sweep", D.IT[D.I_TITHE].holy and D.IT[D.I_TITHE].fire and D.IT[D.I_TITHE].arc < 0 and D.IT[D.I_TITHE].ab == "quake")
	at(m, "store")
	R.do_act(m, "pute", "wpn")
	ok("it cannot be traded", m.wpn == D.I_TITHE and not R.items.has(D.I_TITHE))
	m.state = "dead"; R.undead.clear(); R.night.q = []
	fast(1.0)
	ok("whoever finds it keeps it, even dead", R.phase == "day" and (m.wpn == D.I_TITHE or m.inv.has(D.I_TITHE)) and not R.drops.any(func(d): return d.it == D.I_TITHE))
	put(m, D.TITHE_ORE.x, D.TITHE_ORE.z); m.room = "tcave"; m.rune = 0; m.mith = 0
	hold(m, 2.3)
	ok("one piece of ore in the cave, a day, for whoever gets there first", m.rune + m.mith == 1 and R.tore_day == R.day)
	put(f, D.TITHE_ORE.x, D.TITHE_ORE.z); f.room = "tcave"
	ok("and only one", not R.find_interact(f).ok)
	# ---------------------------------------------------------------- the layout (version 7.14): everything can be walked to
	var free := func(x: float, z: float) -> bool:
		if absf(x - M.x) > M.hw - 0.5 or z < M.z - M.hd + 1.7 or z > M.z + M.hd - 0.5: return false
		for b in M.box:
			if absf(x - b[0]) < b[2] + 0.45 and absf(z - b[1]) < b[3] + 0.45: return false
		return true
	var seen := {}
	var todo := [Vector2i(roundi((M.at[0] - (M.x - M.hw)) * 2), roundi((M.at[1] + 2.6 - (M.z - M.hd)) * 2))]
	while todo.size():
		var c: Vector2i = todo.pop_back()
		if seen.has(c): continue
		var wx: float = M.x - M.hw + c.x * 0.5
		var wz: float = M.z - M.hd + c.y * 0.5
		if not free.call(wx, wz): continue
		seen[c] = true
		for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]: todo.append(c + dv)
	var reach := func(x: float, z: float, r: float) -> bool:   # some free spot within r of it can be walked to from the landing
		for c in seen:
			if D.d2(M.x - M.hw + c.x * 0.5, M.z - M.hd + c.y * 0.5, x, z) < r * r: return true
		return false
	var places := []
	for st in D.STATIONS:
		if st.get("room", "") == "riverside": places.append([st.id, st.x, st.z, st.r * 0.8])
	for kk in D.RIVER_SPOTS.size(): places.append(["heap %d" % kk, D.RIVER_SPOTS[kk][0], D.RIVER_SPOTS[kk][1], 1.8])
	for ck in ["tcave", "rcave"]: places.append([ck + " mouth", D.ROOMS[ck].door[0], D.ROOMS[ck].door[1], 2.0])
	places.append(["the bonfire", D.CAMPFIRE.x, D.CAMPFIRE.z, 2.1])
	var lost := places.filter(func(pl): return not reach.call(pl[1], pl[2], pl[3])).map(func(pl): return pl[0])
	ok("from the landing, through the gates, everything at the Riverside can be walked to", lost.is_empty(), lost)
	# and inside each cave, from the way in: the seams, the rubble and the ore (version 7.21)
	var inside := []
	for ck in ["tcave", "rcave"]:
		var CM: Dictionary = D.ROOMS[ck]
		var free2 := func(x: float, z: float) -> bool:
			if absf(x - CM.x) > CM.hw - 0.4 or absf(z - CM.z) > CM.hd - 0.4: return false
			for b in CM.box:
				if absf(x - b[0]) < b[2] + 0.4 and absf(z - b[1]) < b[3] + 0.4: return false
			return true
		var seen2 := {}
		var todo2 := [Vector2i(roundi((CM.at[0] - (CM.x - CM.hw)) * 4), roundi((CM.at[1] - (CM.z - CM.hd)) * 4))]
		while todo2.size():
			var c: Vector2i = todo2.pop_back()
			if seen2.has(c): continue
			var wx: float = CM.x - CM.hw + c.x * 0.25
			var wz: float = CM.z - CM.hd + c.y * 0.25
			if not free2.call(wx, wz): continue
			seen2[c] = true
			for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]: todo2.append(c + dv)
		var goals := [[D.TITHE_RUBBLE.x, D.TITHE_RUBBLE.z, 2.2], [D.TITHE_ORE.x, D.TITHE_ORE.z, 1.5]] if ck == "tcave" else D.RUNE_SEAMS.map(func(v): return [v[0], v[1], 1.6])
		for g in goals:
			var got := false
			for c in seen2:
				if D.d2(CM.x - CM.hw + c.x * 0.25, CM.z - CM.hd + c.y * 0.25, g[0], g[1]) < g[2] * g[2]: got = true; break
			if not got: inside.append([ck, g])
	ok("inside the caves, the rubble, the ore and every seam can be reached", inside.is_empty(), inside)
	# the posse waits outside a cave's mouth
	var pq: Array = posse(m)
	if pq.is_empty():
		for q in R.peasants:
			if q.kind == 0 and q.state != "body" and pq.size() < 2: q.owner = m.id; q.state = "follow"; pq.append(q)
	m.state = "ok"; R.enter_room(m, "riverside"); m.rafted = true
	for q in pq: q.x = m.x + 1.0; q.z = m.z + 1.0
	R.enter_room(m, "tcave")
	fast(8.0)
	var TW: Array = D.ROOMS.tcave.wait
	ok("the posse waits outside the cave's mouth", pq.all(func(q): return D.d2(q.x, q.z, TW[0], TW[1]) < 25.0), pq.map(func(q): return [snappedf(q.x, 0.1), snappedf(q.z, 0.1)]))
	# ---------------------------------------------------------------- kept and sent
	var sv := R.save_data()
	var R2 := Rules.new()
	R2.load_game(sv, [{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	ok("the save keeps the raft, the cave, and what the players have", R2.raft and R2.rcave and R2.players[0].tithe and R2.players[0].recipes == 1)
	ok("joined games are told", ["rafted", "swimT", "tired", "pot_a", "potA", "potI", "frock", "recipes", "tpaid", "tithe"].all(func(x): return Net.PF.has(x)) and Net.PSTATE.has("swim"))
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
