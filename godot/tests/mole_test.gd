extends SceneTree
## Version 7.16: mole hills. Some each morning, out in the countryside and across the river; walk past one and the mole
## pops up with a few coins, once.
## Run:  godot --headless --path godot -s res://tests/mole_test.gd

var lines := []

func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))

func _init() -> void:
	seed(716)
	var R := Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	var m: E.Player = R.players[0]
	var here := R.moles.filter(func(h): return h[3] == "")
	var there := R.moles.filter(func(h): return h[3] == "riverside")
	ok("mole hills each morning, in the countryside and across the river", here.size() == D.MOLES.main and there.size() == D.MOLES.river, [here.size(), there.size()])
	ok("never in the village", not here.any(func(h): return h[0] > -D.VW - 2 and h[0] < D.VW + 2 and h[1] > D.VN - 2 and h[1] < D.VS + 2))
	ok("never in the hamlet", not there.any(func(h): return h[0] > -178 and h[0] < -142 and h[1] > 296 and h[1] < 326))
	var h: Array = here[0]
	m.x = h[0] + 0.5; m.z = h[1]; m.coin = 0
	R.step(1.0 / 30.0)
	ok("walk past one, and the mole leaves a few coins", m.coin >= D.MOLES.coin[0] and m.coin <= D.MOLES.coin[1] and h[2], m.coin)
	var c0 := m.coin
	R.step(1.0 / 30.0)
	ok("once a day", m.coin == c0)
	var far: Array = there[0]
	m.x = far[0]; m.z = far[1]
	R.step(1.0 / 30.0)
	ok("one across the river only for someone who is across the river", not far[2])
	m.room = "riverside"
	R.step(1.0 / 30.0)
	ok("and then it pops", far[2] and m.coin > c0)
	var before := str(R.moles)
	R.roll_day(false)
	ok("new ones in the morning", str(R.moles) != before and R.moles.all(func(x): return not x[2]))
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
