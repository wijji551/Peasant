extends SceneTree
## Version 7.29: the townsfolk. Their day is worked out from the day and the clock, they keep off buildings, and
## at dusk every one of them is back in the keep before the night.
## Run:  godot --headless --path godot -s res://tests/folk_test.gd

var lines := []
func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))

func _init() -> void:
	var R := Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	var F = load("res://scripts/view/folk.gd").new()
	F.R = R
	F._build()
	var bad := []
	for k in F._paths:
		var p: PackedVector2Array = F._paths[k]
		var d := 0.0
		while d < F._len(p):
			var a: Vector2 = F._along(p, d)[0]
			if F._blocked.has(Vector2i(floori(a.x), floori(a.y))) and a.distance_to(F.HUB) > 1.5: bad.append([k, a]); break
			d += 0.5
	ok("every way they walk keeps off the buildings and walls", bad.is_empty(), bad)
	var A := []
	var B := []
	for i in F.N:
		A.append(F._plan(i, 5)); B.append(F._plan(i, 5))
	ok("the same day is the same for everybody", str(A[0].map(func(l): return [l.t0, l.act])) == str(B[0].map(func(l): return [l.t0, l.act])) and A.size() == 7)
	ok("a different day is different", str(F._plan(0, 5).map(func(l): return l.act)) != str(F._plan(0, 6).map(func(l): return l.act)))
	var acts := {}
	for i in F.N:
		for l in F._plan(i, 3): acts[l.act] = true
	ok("they farm, fish, chop, drink and stand about", acts.has("farm") and acts.has("fish") and acts.has("chop") and acts.has("inn") and acts.has("idle"), acts.keys())
	var longest := 0.0
	for k in F._paths: longest = maxf(longest, F._len(F._paths[k]))
	ok("from the furthest place, they are back in the keep before dusk is over", longest / F.RUN < D.DUSK_LEN, longest / F.RUN)
	for l in lines: print(l)
	var nb := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - nb, nb])
	quit(1 if nb else 0)
