extends Node3D
## Townsfolk (version 7.29): a handful of villagers who go about their day. They work the farm, go out to the mill,
## fish from the bank, take a drink at the Rose, chop at a tree at the edge of the wood, or stand about the market
## and the square. They gather nothing and are not in the rules: what each does when is worked out from the day and
## the time of day alone, so every player sees the same. They say hello when you come near. At dusk they run back to
## the keep and hide in it until morning.

const Figure := preload("res://scripts/view/figure.gd")
const N := 7
const HUB := Vector2(0.6, -4.4)          # the keep's door, where they come out in the morning and run back to at dusk
const SPD := 2.0                         # walking, about their business
const RUN := 6.5                         # running for it, at dusk
const X0 := -112.0
const X1 := 112.0
const Z0 := -30.0
const Z1 := 53.0
# where they go, and what they do there. Their favourite comes up more often than the rest.
const PLACES := {
	"field1": [-62.0, 27.0, "farm"], "field2": [-53.0, 34.0, "farm"], "field3": [-66.0, 38.0, "farm"],
	"mill": [97.5, 30.0, "idle"], "fish1": [-24.0, 52.4, "fish"], "fish2": [31.0, 52.4, "fish"], "fish3": [56.0, 52.4, "fish"],
	"inn": [-13.0, -3.6, "inn"], "market": [1.5, 19.0, "idle"], "square": [6.0, 6.5, "idle"], "board": [-5.5, -8.0, "idle"],
	"smithy": [11.5, -1.5, "idle"], "library": [12.5, 21.5, "idle"],
}
const LIKES := [["field1", "field2", "field3"], ["mill"], ["fish1", "fish2", "fish3"], ["tree"], ["market", "square", "board"], ["inn"], ["library", "smithy", "market"]]
const HELLO := ["Morning!", "Lovely day for it.", "Don't mind me.", "Have you seen my goat?", "Busy, busy.", "Mind how you go.",
	"They say the castle's haunted. Well. They say it's full of the dead, which is worse.", "Hello! Goodbye!", "Is it dusk yet? It feels like dusk.",
	"Grand weather for it.", "I'd help, only I'm busy.", "You look like you've been fighting something.", "Robert Bailiff owes me a shilling.",
	"Afternoon. Or is it morning.", "Nice banner.", "I keep the keep. Well, I hide in it.", "Lovely turnips this year. Lovely."]

var R
var me
var labels
var fx
var _blocked := {}                       # grid cells nobody walks through (Vector2i)
var _came := {}                          # cell -> the cell it was reached from, walking out from the keep's door
var _paths := {}                         # place -> its path from the keep's door, as points
var _folk: Array = []                    # each: {fig, q, plan, last_day_t, hello_t, chop_t, day}
var _ready_ok := false


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x), floori(p.y))


func _free(c: Vector2i) -> bool:
	return c.x >= X0 and c.x <= X1 and c.y >= Z0 and c.y <= Z1 and not _blocked.has(c)


## The ground, as a grid: the buildings and walls blocked (with a little room round them), and a walk out from the
## keep's door to everywhere, so a path to anywhere is the way back along it.
func _build() -> void:
	for b in Map.colliders():
		for x in range(floori(b.x - b.hw - 0.6), ceili(b.x + b.hw + 0.6)):
			for z in range(floori(b.z - b.hd - 0.6), ceili(b.z + b.hd + 0.6)):
				_blocked[Vector2i(x, z)] = true
	var start := _cell(HUB)
	_blocked.erase(start)
	_came[start] = start
	var todo := [start]
	var i := 0
	while i < todo.size():
		var c: Vector2i = todo[i]; i += 1
		for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + dv
			if not _came.has(n) and _free(n):
				_came[n] = c; todo.append(n)
	for k in PLACES: _paths[k] = _path_to(Vector2(PLACES[k][0], PLACES[k][1]))
	_ready_ok = true


func _nearest_reached(p: Vector2) -> Vector2i:
	var c := _cell(p)
	if _came.has(c): return c
	for r in range(1, 8):
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				var n := c + Vector2i(dx, dz)
				if _came.has(n): return n
	return _cell(HUB)


## From the keep's door to p: back along the walk, then pulled straight where nothing is in the way.
func _path_to(p: Vector2) -> PackedVector2Array:
	var c := _nearest_reached(p)
	var cells: Array = [c]
	while _came[c] != c:
		c = _came[c]; cells.append(c)
	cells.reverse()
	var pts := PackedVector2Array([HUB, Vector2(cells[0].x + 0.5, cells[0].y + 0.5)])
	var k := 0
	while k < cells.size() - 1:                          # as far on as can be seen from here, a step at a time
		var j := k + 1
		while j + 1 < cells.size() and _clear_line(cells[k], cells[j + 1]): j += 1
		pts.append(Vector2(cells[j].x + 0.5, cells[j].y + 0.5))
		k = j
	return pts


func _clear_line(a: Vector2i, b: Vector2i) -> bool:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y)) * 4
	for s in range(n + 1):                                  # (from cell middle to cell middle, as the path is walked)
		var t := float(s) / maxf(1.0, float(n))
		var p := Vector2(a.x + 0.5, a.y + 0.5).lerp(Vector2(b.x + 0.5, b.y + 0.5), t)
		if _blocked.has(Vector2i(floori(p.x), floori(p.y))): return false
	return true


func _len(p: PackedVector2Array) -> float:
	var s := 0.0
	for i in p.size() - 1: s += p[i].distance_to(p[i + 1])
	return s


func _along(p: PackedVector2Array, d: float) -> Array:      # [where, which way it faces] at d along p
	for i in p.size() - 1:
		var l := p[i].distance_to(p[i + 1])
		if d <= l or i == p.size() - 2:
			var f := clampf(d / maxf(l, 0.001), 0.0, 1.0)
			var dir := p[i + 1] - p[i]
			return [p[i].lerp(p[i + 1], f), atan2(dir.x, dir.y)]
		d -= l
	return [p[p.size() - 1], 0.0]


## One person's day: from the keep's door to somewhere, a while there, and back to the door; again and again until dark.
func _plan(i: int, day: int) -> Array:
	var rg := RandomNumberGenerator.new(); rg.seed = day * 7919 + i * 104729 + 13
	var out := []
	var t := 4.0 + i * 3.5
	while t < D.DAY_LEN:
		var key: String
		if rg.randf() < 0.6: key = LIKES[i % LIKES.size()][rg.randi() % LIKES[i % LIKES.size()].size()]
		else: key = PLACES.keys()[rg.randi() % PLACES.size()]
		var path: PackedVector2Array
		var act := "idle"
		var face := -1.0
		if key == "tree":                                    # the edge of the wood, by a tree that is still standing
			var tr = _a_tree(rg)
			if tr == null: key = "square"
			else:
				var tk := "tree%d" % tr.i
				if not _paths.has(tk): _paths[tk] = _path_to(Vector2(tr.x + 1.4, tr.z))
				path = _paths[tk]; act = "chop"; face = atan2(tr.x - path[path.size() - 1].x, tr.z - path[path.size() - 1].y)
		if key != "tree":
			path = _paths[key]; act = PLACES[key][2]
			if act == "fish": face = 0.0                      # facing the river
			elif key == "mill": face = PI / 2
		var l := _len(path)
		var dwell := rg.randf_range(25.0, 55.0) if act == "inn" else rg.randf_range(16.0, 42.0)
		out.append({"t0": t, "path": path, "len": l, "dwell": dwell, "act": act, "face": face})
		t += l / SPD * 2.0 + dwell + rg.randf_range(2.0, 8.0)      # (and a moment at the door between)
	return out


func _a_tree(rg: RandomNumberGenerator):
	var near := []
	for tr in R.trees:
		if tr.alive and tr.x < -36 and tr.x > -75 and tr.z > -24 and tr.z < 16: near.append(tr)
	return near[rg.randi() % near.size()] if near.size() else null


## Where they are at t seconds into the day: [where, facing, doing ("walk", "idle", "farm", "fish", "chop", "inn", "gone"), how far from the door].
func _state(f: Dictionary, t: float) -> Array:
	for leg in f.plan:
		var t0: float = leg.t0
		var walk: float = leg.len / SPD
		var end: float = t0 + walk * 2.0 + leg.dwell
		if t < t0: return [HUB, 0.0, "idle" if t > 2.0 + f.i * 3.5 else "gone", 0.0]
		if t >= end: continue
		var s := t - t0
		if s < walk:
			var a := _along(leg.path, s * SPD); return [a[0], a[1], "walk", s * SPD]
		if s < walk + leg.dwell:
			var a := _along(leg.path, leg.len)
			return [a[0], leg.face if leg.face >= 0.0 else a[1], leg.act, leg.len]
		var d: float = leg.len - (s - walk - leg.dwell) * SPD
		var b := _along(leg.path, d)
		return [b[0], b[1] + PI, "walk", d]
	return [HUB, 0.0, "idle", 0.0]


func _leg_at(f: Dictionary, t: float) -> Dictionary:
	for leg in f.plan:
		if t >= leg.t0 and t < leg.t0 + leg.len / SPD * 2.0 + leg.dwell: return leg
	return {}


func _process(delta: float) -> void:
	if R == null or not is_instance_valid(R): return
	if not _ready_ok:
		_build()
		for i in N:
			var fig = Figure.new(); fig.fx = fx; add_child(fig)
			var q := E.Peasant.new(); q.ni = 60 + i * 3; q.kind = 0; q.hp = 9999.0; q.nv = 100.0; q.state = "follow"; q.id = -100 - i
			_folk.append({"fig": fig, "q": q, "plan": [], "day": -1, "i": i, "last_t": D.DAY_LEN, "hello_t": 0.0, "chop_t": 0.0, "dusk_d": -1.0})
	var day_t := D.DAY_LEN - float(R.timeLeft)
	var dusk_t := D.DUSK_LEN - float(R.timeLeft)
	for f in _folk:
		var fig = f.fig
		var q: E.Peasant = f.q
		if f.day != R.day:
			f.day = R.day; f.plan = _plan(f.i, R.day); f.dusk_d = -1.0
		var st: Array
		if R.phase == "day":
			f.last_t = day_t; f.dusk_d = -1.0
			st = _state(f, day_t)
		elif R.phase == "dusk":
			if f.dusk_d < 0.0: f.dusk_d = _state(f, f.last_t)[3]       # how far from the door they were when the bell went
			var leg := _leg_at(f, f.last_t)
			var left: float = f.dusk_d - dusk_t * RUN
			if leg.is_empty() or left <= 0.0 or _state(f, f.last_t)[2] in ["gone", "inn"]: st = [HUB, 0.0, "gone", 0.0]
			else:
				var a := _along(leg.path, left)
				st = [a[0], a[1] + PI, "run", left]
		else:
			st = [HUB, 0.0, "gone", 0.0]
		var doing: String = st[2]
		fig.visible = doing != "gone" and doing != "inn" and (me == null or me.room == "")
		if not fig.visible: continue
		var p: Vector2 = st[0]
		q.x = p.x; q.z = p.y; q.r = st[1]
		q.state = "chop" if doing == "chop" or doing == "farm" else "follow"
		if doing == "chop":                                   # a swing now and then, with the sound of it
			f.chop_t -= delta
			if f.chop_t <= 0.0: f.chop_t = 1.7; q.ac += 1
		fig.peasant(q, null)
		if doing == "farm": fig._set_work("food")
		# hello, when you come near
		f.hello_t = maxf(0.0, f.hello_t - delta)
		if me != null and me.state == "ok" and labels and f.hello_t <= 0.0 and Vector2(me.x - p.x, me.z - p.y).length() < 2.8:
			f.hello_t = 25.0
			labels.bark_at("folk%d" % f.i, HELLO[(R.day * 3 + f.i * 5 + int(day_t / 30.0)) % HELLO.size()], fig)
