extends SceneTree
## Playing together over many days: people who drop out and come back, joining a game already going, rooms for joined
## players, and "I'm a stuck little peasant".
## Run:  godot --headless --path godot -s res://tests/away_test.gd

var R: Rules
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func fast(sec: float) -> void:
	var t := 0.0
	while t < sec:
		R.step(STEP); R.ev.clear(); t += STEP


func _init() -> void:
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Dave", "col": 1, "remote": true}, {"id": 3, "name": "Sam", "col": 2, "remote": true}])
	var matt: E.Player = R.players[0]
	var dave: E.Player = R.players[1]
	var sam: E.Player = R.players[2]
	# ---------- a joined player indoors: the host keeps them in the room, not at the edge of the map
	var mine: Dictionary = D.ROOMS["mine"]
	dave.x = mine.door[0]; dave.z = mine.door[1]; dave.tx = dave.x; dave.tz = dave.z
	R.enter_room(dave, "mine")
	ok("a joined player goes down the mine", dave.room == "mine" and dave.z > 200)
	Net.apply(R, dave, {"t": "in", "x": 2.0, "z": 240.0, "r": 0.0, "e": false, "tp": dave.tp})
	fast(0.6)
	ok("and the host has them where they walked to, inside it", absf(dave.x - 2.0) < 0.3 and absf(dave.z - 240.0) < 0.3, [dave.x, dave.z])
	Net.apply(R, dave, {"t": "in", "x": mine.at[0], "z": mine.at[1] - 1.2, "r": 0.0, "e": false, "tp": dave.tp})
	fast(0.6)
	var it = R.find_interact(dave)
	ok("at the ladder the way out is offered", it != null and it.get("type", "") == "leave", it)
	Net.apply(R, dave, {"t": "in", "x": dave.x, "z": dave.z, "r": 0.0, "e": true, "tp": dave.tp})
	fast(1.5)
	ok("and holding E takes them back up", dave.room == "" and dave.z < 60, [dave.room, dave.x, dave.z])
	Net.apply(R, dave, {"t": "in", "x": 500.0, "z": 500.0, "r": 0.0, "e": false, "tp": dave.tp})
	ok("outdoors they are still kept on the map", dave.tx <= D.X1 and dave.tz <= D.Z1)
	# ---------- I'm a stuck little peasant
	sam.x = 77.0; sam.z = 31.0; sam.tx = sam.x; sam.tz = sam.z
	var tp0 := sam.tp
	R.do_act(sam, "unstick")
	var c := D.cottage(sam.slot)
	ok("a stuck little peasant is put outside their own front door", absf(sam.x - c.sx) < 0.1 and absf(sam.z - c.sz) < 0.1 and sam.tp != tp0 and sam.room == "", [sam.x, sam.z])
	sam.x = 77.0; sam.z = 31.0
	R.do_act(sam, "unstick")
	ok("not twice in a moment", absf(sam.x - 77.0) < 0.1)
	fast(D.STUCK_WAIT + 0.5)
	R.enter_room(sam, "mine")
	R.do_act(sam, "unstick")
	ok("it works from down the mine too", sam.room == "" and absf(sam.x - c.sx) < 0.1, [sam.room, sam.x])
	# ---------- dropping out, and coming back the same day
	dave.wood = 17; dave.books[3] = 4; dave.coin = 99; dave.wpn = 3; dave.inv = [2, 15]     # 15 is a relic
	var dslot := dave.slot
	R.leave_player(2)
	ok("somebody who drops out is not in the game", R.players.size() == 2 and R.player_by_id(2) == null)
	ok("but their peasant is kept", R.away.size() == 1 and R.away[0].name == "Dave" and int(R.away[0].wood) == 17)
	ok("their relic stays with the village, on the ground", R.drops.any(func(d): return d.it == 15) and not R.away[0].inv.has(15), R.away[0].inv)
	var back := R.join_player(7, "dave", 4)
	ok("joining again under the same name gives it back", back.id == 7 and back.wood == 17 and back.books[3] == 4 and back.coin == 99 and back.wpn == 3 and back.inv == [2] and back.slot == dslot, [back.wood, back.books, back.inv, back.slot])
	ok("and nobody is left waiting", R.away.is_empty() and R.players.size() == 3)
	# ---------- a newcomer, mid-game
	var q0 := R.peasants.size()
	var kim := R.join_player(8, "Kim", 5)
	ok("a newcomer moves into an empty cottage", kim.slot != matt.slot and kim.slot != sam.slot and kim.slot != back.slot and R.players.size() == 4, kim.slot)
	ok("with villagers of their own next door", R.peasants.size() == q0 + 3)
	# ---------- the save: who is here, and who is not
	fast(0.2)
	R.leave_player(8)
	var sv := R.save_data()
	ok("the save keeps those playing and those away", sv.players.size() == 3 and sv.away.size() == 1 and sv.away[0].name == "Kim")
	var R2 := Rules.new()
	R2.load_game(sv, [{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Sam", "col": 2, "remote": true}])
	ok("carrying on without Dave: two play, two wait", R2.players.size() == 2 and R2.away.size() == 2 and R2.away.any(func(o): return o.name == "dave" or o.name == "Dave") and R2.away.any(func(o): return o.name == "Kim"), R2.away.map(func(o): return o.name))
	ok("each has their own peasant", R2.players[0].name == "Matt" and R2.players[1].name == "Sam" and R2.players[1].slot == sam.slot)
	var d2 := R2.join_player(5, "Dave", 1)
	ok("and Dave can turn up later and have his", d2.wood == 17 and d2.books[3] == 4 and R2.away.size() == 1, [d2.wood, d2.books])
	var sv2 := R2.save_data()
	var R3 := Rules.new()
	R3.load_game(sv2, [{"id": 1, "name": "Matthew", "col": 0}])
	ok("on your own, the others all wait", R3.players.size() == 1 and R3.away.size() == 3, R3.away.size())
	ok("and the host keeps their own peasant, whatever they call themselves today", R3.players[0].wood == matt.wood and R3.players[0].slot == matt.slot and not R3.away.any(func(o): return o.name == "Matt"))
	var R4 := Rules.new()
	R4.load_game({"v": 3, "day": 3, "pm": 3, "keepHp": 900.0, "store": {}, "stats": {}, "structs": [], "peasants": [], "players": [R.player_record(matt)]}, [{"id": 1, "name": "Somebody Else", "col": 0}])
	ok("one player, one saved peasant, a different name: it is still theirs", R4.players.size() == 1 and R4.away.is_empty() and R4.players[0].wood == matt.wood)
	# ---------- the steel mine, from where it looks as if you should stand
	matt.x = D.STEEL_MINE.x + 3.4; matt.z = D.STEEL_MINE.z + 1.5; matt.room = ""; matt.state = "ok"
	it = R.find_interact(matt)
	ok("the steel mine can be mined from in front of its mouth", it != null and it.get("kind", "") == "steel", it)
	matt.x = D.STEEL_MINE.x + 3.2; matt.z = D.STEEL_MINE.z - 2.0
	it = R.find_interact(matt)
	ok("and from a step to the side", it != null and it.get("kind", "") == "steel", it)
	# ---------- rain is mud for the living too
	matt.x = 40; matt.z = 45; R.weather = "clear"
	R.move_player(matt, 1, 0, 0.2)
	var dry := matt.x - 40.0
	matt.x = 40; R.weather = "rain"
	R.move_player(matt, 1, 0, 0.2)
	ok("rain slows the living a little, and the dead more", matt.x - 40.0 < dry and absf((matt.x - 40.0) / dry - D.MUD) < 0.01 and R.wspeed() < D.MUD, [dry, matt.x - 40.0])
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
