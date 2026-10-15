extends Node3D
## The inside of the chapel (version 7.37). A stone nave, flagged, with a red runner up the aisle; four rows of pews
## either side of it, where holy studies are sat now, with a bible; the altar rail, and behind it the altar with its
## cloth, cross and candlesticks, where the priest stands; a pulpit, a lectern, a font at the back, and coloured windows
## in every wall. On the nights of the bells the windows blaze (they are the world's glass, like the ones outside) and
## every candle the priest owns is lit. Built far off the map, like the library. The world (its parent) lends its helpers.

const Build := preload("res://scripts/build.gd")
const W := preload("res://scripts/world.gd")

var w                                    # the world
var _candles: Array = []                 # [flame, light or null, phase]
var _extra: Node3D                       # the candles that are only lit on the nights of the bells
var _extra_lights: Array = []


func _ready() -> void:
	w = get_parent()
	_build()


func _sign(parent: Node3D, at: Vector3, text: String, size: Vector2, board: Color, ink: Color, px: float = 0.004, ry: float = 0.0) -> void:
	Build.box(parent, Vector3(size.x, size.y, 0.06), at, board, ry)
	var l := Label3D.new()
	l.text = text; l.font_size = 40; l.pixel_size = px; l.modulate = ink; l.outline_size = 0; l.double_sided = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.width = size.x / px * 0.94
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = at + Vector3(sin(ry) * 0.04, size.y * 0.5, cos(ry) * 0.04); l.rotation.y = ry
	parent.add_child(l)


## A candle: wax and a flickering flame. Only a few give off light (lights are dear).
func _candle(parent: Node3D, at: Vector3, lit: bool, h: float = 0.18, r: float = 0.045) -> void:
	Build.cyl(parent, r, r * 1.1, h, at, Color("f1e8d0"), 6)
	var f := Build.cone(parent, r * 0.8, 0.11, at + Vector3(0, h, 0), Color.WHITE, 4)
	f.material_override = Build.mat(Color(1.0, 0.78, 0.35), 2.8)
	var l: OmniLight3D = null
	if lit:
		l = OmniLight3D.new(); l.light_color = Color(1.0, 0.76, 0.45); l.omni_range = 6.0; l.light_energy = 1.2
		l.position = at + Vector3(0, h + 0.3, 0); parent.add_child(l)
	_candles.append([f, l, randf() * TAU])


## A tall pointed window of coloured glass, set in a wall (ry turns it to face into the room).
func _window(parent: Node3D, at: Vector3, ry: float, wdt: float, hgt: float, cols: Array) -> void:
	var g := Node3D.new(); g.position = at; g.rotation.y = ry; parent.add_child(g)
	var trim := Color("8f8878")
	Build.box(g, Vector3(wdt + 0.3, hgt + 0.3, 0.1), Vector3(0, -0.15, 0), trim)
	var panes: int = cols.size()
	for i in panes:                                                              # lights of coloured glass, side by side
		var pw: float = (wdt - 0.08 * (panes - 1)) / panes
		var m: StandardMaterial3D = cols[i]
		Build.glow_box(g, Vector3(pw, hgt, 0.06), Vector3(-wdt / 2 + pw / 2 + i * (pw + 0.08), 0, 0.04), m)
	for k in 3:                                                                  # the lead, across
		Build.box(g, Vector3(wdt, 0.03, 0.08), Vector3(0, hgt * (k + 1) / 4.0, 0.06), Color("2a2622"))
	var tip := Build.glow_box(g, Vector3(wdt * 0.72, wdt * 0.72, 0.06), Vector3(0, hgt - wdt * 0.36, 0.04), cols[0])   # the pointed top
	tip.rotation.z = PI / 4
	var cap := Build.box(g, Vector3(wdt * 0.86, wdt * 0.86, 0.1), Vector3(0, hgt - wdt * 0.43 - 0.04, -0.01), trim)
	cap.rotation.z = PI / 4
	Build.box(g, Vector3(wdt + 0.36, 0.1, 0.24), Vector3(0, -0.2, 0.08), trim)    # the sill


func _pew(parent: Node3D, at: Vector3, rg: RandomNumberGenerator) -> void:
	var oak := Color("6e4a2c")
	var dark := Color("553620")
	Build.box(parent, Vector3(3.9, 0.08, 0.5), at + Vector3(0, 0.24, 0.08), oak)              # the seat
	Build.box(parent, Vector3(3.9, 0.62, 0.07), at + Vector3(0, 0.32, 0.33), oak)             # the back
	Build.box(parent, Vector3(3.96, 0.06, 0.12), at + Vector3(0, 0.94, 0.33), dark)           # its top rail
	for sx in [-1.0, 1.0]:                                                                    # the ends, with a carved top
		Build.box(parent, Vector3(0.08, 0.92, 0.64), at + Vector3(sx * 1.97, 0.0, 0.12), dark)
		Build.cyl(parent, 0.07, 0.07, 0.08, at + Vector3(sx * 1.97, 0.92, 0.33), dark, 6)
	Build.box(parent, Vector3(3.8, 0.05, 0.16), at + Vector3(0, 0.7, 0.44), dark)            # the shelf on the back, for the row behind
	for k in rg.randi_range(2, 4):                                                            # and the hymn books on it
		Build.box(parent, Vector3(0.14, 0.2, 0.12), at + Vector3(rg.randf_range(-1.7, 1.7), 0.75, 0.44), [Color("2f3f5a"), Color("5a2f2f"), Color("3a4a32")][k % 3], rg.randf_range(-0.2, 0.2))
	Build.box(parent, Vector3(3.8, 0.1, 0.22), at + Vector3(0, 0.0, -0.5), Color("7a2224"))   # a kneeler, red, in front


func _build() -> void:
	var M: Dictionary = D.ROOMS.chapel
	var n := Node3D.new()
	n.position = Vector3(M.x, 0, M.z)
	add_child(n)
	var rg := RandomNumberGenerator.new(); rg.seed = 7370
	var hw: float = M.hw
	var hd: float = M.hd
	var stone := Color("cfc8b6")
	var stone2 := Color("b4ad9b")
	var gold := Color("d8b040")
	var Cw: Dictionary = W.C
	Build.box(n, Vector3(44, 0.1, 40), Vector3(0, 0.02, 0), Color("0d0b0a"))                 # the dark all round
	Build.box(n, Vector3(hw * 2, 0.1, hd * 2), Vector3(0, 0.06, 0), Color("948d7c"))       # the flagstones
	for i in 7:                                                                               # their joints
		Build.box(n, Vector3(hw * 2, 0.02, 0.04), Vector3(0, 0.16, -hd + 1.2 + i * 2.3), Color("7a7465"))
	for i in 5:
		Build.box(n, Vector3(0.04, 0.02, hd * 2), Vector3(-hw + 2.0 + i * 2.0, 0.16, 0), Color("7a7465"))
	Build.box(n, Vector3(1.2, 0.03, hd * 2 - 4.0), Vector3(0, 0.17, 1.6), Color("8c2426"))     # the red runner, up the aisle
	for sx in [-0.62, 0.62]: Build.box(n, Vector3(0.06, 0.035, hd * 2 - 4.0), Vector3(sx, 0.17, 1.6), gold)
	# the sanctuary: a step up, with the altar on it
	Build.box(n, Vector3(hw * 2, 0.12, 3.6), Vector3(0, 0.1, -hd + 1.8), Color("aaa290"))
	Build.box(n, Vector3(hw * 2, 0.03, 0.08), Vector3(0, 0.22, -hd + 3.6), stone2)
	# walls: tall at the back and down the sides, and at the front only a low sill either side of the door, so you can see in
	Build.box(n, Vector3(hw * 2 + 0.6, 6.4, 0.4), Vector3(0, 0, -hd - 0.2), stone)
	Build.box(n, Vector3(hw * 2 + 0.6, 0.5, 0.5), Vector3(0, 0, -hd - 0.15), stone2)
	for sx in [-1.0, 1.0]:
		Build.box(n, Vector3(0.4, 4.6, hd * 2), Vector3(sx * (hw + 0.2), 0, 0), stone)
		Build.box(n, Vector3(0.5, 0.5, hd * 2), Vector3(sx * (hw + 0.15), 0, 0), stone2)
		for zz in [-6.0, -2.0, 2.0, 6.0]:                                                     # pilasters, between the windows
			Build.box(n, Vector3(0.4, 4.8, 0.5), Vector3(sx * (hw - 0.05), 0, zz), stone2)
		Build.box(n, Vector3(hw - 1.1, 0.6, 0.4), Vector3(sx * (hw + 1.1) / 2.0, 0, hd + 0.2), stone)
		Build.box(n, Vector3(0.36, 1.2, 0.44), Vector3(sx * 1.05, 0, hd + 0.2), stone2)        # the doorposts
	Build.box(n, Vector3(1.8, 0.05, 0.5), Vector3(0, 0.1, hd - 0.1), Color("7a7465"))           # the step, worn in the middle
	# the glass: its own materials, which are the world's, so they blaze with the others on the nights of the bells
	var red: StandardMaterial3D = Build.mat(Color("c23b3b"), 0.9).duplicate()
	var blue: StandardMaterial3D = Build.mat(Color("3b6fc2"), 0.9).duplicate()
	var amber: StandardMaterial3D = Build.mat(Color("e0b13a"), 0.9).duplicate()
	var green: StandardMaterial3D = Build.mat(Color("3f9a5a"), 0.9).duplicate()
	var violet: StandardMaterial3D = Build.mat(Color("8f5bc2"), 0.9).duplicate()
	for m in [red, blue, amber, green, violet]: w._glass.append(m)
	_window(n, Vector3(0, 2.0, -hd + 0.02), 0.0, 2.2, 3.4, [blue, red, amber])                  # the great east window, over the altar
	for sx in [-1.0, 1.0]:
		var i := 0
		for zz in [-4.0, 0.0, 4.0]:
			_window(n, Vector3(sx * (hw - 0.02), 1.5, zz), -sx * PI / 2, 1.0, 2.2, [[red, green, blue][(i + (1 if sx > 0 else 0)) % 3], [amber, violet, red][i % 3]])
			i += 1
	# the altar: stone, a white cloth with a purple frontal, a gilded cross, candlesticks
	var al := Vector3(0, 0.22, -7.0)
	Build.box(n, Vector3(2.6, 0.95, 1.0), al, stone)
	Build.box(n, Vector3(2.8, 0.05, 1.12), al + Vector3(0, 0.95, 0), Color("f6f1e2"))
	Build.box(n, Vector3(1.6, 0.8, 0.04), al + Vector3(0, 0.15, 0.53), Color("6a2a7a"))
	Build.box(n, Vector3(1.6, 0.06, 0.05), al + Vector3(0, 0.89, 0.54), gold)
	Build.box(n, Vector3(0.1, 0.5, 0.05), al + Vector3(0, 0.3, 0.56), gold); Build.box(n, Vector3(0.34, 0.08, 0.05), al + Vector3(0, 0.6, 0.56), gold)
	var gm := Build.mat(Color("e2b54a"), 0.4)
	Build.glow_box(n, Vector3(0.1, 0.9, 0.08), al + Vector3(0, 1.0, -0.25), gm)                 # the cross
	Build.glow_box(n, Vector3(0.5, 0.09, 0.08), al + Vector3(0, 1.62, -0.25), gm)
	Build.box(n, Vector3(0.36, 0.14, 0.26), al + Vector3(0, 1.0, -0.25), gold)
	for sx in [-1.0, 1.0]:
		Build.cyl(n, 0.05, 0.09, 0.5, al + Vector3(sx * 0.95, 1.0, -0.1), gold, 8)
		_candle(n, al + Vector3(sx * 0.95, 1.5, -0.1), sx > 0, 0.36, 0.05)
	Build.box(n, Vector3(0.42, 0.06, 0.3), al + Vector3(-0.5, 1.0, 0.15), Color("6a1d1a"), 0.2)   # the great book, shut
	# the altar rail: posts and a rail, the gap in the middle where the priest is
	for sx in [-1.0, 1.0]:
		var x0: float = sx * 1.0
		var x1: float = sx * 5.0
		Build.box(n, Vector3(4.0, 0.08, 0.16), Vector3((x0 + x1) / 2.0, 0.92, -4.4), Color("5a3a22"))
		Build.box(n, Vector3(4.0, 0.08, 0.3), Vector3((x0 + x1) / 2.0, 0.16, -4.15), Color("7a2224"))   # the kneeling cushion
		for k in 9:
			Build.box(n, Vector3(0.07, 0.78, 0.07), Vector3(x0 + (x1 - x0) * k / 8.0, 0.16, -4.4), Color("6e4a2c"))
	# the pulpit, on the left, with its steps; and on the right, a brass eagle with the bible open on its wings
	var pu := Vector3(-4.8, 0.1, -3.5)
	Build.cyl(n, 0.5, 0.42, 1.25, pu, Color("6e4a2c"), 6)
	Build.cyl(n, 0.56, 0.56, 0.08, pu + Vector3(0, 1.25, 0), Color("553620"), 6)
	for k in 3: Build.box(n, Vector3(0.5, 0.12, 0.3), Vector3(-4.3 + k * 0.0, 0.1 + k * 0.3, -2.75 + k * 0.0), Color("553620"))
	Build.box(n, Vector3(0.5, 0.05, 0.36), pu + Vector3(0.18, 1.36, 0.1), Color("efe6cf"), 0.0, -0.4)
	var le := Vector3(4.8, 0.1, -3.5)
	Build.cyl(n, 0.06, 0.28, 1.1, le, gold, 8)
	Build.box(n, Vector3(0.7, 0.06, 0.36), le + Vector3(0, 1.12, 0.0), gold, 0.0, -0.45)          # the eagle's wings
	Build.box(n, Vector3(0.12, 0.2, 0.12), le + Vector3(0, 1.22, -0.18), gold)                   # and its head, looking unimpressed
	Build.box(n, Vector3(0.6, 0.04, 0.42), le + Vector3(0, 1.2, 0.04), Color("f3ead2"), 0.0, -0.45)
	Build.box(n, Vector3(0.62, 0.03, 0.44), le + Vector3(0, 1.17, 0.04), Color("6a1d1a"), 0.0, -0.45)
	# the pews: four rows either side of the aisle (the rules have the seats)
	for z in D.PEW_ROWS:
		for cx in [-2.9, 2.9]:
			_pew(n, Vector3(cx, 0.1, z - M.z), rg)
	# the font, at the back on the right, with a lid; and a box for the collection
	var fo := Vector3(4.6, 0.1, 6.2)
	Build.cyl(n, 0.22, 0.3, 0.7, fo, stone2, 8)
	Build.cyl(n, 0.55, 0.4, 0.4, fo + Vector3(0, 0.7, 0), stone, 8)
	Build.cyl(n, 0.46, 0.46, 0.03, fo + Vector3(0, 1.07, 0), Color("7fb8c8"), 8).material_override = Build.mat(Color("8fc8d8"), 0.4)
	Build.cyl(n, 0.5, 0.5, 0.06, fo + Vector3(0.3, 1.18, 0.2), Color("6e4a2c"), 8, 0.0, 0.0, 0.5)
	_sign(n, fo + Vector3(0, 0.0, 0.62), "HOLY WATER\nnot for drinking, washing or throwing at the Bailiff", Vector2(1.1, 0.42), Color("efe6cf"), Color("2a1c12"), 0.0028)
	var cb := Vector3(-4.6, 0.1, 6.4)
	Build.box(n, Vector3(0.12, 0.9, 0.12), cb, Color("553620"))
	Build.box(n, Vector3(0.4, 0.3, 0.3), cb + Vector3(0, 0.9, 0), Color("6e4a2c"))
	Build.box(n, Vector3(0.2, 0.02, 0.04), cb + Vector3(0, 1.21, 0), Color("15121a"))
	_sign(n, cb + Vector3(0, 1.3, 0.0), "FOR THE ROOF", Vector2(0.7, 0.22), Color("efe6cf"), Color("7a2224"), 0.0032)
	# notices on the back wall either side of the east window, and a board of hymn numbers
	_sign(n, Vector3(-3.6, 2.3, -hd + 0.25), "THE DEPARTED ARE ASKED TO STAY DEPARTED", Vector2(1.5, 0.5), Color("efe6cf"), Color("2a1c12"), 0.0034)
	_sign(n, Vector3(3.6, 2.0, -hd + 0.25), "HYMNS\n12   47   12\n(we only know the one)", Vector2(1.1, 0.8), Color("4b2f1e"), Color("efe6cf"), 0.0034)
	# candles: on stands either side of the sanctuary, and along the window sills
	for sx in [-1.0, 1.0]:
		var cs := Vector3(sx * 2.4, 0.22, -5.4)
		Build.cyl(n, 0.04, 0.2, 1.2, cs, Cw.iron, 6)
		Build.cyl(n, 0.5, 0.5, 0.04, cs + Vector3(0, 1.2, 0), Cw.iron, 10)
		for k in 7:
			var a := k * TAU / 7.0
			_candle(n, cs + Vector3(cos(a) * 0.42, 1.24, sin(a) * 0.42), k == 0, 0.16 + (k % 3) * 0.04)
		_candle(n, cs + Vector3(0, 1.24, 0), false, 0.3)
	for sx in [-1.0, 1.0]:
		for zz in [-4.0, 0.0, 4.0]:
			_candle(n, Vector3(sx * (hw - 0.22), 1.32, zz - 0.25), false, 0.14)
			_candle(n, Vector3(sx * (hw - 0.22), 1.32, zz + 0.22), false, 0.2)
	# two lamps on the side walls, near the front, for the reading
	for sx in [-1.0, 1.0]:
		var at := Vector3(sx * (hw - 0.35), 2.4, 1.0)
		Build.box(n, Vector3(0.5, 0.06, 0.06), at + Vector3(sx * 0.15, 0.32, 0), Cw.iron)
		Build.box(n, Vector3(0.26, 0.32, 0.26), at, Color("ffd98a")).material_override = Build.mat(Color("f0a050"), 1.3)
		var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.84, 0.6); l.omni_range = 10.0; l.light_energy = 1.3; l.position = at + Vector3(-sx * 0.8, 0, 0.4); n.add_child(l)
	# the nights of the bells: every candle he owns, on every ledge, step and end of pew
	_extra = Node3D.new(); n.add_child(_extra); _extra.visible = false
	for z in D.PEW_ROWS:
		for sx in [-1.0, 1.0]:
			_candle(_extra, Vector3(sx * 0.95, 1.0, z - M.z + 0.33), false, 0.14)
			_candle(_extra, Vector3(sx * 4.87, 1.0, z - M.z + 0.33), false, 0.14)
	for k in 13:
		_candle(_extra, Vector3(-3.0 + k * 0.5, 0.22, -hd + 1.0 + (k % 2) * 0.3), false, 0.12 + (k % 3) * 0.06)
	for k in 9:
		_candle(_extra, Vector3(-4.6 + k * 0.4 + (0.0 if k < 5 else 5.4), 0.22, -3.9), false, 0.1 + (k % 2) * 0.08)
	for k in 6:
		_candle(_extra, al + Vector3(-1.2 + k * 0.48, 0.97, 0.38), false, 0.1 + (k % 3) * 0.05)
	for sx in [-1.0, 1.0]:
		var el := OmniLight3D.new(); el.light_color = Color(1.0, 0.72, 0.4); el.omni_range = 9.0; el.light_energy = 0.0; el.position = Vector3(sx * 3.0, 1.6, -2.0); n.add_child(el)
		_extra_lights.append(el)


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var bells: bool = w._bells_on
	_extra.visible = bells
	for c in _candles:                                        # the candles flicker
		var f: float = 0.85 + 0.15 * sin(now * 9.0 + c[2]) * sin(now * 4.3 + c[2] * 2.0)
		c[0].scale = Vector3(1.0, f, 1.0)
		if c[1]: c[1].light_energy = 1.2 * f
	for i in _extra_lights.size():
		_extra_lights[i].light_energy = (1.8 + 0.4 * sin(now * 7.0 + i * 2.0) * sin(now * 3.1)) if bells else 0.0
