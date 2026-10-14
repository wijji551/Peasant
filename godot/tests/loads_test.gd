extends SceneTree
## Version 7.20: towers, gates and walls built in loads, by anybody; and the posse sent home, or whistled for.
## Run:  godot --headless --path godot -s res://tests/loads_test.gd

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


func hold(p: E.Player, sec: float) -> void:      # holding E
	var t := 0.0
	while t < sec:
		p.eHold = true
		R.step(STEP); R.ev.clear(); t += STEP
	p.eHold = false
	R.step(STEP); R.ev.clear()


func site(i: int) -> E.Struct:
	for s in R.structs:
		if s.site == i: return s
	return null


func posse(p: E.Player, n: int) -> Array:
	var out := []
	for q in R.peasants:
		if out.size() < n and q.kind == 0 and q.owner == 0 and q.state != "body":
			q.owner = p.id; q.state = "follow"; q.x = p.x + 1.0; q.z = p.z + 1.0; q.plat = 0
			out.append(q)
	p.posse = out.size()
	return out


func _init() -> void:
	seed(720)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	m = R.players[0]; f = R.players[1]
	R.weather = "clear"
	# ---------- a tower in loads
	var t1 := site(1)
	m.x = t1.x; m.z = t1.z + 2.4; m.wood = 20; m.stone = 0
	var it = R.find_interact(m)
	ok("with only some of it, the tower can still be started", it != null and it.type == "found" and it.ok and it.label.contains("loads"), it.label if it else null)
	hold(m, 1.6)
	ok("twenty wood goes in, and it is not built yet", not t1.built and m.wood == 0 and int(t1.dep.get("wood", 0)) == 20, t1.dep)
	it = R.find_interact(m)
	ok("empty-handed, it says what it still wants", it != null and not it.ok and it.label.contains("5 wood") and it.label.contains("8 stone"), it.label if it else null)
	R.load_game(R.save_data(), [{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	m = R.players[0]; f = R.players[1]; t1 = site(1)
	ok("what has been put in is kept in the save", int(t1.dep.get("wood", 0)) == 20, t1.dep)
	f.x = t1.x + 0.5; f.z = t1.z + 2.4; f.wood = 9; f.stone = 3
	hold(f, 1.6)
	ok("somebody else can add to it, and only what is wanted goes in", not t1.built and f.wood == 4 and f.stone == 0 and int(t1.dep.wood) == 25 and int(t1.dep.stone) == 3, [f.wood, f.stone, t1.dep])
	f.stone = 10
	it = R.find_interact(f)
	ok("with the rest in hand, it offers to finish it", it != null and it.ok and it.label.contains("finish"), it.label if it else null)
	hold(f, 1.6)
	ok("and then it is built, with five stone put in", t1.built and f.stone == 5 and t1.dep.is_empty() and t1.kept, [t1.built, f.stone, t1.dep])
	R.destroy_struct(t1)
	ok("knocked down, it starts again from nothing", not t1.built and t1.dep.is_empty())
	# a side gate, the same
	var g := site(4)
	m.x = g.x + 1.0; m.z = g.z; m.wood = 10
	it = R.find_interact(m)
	if it and it.target == g:
		hold(m, 1.6)
		ok("a side gate too takes loads", not g.built and int(g.dep.get("wood", 0)) == 10, g.dep)
	else:
		ok("a side gate too takes loads", false, it)
	# ---------- the posse, sent home and whistled for
	m.x = 8.0; m.z = -12.0; m.state = "ok"     # north of the keep: the way home goes round it
	var mine := posse(m, 3)
	R.posse_home(m)
	ok("sent home: they are all marked to go", mine.all(func(q): return q.sent))
	var C := D.cottage(m.slot)
	fast(16.0)
	ok("and they walk to your cottage door, round the keep", mine.all(func(q): return D.d2(q.x, q.z, C.sx, C.sz) < 16.0), mine.map(func(q): return [snappedf(q.x, 0.1), snappedf(q.z, 0.1)]))
	ok("and are still your posse", mine.all(func(q): return q.owner == m.id) and m.posse == 3)
	m.x = 30.0; m.z = 0.0
	fast(3.0)
	ok("they stay there when you walk away", mine.all(func(q): return D.d2(q.x, q.z, C.sx, C.sz) < 16.0))
	R.posse_whistle(m)
	ok("a whistle: they are no longer sent", mine.all(func(q): return not q.sent) and m.order == 0)
	fast(12.0)
	ok("and they come to you", mine.all(func(q): return D.d2(q.x, q.z, m.x, m.z) < 25.0), mine.map(func(q): return [snappedf(q.x, 0.1), snappedf(q.z, 0.1)]))
	# across the river
	R.posse_home(m)
	var M: Dictionary = D.ROOMS.riverside
	m.room = "riverside"; m.rafted = true; m.x = M.at[0]; m.z = M.at[1] + 2.6
	R.posse_whistle(m)
	ok("from across the river, a whistle is not heard at home", mine.all(func(q): return q.sent))
	fast(2.0)
	ok("and they do not come over", mine.all(func(q): return R.room_at(q.x, q.z) == ""))
	var over: E.Peasant = mine[0]
	over.sent = false; over.x = m.x + 1.0; over.z = m.z + 1.0
	R.posse_home(m)
	ok("one across the river with you cannot be sent home: the raft does not run errands", not over.sent)
	R.leave_room(m)
	R.posse_whistle(m)
	ok("back on this side, the whistle reaches them", mine.all(func(q): return not q.sent))
	# an order does it too
	R.posse_home(m)
	m.books[6] = 1
	R.do_order(m)
	ok("an order brings back those sent home who can hear it", mine.all(func(q): return not q.sent))
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
