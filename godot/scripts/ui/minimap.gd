extends Control
## The map in the corner, drawn as the web version draws it: the village, the river, the hedge and the stakes,
## the castle, trees, today's outcrop, mine and jetty, the rubble (marked if your relic lore can tell), things on
## the ground, the defences, the dead (blinking), peasants in their leader's colour, and the players.

const X0 := -100.0
const X1 := 100.0
const Z0 := -128.0
const Z1 := 72.0
const W := 150.0
const H := 150.0
const SC := 1.24                  # drawn a little larger than the web version's

var R: Rules
var me: E.Player
var _bg: ImageTexture
var _t := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(W, H) * SC
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true                          # nothing is drawn past the edge of the map


func mx(x: float) -> float: return (x - X0) / (X1 - X0) * W * SC
func mz(z: float) -> float: return (z - Z0) / (Z1 - Z0) * H * SC


func _rect(img: Image, x0: float, z0: float, x1: float, z1: float, c: Color) -> void:
	var r := Rect2i(int(mx(x0)), int(mz(z0)), maxi(1, int(mx(x1) - mx(x0))), maxi(1, int(mz(z1) - mz(z0))))
	img.fill_rect(r.intersection(Rect2i(0, 0, img.get_width(), img.get_height())), c)


func _make_bg() -> void:
	var img := Image.create(int(W * SC), int(H * SC), false, Image.FORMAT_RGBA8)
	img.fill(Color("e4d3a0"))
	_rect(img, X0, 58, X1, Z1, Color("7fb6c4"))                                      # the river
	_rect(img, -2.5, -100, 2.5, D.VN, Color("cdb77a"))                                # the castle road
	_rect(img, -46, D.GATE_Z - 2, 46, D.GATE_Z + 2, Color("cdb77a"))                 # the gate road
	_rect(img, -D.VW, D.VN, D.VW, D.VS, Color("d9c890"))                              # the village
	_rect(img, -D.KEEP_H, -D.KEEP_H, D.KEEP_H, D.KEEP_H, Color("7d7668"))
	_rect(img, X0, Z0, X1, D.Z0 - 1, Color("d3c39f"))                                # the castle's ground
	_rect(img, -10, -122, 10, -109, Color("4d485b"))                                  # the castle
	_bg = ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.1:                                       # ten times a second is plenty
		_t = 0.0
		queue_redraw()


func _draw() -> void:
	if R == null: return
	if _bg == null: _make_bg()
	draw_texture(_bg, Vector2.ZERO)
	var ink := Color("6b4f33")
	var wall := PackedVector2Array([Vector2(mx(-21), mz(D.VN)), Vector2(mx(-D.VW), mz(D.VN)), Vector2(mx(-D.VW), mz(D.VS)), Vector2(mx(D.VW), mz(D.VS)), Vector2(mx(D.VW), mz(D.VN)), Vector2(mx(21), mz(D.VN))])
	draw_polyline(wall, ink, 1.5)
	var hedge := Color("3f6b3a")
	draw_line(Vector2(mx(D.X0 - 1.5), mz(D.Z0 - 1)), Vector2(mx(D.X0 - 1.5), mz(58)), hedge, 2)
	draw_line(Vector2(mx(D.X1 + 1.5), mz(D.Z0 - 1)), Vector2(mx(D.X1 + 1.5), mz(58)), hedge, 2)
	draw_dashed_line(Vector2(mx(D.X0 - 1.5), mz(D.Z0 - 1)), Vector2(mx(D.X1 + 1.5), mz(D.Z0 - 1)), Color("5a4a3c"), 1, 3)
	for t: E.Trunk in R.trees:
		if t.st == 1 or t.x < D.X0 or t.x > D.X1 or t.z < D.Z0 or t.z > D.Z1: continue   # scenery past the hedge and the stakes is not on the map
		var s := 1.0 if t.st else 2.0
		draw_rect(Rect2(mx(t.x) - s / 2, mz(t.z) - s / 2, s, s), Color("a9bf78") if t.st else Color("7f9f58"))
	var mark := func(x: float, z: float, c: Color) -> void:
		draw_rect(Rect2(mx(x) - 3.5, mz(z) - 3.5, 7, 7), Color("2f2318"))
		draw_rect(Rect2(mx(x) - 2.5, mz(z) - 2.5, 5, 5), c)
	mark.call(R.QUARRY.x, R.QUARRY.z, Color("d8d2c2"))
	mark.call(R.MINEC.x, R.MINEC.z, Color("b5653a"))
	mark.call(R.JETTY.x, R.JETTY.z + 2, Color("8fd0e0"))
	var L := Map.ruin_layout(R.gseed, R.day)
	var lore := me != null and Rules.rk(me, 8) >= 2
	for k in [1, 2]:
		if R.ruins_seen[k]:
			var cc: Dictionary = L.centres[k]
			draw_rect(Rect2(mx(cc.x - 7), mz(cc.z - 4.4), mx(cc.x + 7) - mx(cc.x - 7), mz(cc.z + 4.4) - mz(cc.z - 4.4)), Color(0.45, 0.42, 0.38, 0.45))
	for i in L.spots.size():
		var sp: Dictionary = L.spots[i]
		if not R.ruins_seen[sp.ruin]: continue                 # the outer ruins are not on the map until someone finds them
		if lore and R.spots[i] > 0: draw_rect(Rect2(mx(sp.x) - 1.5, mz(sp.z) - 1.5, 3, 3), Color("f3d36a"))
		else: draw_rect(Rect2(mx(sp.x) - 1, mz(sp.z) - 1, 2, 2), Color("8a8478"))
	for d: E.Drop in R.drops:
		draw_rect(Rect2(mx(d.x) - 1.5, mz(d.z) - 1.5, 3, 3), Color("ffe27a") if D.IT[d.it].tier == "relic" else Color("c9b48a"))
	for s: E.Struct in R.structs:
		if s.slot >= 0:
			draw_rect(Rect2(mx(s.x - 3) + 0.3, mz(s.z) - 1, mx(s.x + 3) - mx(s.x - 3) - 0.6, 2), ink if s.built else Color(ink, 0.28))
		else:
			draw_rect(Rect2(mx(s.x) - 1, mz(s.z) - 1, 2.5, 2.5), Color("8a6a45"))
	var blink := floori(Time.get_ticks_msec() / 300.0) % 2
	var uc := Color("b0271f") if blink else Color("7e1c16")
	for u: E.Undead in R.undead:
		draw_rect(Rect2(mx(u.x) - 1.5, mz(u.z) - 1.5, 3, 3), uc)
	for q: E.Peasant in R.peasants:
		if q.state == "gone" or q.state == "inn": continue
		if q.state == "body":
			draw_rect(Rect2(mx(q.x) - 1, mz(q.z) - 0.5, 2.5, 1.5), Color("5a5148"))
			continue
		var own := R.player_by_id(q.owner)
		draw_rect(Rect2(mx(q.x) - 1, mz(q.z) - 1, 2, 2), Color(D.PCOL[own.col % 8]) if own else Color("8c7a5c"))
	for p: E.Player in R.players:
		if p.state == "hide" or p.state == "inn": continue
		var c := Vector2(mx(p.x), mz(p.z))
		draw_circle(c, 4.2 if p == me else 3.4, Color("2f2318"))
		draw_circle(c, 3.0 if p == me else 2.3, Color(D.PCOL[p.col % 8]))
	draw_rect(Rect2(Vector2.ZERO, size), Color("4a2a12"), false, 2.0)
