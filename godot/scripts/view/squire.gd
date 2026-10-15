extends Node3D
## The Knight's Squire (version 7.30): the library, now a room to walk into, with the Peasants' Section at the front,
## the librarian at her desk, a rope across the middle, and beyond it the rest of the library and Sir Aldous at his
## research; the lane past the west hedge and the clearing at the end of it, with Sir Aldous's cabin (his squire has gone,
## but where?); and inside the cabin, three paintings that are the lock of the squire's chest. Like the inn and the mine,
## all of it is built far off the map. The world (its parent) lends its helpers.

const Build := preload("res://scripts/build.gd")
const W := preload("res://scripts/world.gd")

var w                                    # the world
var _paint_nodes: Array = []             # the three paintings' contents, drawn when the game's lock is known
var _code := []
var _candles: Array = []                 # [flame, light or null, phase]
var _pennant: Node3D


func _ready() -> void:
	w = get_parent()
	_library()
	_woods()
	_cabin()
	_lane_sign()


## A sign: a board, with words painted on it (they face south, towards the view).
func _sign(parent: Node3D, at: Vector3, text: String, size: Vector2, board: Color = Color("8b6b47"), ink: Color = Color("2a1c12"), px: float = 0.0045, ry: float = 0.0) -> void:
	var b := Build.box(parent, Vector3(size.x, size.y, 0.08), at, board, ry)
	var l := Label3D.new()
	l.text = text
	l.font_size = 40
	l.pixel_size = px
	l.modulate = ink
	l.outline_size = 0
	l.double_sided = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.width = size.x / px * 0.94
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = at + Vector3(sin(ry) * 0.05, size.y * 0.5, cos(ry) * 0.05)
	l.rotation.y = ry
	parent.add_child(l)
	b.set_meta("sign", true)


## A candle: wax, and a little flame that flickers. Every third or so gives off light (lights are dear).
func _candle(parent: Node3D, at: Vector3, lit: bool, h: float = 0.16) -> void:
	Build.cyl(parent, 0.04, 0.045, h, at, Color("efe6cf"), 6)
	var f := Build.cone(parent, 0.035, 0.1, at + Vector3(0, h, 0), Color.WHITE, 4)
	f.material_override = Build.mat(Color(1.0, 0.78, 0.35), 2.6)
	var l: OmniLight3D = null
	if lit:
		l = OmniLight3D.new(); l.light_color = Color(1.0, 0.76, 0.45); l.omni_range = 5.5; l.light_energy = 1.1
		l.position = at + Vector3(0, h + 0.25, 0); parent.add_child(l)
	_candles.append([f, l, randf() * TAU])


## A row of books on a shelf: spines of every colour and height, as one multimesh (there are a great many).
func _books(xfs: Array[Transform3D], cols: Array[Color], from: Vector3, along: Vector3, length: float, rg: RandomNumberGenerator, grand: bool) -> void:
	var t := 0.0
	var dir := along.normalized()
	var ry := atan2(dir.x, dir.z) + PI / 2
	while t < length - 0.06:
		var th: float = rg.randf_range(0.05, 0.11)
		var hh: float = rg.randf_range(0.26, 0.42) if grand else rg.randf_range(0.2, 0.3)
		if rg.randf() < 0.06 and not grand:
			t += th * 2.0; continue                                        # a gap: somebody has it out
		var p := from + dir * (t + th * 0.5)
		var lean := 0.0 if rg.randf() > 0.08 else rg.randf_range(-0.25, 0.25)
		var b := Basis(Vector3.UP, ry) * Basis(Vector3(0, 0, 1), lean)
		xfs.append(Transform3D(b.scaled(Vector3(th, hh, rg.randf_range(0.22, 0.3))), p + Vector3(0, hh * 0.5, 0)))
		var pal := [Color("7d2f2a"), Color("2f4f3a"), Color("3a3f6b"), Color("6b4a2f"), Color("8a6a3a"), Color("4a2f52"), Color("9b4a35"), Color("2c3a4a")] if grand \
			else [Color("7a6248"), Color("6b5a44"), Color("8a7a5c"), Color("5d4a36"), Color("9a8462")]
		var c: Color = pal[rg.randi() % pal.size()]
		cols.append(c.lightened(rg.randf_range(0.0, 0.12)))
		t += th + 0.005


## A bookcase: a back, sides, shelves, a cornice, and books on every shelf. Faces +z (or turned).
func _bookcase(parent: Node3D, at: Vector3, wdt: float, hgt: float, ry: float, xfs: Array[Transform3D], cols: Array[Color], rg: RandomNumberGenerator, grand: bool) -> void:
	var n := Node3D.new(); n.position = at; n.rotation.y = ry; parent.add_child(n)
	var wood := Color("5a3a22") if grand else Color("8b6b47")
	Build.box(n, Vector3(wdt, hgt, 0.08), Vector3(0, 0, -0.26), wood.darkened(0.25))
	for sx in [-1.0, 1.0]: Build.box(n, Vector3(0.1, hgt, 0.6), Vector3(sx * wdt * 0.5, 0, 0), wood)
	if grand: Build.box(n, Vector3(wdt + 0.3, 0.2, 0.72), Vector3(0, hgt, 0), wood.darkened(0.1))
	var shelves := int(hgt / 0.55)
	for k in shelves + 1:
		var y := 0.1 + k * (hgt - 0.2) / float(shelves)
		Build.box(n, Vector3(wdt, 0.05, 0.56), Vector3(0, y, 0), wood)
		if k < shelves:
			var bx: Array[Transform3D] = []
			var bc: Array[Color] = []
			_books(bx, bc, Vector3(-wdt * 0.5 + 0.08, y + 0.05, 0.0), Vector3(1, 0, 0), wdt - 0.16, rg, grand)
			for i in bx.size():
				xfs.append(n.transform * bx[i]); cols.append(bc[i])


# ---------------------------------------------------------------- the library
func _library() -> void:
	var M: Dictionary = D.ROOMS.library
	var n := Node3D.new()
	n.position = Vector3(M.x, 0, M.z)
	add_child(n)
	var rg := RandomNumberGenerator.new(); rg.seed = 7300
	var plaster := Color("d8ccb0")
	var panel := Color("5a3a22")
	var C: Dictionary = W.C
	Build.box(n, Vector3(44, 0.1, 40), Vector3(0, 0.02, 0), Color("100c09"))
	Build.box(n, Vector3(M.hw * 2, 0.1, M.hd * 2), Vector3(0, 0.08, 0), Color("8a6a45"))
	for i in 9:                                                                          # floorboards, at the front
		Build.box(n, Vector3(0.05, 0.02, M.hd + 1.0), Vector3(-8.0 + i * 2.0, 0.18, (M.hd - 1.0) * 0.5), Color("6f5335"))
	Build.box(n, Vector3(M.hw * 2 - 0.4, 0.03, M.hd - 1.4), Vector3(0, 0.19, -(M.hd + 1.0) * 0.5 - 0.2), Color("b8963a"))   # beyond the rope: a red carpet with a gold edge
	Build.box(n, Vector3(M.hw * 2 - 0.9, 0.035, M.hd - 1.9), Vector3(0, 0.19, -(M.hd + 1.0) * 0.5 - 0.2), Color("7a2224"))
	Build.box(n, Vector3(3.0, 0.03, 1.8), Vector3(-0.5, 0.19, 4.0), Color("8a7a52"))       # and at the front, a mat, worn through
	# walls: the back one tall and panelled, the sides lower, the front only a sill so you can see in
	Build.box(n, Vector3(M.hw * 2 + 0.6, 4.6, 0.3), Vector3(0, 0, -M.hd - 0.15), plaster)
	Build.box(n, Vector3(M.hw * 2 + 0.6, 1.1, 0.34), Vector3(0, 0, -M.hd - 0.12), panel)
	Build.box(n, Vector3(M.hw * 2 + 0.6, 0.3, 0.4), Vector3(0, 4.4, -M.hd - 0.12), panel)
	for sx in [-1.0, 1.0]:
		Build.box(n, Vector3(0.3, 3.2, M.hd * 2), Vector3(sx * (M.hw + 0.15), 0, 0), plaster)
		Build.box(n, Vector3(0.34, 1.0, M.hd * 2), Vector3(sx * (M.hw + 0.13), 0, 0), panel)
		Build.box(n, Vector3(M.hw - 1.0, 0.5, 0.3), Vector3(sx * (M.hw + 1.0) / 2.0, 0, M.hd + 0.15), plaster)
		Build.box(n, Vector3(0.26, 2.4, 0.32), Vector3(sx * 0.95, 0, M.hd + 0.15), C.timber)
	Build.box(n, Vector3(2.2, 0.24, 0.32), Vector3(0, 2.4, M.hd + 0.15), C.timber)
	Build.box(n, Vector3(1.5, 0.04, 0.5), Vector3(0, 0.14, M.hd - 0.1), C.path2)
	var xfs: Array[Transform3D] = []
	var cols: Array[Color] = []
	# --- beyond the rope: the library proper. Bookcases to the ceiling along the back, and down both sides
	for i in 5:
		_bookcase(n, Vector3(-7.2 + i * 3.6, 0.1, -M.hd + 0.35), 3.4, 4.0, 0.0, xfs, cols, rg, true)
	for sx in [-1.0, 1.0]:
		for i in 2:
			_bookcase(n, Vector3(sx * (M.hw - 0.35), 0.1, -5.2 + i * 2.6), 2.4, 3.0, -sx * PI / 2, xfs, cols, rg, true)
	# two free-standing cases, back to back, in the middle of the far side
	_bookcase(n, Vector3(-4.6, 0.1, -4.3), 2.6, 2.6, 0.0, xfs, cols, rg, true)
	_bookcase(n, Vector3(-4.6, 0.1, -4.9), 2.6, 2.6, PI, xfs, cols, rg, true)
	# a ladder on wheels, against the back cases
	for sx in [-0.3, 0.3]: Build.box(n, Vector3(0.07, 4.2, 0.07), Vector3(4.6 + sx, 0.1, -M.hd + 1.05), C.wood3, 0.0, -0.22)
	for k in 9: Build.box(n, Vector3(0.6, 0.05, 0.06), Vector3(4.6, 0.4 + k * 0.45, -M.hd + 1.05 - (0.4 + k * 0.45) * 0.22), C.wood3)
	# a globe of the known world, most of which is labelled "Here Be Dragons"
	Build.cyl(n, 0.08, 0.3, 0.9, Vector3(-7.4, 0.1, -2.6), panel, 8)
	var gl := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.42; sm.height = 0.84; gl.mesh = sm
	gl.material_override = Build.mat(Color("6f8e9c")); gl.position = Vector3(-7.4, 1.4, -2.6); n.add_child(gl)
	Build.box(n, Vector3(0.36, 0.2, 0.1), Vector3(-7.38, 1.4, -2.2), Color("b89a5a"), 0.3)
	Build.cyl(n, 0.47, 0.47, 0.04, Vector3(-7.4, 1.38, -2.6), Color("b8963a"), 16, 0.0, 0.4)
	# a lectern, with a chained book on it
	Build.box(n, Vector3(0.18, 1.0, 0.18), Vector3(-1.4, 0.1, -4.6), panel)
	Build.box(n, Vector3(0.8, 0.06, 0.6), Vector3(-1.4, 1.1, -4.6), panel, 0.0, -0.4)
	Build.box(n, Vector3(0.66, 0.06, 0.46), Vector3(-1.4, 1.18, -4.55), Color("efe6cf"), 0.0, -0.4)
	# a chandelier over the far side
	Build.box(n, Vector3(0.04, 1.3, 0.04), Vector3(0, 3.3, -3.6), C.iron)
	Build.cyl(n, 0.9, 0.9, 0.06, Vector3(0, 3.25, -3.6), Color("8a6a2a"), 12)
	for k in 6: _candle(n, Vector3(cos(k * TAU / 6) * 0.85, 3.3, -3.6 + sin(k * TAU / 6) * 0.85), k == 0, 0.14)
	var cl := OmniLight3D.new(); cl.light_color = Color(1.0, 0.8, 0.5); cl.omni_range = 11.0; cl.light_energy = 1.6; cl.position = Vector3(0, 3.0, -3.6); n.add_child(cl)
	# --- Sir Aldous, at his research: a desk heaped with books, his helm and sword by him, his shield against the chair
	var dk := Vector3(2.6, 0, -2.6)
	Build.box(n, Vector3(2.4, 0.78, 1.0), dk + Vector3(0, 0.1, 0), panel)
	Build.box(n, Vector3(2.5, 0.06, 1.1), dk + Vector3(0, 0.88, 0), Color("6b4a2f"))
	for k in 7:                                                                            # the books, in heaps
		var hx := -0.9 + (k % 3) * 0.12
		Build.box(n, Vector3(0.5, 0.1, 0.36), dk + Vector3(hx, 0.94 + k * 0.1 if k < 4 else 0.94 + (k - 4) * 0.1, -0.2 if k < 4 else 0.2), [Color("7d2f2a"), Color("2f4f3a"), Color("3a3f6b"), Color("6b4a2f")][k % 4], k * 0.3)
	Build.box(n, Vector3(0.7, 0.03, 0.5), dk + Vector3(0.2, 0.94, 0.15), Color("efe6cf"), -0.1)     # open, and written in
	Build.box(n, Vector3(0.02, 0.03, 0.46), dk + Vector3(0.2, 0.96, 0.15), Color("8a7a5c"), -0.1)
	Build.box(n, Vector3(0.02, 0.3, 0.02), dk + Vector3(0.75, 0.94, 0.3), Color("efe6cf"), 0.0, 0.3)   # a quill
	Build.cyl(n, 0.06, 0.07, 0.08, dk + Vector3(0.75, 0.94, 0.3), Color("1d1a2a"), 6)
	Build.cyl(n, 0.12, 0.16, 0.06, dk + Vector3(0.85, 0.94, -0.25), Color("b8963a"), 8)
	for k in 3: _candle(n, dk + Vector3(0.78 + (k - 1) * 0.14, 1.0, -0.25), k == 1, 0.2 + (k % 2) * 0.06)
	Build.box(n, Vector3(0.7, 0.42, 0.6), dk + Vector3(0, 0.1, -0.95), C.wood2)                    # his chair
	Build.box(n, Vector3(0.7, 1.0, 0.1), dk + Vector3(0, 0.5, -1.25), C.wood2)
	var kn = w._npc(n, dk + Vector3(0, 0.1, -0.9), 0.0, Color("8f949e"), "bald")                  # the knight: in mail, and a moustache
	Build.box(kn, Vector3(0.5, 0.62, 0.05), Vector3(0, 0.5, 0.215), Color("a8262a"))                 # his tabard, red, with a gold lion (roughly)
	Build.box(kn, Vector3(0.18, 0.2, 0.02), Vector3(0, 0.78, 0.245), Color("e0b840"))
	Build.cyl(n, 0.2, 0.22, 0.32, dk + Vector3(-0.55, 0.94, 0.25), Color("aeb4bd"), 8)               # his helm, on the desk
	Build.box(n, Vector3(0.22, 0.05, 0.06), dk + Vector3(-0.55, 1.12, 0.45), Color("1a1a1e"))
	Build.box(n, Vector3(0.1, 1.3, 0.04), dk + Vector3(1.35, 0.1, 0.3), Color("cfd4dc"), 0.0, 0.0, 0.25)   # his sword, leaning on the desk
	Build.box(n, Vector3(0.4, 0.06, 0.1), dk + Vector3(1.22, 1.3, 0.3), C.iron, 0.0, 0.0, 0.25)
	Build.box(n, Vector3(0.7, 0.9, 0.08), dk + Vector3(-0.85, 0.1, -1.0), Color("a8262a"), 0.5, -0.2)     # his shield, against the chair
	Build.box(n, Vector3(0.3, 0.3, 0.02), dk + Vector3(-0.82, 0.45, -0.95), Color("e0b840"), 0.5, -0.2)
	# --- the rope: brass posts, and a red rope looping between them, the whole width of the room
	var px: float = -M.hw + 0.4
	while px <= M.hw - 0.3:
		Build.cyl(n, 0.05, 0.12, 0.95, Vector3(px, 0.1, -1.0), Color("c9a24a"), 8)
		Build.cyl(n, 0.09, 0.09, 0.1, Vector3(px, 1.02, -1.0), Color("e0bc5a"), 8)
		if px + 1.6 <= M.hw:
			for k in 4:
				var t := (k + 0.5) / 4.0
				var sag := 0.18 * sin(t * PI)
				Build.box(n, Vector3(0.42, 0.05, 0.05), Vector3(px + t * 1.6, 0.98 - sag, -1.0), Color("a8262a"), 0.0, 0.0, (0.5 - t) * 0.42)
		px += 1.6
	_sign(n, Vector3(-2.6, 1.1, -0.85), "MEMBERS OF THE NOBILITY ONLY", Vector2(1.4, 0.5), Color("efe6cf"), Color("7a2224"), 0.0036)
	Build.box(n, Vector3(0.05, 1.05, 0.05), Vector3(-2.6, 0.1, -0.85), Color("c9a24a"))
	# --- the librarian's desk, with a stamp, a box of cards, and the librarian behind it
	var ld := Vector3(-5.2, 0, 2.2)
	Build.box(n, Vector3(3.0, 0.9, 0.9), ld + Vector3(0, 0.1, 0), panel)
	Build.box(n, Vector3(3.1, 0.06, 1.0), ld + Vector3(0, 1.0, 0), Color("6b4a2f"))
	Build.box(n, Vector3(0.5, 0.25, 0.32), ld + Vector3(0.9, 1.06, 0.05), Color("8b6b47"))            # the card index
	for k in 6: Build.box(n, Vector3(0.44, 0.12, 0.02), ld + Vector3(0.9, 1.25, -0.1 + k * 0.045), Color("efe6cf"))
	Build.cyl(n, 0.05, 0.05, 0.16, ld + Vector3(-0.4, 1.06, 0.15), Color("5b4130"), 6)                 # the stamp
	Build.box(n, Vector3(0.16, 0.06, 0.12), ld + Vector3(-0.4, 1.06, 0.15), Color("2a1c12"))
	for k in 5: Build.box(n, Vector3(0.36, 0.08, 0.26), ld + Vector3(-1.0, 1.06 + k * 0.08, -0.05), [Color("7a6248"), Color("6b5a44"), Color("8a7a5c")][k % 3], k * 0.2)
	_candle(n, ld + Vector3(0.2, 1.06, -0.2), true)
	var lib = w._npc(n, ld + Vector3(0, 0, -0.95), 0.0, Color("3f5a48"), "bonnet", false)
	for sx in [-0.09, 0.09]: Build.box(lib, Vector3(0.11, 0.08, 0.03), Vector3(sx, 1.37, 0.21), Color("c9a24a"))   # her spectacles
	Build.box(n, Vector3(1.2, 0.44, 0.06), ld + Vector3(0, 0.45, 0.47), Color("6b4a2f"))
	_sign(n, ld + Vector3(0, 0.5, 0.52), "SILENCE", Vector2(0.9, 0.24), Color("efe6cf"), Color("2a1c12"), 0.004)
	# --- the Peasants' Section: planks on bricks, in front of the rope, facing you; books in brown, a sign, and straw
	var ps := Vector3(6.3, 0, -0.3)
	var pb: Array[Transform3D] = []
	var pc: Array[Color] = []
	Build.box(n, Vector3(4.2, 2.0, 0.06), ps + Vector3(0, 0.1, -0.24), Color("7d5f3f"))                    # a back of old boards
	for k in 3:
		var y := 0.28 + k * 0.6
		for xx in [-1.9, 0.0, 1.9]: Build.box(n, Vector3(0.22, 0.28 if k == 0 else 0.3, 0.36), ps + Vector3(xx, y - 0.28 if k == 0 else y - 0.32, 0), Color("9a4a35"))   # the bricks
		Build.box(n, Vector3(4.2, 0.06, 0.46), ps + Vector3(0, y, 0), Color("a08562"), 0.0, 0.0, (k - 1) * 0.015)
		_books(pb, pc, ps + Vector3(-2.0, y + 0.03, 0.02), Vector3(1, 0, 0), 4.0, rg, false)
	for i in pb.size(): xfs.append(pb[i]); cols.append(pc[i])
	_sign(n, ps + Vector3(0.1, 2.15, 0.0), "PEASANTS’ SECTION\n(please do not lick the books)", Vector2(2.4, 0.6), Color("c8a868"), Color("3a2614"), 0.0042, 0.06)
	for sx in [-1.0, 1.0]: Build.box(n, Vector3(0.06, 0.6, 0.06), ps + Vector3(sx * 1.0, 2.0, -0.02), W.C.timber)
	for k in 16: Build.box(n, Vector3(rg.randf_range(0.3, 0.6), 0.03, 0.06), ps + Vector3(rg.randf_range(-2.2, 2.2), 0.16, rg.randf_range(0.5, 2.4)), W.C.straw, rg.randf() * TAU)   # straw on the floor
	Build.cyl(n, 0.2, 0.17, 0.4, ps + Vector3(2.5, 0.1, 0.5), Color("6b5a44"), 8)                         # a bucket, for some reason
	_candle(n, ps + Vector3(1.7, 1.48, 0.05), true, 0.12)
	# a reading table for peasants, with two benches and one candle between all of them
	var rt := Vector3(2.6, 0, 3.6)
	Build.box(n, Vector3(2.6, 0.72, 1.0), rt + Vector3(0, 0.1, 0), Color("8b6b47"))
	Build.box(n, Vector3(2.7, 0.06, 1.1), rt + Vector3(0, 0.82, 0), Color("98784f"))
	for sz in [-0.85, 0.85]: Build.box(n, Vector3(2.4, 0.4, 0.34), rt + Vector3(0, 0.1, sz), Color("7d5f3f"))
	Build.box(n, Vector3(0.5, 0.05, 0.36), rt + Vector3(-0.6, 0.88, 0.1), Color("7a6248"), 0.2)
	_candle(n, rt + Vector3(0.4, 0.88, -0.1), false)
	# and a window or two, high up, letting in a little grey daylight
	for sx in [-1.0, 1.0]:
		for z in [-4.4, 3.2]:
			Build.box(n, Vector3(0.12, 1.3, 0.9), Vector3(sx * (M.hw + 0.02), 1.6, z), C.timber)
			Build.glow_box(n, Vector3(0.12, 1.1, 0.7), Vector3(sx * (M.hw - 0.0), 1.7, z), Build.mat(Color("cfd8e0"), 0.6))
	for sx in [-1.0, 1.0]:                                                                        # and lamps on the walls at the front
		var at := Vector3(sx * (M.hw - 0.35), 2.1, 1.0)
		Build.box(n, Vector3(0.5, 0.06, 0.06), at + Vector3(sx * 0.15, 0.3, 0), C.iron)
		Build.box(n, Vector3(0.26, 0.32, 0.26), at, Color("ffd98a")).material_override = Build.mat(Color("f0a050"), 1.3)
		var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.82, 0.55); l.omni_range = 9.0; l.light_energy = 1.4; l.position = at + Vector3(-sx * 0.6, 0, 0.6); n.add_child(l)
	for i in xfs.size(): xfs[i] = n.transform * xfs[i]          # (from the room's own ground to the world's)
	w._multi(_box_mesh(), xfs, cols)


static func _box_mesh() -> BoxMesh:
	var b := BoxMesh.new(); b.size = Vector3.ONE
	return b


# ---------------------------------------------------------------- the lane, the clearing, and Sir Aldous's cabin
func _woods() -> void:
	var M: Dictionary = D.ROOMS.woods
	var n := Node3D.new()
	n.position = Vector3(M.x, 0, M.z)
	add_child(n)
	var C: Dictionary = W.C
	var rg := RandomNumberGenerator.new(); rg.seed = 7301
	var r := func(a: float, b: float) -> float: return rg.randf_range(a, b)
	Build.box(n, Vector3(170, 0.1, 120), Vector3(0, 0.0, 0), C.grass2)
	Build.box(n, Vector3(M.hw * 2 + 2, 0.1, M.hd * 2 + 2), Vector3(0, 0.03, 0), C.grass)
	Build.box(n, Vector3(22.0, 0.04, M.hd * 2 - 2), Vector3(-12.5, 0.07, 0), Color("a5b866"))            # the clearing, trodden
	Build.box(n, Vector3(60.0, 0.07, 3.6), Vector3(27.0, 0.08, 0.6), C.path)                             # the lane, from the village to the clearing
	for k in 2: Build.box(n, Vector3(60.0, 0.075, 0.35), Vector3(27.0, 0.09, 0.6 + (k * 2 - 1) * 1.0), C.path.darkened(0.12))
	for k in 30: Build.box(n, Vector3(r.call(0.4, 0.9), 0.085, r.call(0.4, 0.9)), Vector3(r.call(-2, 56), 0.0, 0.6 + r.call(-1.6, 1.6)), C.path2, r.call(0, 3))
	Build.box(n, Vector3(6.0, 0.072, 2.6), Vector3(-14.0, 0.08, 0.6), C.path2)                            # the path up to the cabin door
	Build.box(n, Vector3(2.0, 0.072, 3.6), Vector3(-13.0, 0.08, -2.0), C.path2)
	# --- the woods: thick both sides of the lane, and all round the clearing
	var kinds := ["wild_pine", "wild_oak", "wild_bush", "wild_tuft", "wild_flowers", "wild_rock"]
	var xs := {}
	var cs := {}
	for k in kinds:
		var a1: Array[Transform3D] = []
		var a2: Array[Color] = []
		xs[k] = a1; cs[k] = a2
	var put := func(k: String, x: float, z: float, s: float) -> void:
		(xs[k] as Array[Transform3D]).append(Transform3D(Basis(Vector3.UP, rg.randf() * TAU).scaled(Vector3.ONE * s), Vector3(M.x + x, 0, M.z + z)))
		var t: float = rg.randf_range(0.85, 1.08)
		(cs[k] as Array[Color]).append(Color(t, t, t))
	for i in 1300:
		var x: float = r.call(-60.0, 60.0)
		var z: float = r.call(-50.0, 50.0)
		var in_lane: bool = x > -1.0 and x < M.hw + 40 and absf(z - 0.6) < 5.2
		var in_clearing: bool = x < 0.5 and x > -M.hw - 0.5 and absf(z) < M.hd + 0.5 and Vector2((x + 12.0) / 13.0, z / 13.0).length() < 1.08
		if in_lane or in_clearing: continue
		put.call("wild_pine" if rg.randf() < 0.5 else "wild_oak", x, z, r.call(0.8, 1.45))
		if rg.randf() < 0.3: put.call("wild_bush", x + r.call(-2, 2), z + r.call(-2, 2), r.call(0.8, 1.4))
	for i in 60:
		var x: float = r.call(-M.hw, M.hw)
		var z: float = r.call(-M.hd, M.hd)
		put.call("wild_tuft" if i % 3 else "wild_flowers", x, z, r.call(0.7, 1.2))
	for i in 8: put.call("wild_rock", r.call(-M.hw, 0), r.call(-M.hd, M.hd) * (1.0 if i % 2 else -1.0), r.call(0.5, 0.9))
	for k in kinds:
		if (xs[k] as Array).size(): w._multi(Models.get_mesh(k), xs[k], cs[k], {"wild_pine": 0.035, "wild_oak": 0.03, "wild_bush": 0.05, "wild_tuft": 0.3, "wild_flowers": 0.25}.get(k, 0.0))
	# --- the cabin: logs, a shingle roof, a stone chimney, a shield over the door, a pennant, shutters closed
	var cb := Node3D.new(); cb.position = Vector3(-13.0, 0, -6.0); n.add_child(cb)
	Build.box(cb, Vector3(7.4, 0.3, 5.4), Vector3.ZERO, C.stone2)
	for k in 9:                                                                                          # the logs
		var y := 0.3 + k * 0.3
		Build.box(cb, Vector3(7.0, 0.3, 5.0), Vector3(0, y, 0), C.wood if k % 2 else C.wood2)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]: Build.cyl(cb, 0.17, 0.17, 0.32, Vector3(sx * 3.55, y + 0.15, sz * 2.55), C.wood3, 6, 0.0, PI / 2)
	Build.roof(cb, 6.2, 2.0, 8.2, Vector3(0, 3.0, 0), Color("6a4a3a"), PI / 2)
	Build.box(cb, Vector3(0.9, 4.6, 0.9), Vector3(2.4, 0.3, -1.2), C.stone3)
	Build.box(cb, Vector3(1.2, 2.0, 0.14), Vector3(0, 0.3, 2.52), C.timber)                               # the door
	Build.box(cb, Vector3(0.1, 0.1, 0.06), Vector3(0.4, 1.3, 2.6), C.iron)
	Build.box(cb, Vector3(0.3, 0.22, 0.03), Vector3(-0.2, 1.6, 2.6), Color("efe6cf"), 0.1)                # a note on the door, too
	Build.box(cb, Vector3(0.8, 0.95, 0.08), Vector3(0, 2.45, 2.56), Color("a8262a"))                      # the shield over it
	Build.box(cb, Vector3(0.32, 0.36, 0.03), Vector3(0, 2.7, 2.61), Color("e0b840"))
	for sx in [-2.2, 2.2]:                                                                                # shuttered windows
		Build.box(cb, Vector3(1.0, 0.9, 0.1), Vector3(sx, 1.2, 2.53), C.timber)
		Build.box(cb, Vector3(0.06, 0.9, 0.12), Vector3(sx, 1.2, 2.56), C.wood3)
	Build.box(cb, Vector3(0.08, 2.4, 0.08), Vector3(-3.7, 3.0, 2.6), C.timber)                            # a pennant, drooping
	_pennant = Node3D.new(); _pennant.position = Vector3(-3.7, 5.2, 2.6); cb.add_child(_pennant)
	Build.box(_pennant, Vector3(1.0, 0.3, 0.03), Vector3(0.5, -0.15, 0), Color("a8262a"))
	Build.box(_pennant, Vector3(0.5, 0.16, 0.03), Vector3(1.2, -0.12, 0), Color("e0b840"))
	# the stable: a lean-to on posts, with hay, and an empty saddle on the rail. The horse has gone too
	var st := Vector3(-4.0, 0, -8.5)
	for sx in [-2.0, 2.0]:
		Build.box(n, Vector3(0.18, 2.4, 0.18), st + Vector3(sx, 0, 1.2), C.timber)
		Build.box(n, Vector3(0.18, 1.8, 0.18), st + Vector3(sx, 0, -1.2), C.timber)
	Build.box(n, Vector3(4.6, 0.12, 3.0), st + Vector3(0, 2.05, 0), Color("6a4a3a"), 0.0, -0.2)
	Build.box(n, Vector3(4.0, 0.1, 0.12), st + Vector3(0, 1.0, 1.2), C.wood3)
	Build.box(n, Vector3(0.6, 0.32, 0.5), st + Vector3(-0.6, 1.0, 1.2), Color("6b3a22"))                 # the saddle
	Build.cyl(n, 0.9, 1.0, 0.8, st + Vector3(1.0, 0.05, -0.4), C.straw, 8)
	Build.box(n, Vector3(0.28, 0.2, 0.02), st + Vector3(2.0, 1.4, 1.3), Color("efe6cf"))                  # the note, on the post
	# a straw dummy, well hacked about, with a bucket for a helmet
	var dm := Vector3(-3.0, 0, 4.0)
	Build.box(n, Vector3(0.12, 1.2, 0.12), dm, C.timber)
	Build.cyl(n, 0.3, 0.26, 0.8, dm + Vector3(0, 0.9, 0), C.straw, 8)
	Build.box(n, Vector3(1.0, 0.12, 0.12), dm + Vector3(0, 1.4, 0), C.timber)
	Build.cyl(n, 0.2, 0.24, 0.3, dm + Vector3(0, 1.75, 0), C.iron, 8)
	for k in 6: Build.box(n, Vector3(0.3, 0.03, 0.08), dm + Vector3(r.call(-0.6, 0.6), 0.1, r.call(-0.6, 0.6)), C.straw, r.call(0, 3))
	# a weapon rack beside the cabin, with one sword in it and two gaps
	var wr := Vector3(-18.5, 0, -3.0)
	for sx in [-0.9, 0.9]: Build.box(n, Vector3(0.12, 1.3, 0.12), wr + Vector3(sx, 0, 0), C.timber)
	Build.box(n, Vector3(2.0, 0.1, 0.16), wr + Vector3(0, 1.15, 0), C.wood3)
	Build.box(n, Vector3(2.0, 0.1, 0.16), wr + Vector3(0, 0.3, 0.1), C.wood3)
	Build.box(n, Vector3(0.08, 1.1, 0.03), wr + Vector3(-0.5, 0.25, 0.05), Color("cfd4dc"), 0.0, 0.08)
	_sign(n, wr + Vector3(0.0, 1.32, 0.1), "SQUIRE’S", Vector2(0.7, 0.18), Color("98784f"), Color("2a1c12"), 0.0032)
	# the old fire: a ring of stones, cold ash, and a pot on a tripod with something in it that has given up
	var cf := Vector3(-9.0, 0, 3.5)
	for i in 9: Build.box(n, Vector3(0.36, 0.26, 0.36), cf + Vector3(cos(i * TAU / 9) * 0.65, 0, sin(i * TAU / 9) * 0.65), C.stone3, i)
	Build.box(n, Vector3(0.9, 0.05, 0.9), cf + Vector3(0, 0.07, 0), Color("5a5550"))
	for i in 3: Build.box(n, Vector3(0.05, 1.3, 0.05), cf + Vector3(cos(i * TAU / 3) * 0.45, 0, sin(i * TAU / 3) * 0.45), C.timber).rotation = Vector3(0.3 * sin(i * TAU / 3), 0, -0.3 * cos(i * TAU / 3))
	Build.cyl(n, 0.24, 0.2, 0.28, cf + Vector3(0, 0.55, 0), C.iron, 8)
	Build.cyl(n, 0.3, 0.3, 0.32, cf + Vector3(1.2, 0, 0.5), C.wood, 7)                                   # a stump to sit on
	# the woodpile, and an axe in the block
	var wp := Vector3(-19.4, 0, -6.0)
	for k in 12: Build.cyl(n, 0.14, 0.14, 1.0, wp + Vector3((k % 3) * 0.3 - 0.3, 0.14 + floorf(k / 3.0) * 0.26, (k % 2) * 0.1), C.wood if k % 2 else C.wood2, 6, 0.0, PI / 2)
	Build.cyl(n, 0.3, 0.32, 0.5, wp + Vector3(1.1, 0, 1.7), C.wood3, 8)
	Build.box(n, Vector3(0.06, 0.7, 0.06), wp + Vector3(1.1, 0.5, 1.7), C.timber, 0.0, 0.4)
	# the washing, still out: a tabard in his colours, and some very long johns
	w._washing(Vector3(M.x - 22.0, 0, M.z + 1.5), Vector3(M.x - 16.5, 0, M.z + 3.0))
	# and the trail: a boot, a gauntlet, a helmet with a nest in it, and hoofprints, going off into the trees
	var tr := [Vector3(-17.0, 0, 6.2), Vector3(-19.4, 0, 8.4), Vector3(-21.6, 0, 9.8)]
	Build.box(n, Vector3(0.24, 0.3, 0.44), tr[0] + Vector3(0, 0.08, 0), Color("4a3428"), 0.6)
	Build.box(n, Vector3(0.22, 0.14, 0.3), tr[1] + Vector3(0, 0.08, 0), C.iron, -0.4)
	Build.cyl(n, 0.26, 0.2, 0.3, tr[2] + Vector3(0, 0.06, 0), Color("aeb4bd"), 8, 0.0, PI)
	Build.cyl(n, 0.16, 0.14, 0.06, tr[2] + Vector3(0, 0.36, 0), Color("8a7050"), 8)
	for k in 12:
		var t := float(k) / 11.0
		var hp := Vector3(-14.0, 0, 5.0).lerp(Vector3(-23.6, 0, 11.6), t) + Vector3((k % 2) * 0.4 - 0.2, 0, 0)
		Build.box(n, Vector3(0.22, 0.02, 0.26), hp + Vector3(0, 0.09, 0), Color("6b5a3a"), -0.6)
	# the sign at the top of the lane
	Build.box(n, Vector3(0.14, 1.6, 0.14), Vector3(20.0, 0, -2.9), C.timber)
	_sign(n, Vector3(20.0, 1.05, -2.8), "SIR ALDOUS DE VERE, KNIGHT.\nPRIVATE. NO PEASANTS.\n(except on business) — W.", Vector2(1.9, 0.62), Color("98784f"), Color("7a2224"), 0.0036)


# ---------------------------------------------------------------- inside the cabin
func _cabin() -> void:
	var M: Dictionary = D.ROOMS.cabin
	var n := Node3D.new()
	n.position = Vector3(M.x, 0, M.z)
	add_child(n)
	var C: Dictionary = W.C
	Build.box(n, Vector3(30, 0.1, 30), Vector3(0, 0.02, 0), Color("0c0a08"))
	Build.box(n, Vector3(M.hw * 2, 0.1, M.hd * 2), Vector3(0, 0.08, 0), Color("7d5f3f"))
	for i in 5: Build.box(n, Vector3(0.05, 0.02, M.hd * 2), Vector3(-4.0 + i * 2.0, 0.18, 0), Color("5f4530"))
	Build.box(n, Vector3(2.6, 0.03, 1.8), Vector3(0.3, 0.19, 0.8), Color("7a2224"))                        # a rug, with a gold edge
	Build.box(n, Vector3(2.2, 0.035, 1.4), Vector3(0.3, 0.19, 0.8), Color("8a3a2a"))
	# log walls: the back full height, the sides lower, the front a low sill
	for k in 10:
		var y := k * 0.3
		Build.box(n, Vector3(M.hw * 2 + 0.6, 0.3, 0.34), Vector3(0, y, -M.hd - 0.17), C.wood if k % 2 else C.wood2)
	for sx in [-1.0, 1.0]:
		for k in 8: Build.box(n, Vector3(0.34, 0.3, M.hd * 2), Vector3(sx * (M.hw + 0.17), k * 0.3, 0), C.wood2 if k % 2 else C.wood)
		Build.box(n, Vector3(M.hw - 1.0, 0.6, 0.34), Vector3(sx * (M.hw + 1.0) / 2.0, 0, M.hd + 0.17), C.wood2)
		Build.box(n, Vector3(0.26, 2.2, 0.34), Vector3(sx * 0.95, 0, M.hd + 0.17), C.timber)
	# the three paintings on the back wall, in frames, numbered I, II and III (what is in them comes from the game: set_code)
	for i in 3:
		var at := Vector3(-3.0 + i * 3.0, 1.2, -M.hd + 0.02)
		Build.box(n, Vector3(2.0, 1.45, 0.08), at, Color("b8963a"))
		Build.box(n, Vector3(1.76, 1.21, 0.04), at + Vector3(0, 0.12, 0.05), [Color("9dbf68"), Color("6b4a2f"), Color("c8d8e8")][i])
		var pn := Node3D.new(); pn.position = at + Vector3(0, 0.14, 0.08); pn.scale = Vector3(1.35, 1.35, 1.0); n.add_child(pn)
		_paint_nodes.append(pn)
		_sign(n, at + Vector3(0, -0.3, 0.06), ["I", "II", "III"][i], Vector2(0.44, 0.26), Color("b8963a"), Color("3a2614"), 0.005)
	# Sir Aldous's bed: four posts, a canopy, and a red cover. The squire's: a cot, with straw coming out of it
	var bd := Vector3(-3.9, 0, 0.6)
	Build.box(n, Vector3(1.6, 0.5, 2.6), bd + Vector3(0, 0.1, 0), C.wood2)
	Build.box(n, Vector3(1.5, 0.2, 2.3), bd + Vector3(0, 0.6, 0.1), Color("a8262a"))
	Build.box(n, Vector3(1.3, 0.16, 0.4), bd + Vector3(0, 0.66, -1.0), Color("efe6cf"))
	for sx in [-0.75, 0.75]:
		for sz in [-1.25, 1.25]: Build.box(n, Vector3(0.1, 2.2, 0.1), bd + Vector3(sx, 0.1, sz), C.timber)
	Build.box(n, Vector3(1.7, 0.08, 2.7), bd + Vector3(0, 2.3, 0), Color("7a2224"))
	var ct := Vector3(4.2, 0, -1.4)
	Build.box(n, Vector3(0.9, 0.36, 1.9), ct + Vector3(0, 0.1, 0), C.wood3)
	Build.box(n, Vector3(0.8, 0.14, 1.8), ct + Vector3(0, 0.46, 0), C.straw)
	Build.box(n, Vector3(0.9, 0.06, 1.0), ct + Vector3(-0.05, 0.6, 0.3), Color("5a6b4a"), 0.25)
	# the chest: iron bands, and a lock of three dials (a sheep, a candle, a crow scratched on them)
	var ch := Vector3(4.2, 0, 2.2)
	Build.box(n, Vector3(0.8, 0.6, 1.1), ch + Vector3(0, 0.1, 0), C.wood)
	Build.box(n, Vector3(0.84, 0.18, 1.14), ch + Vector3(0, 0.68, 0), C.wood2)
	for sz in [-0.4, 0.4]: Build.box(n, Vector3(0.86, 0.66, 0.07), ch + Vector3(0, 0.1, sz), C.iron)
	for k in 3: Build.cyl(n, 0.07, 0.07, 0.06, ch + Vector3(-0.43, 0.58, -0.2 + k * 0.2), Color("c9a24a"), 8, 0.0, 0.0, PI / 2)
	# the hearth, cold, with a pot in it
	var hh := Vector3(-M.hw + 0.4, 0, 3.0)
	Build.box(n, Vector3(0.8, 1.6, 1.8), hh, C.stone2)
	Build.box(n, Vector3(0.5, 0.8, 1.1), hh + Vector3(0.2, 0.1, 0), Color("1b1612"))
	Build.box(n, Vector3(1.0, 0.14, 2.0), hh + Vector3(0.05, 1.6, 0), C.stone3)
	Build.cyl(n, 0.18, 0.15, 0.24, hh + Vector3(0.3, 0.12, 0), C.iron, 8)
	# the table: two plates, one of them still full; two stools
	var tb := Vector3(0.3, 0, 0.6)
	Build.box(n, Vector3(1.6, 0.72, 1.0), tb + Vector3(0, 0.1, 0), C.wood3)
	Build.box(n, Vector3(1.7, 0.06, 1.1), tb + Vector3(0, 0.82, 0), C.wood)
	for k in 2:
		Build.cyl(n, 0.2, 0.2, 0.03, tb + Vector3(-0.4 + k * 0.8, 0.88, 0), Color("c8c0b0"), 10)
		Build.cyl(n, 0.24, 0.24, 0.42, tb + Vector3(-0.4 + k * 0.8, 0.1, 0.9 * (1 if k else -1)), C.wood2, 7)
	Build.box(n, Vector3(0.22, 0.1, 0.16), tb + Vector3(0.4, 0.92, 0), Color("8a5a34"))                  # supper, untouched, some weeks old
	_candle(n, tb + Vector3(0.0, 0.88, -0.25), true, 0.1)
	# the armour stand: a post, a cross-piece, and nothing on it at all
	var ar := Vector3(-1.4, 0, -3.2)
	Build.box(n, Vector3(0.1, 1.6, 0.1), ar + Vector3(0, 0.1, 0), C.timber)
	Build.box(n, Vector3(0.7, 0.1, 0.1), ar + Vector3(0, 1.5, 0), C.timber)
	Build.cyl(n, 0.24, 0.3, 0.08, ar + Vector3(0, 0.1, 0), C.timber, 8)
	# a lamp, and a little daylight through the door
	var la := tb + Vector3(-0.55, 0.88, -0.3)                                                            # a lantern on the table
	Build.box(n, Vector3(0.22, 0.28, 0.22), la, Color("ffd98a")).material_override = Build.mat(Color("f0a050"), 1.2)
	Build.box(n, Vector3(0.26, 0.04, 0.26), la + Vector3(0, 0.28, 0), C.iron)
	var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.82, 0.55); l.omni_range = 9.0; l.light_energy = 1.4; l.position = la + Vector3(0, 1.4, -0.8); n.add_child(l)
	var dl := OmniLight3D.new(); dl.light_color = Color(1.0, 0.96, 0.86); dl.omni_range = 4.0; dl.light_energy = 0.8; dl.position = Vector3(0, 1.8, M.hd); n.add_child(dl)


## A fingerpost on the main map, by the west road where it goes through the hedge.
func _lane_sign() -> void:
	var at := Vector3(-121.6, 0, 4.9)
	Build.box(self, Vector3(0.16, 1.9, 0.16), at, W.C.timber)
	Build.box(self, Vector3(1.4, 0.3, 0.08), at + Vector3(-0.55, 1.5, 0.05), W.C.wood3, 0.0, 0.0, 0.05)
	Build.box(self, Vector3(0.24, 0.22, 0.08), at + Vector3(-1.3, 1.5, 0.05), W.C.wood3, PI / 4)
	var lb := Label3D.new(); lb.text = "SIR ALDOUS (PRIVATE)"; lb.font_size = 40; lb.pixel_size = 0.0028; lb.modulate = Color("2a1c12"); lb.double_sided = false
	lb.position = at + Vector3(-0.55, 1.65, 0.1); add_child(lb)


## The three paintings' contents: so many sheep, candles and crows (the lock of the squire's chest), from the game's seed.
func set_code(code: Array) -> void:
	if code == _code or code.size() < 3: return
	_code = code.duplicate()
	for i in 3:
		var pn: Node3D = _paint_nodes[i]
		for c in pn.get_children(): c.queue_free()
		var k: int = code[i]
		match i:
			0:                                       # a field, with sheep in it
				for j in k:
					var p := Vector3(-0.5 + (j % 5) * 0.25, 0.08 + floorf(j / 5.0) * 0.26, 0)
					Build.box(pn, Vector3(0.16, 0.11, 0.02), p, Color("f2efe6"))
					Build.box(pn, Vector3(0.06, 0.06, 0.025), p + Vector3(0.09, 0.05, 0), Color("2a2622"))
			1:                                       # a table, with candles on it
				Build.box(pn, Vector3(1.1, 0.06, 0.02), Vector3(0, 0.12, 0), Color("98784f"))
				for j in k:
					var x := -0.48 + j * (0.96 / maxf(1.0, k - 1.0))
					Build.box(pn, Vector3(0.05, 0.18, 0.02), Vector3(x, 0.18, 0), Color("efe6cf"))
					Build.box(pn, Vector3(0.04, 0.06, 0.025), Vector3(x, 0.37, 0), Color("ffb040")).material_override = Build.mat(Color(1.0, 0.7, 0.3), 1.5)
			2:                                       # a tree, with crows in it
				Build.box(pn, Vector3(0.08, 0.6, 0.02), Vector3(0, 0.0, 0), Color("4a3428"))
				for b in [[-0.3, 0.42, 0.5], [0.3, 0.5, -0.5], [0.0, 0.62, 0.0]]:
					Build.box(pn, Vector3(0.6, 0.04, 0.02), Vector3(b[0] * 0.5, b[1], 0), Color("4a3428"), 0.0, 0.0, b[2])
				for j in k:
					var a := j * 2.4
					Build.box(pn, Vector3(0.09, 0.07, 0.025), Vector3(cos(a) * (0.12 + j * 0.05), 0.42 + sin(a) * 0.22 + 0.1, 0), Color("15121a"))


func _process(delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for c in _candles:                                        # the candles flicker
		var f: float = 0.85 + 0.15 * sin(now * 9.0 + c[2]) * sin(now * 4.3 + c[2] * 2.0)
		c[0].scale = Vector3(1.0, f, 1.0)
		if c[1]: c[1].light_energy = 1.1 * f
	if _pennant: _pennant.rotation.y = 0.15 * sin(now * 0.7)
