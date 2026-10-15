extends SceneTree
## Version 7.39: the polish before the test plays. Run:  godot --headless --path godot -s res://tests/polish_test.gd

var lines := []

func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))

func _init() -> void:
	seed(739)
	var R := Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Jo", "col": 1}])
	var m: E.Player = R.players[0]
	var j: E.Player = R.players[1]
	# the stranger has a word for every boss of the month
	ok("the stranger has a hint for every boss night", D.BOSS_NIGHTS.values().all(func(k): return D.BOSS_HINT.has(k)), D.BOSS_NIGHTS.values().filter(func(k): return not D.BOSS_HINT.has(k)))
	# the dog stays, and keeps its name
	m.books[D.B_DOG] = 1
	R.ensure_dogs()
	var dog: E.Peasant = R.peasants.filter(func(q): return q.kind == 3 and q.owner == m.id)[0]
	var nm := dog.ni
	dog.state = "down"; dog.hp = 0
	R.phase = "night"; R.night = {"t": 0.0, "q": [], "total": 0, "c": 0, "dur": 0, "kills": 0, "boss": -1, "idle": 0.0, "sides": []}
	R.end_night()
	var dogs := R.peasants.filter(func(q): return q.kind == 3 and q.owner == m.id)
	ok("a dog is the same dog in the morning, and back on its feet", dogs.size() == 1 and dogs[0] == dog and dog.ni == nm and dog.state == "follow" and dog.hp > 0, [dogs.size(), dog.state])
	# dropped indoors: left outside the door, in the village
	var M: Dictionary = D.ROOMS.chapel
	R.drop_item(1, M.x, M.z)
	var dr: E.Drop = R.drops[R.drops.size() - 1]
	ok("a thing dropped in the chapel is left outside its door", D.d2(dr.x, dr.z, M.door[0], M.door[1]) < 9.0, [dr.x, dr.z])
	R.drop_item(1, -80.0, 240.0)
	dr = R.drops[R.drops.size() - 1]
	ok("and one dropped in the Rune Cave, on the village bank by the raft", D.d2(dr.x, dr.z, D.ROOMS.riverside.door[0], D.ROOMS.riverside.door[1]) < 16.0, [dr.x, dr.z])
	# the library card will not take the Knight's Squire
	var lib := D.station("library")
	m.room = "library"; m.x = lib.x; m.z = lib.z; m.state = "ok"
	m.books[D.B_SQUIRE] = 3; m.inv = [D.I_CARD]
	R.do_act(m, "card", D.B_SQUIRE)
	ok("a library card cannot hand back Sir Aldous's book", m.books[D.B_SQUIRE] == 3 and m.inv.has(D.I_CARD))
	m.room = ""
	# placing: a reason, not silence
	ok("a thing cannot go on the north wall's foundations, and says so", R.place_why("barricade", 0.0, D.VN, 0.0) != "" and not R.valid_place("barricade", 0.0, D.VN, 0.0))
	# a player going down tells the others
	R.phase = "night"; R.ev.clear()
	j.state = "ok"; j.hp = 1; j.upOnce = true
	R.hurt_friend(j, 500.0, true, null, false)
	ok("going down is announced, with where", R.ev.any(func(e): return e[0] == "pdown" and e[1] == j.id), j.state)
	# the hat: not for a night spent in the chapel
	R.phase = "night"; R.night = {"t": 0.0, "q": [], "total": 0, "c": 0, "dur": 0, "kills": 0, "boss": -1, "idle": 0.0, "sides": []}
	m.state = "ok"; j.state = "ok"
	m.nin = 200.0; m.nout = 10.0; j.nin = 0.0; j.nout = 200.0
	var c0 := m.coin
	var c1 := j.coin
	R.end_night()
	ok("a night indoors gets no share of the hat; a night out does", m.coin == c0 and j.coin > c1, [m.coin - c0, j.coin - c1])
	# attacks: the view waits as long as the rules do
	m.wpn = 0; m.mist = 5.0
	ok("Red Mist shortens the wait between blows, for the view as well", absf(Rules.atk_wait(m) - D.IT[0].cd * 0.67) < 0.001)
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
