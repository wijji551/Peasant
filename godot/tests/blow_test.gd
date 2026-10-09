extends SceneTree
## Blows that feel like something: the rules say where each one landed, how hard, and how it told, so the view can
## show a number, make the right noise and knock the camera.
## Run:  godot --headless --path godot -s res://tests/blow_test.gd

var R: Rules
var m: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func one(k: int, x: float, z: float) -> E.Undead:
	var u := R.spawn_undead(k, x, z)
	u.state = "walk"; u.t = 0; u.stun = 99; u.hp = 900; u.mhp = 900
	return u


func hits() -> Array:
	var h: Array = R.ev.filter(func(e): return e[0] == "hit")
	R.ev.clear()
	return h


func swing() -> Array:
	R.ev.clear()
	m.atkCd = 0; R.do_attack(m)
	return hits()


func _init() -> void:
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	R.weather = "clear"
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()
	m.x = 0; m.z = -30; m.r = 0; m.wpn = 0
	# ---------- an ordinary blow
	var a := one(0, 0, -28.6)
	var h := swing()
	ok("a blow that lands is reported once, with where it landed", h.size() == 1 and absf(h[0][1] - a.x) < 1.0 and absf(h[0][2] - a.z) < 1.0, h)
	ok("with how much it did, whose it was, and what it hit", h.size() == 1 and h[0][3] == roundi(900 - a.hp) and h[0][5] == m.id and h[0][6] == 0 and h[0][7] == false, [h, 900 - a.hp])
	ok("an ordinary blow is marked ordinary", h.size() == 1 and h[0][4] == 0, h)
	R.kill_undead(a)
	# ---------- the wrong tool: a pitchfork on armour
	var g := one(D.U_GUARD, 0, -28.6)
	h = swing()
	ok("a farm tool on armour is marked feeble", h.size() == 1 and h[0][4] == 2, h)
	m.wpn = 3
	h = swing()
	ok("a mace on armour is not", h.size() == 1 and h[0][4] != 2, h)
	R.kill_undead(g)
	# ---------- the right tool: a mace on bones
	var s := one(1, 0, -28.6)
	h = swing()
	ok("a mace on a skeleton is marked telling", h.size() == 1 and h[0][4] == 1, h)
	R.kill_undead(s)
	# ---------- a wraith
	m.wpn = 0
	var w := one(D.U_WRAITH, 0, -28.6)
	h = swing()
	ok("a blow that passes through a wraith is not a hit", h.is_empty() and w.hp == 900)
	R.kill_undead(w)
	# ---------- the finishing blow
	var f := one(0, 0, -28.6)
	f.hp = 1
	h = swing()
	ok("the blow that finishes one says so", h.size() == 1 and h[0][7] == true, h)
	# ---------- a lucky double: the fifth blow in a row, for a master of the fighting book
	m.books[4] = 7; m.combo = 0
	var c := one(0, 0, -28.6)
	var marks: Array = []
	for i in 5:
		h = swing()
		marks.append(h[0][4] if h.size() == 1 else -1)
	ok("a master's fifth blow is marked as a double", marks == [0, 0, 0, 0, 3], marks)
	m.books[4] = 0
	R.kill_undead(c)
	# ---------- a shot: shown when it gets there
	m.wpn = 12; m.books[5] = 3
	var t := one(0, 0, -24.0)
	h = swing()
	ok("a shot's blow says it is a shot, so it can be shown when the stone arrives", h.size() == 1 and h[0].size() == 9 and h[0][8] == true, h)
	R.kill_undead(t)
	# ---------- fire
	m.wpn = D.I_TORCH; m.books[5] = 0
	var b := one(0, 0, -28.6)
	h = swing()
	ok("the torch's own blow is a blow", h.size() == 1 and h[0][4] != 4, h)
	var burns: Array = []
	var tt := 0.0
	while tt < 2.0:
		R.step(STEP); tt += STEP
		burns.append_array(hits())
	ok("and the burning after it is reported as burning, nobody's blow in particular", burns.size() >= 3 and burns.all(func(e): return e[4] == 4 and e[5] == 0), burns)
	R.kill_undead(b)
	# ---------- the posse
	R.undead.clear()
	var q: E.Peasant = null
	for p in R.peasants:
		if p.kind == 0 and p.owner == 0 and q == null: q = p
	if q:
		var pu := one(0, q.x + 0.8, q.z)
		R.ev.clear()
		R.hit_u(pu, 6.0, {"q": q, "x": q.x, "z": q.z})
		h = hits()
		ok("a villager's blow is reported too, as nobody's in particular", h.size() == 1 and h[0][5] == 0 and h[0][3] == 6, h)
	# ---------- what is not reported
	var d := one(0, 5, -28.6)
	R.ev.clear()
	R.hit_u(d, 10.0, {})
	ok("damage from spikes and the like is not (the view has other ways to show it)", hits().is_empty())
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
