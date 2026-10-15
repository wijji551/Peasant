extends Node3D
## The map of Thornhallow, built from simple shapes.
## Same layout and measurements as the web version: x runs east, z runs south, north is -z.

const Build := preload("res://scripts/build.gd")
const Squire := preload("res://scripts/view/squire.gd")
const Chapel := preload("res://scripts/view/chapel.gd")
var squire: Node3D

const VW := 28.0          # half the village's width
const VN := D.VN          # the north wall (moved forward three paces in version 7.5)
const VS := 26.0          # the south wall
const GATE_Z := 2.0       # the west and east gateways
const KEEP_H := 3.3       # half the keep's width
const HILL := Vector3(0, 0, -116)
const X_MIN := -124.0
const X_MAX := 124.0
const Z_MIN := -62.0
const Z_MAX := 53.0

const C := {
	grass = Color("9dbf68"), grass2 = Color("90b45e"), grass3 = Color("a8c872"), vill = Color("b9c67d"),
	path = Color("dcc78e"), path2 = Color("cfb97f"), cream = Color("f0e3c3"), cream2 = Color("e4d2a8"),
	roof = Color("b0573c"), roof2 = Color("934834"), roof3 = Color("c0703f"), thatch = Color("cdb46a"),
	timber = Color("5b4130"), wood = Color("8b6b47"), wood2 = Color("7d5f3f"), wood3 = Color("98784f"),
	stone = Color("c3bcab"), stone2 = Color("a69f90"), stone3 = Color("8a8478"), slate = Color("67768b"),
	water = Color("6fb4c8"), water2 = Color("8fcbd8"), sand = Color("e3d6a4"),
	field1 = Color("d0b256"), field2 = Color("9c7d47"), field3 = Color("b9c66b"),
	castle = Color("7d778c"), castle2 = Color("686279"), croof = Color("4d3b69"),
	straw = Color("dcbc62"), iron = Color("70757f"), red = Color("b23a31"),
	leaf = Color("5d9349"), leaf2 = Color("6aa04e"), trunk = Color("6b4a2f"), grave = Color("8f8c95"),
	dead = Color("8c9a70"), dead2 = Color("7f8d68"), hedge = Color("3f6b3a"), hedge2 = Color("39603a"), hedge3 = Color("47753f"),
}

## Windows share one material, so the whole village lights up together at dusk.
var window_mat: StandardMaterial3D
## Lanterns that come on at night.
var lanterns: Array[OmniLight3D] = []
var rng := RandomNumberGenerator.new()
## The keep, which goes see-through when something is behind it (main.gd says when).
var keep: Node3D
var keep_window_mat: StandardMaterial3D
var _keep_mats: Array[StandardMaterial3D] = []
var _keep_alpha := 1.0

## The haunted ground round the castle: green fires and windows that glow at night (atmos.gd turns them up).
var haunt_lights: Array[OmniLight3D] = []
var haunt_mat: StandardMaterial3D
## The tops of the chimneys, for atmos.gd's smoke.
var chimneys: Array[Vector3] = []
var bell: Node3D                          # the village bell, which swings when rung
var dummies: Array[Node3D] = []           # the straw dummies in the training yard, which wobble when hit
var mill_sails: Node3D                    # the old mill's sails, turning slowly
var maypole: Node3D                       # the maypole's ribbons and crown, which turn in the breeze
var letter_paper: Node3D                  # the Lord's letter, nailed to the gatepost
var rider: Node3D                         # the headless rider who brings it
var _rider_t := -1.0
var _inn_fire: OmniLight3D                # the fire in the Thorny Rose
var _veins: Array = []                    # the rune veins in the old workings: [node, material, light]
var _raft: Node3D                         # the raft on the village bank, once it is built
var _raft_pile: Node3D                    # and the wood stacked for it until then
var _raft_flag: Node3D                    # the flag over its building site
var _raft_far: Node3D                     # the raft, tied up at the Riverside
var _rcave_props: Node3D                  # the Rune Cave's props, once it has been made fit to explore
var _seams: Array = []                    # its seams of runes: [node, material]
var _chickens: Array = []                 # the Riverside's hens: [node, where it is, where it is going, until the next peck]
var _cow: Node3D
var _donkey: Node3D
var _torch_flames: Array = []             # the hamlet's torches, lit at dusk
var _mine_glow: Array = []                 # the glow up the Old Mine's hole: [material, light]
var _cave_flames: Array = []              # the torches in the two caves, always lit: [flame, light]
var _twinkle: Array = []                  # something glinting behind a rock in the Rune Cave: [mesh, material]
var _rcave_boards: Node3D                 # the Rune Cave's mouth, boarded up until the shady fellow is paid
var _bonfire_flames: Array = []
var _bonfire_light: OmniLight3D
var _beast_t := [6.0, 11.0, 2.0]          # until the next moo, bray and cluck
var _evil: Array[Node3D] = []             # the castle's worse and worse looks, one set a week
var _evil_now := -1
var _castle_lit: StandardMaterial3D       # the one window that is always lit
var _lord_win: Node3D                     # (version 7.33) the Lord in that window
var _lord_wall: Node3D                    # and, in the last week, on the wall over the gate
var _lord_out := false                    # he is on the field tonight
var storm: Node3D                         # the sky turning over the castle, in the last week
var _storm_light: OmniLight3D
var night := 0.0                          # how dark it is (main.gd keeps this up to date)
var view_at := Vector3.ZERO               # where the view is looking (main.gd), for the crows and the things in the dark
var _bell_swing := 0.0
var _glass: Array = []                    # (version 7.37) the chapel's coloured windows: on the nights of the bells they blaze
var _chapel_lights: Array = []
var _spill: Array = []                    # the windows' colours on the grass: [mesh, material, which window]
var _bells_on := false
var _ducks: Array = []                    # the ducks on the pond: [node, phase, radius, speed]
var _pond := Vector3.ZERO
var _dummy_hit: Array[float] = [0.0, 0.0, 0.0]

var _log_xf: Array[Transform3D] = []
var _log_col: Array[Color] = []


func _ready() -> void:
	rng.seed = 1337
	window_mat = StandardMaterial3D.new()
	window_mat.albedo_color = Color("3a3f52")
	window_mat.emission_enabled = true
	window_mat.emission = Color("ff9a3c")
	window_mat.emission_energy_multiplier = 0.0
	_ground()
	_castle()
	_haunted()
	_graveyard_and_edges()
	_walls()
	_keep()
	_buildings()
	_green()
	_gatepost()
	_mine_room()
	_inn_room()
	_tcave_room()
	_rcave_room()
	_farms()
	_downs()
	_riverside()
	_ground_detail()
	_wilds()
	squire = Squire.new(); add_child(squire)     # (version 7.30) the library, the lane and the cabin
	add_child(Chapel.new())                      # (version 7.37) the inside of the chapel


## A fire in a brazier: flames that flicker (they are turned up at night with the lanterns), and the light.
var _brazier_flames: Array = []
func _brazier_fire(pos: Vector3, reach: float) -> void:
	var fm := StandardMaterial3D.new(); fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; fm.albedo_color = Color(1.0, 0.6, 0.2)
	var fm2 := StandardMaterial3D.new(); fm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; fm2.albedo_color = Color(1.0, 0.85, 0.35)
	for k in 3:
		var a := k * TAU / 3.0
		var f := Build.cone(self, 0.2, 0.55, pos + Vector3(cos(a) * 0.14, 0, sin(a) * 0.14), Color.WHITE, 5, a)
		f.material_override = fm if k != 1 else fm2
		_brazier_flames.append(f)
	var f2 := Build.cone(self, 0.16, 0.8, pos, Color.WHITE, 5); f2.material_override = fm2; _brazier_flames.append(f2)
	var l := OmniLight3D.new(); l.position = pos + Vector3(0, 0.6, 0); l.light_color = Color("ff9a48"); l.omni_range = reach
	l.omni_attenuation = 1.4; l.light_energy = 0.0; l.shadow_enabled = false; add_child(l); lanterns.append(l)


## A lantern on a crooked post, by a road.
func _lantern_post(at: Vector3, face: float) -> void:
	Build.box(self, Vector3(0.16, 2.7, 0.16), at, C.timber)
	Build.box(self, Vector3(0.8, 0.1, 0.1), at + Vector3(face * 0.34, 2.62, 0), C.timber)
	Build.box(self, Vector3(0.24, 0.1, 0.24), at, C.stone3)
	lantern(at + Vector3(face * 0.66, 1.92, 0), 11.0)


func rr(a: float, b: float) -> float:
	return rng.randf_range(a, b)


## A lantern: an iron frame round warm glass, and a light that main.gd turns up at night. (Version 7.25: it was a
## plain glowing box, which at night read as a white cube.)
func lantern(pos: Vector3, reach: float = 14.0) -> void:
	Build.glow_box(self, Vector3(0.3, 0.34, 0.3), pos + Vector3(0, 0.04, 0), window_mat)
	Build.box(self, Vector3(0.42, 0.06, 0.42), pos, C.iron)                                   # its base,
	Build.cone(self, 0.3, 0.16, pos + Vector3(0, 0.38, 0), C.iron, 4, PI / 4)                 # its little roof,
	Build.box(self, Vector3(0.08, 0.1, 0.08), pos + Vector3(0, 0.54, 0), C.iron)              # and a ring to hang it by
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]: Build.box(self, Vector3(0.04, 0.36, 0.04), pos + Vector3(sx * 0.17, 0.03, sz * 0.17), C.iron)
	var l := OmniLight3D.new()
	l.position = pos + Vector3(0, 0.3, 0)
	l.light_color = Color("ffc070")
	l.omni_range = reach
	l.omni_attenuation = 1.4
	l.light_energy = 0.0
	l.shadow_enabled = false
	add_child(l)
	lanterns.append(l)


func _ground() -> void:
	Build.box(self, Vector3(900, 1, 900), Vector3(0, -1, 0), C.grass)
	for i in 300:
		var s := rr(2.5, 7.5)
		Build.box(self, Vector3(s, 0.01 + i * 0.0001, s * rr(0.6, 1.5)), Vector3(rr(-175, 175), 0, rr(-150, 95)), C.grass2 if i % 2 else C.grass3, rr(0, 3))
	Build.box(self, Vector3(2 * VW, 0.045, VS - VN), Vector3(0, 0, (VS + VN) / 2.0), C.vill)
	# dead ground: everything beyond the stakes belongs to the castle
	Build.box(self, Vector3(420, 0.05, 104), Vector3(0, 0, -115.2), C.dead)
	for i in 70:
		var s := rr(3, 8)
		Build.box(self, Vector3(s, 0.055, s * rr(0.6, 1.4)), Vector3(rr(-130, 130), 0, rr(-150, -67)), C.dead2, rr(0, 3))
	Build.box(self, Vector3(6.5, 0.07, 56), Vector3(0, 0, -50), C.path)                    # the castle road
	Build.box(self, Vector3(6.5, 0.07, VS - VN), Vector3(0, 0, (VS + VN) / 2.0), C.path)   # the avenue through the village
	Build.box(self, Vector3(92, 0.07, 5), Vector3(0, 0, GATE_Z), C.path)                   # west gate to east gate
	Build.box(self, Vector3(15, 0.08, 12.6), Vector3.ZERO, C.path2)                        # the square round the keep
	for i in 70:
		var on_road := i % 2 == 1
		Build.box(self, Vector3(rr(0.4, 0.9), 0.085, rr(0.4, 0.9)), Vector3(rr(-2.8, 2.8) if on_road else rr(-44, 44), 0, rr(-76, 24) if on_road else GATE_Z + rr(-2, 2)), C.path2, rr(0, 3))
	_river()
	# (the jetty moves every morning: sites.gd draws it)


func _castle() -> void:
	Build.cyl(self, 30, 42, 7, HILL, Color("75855a"), 14)   # (version 7.24: duller, as befits it)
	Build.box(self, Vector3(6.5, 0.3, 14.4), Vector3(0, 3.42, -80.2), C.path2, 0.0, 0.53)
	Build.box(self, Vector3(6.5, 0.1, 22), Vector3(0, 7, -97.5), C.path2)
	var n := Node3D.new()
	n.position = HILL
	add_child(n)
	Build.box(n, Vector3(21, 8, 13), Vector3(0, 7, 0), C.castle)
	Build.box(n, Vector3(22, 1, 14), Vector3(0, 15, 0), C.castle2)
	for i in range(-4, 5):
		Build.box(n, Vector3(1.3, 1, 0.8), Vector3(i * 2.4, 16, 6.6), C.castle2)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Build.cyl(n, 3, 3.3, 13, Vector3(sx * 10.5, 7, sz * 6.5), C.castle2, 7)
			Build.cone(n, 3.9, 5.5, Vector3(sx * 10.5, 20, sz * 6.5), C.croof, 7)
	Build.box(n, Vector3(7, 16, 7), Vector3(0, 7, -1), C.castle)
	Build.cone(n, 5.6, 7.5, Vector3(0, 23, -1), C.croof, 4, PI / 4)
	Build.box(n, Vector3(3.8, 4.8, 0.4), Vector3(0, 7, 6.5), Color("231c2d"))
	# the one lit window, always lit
	var lit := StandardMaterial3D.new()
	lit.albedo_color = Color("ffe9a8")
	lit.emission_enabled = true
	lit.emission = Color("ffd070")
	lit.emission_energy_multiplier = 3.0
	Build.glow_box(n, Vector3(1.2, 1.9, 0.2), Vector3(0, 18.4, 2.56), lit)
	_castle_lit = lit
	# (version 7.33) and in it, small against the light, the Lord himself, looking down on the village. In the last week
	# he comes out on to the wall over the gate, with his goblet. Both are gone the night he comes down in person.
	Build.box(n, Vector3(1.9, 0.18, 0.8), Vector3(0, 18.22, 2.9), C.castle2)                     # a little balcony under the window
	for bx in [-0.85, 0.85]: Build.box(n, Vector3(0.12, 0.5, 0.12), Vector3(bx, 18.4, 3.22), C.castle2)
	Build.box(n, Vector3(1.9, 0.1, 0.12), Vector3(0, 18.85, 3.22), C.castle2)
	_lord_win = Models.lord_figure(); _lord_win.scale = Vector3.ONE * 0.62; _lord_win.position = Vector3(0, 18.4, 2.86); n.add_child(_lord_win)
	_lord_wall = Models.lord_figure(); _lord_wall.position = Vector3(0, 16.0, 6.05); _lord_wall.visible = false; n.add_child(_lord_wall)
	_evil_build(n)
	_hilltop()


## The castle's hilltop (version 7.24): it was bare grass. Now: dead turf, a ruined curtain wall, the Lord's own graveyard
## with its mausoleum, a dry fountain gone green, gargoyles and green-lit lanterns up the road, dead trees with crows on
## them, coffins waiting, bones, and a low mist.
func _hilltop() -> void:
	var top := HILL + Vector3(0, 7.0, 0)
	var n := Node3D.new(); n.position = top; add_child(n)
	var rg := RandomNumberGenerator.new(); rg.seed = 1313
	var r := func(a: float, b: float) -> float: return rg.randf_range(a, b)
	var stone := C.castle2
	var stone2 := Color("5a5466")
	var iron := Color("2c2c33")
	var bone := Color("e6dcc4")
	var free := func(x: float, z: float, pad: float) -> bool:      # off the castle, off the road, on the hill
		if absf(x) < 12.5 + pad and absf(z) < 8.5 + pad: return false
		if absf(x) < 4.2 + pad and z > 6.0: return false
		return Vector2(x, z).length() < 27.0 - pad
	Build.cyl(n, 29.6, 29.6, 0.04, Vector3(0, 0.0, 0), Color("6f7c5a"), 14)                  # the turf, gone grey
	for i in 26:
		var x: float = r.call(-26, 26); var z: float = r.call(-26, 26)
		if free.call(x, z, 0.0): Build.box(n, Vector3(r.call(2, 6), 0.05, r.call(1.5, 4)), Vector3(x, 0.02, z), [Color("5f6b4c"), Color("6a6250"), Color("7a8466")][i % 3], r.call(0, 3))
	# the curtain wall, mostly fallen: pieces in a ring, gaps, and a gateway where the road comes up
	for i in 22:
		var a := TAU * i / 22.0
		if absf(wrapf(a - PI / 2, -PI, PI)) < 0.35: continue                                  # the gateway, towards the village
		if i % 4 == 1: continue                                                               # where it has come down
		var rad := 21.0
		var x := cos(a) * rad
		var z := sin(a) * rad
		var h: float = r.call(1.2, 3.4)
		Build.box(n, Vector3(5.6, h, 1.2), Vector3(x, 0, z), stone if i % 2 else stone2, -a + PI / 2, 0.0, r.call(-0.06, 0.06))
		if h > 2.4:
			for c in 2: Build.box(n, Vector3(0.9, 0.6, 1.2), Vector3(x, h, z) + Vector3(-sin(a), 0, cos(a)) * (c * 2.2 - 1.1), stone2, -a + PI / 2)
		for k in 3: Build.box(n, Vector3(r.call(0.4, 0.9), r.call(0.3, 0.6), r.call(0.4, 0.8)), Vector3(x, 0, z) + Vector3(r.call(-2.5, 2.5), 0, r.call(-2.5, 2.5)), stone2, r.call(0, 3))
	for sx in [-1.0, 1.0]:                                                                    # the gateposts, with a skull on each
		Build.box(n, Vector3(1.4, 4.2, 1.4), Vector3(sx * 3.9, 0, 20.8), stone)
		Build.box(n, Vector3(1.7, 0.3, 1.7), Vector3(sx * 3.9, 4.2, 20.8), stone2)
		Build.box(n, Vector3(0.6, 0.55, 0.6), Vector3(sx * 3.9, 4.5, 20.8), bone)
		Build.box(n, Vector3(0.14, 0.14, 0.05), Vector3(sx * 3.9 - 0.14, 4.75, 21.11), Color("17131c"))
		Build.box(n, Vector3(0.14, 0.14, 0.05), Vector3(sx * 3.9 + 0.14, 4.75, 21.11), Color("17131c"))
	# gargoyles on plinths, and green-lit lanterns, up the road
	var gl := StandardMaterial3D.new(); gl.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; gl.albedo_color = Color(0.45, 1.0, 0.55)
	for row in 2:
		var gz := 12.0 + row * 5.5
		for sx in [-1.0, 1.0]:
			var gp := Node3D.new(); gp.position = Vector3(sx * 5.4, 0, gz); gp.rotation.y = -sx * 0.5; n.add_child(gp)
			Build.box(gp, Vector3(1.0, 1.3, 1.0), Vector3.ZERO, stone2)
			Build.box(gp, Vector3(0.6, 0.6, 0.8), Vector3(0, 1.3, 0), stone)                        # hunched
			Build.box(gp, Vector3(0.44, 0.4, 0.42), Vector3(0, 1.85, 0.22), stone)                  # a head, leaning out
			for ex in [-0.12, 0.12]: Build.box(gp, Vector3(0.08, 0.08, 0.04), Vector3(ex, 2.0, 0.44), Color(0.6, 1.0, 0.6)).material_override = gl
			for wx in [-1.0, 1.0]: Build.box(gp, Vector3(0.1, 0.7, 0.6), Vector3(wx * 0.38, 1.5, -0.1), stone2, 0.0, 0.3, wx * 0.5)   # wings
			for hx in [-0.14, 0.14]: Build.cone(gp, 0.06, 0.26, Vector3(hx, 2.04, 0.12), stone2, 4)   # horns
		var lp := Vector3(-4.6 if row == 0 else 4.6, 0, gz + 2.6)                              # a lantern on a crooked post
		Build.box(n, Vector3(0.16, 2.6, 0.16), lp, iron, 0.0, 0.0, 0.06)
		Build.box(n, Vector3(0.7, 0.1, 0.1), lp + Vector3(0.3, 2.5, 0), iron)
		Build.box(n, Vector3(0.36, 0.44, 0.36), lp + Vector3(0.6, 1.95, 0), iron)
		Build.cone(n, 0.12, 0.3, lp + Vector3(0.6, 2.0, 0), Color.WHITE, 5).material_override = gl
		var ll := OmniLight3D.new(); ll.light_color = Color(0.45, 1.0, 0.55); ll.omni_range = 5.0; ll.light_energy = 0.9
		ll.position = lp + Vector3(0.6, 2.1, 0); n.add_child(ll)
	# the Lord's graveyard, to the west, behind iron railings, with the family's mausoleum
	var gy := Vector3(-18.0, 0, 8.0)
	for i in 12:
		var hp_ := gy + Vector3(-4.0 + (i % 4) * 2.4 + r.call(-0.3, 0.3), 0, -3.0 + (i / 4) * 2.4 + r.call(-0.3, 0.3))
		var tall := i % 3 == 0
		Build.box(n, Vector3(0.7, 1.4 if tall else 0.9, 0.22), hp_, [stone, stone2, Color("8a8494")][i % 3], r.call(-0.25, 0.25), r.call(-0.25, 0.2), r.call(-0.2, 0.2))
		if tall: Build.box(n, Vector3(0.9, 0.18, 0.24), hp_ + Vector3(0, 1.05, 0), stone, 0.0, 0.0, r.call(-0.1, 0.1))   # a cross
		Build.box(n, Vector3(0.8, 0.08, 1.5), hp_ + Vector3(0, 0, 0.9), Color("4f4636"))             # the grave
	for i in 18:                                                                              # the railings round it
		var t := i / 17.0
		for side in [[Vector3(-6.0 + t * 12.0, 0, -4.8)], [Vector3(-6.0 + t * 12.0, 0, 5.0)], [Vector3(-6.0, 0, -4.8 + t * 9.8)], [Vector3(6.0, 0, -4.8 + t * 9.8)]]:
			if i % 6 == 2 and side[0].z > 4.0: continue
			Build.box(n, Vector3(0.06, 1.3, 0.06), gy + side[0], iron)
			Build.cone(n, 0.08, 0.18, gy + side[0] + Vector3(0, 1.3, 0), iron, 4)
	var mz := gy + Vector3(0, 0, -7.8)                                                       # the mausoleum
	Build.box(n, Vector3(4.6, 3.4, 3.6), mz, stone2)
	Build.box(n, Vector3(5.0, 0.4, 4.0), mz + Vector3(0, 3.4, 0), stone)
	Build.cone(n, 3.0, 1.6, mz + Vector3(0, 3.8, 0), C.croof, 4, PI / 4)
	Build.box(n, Vector3(1.4, 2.2, 0.1), mz + Vector3(0, 0, 1.82), Color("17131c"))
	for sx in [-1.0, 1.0]: Build.cyl(n, 0.25, 0.28, 3.2, mz + Vector3(sx * 1.6, 0, 2.0), stone, 6)
	var mg := OmniLight3D.new(); mg.light_color = Color(0.5, 1.0, 0.6); mg.omni_range = 3.0; mg.light_energy = 0.7
	mg.position = mz + Vector3(0, 1.0, 2.4); n.add_child(mg)
	# a dry fountain to the east, its last water gone green and glowing; coffins stacked by it
	var fz := Vector3(18.0, 0, 7.0)
	Build.cyl(n, 2.6, 2.8, 0.7, fz, stone2, 10)
	var wm := StandardMaterial3D.new(); wm.albedo_color = Color(0.25, 0.5, 0.3); wm.emission_enabled = true; wm.emission = Color(0.3, 0.9, 0.4); wm.emission_energy_multiplier = 0.8
	var wt := Build.cyl(n, 2.3, 2.3, 0.08, fz + Vector3(0, 0.55, 0), Color.WHITE, 10); wt.material_override = wm
	Build.cyl(n, 0.35, 0.45, 2.0, fz, stone, 6)
	Build.cyl(n, 0.9, 0.5, 0.3, fz + Vector3(0, 2.0, 0), stone, 8)
	Build.box(n, Vector3(0.4, 0.5, 0.5), fz + Vector3(0, 2.3, 0), stone2)                       # a small gargoyle that used to spit water, and now just looks
	var fl := OmniLight3D.new(); fl.light_color = Color(0.4, 1.0, 0.5); fl.omni_range = 5.0; fl.light_energy = 0.8
	fl.position = fz + Vector3(0, 1.0, 0); n.add_child(fl)
	for i in 5:                                                                               # coffins, some stood up, waiting
		var up := i >= 3
		var cp := fz + Vector3(4.0 + (i % 3) * 0.9, 0.0 if up else (i / 1) * 0.0 + 0.0, -4.0 + (i % 3) * 0.2) if not up else fz + Vector3(-3.6 + (i - 3) * 1.1, 0, -4.6)
		if up: Build.box(n, Vector3(0.75, 2.0, 0.42), cp, Color("3b2a22"), r.call(-0.3, 0.3), -0.1)
		else: Build.box(n, Vector3(0.8, 0.45, 2.0), cp + Vector3(0, i * 0.45 if i < 2 else 0.0, 0), Color("4a3428"), r.call(-0.1, 0.1))
	# dead trees round the back, with crows sitting in them
	var bark := Color("2e2620")
	for i in 9:
		var a: float = -PI / 2 + r.call(-1.3, 1.3)
		var tp := Vector3(cos(a) * float(r.call(14.0, 25.0)), 0, sin(a) * float(r.call(11.0, 24.0)))
		if not free.call(tp.x, tp.z, 0.5): continue
		var tr := Node3D.new(); tr.position = tp; tr.rotation = Vector3(0, r.call(0, TAU), r.call(-0.15, 0.15)); n.add_child(tr)
		var h: float = r.call(3.0, 5.2)
		Build.cyl(tr, 0.15, 0.36, h, Vector3.ZERO, bark, 5)
		for b in 3:
			var br := Node3D.new(); br.position = Vector3(0, h * r.call(0.5, 0.95), 0); br.rotation = Vector3(0, r.call(0, TAU), r.call(0.6, 1.1)); tr.add_child(br)
			var bl: float = r.call(1.0, 2.0)
			Build.cyl(br, 0.04, 0.1, bl, Vector3.ZERO, bark, 4)
			if b == 0 and i % 2 == 0:                                                            # a crow
				Build.box(br, Vector3(0.2, 0.22, 0.34), Vector3(0, bl * 0.8, 0), Color("141018"))
				Build.box(br, Vector3(0.12, 0.12, 0.14), Vector3(0, bl * 0.8 + 0.18, 0.16), Color("141018"))
	# bones in the grass, and a low mist that lies on the hilltop
	for i in 30:
		var x: float = r.call(-25, 25); var z: float = r.call(-25, 25)
		if free.call(x, z, 0.0): Build.box(n, Vector3(0.5, 0.08, 0.1), Vector3(x, 0.04, z), bone, r.call(0, 3))
	var mist := StandardMaterial3D.new(); mist.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mist.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist.albedo_color = Color(0.82, 0.9, 0.84, 0.07); mist.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in 14:
		var x: float = r.call(-24, 24); var z: float = r.call(-24, 24)
		if Vector2(x, z).length() < 26: Build.glow_box(n, Vector3(r.call(5, 10), 0.6, r.call(4, 8)), Vector3(x, 0.05, z), mist, r.call(0, 3))


## Ashhollow gets worse as the month goes on. Three sets of things, hidden to begin with: one more is shown each week.
func _evil_build(n: Node3D) -> void:
	var red := Color("8e1f25")
	var bone := Color("efe6cf")
	var black := Color("17131c")
	for i in 3:
		var g := Node3D.new()
		g.visible = false
		n.add_child(g)
		_evil.append(g)
	# week 2: the Lord's banners on the front wall (a white stag on red), and green fire along the battlements
	for sx in [-1.0, 1.0]:
		var bx: float = sx * 6.4
		Build.box(_evil[0], Vector3(2.3, 5.6, 0.12), Vector3(bx, 8.6, 6.62), red)
		Build.box(_evil[0], Vector3(0.9, 0.5, 0.14), Vector3(bx - 0.5, 8.3, 6.62), red, 0, 0, 0.78)      # the swallow tail
		Build.box(_evil[0], Vector3(0.9, 0.5, 0.14), Vector3(bx + 0.5, 8.3, 6.62), red, 0, 0, -0.78)
		Build.box(_evil[0], Vector3(0.5, 0.75, 0.05), Vector3(bx, 10.6, 6.7), bone)                        # the stag's head
		Build.box(_evil[0], Vector3(0.3, 0.35, 0.05), Vector3(bx, 10.35, 6.7), bone)
		for ax in [-1.0, 1.0]:                                                                              # and antlers
			Build.box(_evil[0], Vector3(0.1, 0.95, 0.05), Vector3(bx + ax * 0.34, 11.3, 6.7), bone, 0, 0, -ax * 0.45)
			Build.box(_evil[0], Vector3(0.08, 0.45, 0.05), Vector3(bx + ax * 0.72, 11.75, 6.7), bone, 0, 0, ax * 0.5)
			Build.box(_evil[0], Vector3(0.08, 0.4, 0.05), Vector3(bx + ax * 0.5, 11.85, 6.7), bone, 0, 0, -ax * 0.1)
	var fire := StandardMaterial3D.new()
	fire.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fire.albedo_color = Color(0.45, 1.0, 0.55)
	for fx_ in [-8.4, -3.6, 3.6, 8.4]:
		Build.cyl(_evil[0], 0.45, 0.3, 0.6, Vector3(fx_, 16.4, 6.6), black, 6)
		Build.cone(_evil[0], 0.4, 1.1, Vector3(fx_, 17.0, 6.6), Color.WHITE, 5).material_override = fire
	for sx in [-1.0, 1.0]:
		var l := OmniLight3D.new()
		l.position = Vector3(sx * 6.0, 18.5, 8.0)
		l.light_color = Color(0.4, 1.0, 0.5)
		l.omni_range = 22.0
		l.light_energy = 0.5
		_evil[0].add_child(l)
		haunt_lights.append(l)
	# week 3: thorns as tall as trees, up round the hill and out of the walls
	var rng3 := RandomNumberGenerator.new()
	rng3.seed = 1313
	for i in 22:
		var a := TAU * i / 22.0 + rng3.randf_range(-0.1, 0.1)
		var rad := rng3.randf_range(31.0, 39.0)
		var p := Vector3(cos(a) * rad, 0, sin(a) * rad)
		if absf(p.x) < 6 and p.z > 0: continue                         # not across the road
		var h := rng3.randf_range(7.0, 13.0)
		Build.cone(_evil[1], rng3.randf_range(0.7, 1.2), h, Vector3(p.x, -1.0, p.z), Color("33203a"), 5, rng3.randf() * TAU)
		Build.cone(_evil[1], 0.35, h * 0.45, Vector3(p.x + rng3.randf_range(-1.6, 1.6), -0.5, p.z + rng3.randf_range(-1.6, 1.6)), Color("241a2c"), 4)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Build.cone(_evil[1], 0.5, 6.0, Vector3(sx * 13.6, 9.0, sz * 6.5), black, 4)
			Build.cone(_evil[1], 0.4, 4.5, Vector3(sx * 10.5, 14.0, sz * 9.6), black, 4)
	# week 4: a black spire on the keep, and the sky turning over it
	Build.cone(_evil[2], 1.5, 13.0, Vector3(0, 28.5, -1), black, 4, PI / 4)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Build.cone(_evil[2], 0.9, 7.0, Vector3(sx * 10.5, 24.0, sz * 6.5), black, 5)
	storm = Node3D.new()
	storm.position = Vector3(0, 40, -1)
	_evil[2].add_child(storm)
	var cloud := StandardMaterial3D.new()
	cloud.albedo_color = Color(0.34, 0.07, 0.1, 0.88)
	cloud.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 16:
		var a := TAU * i / 16.0
		var rad := 19.0 if i % 2 else 12.0
		var c := Build.box(storm, Vector3(rng3.randf_range(7, 11), rng3.randf_range(1.2, 2.2), rng3.randf_range(4, 6)), Vector3(cos(a) * rad, rng3.randf_range(-1.5, 1.5), sin(a) * rad), Color.WHITE, -a)
		c.material_override = cloud
	_storm_light = OmniLight3D.new()
	_storm_light.light_color = Color(1.0, 0.2, 0.2)
	_storm_light.omni_range = 46.0
	_storm_light.light_energy = 0.0
	_storm_light.position = Vector3(0, 36, -1)
	_evil[2].add_child(_storm_light)


## The Lord has come down in person (main.gd): he is not at his window, nor on his wall.
func set_lord_out(out: bool) -> void:
	_lord_out = out
	if _lord_win: _lord_win.visible = not out and _evil_now < 3      # (version 7.34) one Lord at a time: in the last week he has left the window for the wall
	if _lord_wall: _lord_wall.visible = not out and _evil_now >= 3

func _lord_step(delta: float) -> void:                 # at the window he turns a little, now and then; on the wall he raises his goblet to you
	if _lord_win and _lord_win.visible:
		_lord_win.rotation.y = 0.25 * sin(Time.get_ticks_msec() / 1000.0 * 0.21)
		(_lord_win.get_node("ArmR") as Node3D).rotation.x = -0.6; Models.keep_goblet(_lord_win)
	if _lord_wall and _lord_wall.visible:
		var t := Time.get_ticks_msec() / 1000.0
		var raise := pow(maxf(0.0, sin(t * 0.45)), 8.0)
		(_lord_wall.get_node("ArmR") as Node3D).rotation.x = -0.5 - 1.6 * raise
		(_lord_wall.get_node("ArmL") as Node3D).rotation.x = -0.2 * sin(t * 0.3)
		(_lord_wall.get_node("Cloak") as Node3D).rotation.x = 0.15 + 0.08 * sin(t * 1.1)
		_lord_wall.rotation.y = 0.35 * sin(t * 0.13)
		Models.keep_goblet(_lord_wall)

## How far gone the castle is: 0 in the first week, to 3 in the last.
func set_evil(level: int) -> void:
	if level == _evil_now: return
	_evil_now = level
	for i in _evil.size(): _evil[i].visible = level > i
	if _lord_wall: _lord_wall.visible = not _lord_out and level >= 3
	if _lord_win: _lord_win.visible = not _lord_out and level < 3
	if haunt_mat: haunt_mat.emission = [Color("b45cff"), Color("b45cff"), Color("d0406a"), Color("ff2a2a")][clampi(level, 0, 3)]
	if _castle_lit:
		_castle_lit.albedo_color = Color("ff5a4a") if level >= 3 else Color("ffe9a8")
		_castle_lit.emission = Color("ff2a1a") if level >= 3 else Color("ffd070")


## Between the stakes and the castle: dead trees, a gibbet by the road, broken railings, toppled stones, and at
## the castle gate two braziers of green fire. The castle's narrow windows glow a sickly purple after dark.
func _haunted() -> void:
	var bark := Color("2e2620")
	var bark2 := Color("3b3029")
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 666
	var placed := 0
	var tries := 0
	while placed < 34 and tries < 400:
		tries += 1
		var x := rng2.randf_range(-78, 78)
		var z := rng2.randf_range(-108, -76)
		if absf(x) < 7: continue                                                  # keep the road clear
		if Vector2(x, z).distance_to(Vector2(HILL.x, HILL.z)) < 31: continue      # not on the castle's own hilltop
		var h := rng2.randf_range(2.6, 4.8)
		var lean := rng2.randf_range(-0.18, 0.18)
		var t := Node3D.new()
		t.position = Vector3(x, 0, z)
		t.rotation = Vector3(0, rng2.randf_range(0, TAU), lean)
		add_child(t)
		Build.cyl(t, 0.14, 0.34, h, Vector3.ZERO, bark, 5)
		for b in rng2.randi_range(2, 4):                                          # crooked bare branches
			var by := h * rng2.randf_range(0.45, 0.95)
			var ang := rng2.randf_range(0, TAU)
			var br := Node3D.new()
			br.position = Vector3(0, by, 0)
			br.rotation = Vector3(0, ang, rng2.randf_range(0.6, 1.1))
			t.add_child(br)
			var bl := rng2.randf_range(0.9, 1.9)
			Build.cyl(br, 0.04, 0.1, bl, Vector3.ZERO, bark2, 4)
			var tw := Node3D.new(); tw.position = Vector3(0, bl, 0); tw.rotation.z = rng2.randf_range(-0.9, 0.9); br.add_child(tw)
			Build.cyl(tw, 0.02, 0.05, bl * 0.6, Vector3.ZERO, bark2, 4)
		placed += 1
	# a gibbet by the road, with an empty cage that turns in the wind (it is empty. Probably.)
	Build.box(self, Vector3(0.3, 5.2, 0.3), Vector3(-6.2, 0, -84), bark)
	Build.box(self, Vector3(2.4, 0.26, 0.26), Vector3(-5.1, 5.0, -84), bark)
	Build.box(self, Vector3(0.18, 1.2, 0.18), Vector3(-5.9, 4.0, -84), bark, 0.0, 0.0, -0.8)
	var cage := Node3D.new(); cage.position = Vector3(-4.2, 2.6, -84); add_child(cage)
	for a in 6:
		var v := Vector3(cos(a * TAU / 6) * 0.42, 0, sin(a * TAU / 6) * 0.42)
		Build.box(cage, Vector3(0.05, 1.5, 0.05), v, Color("3a3a40"))
	Build.cyl(cage, 0.5, 0.5, 0.06, Vector3(0, 0, 0), Color("3a3a40"), 6)
	Build.cone(cage, 0.5, 0.5, Vector3(0, 1.5, 0), Color("3a3a40"), 6)
	Build.box(self, Vector3(0.04, 1.0, 0.04), Vector3(-4.2, 4.0, -84), Color("3a3a40"))
	# broken iron railings along the foot of the hill
	for i in 26:
		if i % 5 == 3: continue                                                   # gaps where it has fallen
		var a := PI * (0.12 + i * 0.03)
		var x := HILL.x + cos(a + PI) * 44.5
		var z := HILL.z - sin(a + PI) * 44.5
		if absf(x) < 5: continue
		Build.box(self, Vector3(0.08, rr(1.0, 1.8), 0.08), Vector3(x, 0, z), Color("2c2c33"), 0.0, rr(-0.25, 0.25), rr(-0.25, 0.25))
		Build.cone(self, 0.1, 0.25, Vector3(x, 1.8, z), Color("2c2c33"), 4)
	# braziers of green fire either side of the castle gate
	for sx in [-1.0, 1.0]:
		var bp := HILL + Vector3(sx * 4.2, 7.0, 9.6)
		Build.cyl(self, 0.6, 0.35, 1.1, bp, Color("2c2c33"), 6)
		var fire := StandardMaterial3D.new()
		fire.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fire.albedo_color = Color(0.45, 1.0, 0.55)
		Build.cone(self, 0.45, 1.0, bp + Vector3(0, 1.1, 0), Color.WHITE, 5).material_override = fire
		var l := OmniLight3D.new()
		l.position = bp + Vector3(0, 2.0, 0)
		l.light_color = Color(0.4, 1.0, 0.5)
		l.omni_range = 16.0
		l.light_energy = 0.5
		add_child(l)
		haunt_lights.append(l)
	# the castle's windows: dark by day, a sickly purple by night
	haunt_mat = StandardMaterial3D.new()
	haunt_mat.albedo_color = Color("2a1f38")
	haunt_mat.emission_enabled = true
	haunt_mat.emission = Color("b45cff")
	haunt_mat.emission_energy_multiplier = 0.2
	var hn := Node3D.new(); hn.position = HILL; add_child(hn)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			for wy in [10.5, 14.5]:
				var wn := Node3D.new(); wn.position = Vector3(sx * 10.5, 0, sz * 6.5); wn.rotation.y = atan2(sx, sz); hn.add_child(wn)
				Build.glow_box(wn, Vector3(0.45, 1.3, 0.2), Vector3(0, wy, 3.05), haunt_mat)
	for wx in [-6.0, -3.0, 3.0, 6.0]:
		Build.glow_box(hn, Vector3(0.6, 1.4, 0.2), Vector3(wx, 10.5, 6.55), haunt_mat)


func _graveyard_and_edges() -> void:
	for i in 40:
		var sd := 1.0 if i % 2 else -1.0
		var x := sd * rr(4.5, 35)
		var z := rr(-73, -64.2)
		var ry := rr(-0.3, 0.3)
		Build.box(self, Vector3(0.75, rr(0.8, 1.2), 0.24), Vector3(x, 0, z), C.grave, ry, 0.0, rr(-0.12, 0.12))
		if i % 3 == 0:
			Build.box(self, Vector3(0.16, 1.5, 0.16), Vector3(x + 1.6, 0, z + 0.8), C.grave, ry)
			Build.box(self, Vector3(0.7, 0.16, 0.16), Vector3(x + 1.6, 1, z + 0.8), C.grave, ry)
		if i % 5 == 0:
			Build.box(self, Vector3(1.1, 0.07, 2.1), Vector3(x, 0, z + 1.4), Color("6f6a5c"), ry)
	for p in [Vector2(-11, -67), Vector2(12.5, -71), Vector2(-27, -70), Vector2(29, -66.5), Vector2(-33, -65)]:
		Build.cyl(self, 0.18, 0.34, 2.6, Vector3(p.x, 0, p.y), Color("4a3b33"), 5)
		Build.box(self, Vector3(0.14, 1.3, 0.14), Vector3(p.x + 0.4, 1.9, p.y), Color("4a3b33"), 0.0, 0.0, -0.8)
		Build.box(self, Vector3(0.12, 1.1, 0.12), Vector3(p.x - 0.35, 2.1, p.y), Color("4a3b33"), 0.0, 0.0, 0.7)
	# north: a line of warning stakes
	var sx_ := -122.0
	while sx_ <= 122.0:
		if absf(sx_) >= 4.0:
			var lean := rr(-0.16, 0.16)
			Build.cyl(self, 0.09, 0.13, 2, Vector3(sx_, 0, -62.8), Color("4a3b33"), 5, rr(0, 3), 0.0, lean)
			Build.box(self, Vector3(0.34, 0.3, 0.32), Vector3(sx_ - lean * 1.9, 1.95, -62.8), Color("e9e4cf"), rr(-0.5, 0.5))
		sx_ += 4.5
	# west and east: the thorn hedge the village is named for (version 7.26: bushes, drawn in _wilds)


## A run of sharpened palisade logs, gathered up and drawn in one go at the end.
func _logs(x0: float, z0: float, x1: float, z1: float) -> void:
	var length := Vector2(x1 - x0, z1 - z0).length()
	var n: int = maxi(1, roundi(length / 0.78))
	for i in n:
		var f := (i + 0.5) / n
		var h := 2.55 + ((i * 7) % 5) * 0.08
		var xf := Transform3D(Basis(Vector3.UP, i * 1.3).scaled(Vector3(1, h, 1)), Vector3(lerpf(x0, x1, f), 0, lerpf(z0, z1, f)))
		_log_xf.append(xf)
		_log_col.append([C.wood, C.wood2, C.wood3][i % 3])


func _wall(x0: float, z0: float, x1: float, z1: float) -> void:
	_logs(x0, z0, x1, z1)


func _gateway(pos: Vector3, rot_y: float, lit_side: float) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = rot_y
	add_child(n)
	for e in [-1.0, 1.0]:
		Build.box(n, Vector3(0.8, 3.8, 1), Vector3(e * 3, 0, 0), C.timber)
	Build.box(n, Vector3(7, 0.55, 1.1), Vector3(0, 3.8, 0), C.timber)
	Build.roof(n, 1.9, 0.8, 7.4, Vector3(0, 4.35, 0), C.roof2, PI / 2)
	lantern(pos + Vector3(0, 2.6, 0) + Vector3(sin(rot_y), 0, cos(rot_y)) * lit_side, 12.0)


func _walls() -> void:
	# the north side: the permanent stretches at the corners. The seven foundations between are built in play (defences.gd).
	_wall(-VW, VN, -21, VN)
	_wall(21, VN, VW, VN)
	_wall(-VW, VN, -VW, GATE_Z - 3)
	_wall(-VW, GATE_Z + 3, -VW, VS)
	_wall(VW, VN, VW, GATE_Z - 3)
	_wall(VW, GATE_Z + 3, VW, VS)
	_wall(-VW, VS, VW, VS)
	_gateway(Vector3(-VW, 0, GATE_Z), PI / 2, -0.9)
	_gateway(Vector3(VW, 0, GATE_Z), PI / 2, 0.9)
	# two braziers on the road outside the north gate (version 7.25: with a fire in them, not a white box)
	for s in [-1.0, 1.0]:
		Build.cyl(self, 0.3, 0.42, 1.5, Vector3(s * 4.4, 0, VN - 2.6), C.stone3, 6)
		Build.cyl(self, 0.55, 0.34, 0.4, Vector3(s * 4.4, 1.5, VN - 2.6), C.iron, 6)
		_brazier_fire(Vector3(s * 4.4, 1.85, VN - 2.6), 16.0)
	# (version 7.25) lantern posts along the roads, so the village has some light to fight in after dark
	for lp in [[-4.1, -19.5, 1.0], [4.1, -12.5, -1.0], [-12.0, 4.9, 1.0], [12.0, 4.9, -1.0], [-22.0, -0.9, 1.0], [22.0, -0.9, -1.0], [-3.9, 21.5, 1.0], [3.9, 21.5, -1.0]]:
		_lantern_post(Vector3(lp[0], 0, lp[1]), lp[2])
	# draw every log at once
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.36
	trunk.bottom_radius = 0.4
	trunk.height = 1.0
	trunk.radial_segments = 5
	trunk.rings = 1
	var tip := CylinderMesh.new()
	tip.top_radius = 0.0
	tip.bottom_radius = 0.38
	tip.height = 0.6
	tip.radial_segments = 5
	tip.rings = 1
	var trunk_xf: Array[Transform3D] = []
	var tip_xf: Array[Transform3D] = []
	for xf in _log_xf:
		var h := xf.basis.get_scale().y
		trunk_xf.append(Transform3D(xf.basis, xf.origin + Vector3(0, h * 0.5, 0)))
		tip_xf.append(Transform3D(Basis(Vector3.UP, 0.0), xf.origin + Vector3(0, h + 0.3, 0)))
	_multi(trunk, trunk_xf, _log_col)
	_multi(tip, tip_xf, _log_col)


## Many copies of one mesh, each with its own place and colour.
## Small things on the ground (version 7.16), so the open grass is not one flat green: tufts of grass, pebbles,
## flowers, bare patches of earth, little bushes, and toadstools in the forest. A handful of shared meshes, drawn many
## times each; nothing to bump into. Fewer in the village and the hamlet, none on the roads, the fields or the river.
func _ground_detail() -> void:
	var rg := RandomNumberGenerator.new()
	rg.seed = 7160
	var cs := Map.colliders()
	var clear := func(x: float, z: float, r: float) -> bool:   # not inside anything built
		for c: E.Box in cs:
			if absf(x - c.x) < c.hw + r and absf(z - c.z) < c.hd + r: return false
		return true
	var main_ok := func(x: float, z: float) -> bool:
		if x < D.X0 + 1 or x > D.X1 - 1 or z < D.Z0 + 2 or z > 52.5: return false
		if absf(x) < 3.6 and z < D.VN: return false                                      # the castle road
		if absf(z - D.GATE_Z) < 2.6: return false                                         # the gate roads (version 7.27: all the way to the edges)
		if x > D.FARM.x0 - 1 and x < D.FARM.x1 + 1 and z > D.FARM.z0 - 1 and z < D.FARM.z1 + 1: return false
		if Vector2(x, z).distance_to(D.HILL) < 30: return false                          # the castle
		if Vector2(x - D.MILL.x, z - D.MILL.z).length() < 4.5: return false
		var inside := x > -D.VW and x < D.VW and z > D.VN and z < D.VS
		if inside and (rg.randf() < 0.7 or absf(x) < 4.5): return false                  # the village: a few, round the edges
		return clear.call(x, z, 0.5)
	var RM: Dictionary = D.ROOMS.riverside
	var river_ok := func(x: float, z: float) -> bool:
		if absf(x - RM.x) > RM.hw - 0.5 or z < RM.z - RM.hd + 3 or z > RM.z + RM.hd - 0.5: return false
		if absf(x + 160.0) < 2.6 and z > 324: return false                                # the road south
		if x > -128 and x < -116 and z > 328: return false                                # the fields
		var inside := x > -178 and x < -142 and z > 296 and z < 326
		if inside and rg.randf() < 0.65: return false
		for b in RM.box:
			if absf(x - b[0]) < b[2] + 0.5 and absf(z - b[1]) < b[3] + 0.5: return false
		return true
	var spots := func(n: int, ok_: Callable, x0: float, x1: float, z0: float, z1: float) -> Array:
		var out := []
		for t in n * 3:
			if out.size() >= n: break
			var x := rg.randf_range(x0, x1)
			var z := rg.randf_range(z0, z1)
			if ok_.call(x, z): out.append(Vector2(x, z))
		return out
	var areas := [[main_ok, D.X0, D.X1, D.Z0, 53.0, 1.0], [river_ok, RM.x - RM.hw, RM.x + RM.hw, RM.z - RM.hd, RM.z + RM.hd, 0.28]]
	var tuft := PrismMesh.new(); tuft.size = Vector3(0.36, 0.42, 0.12)
	var pebble := BoxMesh.new(); pebble.size = Vector3(0.3, 0.12, 0.24)
	var stem := BoxMesh.new(); stem.size = Vector3(0.04, 0.26, 0.04)
	var petal := BoxMesh.new(); petal.size = Vector3(0.14, 0.08, 0.14)
	var dirt := CylinderMesh.new(); dirt.top_radius = 0.5; dirt.bottom_radius = 0.5; dirt.height = 0.025; dirt.radial_segments = 7; dirt.rings = 1
	var bush := SphereMesh.new(); bush.radius = 0.5; bush.height = 0.7; bush.radial_segments = 7; bush.rings = 3
	var cap := CylinderMesh.new(); cap.top_radius = 0.04; cap.bottom_radius = 0.2; cap.height = 0.14; cap.radial_segments = 7
	var mstem := CylinderMesh.new(); mstem.top_radius = 0.05; mstem.bottom_radius = 0.06; mstem.height = 0.18; mstem.radial_segments = 6
	var lists := {"tuft": [[], []], "pebble": [[], []], "stem": [[], []], "petal": [[], []], "dirt": [[], []], "bush": [[], []], "cap": [[], []], "mstem": [[], []]}
	var put := func(k: String, xf: Transform3D, c: Color) -> void:
		lists[k][0].append(xf); lists[k][1].append(c)
	var flowers := [Color("f2c94c"), Color("f6f0ff"), Color("e05a7a"), Color("b36ad8"), Color("6aa8f0"), Color("f08a3a")]
	for A in areas:
		var f: float = A[5]
		for p in spots.call(int(1275 * f), A[0], A[1], A[2], A[3], A[4]):            # tufts of grass, in little clumps
			for j in 3:
				var h := rg.randf_range(0.7, 1.4)
				put.call("tuft", Transform3D(Basis.from_euler(Vector3(0, rg.randf() * TAU, rg.randf_range(-0.2, 0.2))).scaled(Vector3(1, h, 1)), Vector3(p.x + rg.randf_range(-0.3, 0.3), 0.2 * h, p.y + rg.randf_range(-0.3, 0.3))),
					[Color("6f9a3e"), Color("83ad4c"), Color("9cbf5e"), Color("7a9440")][j % 4])
		for p in spots.call(int(490 * f), A[0], A[1], A[2], A[3], A[4]):               # pebbles
			var s := rg.randf_range(0.6, 1.5)
			put.call("pebble", Transform3D(Basis.from_euler(Vector3(rg.randf_range(-0.2, 0.2), rg.randf() * TAU, 0)).scaled(Vector3(s, s, s)), Vector3(p.x, 0.04 * s, p.y)), [Color("a69f90"), Color("c3bcab"), Color("8a8478")][rg.randi() % 3])
		for p in spots.call(int(285 * f), A[0], A[1], A[2], A[3], A[4]):               # flowers, a few together and all of a colour
			var col: Color = flowers[rg.randi() % flowers.size()]
			for j in rg.randi_range(2, 5):
				var at := Vector3(p.x + rg.randf_range(-0.6, 0.6), 0, p.y + rg.randf_range(-0.6, 0.6))
				put.call("stem", Transform3D(Basis(), at + Vector3(0, 0.13, 0)), Color("5d8a3a"))
				put.call("petal", Transform3D(Basis.from_euler(Vector3(0, rg.randf() * TAU, 0)), at + Vector3(0, 0.28, 0)), col)
		for p in spots.call(int(105 * f), A[0], A[1], A[2], A[3], A[4]):               # bare earth
			var s := Vector3(rg.randf_range(0.9, 2.0), 1, rg.randf_range(0.7, 1.5))
			put.call("dirt", Transform3D(Basis.from_euler(Vector3(0, rg.randf() * TAU, 0)).scaled(s), Vector3(p.x, 0.02, p.y)), [Color("9c7d47"), Color("a88a55"), Color("8a6e40")][rg.randi() % 3])
		for p in spots.call(int(112 * f), A[0], A[1], A[2], A[3], A[4]):               # little bushes
			var s := rg.randf_range(0.6, 1.3)
			put.call("bush", Transform3D(Basis.from_euler(Vector3(0, rg.randf() * TAU, 0)).scaled(Vector3(s * 1.2, s, s)), Vector3(p.x, 0.22 * s, p.y)), [C.leaf, C.leaf2, C.hedge3][rg.randi() % 3])
	var trees_ := Map.trees()                                                           # toadstools, by the trees of the forest
	for k in 82:
		var t: E.Trunk = trees_[rg.randi() % trees_.size()]
		if t.x > -34: continue
		var a := rg.randf() * TAU
		var at := Vector3(t.x + cos(a) * rg.randf_range(0.9, 1.6), 0, t.z + sin(a) * rg.randf_range(0.9, 1.6))
		for j in rg.randi_range(1, 3):
			var o := at + Vector3(rg.randf_range(-0.3, 0.3), 0, rg.randf_range(-0.3, 0.3))
			var s := rg.randf_range(0.7, 1.3)
			var red := rg.randf() < 0.6
			put.call("mstem", Transform3D(Basis().scaled(Vector3(s, s, s)), o + Vector3(0, 0.09 * s, 0)), Color("efe6cf"))
			put.call("cap", Transform3D(Basis().scaled(Vector3(s, s, s)), o + Vector3(0, 0.22 * s, 0)), Color("c0262e") if red else Color("b08a5a"))
	var meshes := {"tuft": tuft, "pebble": pebble, "stem": stem, "petal": petal, "dirt": dirt, "bush": bush, "cap": cap, "mstem": mstem}
	for k in lists:
		var xf: Array[Transform3D] = []
		var cl: Array[Color] = []
		xf.assign(lists[k][0]); cl.assign(lists[k][1])
		if xf.size(): _multi(meshes[k], xf, cl, 0.3 if k == "tuft" else 0.0, 0.21 if k == "tuft" else 0.0)   # (version 7.27: the grass moves)


## The country beyond the edges (version 7.26): it was flat empty grass to the horizon, and at the Riverside a sharp line
## where the fields stopped. Now: woods thick on both sides of the village, the far bank of the river in fields and
## hedgerows with a farm or two, the dead wood and a ridge of hills beyond the castle, and the Riverside ringed with woods.
## All of it is out of reach and out of the way: none of it is in the rules.
func _wilds() -> void:
	var rg := RandomNumberGenerator.new(); rg.seed = 7260
	var r := func(a: float, b: float) -> float: return rg.randf_range(a, b)
	var kinds := ["wild_pine", "wild_oak", "wild_dead", "wild_bush", "wild_rock", "wild_cottage", "wild_barn", "wild_hay", "wild_tuft", "wild_flowers"]
	var xs := {}
	var cs := {}
	for k in kinds:
		var a1: Array[Transform3D] = []
		var a2: Array[Color] = []
		xs[k] = a1; cs[k] = a2
	var put := func(k: String, x: float, z: float, s: float, ry: float = -1.0, tint: Color = Color.WHITE) -> void:
		var b := Basis(Vector3.UP, ry if ry >= 0.0 else rg.randf() * TAU).scaled(Vector3.ONE * s)
		(xs[k] as Array[Transform3D]).append(Transform3D(b, Vector3(x, 0, z)))
		var t: float = r.call(0.85, 1.08)
		(cs[k] as Array[Color]).append(Color(tint.r * t, tint.g * t, tint.b * t))
	var RM: Dictionary = D.ROOMS.riverside
	var clear := func(x: float, z: float) -> bool:                    # never on the ground anybody walks on, nor in a river
		if x > D.X0 - 3 and x < D.X1 + 3 and z > D.Z0 - 4 and z < 56: return false          # the main map
		if z > 54 and z < 76: return false                                                     # its river
		if x > RM.x - RM.hw - 6 and x < RM.x + RM.hw + 6 and z > RM.z - RM.hd - 18 and z < RM.z + RM.hd + 6: return false   # the Riverside and its own fields
		if absf(x - RM.x) < 6 and z > RM.z + RM.hd and z < RM.z + RM.hd + 80: return false   # the road south to Hallowshire Town
		if absf(z - D.GATE_Z) < 4.0: return false                                              # the west and east roads, on into the woods
		for rk_ in D.ROOMS:                                                                    # (version 7.32) and never inside a room: trees were growing in the caves
			var RR: Dictionary = D.ROOMS[rk_]
			if rk_ != "riverside" and absf(x - RR.x) < RR.hw + 14 and absf(z - RR.z) < RR.hd + 14: return false
		return true
	# --- the thorn hedge at the village's west and east edges: bushes of all sizes, not a row of boxes
	for sx in [-1.0, 1.0]:
		var z := -66.0
		while z <= 56.0:
			if absf(z - D.GATE_Z) < 4.2:                                                          # (a gap for the road)
				z += 1.0; continue
			put.call("wild_bush", sx * (D.X1 + r.call(1.8, 3.4)), z, r.call(1.3, 2.1))
			if rg.randf() < 0.45: put.call("wild_bush", sx * (D.X1 + r.call(3.5, 5.5)), z + r.call(-1, 1), r.call(1.5, 2.4))
			z += r.call(1.6, 2.4)
	# --- the west and east roads go on, past the hedge and into the woods, rutted and fading
	for sx in [-1.0, 1.0]:
		Build.box(self, Vector3(200, 0.07, 5), Vector3(sx * 146.0, 0, D.GATE_Z), C.path)
		for k in 60:
			Build.box(self, Vector3(r.call(0.4, 0.9), 0.085, r.call(0.4, 0.9)), Vector3(sx * r.call(48, 240), 0, D.GATE_Z + r.call(-2, 2)), C.path2, r.call(0, 3))
		for k in 2: Build.box(self, Vector3(200, 0.075, 0.35), Vector3(sx * 146.0, 0, D.GATE_Z + (k * 2 - 1) * 1.1), C.path.darkened(0.12))   # cart ruts
		var sp := Vector3(sx * (D.X1 + 9.0), 0, D.GATE_Z - 3.6)                                    # and a milestone, just past the hedge
		Build.box(self, Vector3(0.6, 1.0, 0.35), sp, C.stone3)
		Build.cyl(self, 0.3, 0.3, 0.35, sp + Vector3(0, 1.0, 0), C.stone3, 8, 0.0, PI / 2)
	# --- the woods either side of the village, thickest nearest the hedge
	for sx in [-1.0, 1.0]:
		for i in 900:
			var d: float = pow(rg.randf(), 1.6) * 75.0
			var x: float = sx * (D.X1 + 5.0 + d)
			var z: float = r.call(-180.0, 175.0)
			if not clear.call(x, z): continue
			var dead_ground := z < -63
			put.call("wild_dead" if dead_ground and rg.randf() < 0.7 else "wild_pine" if rg.randf() < 0.55 else "wild_oak", x, z, r.call(0.9, 1.7))
			if rg.randf() < 0.18: put.call("wild_bush", x + r.call(-3, 3), z + r.call(-3, 3), r.call(0.9, 1.5))
	# --- the far bank of the village's river: fields in hedgerows, odd trees, a farm or two
	var fields := []
	for i in 14:
		var fx: float = r.call(-200, 200)
		var fz: float = r.call(84, 160)
		var fw: float = r.call(16, 34)
		var fd: float = r.call(10, 22)
		if not clear.call(fx, fz): continue
		fields.append([fx, fz, fw, fd])
		Build.box(self, Vector3(fw, 0.04, fd), Vector3(fx, 0.02, fz), [C.field1, C.field2, C.field3, Color("9aaa62")][i % 4], r.call(-0.08, 0.08))
		for k in int(fw / 2.2):                                                                 # a hedgerow round each, with gaps
			if rg.randf() < 0.18: continue
			put.call("wild_bush", fx - fw / 2 + k * 2.2, fz - fd / 2 - 0.8, r.call(0.7, 1.1))
			if rg.randf() < 0.8: put.call("wild_bush", fx - fw / 2 + k * 2.2, fz + fd / 2 + 0.8, r.call(0.7, 1.1))
		if i % 3 == 0:
			for h in 4: put.call("wild_hay", fx + r.call(-fw / 3, fw / 3), fz + r.call(-fd / 3, fd / 3), r.call(0.8, 1.0))
	for i in 2600:                                                                               # grass, flowers and the odd bush, so it is not a carpet
		var x: float = r.call(-230, 230)
		var z: float = r.call(77, 175)
		if not clear.call(x, z): continue
		var roll := rg.randf()
		if roll < 0.75: put.call("wild_tuft", x, z, r.call(0.8, 1.4))
		elif roll < 0.95: put.call("wild_flowers", x, z, r.call(0.8, 1.2), -1.0, [Color(1, 0.9, 0.3), Color(0.95, 0.95, 1.0), Color(0.75, 0.5, 1.0), Color(1.0, 0.45, 0.4)][rg.randi() % 4])
		else: put.call("wild_bush", x, z, r.call(0.5, 0.9))
	for i in 30:                                                                                 # patches of longer or worn grass
		var x: float = r.call(-220, 220); var z: float = r.call(78, 170)
		if clear.call(x, z): Build.box(self, Vector3(r.call(6, 16), 0.03, r.call(4, 10)), Vector3(x, 0.01, z), [C.grass2, C.grass3, Color("7f9f52")][i % 3], r.call(0, 3))
	for i in 140:                                                                                # reeds along the far bank
		var x: float = r.call(-215, 215)
		put.call("wild_tuft", x, r.call(74.5, 76.5), r.call(1.3, 1.9), -1.0, Color(0.85, 0.95, 0.7))
	for i in 420:                                                                                # trees, scattered and in copses
		var x: float = r.call(-220, 220)
		var z: float = r.call(80, 175)
		if not clear.call(x, z): continue
		if fields.any(func(f): return absf(x - f[0]) < f[2] / 2 + 1 and absf(z - f[1]) < f[3] / 2 + 1): continue
		put.call("wild_oak" if rg.randf() < 0.6 else "wild_pine", x, z, r.call(0.9, 1.6))
	for fm in [[38.0, 108.0, 0.4], [-74.0, 122.0, 2.7], [150.0, 96.0, 1.2]]:                      # farmsteads: a cottage, a barn, a haystack
		put.call("wild_cottage", fm[0], fm[1], 1.0, fm[2])
		put.call("wild_barn", fm[0] + 8.0 * cos(fm[2]), fm[1] - 8.0 * sin(fm[2]), 1.0, fm[2])
		for h in 3: put.call("wild_hay", fm[0] + r.call(-6, 6), fm[1] + r.call(5, 9), r.call(0.8, 1.0))
	for i in 40:
		var rkx: float = r.call(-210, 210); var rkz: float = r.call(80, 170)
		if clear.call(rkx, rkz): put.call("wild_rock", rkx, rkz, r.call(0.6, 1.4))
	# --- beyond the castle: dead ground carries on, into a dead wood, and a ridge of grey hills on the horizon
	Build.box(self, Vector3(700, 0.05, 300), Vector3(0, 0.0, -317.0), C.dead)
	for i in 700:
		var x: float = r.call(-260, 260)
		var z: float = r.call(-330, -150)
		if absf(x) < 45 and z > -175: continue                                                    # the castle's own hill, and its road
		if not clear.call(x, z): continue
		put.call("wild_dead", x, z, r.call(0.9, 1.8))
	for i in 34:
		var hx: float = -420 + i * 25.0 + r.call(-8, 8)
		var hh: float = r.call(30, 70)
		Build.cone(self, r.call(40, 70), hh, Vector3(hx, -2, r.call(-470, -420)), Color("6d6878").lerp(Color("57606a"), rg.randf()), 6, r.call(0, 3))
	# --- the Riverside, ringed with woods so its fields do not just stop
	var rx0: float = RM.x - RM.hw - 6; var rx1: float = RM.x + RM.hw + 6
	var rz0: float = RM.z - RM.hd - 14; var rz1: float = RM.z + RM.hd + 6
	Build.box(self, Vector3(rx1 - rx0 + 220, 0.06, 260), Vector3(RM.x, -0.04, (rz0 + rz1) / 2.0 + 40), Color("86a85a"))   # the ground under it all, one colour, a little darker
	for i in 4200:
		var x: float = r.call(rx0 - 110, rx1 + 110)
		var z: float = r.call(rz0 - 6, rz1 + 110)
		if x > rx0 and x < rx1 and z < rz1: continue
		if absf(x - RM.x) < 6 and z > RM.z + RM.hd: continue                                   # (the road goes on south, through the wood)
		if z < RM.z - RM.hd - 2: continue                                                         # (not across the river)
		var near_: float = minf(minf(absf(x - rx0), absf(x - rx1)), absf(z - rz1))
		if rg.randf() < near_ / 180.0: continue                                                    # thick at the edge, thinning out
		if not clear.call(x, z) and z > rz1: continue                                              # (and nowhere near a room)
		if near_ < 30 and rg.randf() < 0.45: continue                                              # (but the first of it a little open, a meadow's edge)
		put.call("wild_pine" if rg.randf() < 0.5 else "wild_oak", x, z, r.call(1.0, 1.8))
		if rg.randf() < 0.15: put.call("wild_bush", x + r.call(-3, 3), z + r.call(-3, 3), r.call(1.0, 1.6))
	for i in 260:                                                                                # and the far side of its river: woods too
		var x: float = r.call(rx0 - 60, rx1 + 60)
		var z: float = r.call(RM.z - RM.hd - 70, RM.z - RM.hd - 19)
		if not clear.call(x, z): continue
		put.call("wild_pine" if rg.randf() < 0.5 else "wild_oak", x, z, r.call(1.0, 1.7))
	for k in kinds:
		var xa: Array[Transform3D] = xs[k]
		var ca: Array[Color] = cs[k]
		if xa.size(): _multi(Models.get_mesh(k), xa, ca, {"wild_pine": 0.035, "wild_oak": 0.03, "wild_dead": 0.012, "wild_bush": 0.05, "wild_tuft": 0.3, "wild_flowers": 0.25}.get(k, 0.0))


# --- (version 7.27) crows that lift out of the trees now and then and circle before they go, and at night, out
# on the dead ground, eyes that open and shut and a will-o'-the-wisp or two drifting about. None of it is in the rules.
var _crows: Array = []                    # [node, wing L, wing R, phase, radius, height, angle speed]
var _crow_c := Vector3.ZERO
var _crow_t := 9.0
var _crow_age := -1.0
var _crow_out := Vector3.ZERO
var _eyes: Array = []                     # [node, seconds shown, seconds hidden]
var _wisps: Array = []                    # [node, light, base position, phase]

func _outside(p: Vector3) -> bool:       # out of the village walls, where a crow or a pair of eyes might be
	return absf(p.x) > D.VW + 4 or p.z < D.VN - 4 or p.z > D.VS + 4

func _crows_step(delta: float) -> void:
	if _crows.is_empty():
		var black := Build.mat(Color("141018"))
		for i in 7:
			var n := Node3D.new(); n.visible = false; add_child(n)
			Build.box(n, Vector3(0.22, 0.18, 0.46), Vector3(0, 0, 0), Color("141018")).material_override = black
			Build.box(n, Vector3(0.12, 0.12, 0.16), Vector3(0, 0.08, 0.28), Color("141018")).material_override = black
			var wl := Node3D.new(); wl.position = Vector3(-0.1, 0.12, 0); n.add_child(wl)
			Build.box(wl, Vector3(0.5, 0.03, 0.26), Vector3(-0.25, 0, 0), Color("141018")).material_override = black
			var wr := Node3D.new(); wr.position = Vector3(0.1, 0.12, 0); n.add_child(wr)
			Build.box(wr, Vector3(0.5, 0.03, 0.26), Vector3(0.25, 0, 0), Color("141018")).material_override = black
			_crows.append([n, wl, wr, randf() * TAU, randf_range(3.5, 8.0), randf_range(8.0, 13.0), randf_range(0.9, 1.5) * (1.0 if i % 2 else -1.0)])
		if OS.get_environment("DTV_CROWS") != "": _crow_t = 1.0              # for pictures: a flock up at once
	var now := Time.get_ticks_msec() / 1000.0
	if _crow_age < 0.0:
		_crow_t -= delta
		if _crow_t > 0.0 or night > 0.6: return
		_crow_t = randf_range(18.0, 40.0)
		for k in 8:                                    # somewhere out of the village, near enough to be seen: ahead or to the side (the view looks north)
			var a := randf_range(PI * 0.95, PI * 2.05)
			var c := view_at + Vector3(cos(a), 0, sin(a)) * randf_range(16.0, 32.0)
			if _outside(c) and absf(c.z - 65.0) > 10.0:
				_crow_c = c; _crow_age = 0.0
				_crow_out = Vector3(cos(a), 0, sin(a))
				Sound.play("caw0" if randf() < 0.5 else "caw1", 0.8, Vector2(c.x, c.z))
				break
		return
	_crow_age += delta
	if OS.get_environment("DTV_CROWS") != "":
		_crow_age = minf(_crow_age, 5.0)   # (for pictures: held mid-circle)
	var done := true
	for cw in _crows:
		var n: Node3D = cw[0]
		var t := _crow_age - fmod(float(cw[3]), 1.0) * 0.8          # they go up one after another
		if t < 0.0: n.visible = false; done = false; continue
		var ang: float = cw[3] + t * float(cw[6])
		var h: float = minf(float(cw[5]), t * 4.0)
		var p := _crow_c + Vector3(cos(ang) * float(cw[4]), h, sin(ang) * float(cw[4]))
		if t > 9.0: p += _crow_out * (t - 9.0) * 9.0 + Vector3(0, (t - 9.0) * 2.0, 0)   # and away
		n.visible = t < 16.0
		if n.visible: done = false
		var dir := Vector3(-sin(ang) * float(cw[6]), 0.2, cos(ang) * float(cw[6])) if t <= 9.0 else _crow_out
		n.position = p
		n.look_at(p + dir, Vector3.UP)
		n.rotate_object_local(Vector3.UP, PI)
		var flap := sin(now * 14.0 + float(cw[3]) * 3.0) * 0.7
		(cw[1] as Node3D).rotation.z = flap; (cw[2] as Node3D).rotation.z = -flap
	if done: _crow_age = -1.0

func _haunts_step(delta: float) -> void:
	if _eyes.is_empty():
		for i in 6:                                        # eyes: a pair, red or green, low among the dead trees
			var n := Node3D.new(); n.visible = false; add_child(n)
			var em := Build.mat(Color(1.0, 0.18, 0.1) if i % 2 else Color(0.5, 1.0, 0.3), 3.0)
			for sx in [-0.09, 0.09]: Build.box(n, Vector3(0.07, 0.05, 0.05), Vector3(sx, 0, 0), Color.WHITE).material_override = em
			_eyes.append([n, 0.0, randf_range(1.0, 6.0)])
		for i in 3:                                        # will-o'-the-wisps: a pale light that drifts and bobs
			var n := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.16; sm.height = 0.32; n.mesh = sm
			n.material_override = Build.mat(Color(0.55, 0.95, 1.0), 4.0); n.visible = false; add_child(n)
			var l := OmniLight3D.new(); l.light_color = Color(0.5, 0.9, 1.0); l.omni_range = 4.0; l.light_energy = 0.0; n.add_child(l)
			_wisps.append([n, l, Vector3.ZERO, randf() * TAU])
	var dark := night > 0.45
	var dead_ground := func(p: Vector3) -> bool:
		return p.z < D.VN - 6 and p.z > -175.0 and absf(p.x) > 6.0 and Vector2(p.x - HILL.x, p.z - HILL.z).length() > 44.0
	for e in _eyes:
		var n: Node3D = e[0]
		if not dark: n.visible = false; continue
		if n.visible:
			e[1] -= delta
			if e[1] <= 0.0: n.visible = false; e[2] = randf_range(2.0, 8.0)
			elif randf() < delta * 0.6: n.scale = Vector3(1, 0.1, 1)          # a blink
			else: n.scale = Vector3.ONE
		else:
			e[2] -= delta
			if e[2] <= 0.0:
				for k in 6:
					var a := randf() * TAU
					var p := view_at + Vector3(cos(a), 0, sin(a)) * randf_range(10.0, 30.0)
					if dead_ground.call(p):
						n.position = Vector3(p.x, randf_range(0.5, 1.3), p.z)
						n.look_at(Vector3(view_at.x, n.position.y, view_at.z), Vector3.UP); n.rotate_object_local(Vector3.UP, PI)
						n.visible = true; e[1] = randf_range(2.0, 5.0)
						break
				if not n.visible: e[2] = 1.5
	var now := Time.get_ticks_msec() / 1000.0
	for wsp in _wisps:
		var n: MeshInstance3D = wsp[0]
		var l: OmniLight3D = wsp[1]
		if not dark: n.visible = false; l.light_energy = 0.0; continue
		var b: Vector3 = wsp[2]
		if not n.visible or Vector2(b.x - view_at.x, b.z - view_at.z).length() > 45.0:
			for k in 6:
				var a := randf() * TAU
				var p := view_at + Vector3(cos(a), 0, sin(a)) * randf_range(14.0, 34.0)
				if dead_ground.call(p): wsp[2] = p; n.visible = true; break
			b = wsp[2]
		var ph: float = wsp[3]
		n.position = b + Vector3(sin(now * 0.3 + ph) * 3.0, 0.9 + 0.35 * sin(now * 1.7 + ph), cos(now * 0.23 + ph) * 3.0)
		l.light_energy = (0.6 + 0.3 * sin(now * 3.1 + ph)) * clampf((night - 0.45) * 4.0, 0.0, 1.0)


## Things that bend in the wind (version 7.27): each sways by how high the point is above its own foot, in a slow
## breeze that rolls across the land (its phase from where it stands), and gusts now and then.
const SWAY_SHADER := """
shader_type spatial;
uniform float amount = 0.04;
uniform float base = 0.0;
uniform float wind = 1.0;
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float h = max(VERTEX.y + base, 0.0);
	float t = TIME * (1.1 + 0.5 * max(wind - 1.0, 0.0)) + wp.x * 0.07 + wp.z * 0.05;
	float gust = 0.75 + 0.25 * sin(TIME * 0.23 + wp.x * 0.01);
	float storm = max(wind - 1.2, 0.0);
	VERTEX.x += (sin(t) * gust + storm * 0.55 + storm * 0.25 * sin(TIME * 5.3 + wp.z * 0.4)) * amount * h * wind;   // in a storm: bent over, and thrashing
	VERTEX.z += cos(t * 0.83 + 1.3) * amount * 0.6 * h * gust * wind;
}
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.15;
}
"""
static var _sway_shader: Shader
var _sway_mats: Array = []

## How hard the wind blows (main.gd, from the weather): 1 a breeze, nearly 3 a storm, 0.3 fog's still air.
func set_wind(w: float) -> void:
	for sm in _sway_mats: (sm as ShaderMaterial).set_shader_parameter("wind", w)

## A material that sways in the wind (and follows set_wind), for anything else drawn as a multimesh: the village's own trees (version 7.31).
func sway_mat(amount: float, base: float = 0.0) -> ShaderMaterial:
	if _sway_shader == null:
		_sway_shader = Shader.new(); _sway_shader.code = SWAY_SHADER
	var sm := ShaderMaterial.new(); sm.shader = _sway_shader
	sm.set_shader_parameter("amount", amount); sm.set_shader_parameter("base", base)
	_sway_mats.append(sm)
	return sm

func _multi(mesh: Mesh, xfs: Array[Transform3D], cols: Array[Color], sway: float = 0.0, base: float = 0.0) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_color(i, cols[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	if sway > 0.0:
		if _sway_shader == null:
			_sway_shader = Shader.new(); _sway_shader.code = SWAY_SHADER
		var sm := ShaderMaterial.new(); sm.shader = _sway_shader
		sm.set_shader_parameter("amount", sway); sm.set_shader_parameter("base", base)
		_sway_mats.append(sm)
		mmi.material_override = sm
	else:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 1.0
		m.metallic_specular = 0.15
		mmi.material_override = m
	add_child(mmi)


func _keep() -> void:
	var n := Node3D.new()
	add_child(n)
	keep = n
	keep_window_mat = window_mat.duplicate()
	Build.box(n, Vector3(6.6, 0.8, 6.6), Vector3.ZERO, C.stone3)
	Build.box(n, Vector3(5.6, 7, 5.6), Vector3(0, 0.8, 0), C.stone)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Build.box(n, Vector3(1.2, 8, 1.2), Vector3(sx * 2.6, 0.8, sz * 2.6), C.stone2)
	Build.box(n, Vector3(6.3, 0.6, 6.3), Vector3(0, 7.8, 0), C.stone2)
	for i in range(-1, 2):
		for s in [-1.0, 1.0]:
			Build.box(n, Vector3(0.8, 0.6, 0.5), Vector3(i * 1.5, 8.4, s * 2.9), C.stone2)
			Build.box(n, Vector3(0.5, 0.6, 0.8), Vector3(s * 2.9, 8.4, i * 1.5), C.stone2)
	Build.cone(n, 3.3, 3, Vector3(0, 8.4, 0), C.slate, 4, PI / 4)
	Build.box(n, Vector3(0.14, 2.6, 0.14), Vector3(0, 11.2, 0), C.timber)
	Build.box(n, Vector3(1.3, 0.8, 0.07), Vector3(0.7, 12.9, 0), C.red)
	Build.box(n, Vector3(1.7, 2.5, 0.2), Vector3(0, 0.8, -2.85), C.timber)
	Build.box(n, Vector3(2.2, 0.32, 0.3), Vector3(0, 3.3, -2.85), C.stone3)
	for s in [-1.0, 1.0]:
		Build.glow_box(n, Vector3(0.45, 1, 0.1), Vector3(s * 1.4, 4.4, -2.83), keep_window_mat)
		Build.glow_box(n, Vector3(0.45, 1, 0.1), Vector3(s * 1.4, 4.4, 2.83), keep_window_mat)
		Build.glow_box(n, Vector3(0.1, 1, 0.45), Vector3(-2.83, 4.4, s * 1.4), keep_window_mat)
		Build.glow_box(n, Vector3(0.1, 1, 0.45), Vector3(2.83, 4.4, s * 1.4), keep_window_mat)
	lantern(Vector3(1.25, 2.6, -3.1), 12.0)
	# its own copies of its materials, so it can fade without fading every stone building in the village
	for c in n.get_children():
		if c is MeshInstance3D and c.material_override != keep_window_mat:
			var m: StandardMaterial3D = c.material_override.duplicate()
			c.material_override = m
			_keep_mats.append(m)
	_keep_mats.append(keep_window_mat)


## How solid the keep looks: 1 solid, 0.3 mostly see-through.
func keep_alpha(a: float) -> void:
	if absf(a - _keep_alpha) < 0.001:
		return
	_keep_alpha = a
	for m in _keep_mats:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if a < 0.985 else BaseMaterial3D.TRANSPARENCY_DISABLED
		m.albedo_color.a = a


## A house. w is across its front, d its depth; its door is on the side it faces (rot_y 0 faces south).
func house(x: float, z: float, rot_y: float, w: float, d: float, h: float, wall_c: Color, roof_c: Color, plain: bool = false, chimney: bool = false, rh: float = -1.0, door: bool = true) -> Node3D:
	var n := Node3D.new()
	n.position = Vector3(x, 0, z)
	n.rotation.y = rot_y
	add_child(n)
	var f := 0.4
	Build.box(n, Vector3(w + 0.4, f, d + 0.4), Vector3.ZERO, C.stone2)
	Build.box(n, Vector3(w, h, d), Vector3(0, f, 0), wall_c)
	if not plain:
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				Build.box(n, Vector3(0.28, h, 0.28), Vector3(sx * (w / 2 - 0.08), f, sz * (d / 2 - 0.08)), C.timber)
		Build.box(n, Vector3(w + 0.12, 0.22, d + 0.12), Vector3(0, f + h - 0.22, 0), C.timber)
		if h >= 1.9:                                      # half-timbering: a rail round the middle, and braces up to it
			var mid := f + h * 0.5
			Build.box(n, Vector3(w + 0.08, 0.16, d + 0.08), Vector3(0, mid - 0.08, 0), C.timber)
			# A brace runs from the foot of a corner post up and inwards to the rail, flat against the wall. (A box turns
			# about its middle, so the middle is put where the brace's middle should be: before, the braces were turned
			# about a point on the corner and one end stuck out past it into the air.)
			var lean := 0.62
			var blen := (h * 0.5) / cos(lean)
			var run := blen * sin(lean)                 # how far along the wall a brace reaches
			var by := f + h * 0.25 - blen * 0.5         # so that it stands between the ground and the rail
			for sz in [-1.0, 1.0]:
				for sx in [-1.0, 1.0]:
					Build.box(n, Vector3(0.15, blen, 0.06), Vector3(sx * (w / 2 - 0.2 - run * 0.5), by, sz * (d / 2 + 0.03)), C.timber, 0.0, 0.0, sx * lean)
					Build.box(n, Vector3(0.15, h * 0.5, 0.06), Vector3(sx * w * 0.16, mid, sz * (d / 2 + 0.03)), C.timber)
			for sx in [-1.0, 1.0]:
				Build.box(n, Vector3(0.06, blen, 0.15), Vector3(sx * (w / 2 + 0.03), by, -d / 2 + 0.2 + run * 0.5), C.timber, 0.0, lean, 0.0)
	if rh < 0.0:
		rh = minf(w, d) * 0.5
	if w >= d:
		Build.roof(n, d + 1.1, rh, w + 1.1, Vector3(0, f + h, 0), roof_c, PI / 2)
	else:
		Build.roof(n, w + 1.1, rh, d + 1.1, Vector3(0, f + h, 0), roof_c, 0.0)
	if door:
		Build.box(n, Vector3(1.05, 1.75, 0.16), Vector3(0, f, d / 2 + 0.02), C.timber)
	var wy := f + h * 0.5
	if w > 3.2:
		for sx in [-1.0, 1.0]:
			Build.box(n, Vector3(0.82, 0.82, 0.1), Vector3(sx * w * 0.3, wy - 0.1, d / 2 + 0.01), C.timber)
			Build.glow_box(n, Vector3(0.6, 0.6, 0.1), Vector3(sx * w * 0.3, wy + 0.01, d / 2 + 0.04), window_mat)
	for sx in [-1.0, 1.0]:
		Build.box(n, Vector3(0.1, 0.82, 0.82), Vector3(sx * (w / 2 + 0.01), wy - 0.1, 0), C.timber)
		Build.glow_box(n, Vector3(0.1, 0.6, 0.6), Vector3(sx * (w / 2 + 0.04), wy + 0.01, 0), window_mat)
	if chimney:
		Build.box(n, Vector3(0.7, rh + 1, 0.7), Vector3(w * 0.28, f + h, -d * 0.12), C.stone2)
		chimneys.append(n.transform * Vector3(w * 0.28, f + h + rh + 1.1, -d * 0.12))
	return n


## Where player number i lives: two rows of four cottages south of the keep.
static func cottage(i: int) -> Dictionary:
	var col := i % 4
	var row := floori(i / 4.0)
	var x := -7.5 + col * 5.0
	var z := 15.2 if row else 9.0
	var dir := 1.0 if row else -1.0
	return { x = x, z = z, dir = dir, door = Vector3(x, 0, z + dir * 3.1) }


func _buildings() -> void:
	# Robert Bailiff's house: bolted, boarded
	house(-14.5, -12.6, 0, 9, 6.4, 4.8, C.cream, C.roof2, false, true, 3.3)
	Build.box(self, Vector3(1.5, 0.18, 0.1), Vector3(-14.5, 1.05, -9.28), C.wood3, 0.0, 0.0, 0.5)
	Build.box(self, Vector3(1.5, 0.18, 0.1), Vector3(-14.5, 1.05, -9.28), C.wood3, 0.0, 0.0, -0.5)
	# his window: the east one on the front, which the inn does not hide. Bigger than the rest, with shutters thrown back and a sill to lean on
	Build.box(self, Vector3(1.5, 1.35, 0.12), Vector3(D.BAILIFF_AT.x, 2.2, -9.36), C.timber)
	Build.box(self, Vector3(1.26, 1.12, 0.12), Vector3(D.BAILIFF_AT.x, 2.32, -9.33), Color("2a2026"))
	Build.box(self, Vector3(1.7, 0.12, 0.34), Vector3(D.BAILIFF_AT.x, 2.14, -9.22), C.wood2)
	for sx in [-1.0, 1.0]:
		Build.box(self, Vector3(0.62, 1.2, 0.07), Vector3(D.BAILIFF_AT.x + sx * 1.02, 2.28, -9.3), C.red, 0.0, 0.0, 0.0)
	# (version 7.23) and his back door, which there now is: stout planks in a frame, iron hinges, a knocker, a step, and a bolt you can hear
	var bz := -15.86
	Build.box(self, Vector3(1.5, 2.3, 0.14), Vector3(-14.5, 0, bz), C.timber)                     # the frame
	Build.box(self, Vector3(1.18, 2.08, 0.1), Vector3(-14.5, 0.05, bz - 0.07), C.wood2)               # the door
	for k in 4: Build.box(self, Vector3(0.03, 2.04, 0.04), Vector3(-14.5 - 0.44 + k * 0.29, 0.07, bz - 0.13), C.wood3)   # between the planks
	for hy in [0.45, 1.65]: Build.box(self, Vector3(0.62, 0.08, 0.04), Vector3(-14.72, hy, bz - 0.14), C.iron)   # hinges
	Build.cyl(self, 0.09, 0.09, 0.03, Vector3(-14.2, 1.2, bz - 0.15), C.iron, 8, 0.0, PI / 2)        # the knocker
	Build.box(self, Vector3(0.05, 0.05, 0.05), Vector3(-14.2, 1.3, bz - 0.15), C.iron)
	Build.box(self, Vector3(1.6, 0.16, 0.6), Vector3(-14.5, 0, bz - 0.4), C.stone2)                   # the step
	Build.box(self, Vector3(1.7, 0.12, 0.3), Vector3(-14.5, 2.32, bz - 0.1), C.wood3)                 # a lintel
	# the old ruins and the priest's chapel
	_chapel()
	for i in 6:                                     # (smaller since version 7.6: the towers wanted the elbow room)
		Build.box(self, Vector3(rr(0.7, 1.6), rr(0.4, 1.5), 0.42), Vector3(rr(9.4, 12.4), 0, rr(-16.2, -12.8)), C.stone2 if i % 2 else C.stone3, rr(0, 3))
	for p in [Vector2(9.6, -15.2), Vector2(9.0, -12.4)]:
		Build.cyl(self, 0.3, 0.36, rr(1.0, 1.7), Vector3(p.x, 0, p.y), C.stone2, 6)
	# the Thorny Rose Inn
	house(-17.5, -4.7, PI / 2, 8, 6, 4.2, C.cream, C.roof, false, true, 3.0)
	Build.box(self, Vector3(0.18, 3, 0.18), Vector3(-13.4, 0, -1.4), C.timber)
	Build.box(self, Vector3(1.5, 0.14, 0.14), Vector3(-12.8, 2.86, -1.4), C.timber)
	Build.box(self, Vector3(1, 0.8, 0.1), Vector3(-12.6, 1.95, -1.4), C.cream2)
	Build.box(self, Vector3(0.42, 0.42, 0.14), Vector3(-12.6, 2.14, -1.4), C.red)
	for p in [Vector2(-13.6, -7.2), Vector2(-13.2, -6.3)]:
		Build.cyl(self, 0.42, 0.42, 0.9, Vector3(p.x, 0, p.y), C.wood2, 7)
	lantern(Vector3(-13.6, 2.4, -4.7), 12.0)
	# the smithy
	house(17.5, -4.7, -PI / 2, 6.5, 5.6, 3.2, C.stone, C.slate, true, true, 2.4)
	for zz in [-6.8, -2.6]:
		Build.box(self, Vector3(0.24, 2.4, 0.24), Vector3(13.2, 0, zz), C.timber)
	Build.box(self, Vector3(2.2, 0.16, 5.2), Vector3(13.7, 2.5, -4.7), C.roof2, 0.0, 0.0, 0.22)
	Build.box(self, Vector3(0.9, 0.5, 0.45), Vector3(13, 0, -5.6), C.iron)
	Build.box(self, Vector3(1.2, 0.8, 1.2), Vector3(13.4, 0, -3.5), C.stone3)
	lantern(Vector3(13.4, 1.0, -3.5), 9.0)       # the forge
	# the training yard
	for i in 9:
		var fx := -22 + i * 1.25
		Build.box(self, Vector3(0.2, 1, 0.2), Vector3(fx, 0, 7.4), C.wood2)
		Build.box(self, Vector3(0.2, 1, 0.2), Vector3(fx, 0, 14), C.wood2)
	Build.box(self, Vector3(10, 0.12, 0.1), Vector3(-17, 0.75, 7.4), C.wood3)
	Build.box(self, Vector3(10, 0.12, 0.1), Vector3(-17, 0.75, 14), C.wood3)
	Build.box(self, Vector3(10, 0.06, 6.6), Vector3(-17, 0, 10.7), C.path2)
	for x in [-20.0, -17.0, -14.0]:
		var dm := Node3D.new()                     # a dummy, on a post that leans when it is hit
		dm.position = Vector3(x, 0, 10.8)
		add_child(dm)
		Build.box(dm, Vector3(0.18, 1.7, 0.18), Vector3(0, 0, 0), C.timber)
		Build.box(dm, Vector3(1.1, 0.16, 0.16), Vector3(0, 1.15, 0), C.timber)
		Build.box(dm, Vector3(0.5, 0.7, 0.4), Vector3(0, 0.75, 0), C.straw)
		Build.box(dm, Vector3(0.36, 0.36, 0.34), Vector3(0, 1.5, 0), C.straw)
		Build.box(dm, Vector3(0.08, 0.08, 0.04), Vector3(-0.08, 1.7, 0.18), Color("2a2018"))
		Build.box(dm, Vector3(0.08, 0.08, 0.04), Vector3(0.08, 1.7, 0.18), Color("2a2018"))
		dummies.append(dm)
	# the storehouse
	house(17.5, 10.6, -PI / 2, 7, 5.6, 3.6, C.cream2, C.thatch, false, false, 2.8)
	for p in [Vector3(13.3, 0.9, 8.2), Vector3(13.1, 0.9, 9.2), Vector3(13.6, 1.0, 13)]:
		Build.cyl(self, 0.45, 0.45, p.y, Vector3(p.x, 0, p.z), C.wood2, 7)
	# the slum
	house(-21.5, 19.2, 0.12, 3, 2.8, 1.7, C.cream2, C.thatch, true, false, 1.5)
	house(-17.6, 21.6, -0.2, 3.3, 2.7, 1.6, Color("d6c193"), C.wood2, true, false, 1.3)
	house(-13.8, 19.4, 0.25, 2.8, 2.8, 1.8, C.cream2, C.thatch, true, false, 1.6)
	# the market
	var awning := [C.red, Color("3f77c4"), Color("e0a526")]
	for k in 3:
		var n := Node3D.new()
		n.position = Vector3(-5 + k * 5, 0, 21.6)
		add_child(n)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				Build.box(n, Vector3(0.16, 2.1, 0.16), Vector3(sx * 1.3, 0, sz * 0.9), C.timber)
		for i in 5:
			Build.box(n, Vector3(0.6, 0.12, 2.3), Vector3(-1.2 + i * 0.6, 2.1 + (i % 2) * 0.01, 0), C.cream if i % 2 else awning[k])
		Build.box(n, Vector3(2.6, 0.14, 1.2), Vector3(0, 0.85, 0), C.wood3)
		Build.box(n, Vector3(0.5, 0.35, 0.5), Vector3(-0.6, 0.99, 0), C.straw)
		Build.box(n, Vector3(0.5, 0.3, 0.5), Vector3(0.5, 0.99, 0.1), C.roof3)
	# the library
	house(17.5, 20.4, -PI / 2, 6.6, 6, 4.6, C.stone, C.roof2, false, false, 3.4)
	# the bell and the notice board in the square
	for s in [-1.0, 1.0]:
		Build.box(self, Vector3(0.22, 2.6, 0.22), Vector3(5.5 + s * 0.8, 0, -9.5), C.timber)
		Build.box(self, Vector3(0.18, 1.9, 0.18), Vector3(-5.5 + s * 0.9, 0, -9.5), C.timber)
	Build.box(self, Vector3(2.1, 0.22, 0.26), Vector3(5.5, 2.6, -9.5), C.timber)
	bell = Node3D.new()                            # hung from the beam, so it can swing
	bell.position = Vector3(5.5, 2.6, -9.5)
	add_child(bell)
	Build.cyl(bell, 0.2, 0.42, 0.6, Vector3(0, -0.75, 0), Color("c9962f"), 7)
	Build.box(bell, Vector3(0.05, 0.3, 0.05), Vector3(0, -0.3, 0), C.iron)
	Build.box(bell, Vector3(0.04, 0.9, 0.04), Vector3(0, -1.6, 0), Color("a08562"))       # the rope
	Build.box(self, Vector3(2, 1.2, 0.12), Vector3(-5.5, 0.75, -9.5), C.wood3)
	Build.box(self, Vector3(0.6, 0.8, 0.14), Vector3(-5.9, 0.95, -9.5), C.cream)
	# the cottages, one per player
	var roofs := [C.roof, C.thatch, C.roof3, C.roof2]
	for i in 8:
		var c := cottage(i)
		house(c.x, c.z, 0.0 if c.dir > 0 else PI, 3.7, 3.3, 2.0, C.cream if i % 2 else C.cream2, roofs[i % 4], false, i % 3 == 0, 1.9)


## The chapel: a stone nave with buttresses and tall pointed windows of coloured glass, a round window over
## the door, a rounded end to the north, and a bell tower with a spire and a gilded cross over the door.
func _chapel() -> void:
	var n := Node3D.new()
	n.position = Vector3(17, 0, -14)
	add_child(n)
	var w := 4.2
	var d := 5.6
	var h := 3.8
	var stone := Color("cfc8b6")
	var trim := Color("a39c8b")
	Build.box(n, Vector3(w + 0.5, 0.35, d + 0.5), Vector3(0, 0, 0.2), trim)                  # plinth
	Build.box(n, Vector3(w, h, d), Vector3(0, 0.35, 0), stone)                              # the nave
	Build.roof(n, w + 0.7, 3.0, d + 0.6, Vector3(0, 0.35 + h, 0), C.slate, 0.0)              # steep slate roof
	Build.box(n, Vector3(0.25, 0.2, d + 0.7), Vector3(0, 0.35 + h + 2.95, 0), Color("4f5b6c"))  # ridge
	Build.cyl(n, 1.9, 1.9, h - 0.4, Vector3(0, 0.35, -d / 2), stone, 10)                     # the rounded north end
	Build.cone(n, 2.1, 2.2, Vector3(0, 0.35 + h - 0.4, -d / 2), C.slate, 10)
	# buttresses along both sides, stepping in as they rise
	for sx in [-1.0, 1.0]:
		for zz in [-1.9, 0.0, 1.9]:
			Build.box(n, Vector3(0.45, 2.6, 0.45), Vector3(sx * (w / 2 + 0.2), 0.35, zz), trim)
			Build.box(n, Vector3(0.32, 1.0, 0.32), Vector3(sx * (w / 2 + 0.14), 2.95, zz), trim, 0.0, 0.0, sx * 0.25)
	# tall pointed windows of coloured glass between the buttresses
	var glass := [Build.mat(Color("c23b3b"), 0.9).duplicate(), Build.mat(Color("3b6fc2"), 0.9).duplicate(), Build.mat(Color("e0b13a"), 0.9).duplicate()]   # (their own: they change)
	_glass = glass.duplicate()
	for sx in [-1.0, 1.0]:
		for i in 2:
			var zz := -0.95 + i * 1.9
			var g: Material = glass[(i + (1 if sx > 0 else 0)) % 3]
			Build.box(n, Vector3(0.12, 1.9, 0.62), Vector3(sx * (w / 2 + 0.02), 1.15, zz), Color("4a4438"))
			Build.glow_box(n, Vector3(0.12, 1.6, 0.44), Vector3(sx * (w / 2 + 0.05), 1.25, zz), g)
			var tip := Build.glow_box(n, Vector3(0.12, 0.32, 0.32), Vector3(sx * (w / 2 + 0.05), 2.82, zz), g)
			var sm := StandardMaterial3D.new(); sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD; sm.albedo_color = Color((g as StandardMaterial3D).albedo_color, 0.0)
			var spill := Build.glow_box(n, Vector3(1.6, 0.02, 0.7), Vector3(sx * (w / 2 + 1.0), 0.14, zz), sm)   # (version 7.37) its colour thrown on the grass, on the nights of the bells
			spill.visible = false; _spill.append([spill, sm, _glass.find(g)])
			tip.rotation.x = PI / 4                                                            # the pointed top
	# the front (version 7.37: on the face of the bell tower, which used to stand in front of them and hide them): a pointed
	# doorway with a stone surround, a pair of oak doors with iron straps and a ring, a step, and a round window above
	var f := d / 2 + 0.25                                                                       # the tower's front face
	var oak := Color("6b4326")
	Build.box(n, Vector3(1.35, 0.14, 0.7), Vector3(0, 0.35, f + 0.3), trim)                       # the step
	Build.box(n, Vector3(1.4, 2.25, 0.14), Vector3(0, 0.35, f + 0.02), trim)                      # the stone surround
	var sa := Build.box(n, Vector3(0.99, 0.99, 0.14), Vector3(0, 2.13, f + 0.02), trim)          # and its pointed top
	sa.rotation.z = PI / 4
	Build.box(n, Vector3(1.0, 1.95, 0.12), Vector3(0, 0.35, f + 0.1), oak)                         # the doors
	var da := Build.box(n, Vector3(0.71, 0.71, 0.12), Vector3(0, 1.94, f + 0.1), oak)
	da.rotation.z = PI / 4
	Build.box(n, Vector3(0.05, 2.2, 0.14), Vector3(0, 0.35, f + 0.11), Color("3a2414"))            # where they meet
	for k in 7: Build.box(n, Vector3(0.02, 1.9, 0.13), Vector3(-0.45 + k * 0.15, 0.36, f + 0.105), Color("573620"))   # the planks
	for y in [0.75, 1.75]:                                                                         # the iron straps
		for sx in [-1.0, 1.0]: Build.box(n, Vector3(0.42, 0.07, 0.15), Vector3(sx * 0.25, y, f + 0.12), C.iron)
	for sx in [-1.0, 1.0]:                                                                         # and the rings
		Build.cyl(n, 0.09, 0.09, 0.03, Vector3(sx * 0.12, 1.12, f + 0.19), Color("3a3d44"), 10, 0.0, PI / 2)
		Build.cyl(n, 0.05, 0.05, 0.04, Vector3(sx * 0.12, 1.12, f + 0.2), Color("70757f"), 8, 0.0, PI / 2)
	var rose := Build.cyl(n, 0.48, 0.48, 0.12, Vector3(0, 3.6, f), trim, 12, 0.0, PI / 2)
	rose.position = Vector3(0, 3.6, f + 0.04)
	var rg := Build.cyl(n, 0.38, 0.38, 0.12, Vector3(0, 3.6, f + 0.08), Color.WHITE, 12, 0.0, PI / 2)
	rg.material_override = Build.mat(Color("8f5bc2"), 1.0).duplicate()
	_glass.append(rg.material_override)
	for sx in [-1.0, 1.0]:                                                                       # the light through them, out on to the grass, on the nights of the bells
		var cl := OmniLight3D.new(); cl.position = Vector3(sx * (w / 2 + 1.4), 1.6, 0); cl.omni_range = 7.0; cl.light_energy = 0.0; n.add_child(cl)
		_chapel_lights.append(cl)
	rg.position = Vector3(0, 3.6, f + 0.08)
	# the bell tower, at the south end
	var tz := d / 2 - 0.6
	Build.box(n, Vector3(1.7, 7.2, 1.7), Vector3(0, 0.35, tz), stone)
	Build.box(n, Vector3(1.9, 0.22, 1.9), Vector3(0, 7.55, tz), trim)
	for a in 4:                                                                                  # the belfry's openings
		var b := Node3D.new(); b.position = Vector3(0, 0, tz); b.rotation.y = a * PI / 2; n.add_child(b)
		Build.box(b, Vector3(0.55, 1.0, 0.1), Vector3(0, 6.1, 0.82), Color("231d18"))
		var ba := Build.box(b, Vector3(0.39, 0.39, 0.1), Vector3(0, 6.9, 0.82), Color("231d18"))
		ba.rotation.z = PI / 4
	Build.cyl(n, 0.3, 0.42, 0.55, Vector3(0, 6.15, tz), Color("c9962f"), 8)                    # the bell
	Build.cone(n, 1.3, 3.4, Vector3(0, 7.77, tz), C.slate, 4, PI / 4)                           # the spire
	var gold := Build.mat(Color("e2b54a"), 0.35)
	var c1 := Build.glow_box(n, Vector3(0.12, 1.1, 0.12), Vector3(0, 11.1, tz), gold)          # the gilded cross
	var c2 := Build.glow_box(n, Vector3(0.62, 0.12, 0.12), Vector3(0, 11.75, tz), gold)
	# a little churchyard: a few old headstones and a yew
	for i in 4:
		Build.box(self, Vector3(0.6, 0.85, 0.16), Vector3(20.6 + (i % 2) * 1.1, 0, -16.4 + i * 1.3), C.grave, rr(-0.2, 0.2), 0.0, rr(-0.12, 0.12))
	Build.cyl(self, 0.25, 0.3, 1.0, Vector3(21.8, 0, -11.2), C.trunk, 6)
	Build.cone(self, 1.1, 2.6, Vector3(21.8, 0.8, -11.2), Color("2f5a33"), 7)
	Build.box(self, Vector3(0.14, 2.3, 0.14), Vector3(15.3, 0, -10.6), C.timber)          # a lantern on a post by the door
	Build.box(self, Vector3(0.5, 0.1, 0.1), Vector3(15.5, 2.25, -10.6), C.timber)
	lantern(Vector3(15.7, 1.85, -10.6), 8.0)


## The river, south: a sandy bank, reeds and lily pads, and water that runs west (downstream).
func _river() -> void:
	Build.box(self, Vector3(420, 0.03, 4.2), Vector3(0, 0, 56.4), C.sand)
	for i in 120:                                   # the bank is not a ruler: bites of sand and grass along it
		var x := rr(-205, 205)
		Build.box(self, Vector3(rr(2, 6), 0.035, rr(0.8, 2.2)), Vector3(x, 0, rr(54.2, 55.2)), C.sand if i % 3 else C.grass3, rr(-0.2, 0.2))
	Build.box(self, Vector3(420, 0.03, 3.4), Vector3(0, 0, 73.4), C.sand)          # the far bank
	var water := _water(Vector3(0, 0.05, 65), Vector2(420, 15.6), 65.0, 7.8)
	add_child(water)
	# reeds in clumps on both banks, lily pads in the slack water, and a few stones
	var reed := BoxMesh.new()
	reed.size = Vector3(0.06, 1.0, 0.06)
	var xf: Array[Transform3D] = []
	var cols: Array[Color] = []
	for i in 140:
		var near := i % 3 != 0
		var cx := rr(-200, 200)
		var cz := rr(56.8, 58.2) if near else rr(71.6, 72.6)
		for j in 7:
			var h := rr(0.7, 1.6)
			var b := Basis.from_euler(Vector3(rr(-0.18, 0.18), 0, rr(-0.18, 0.18))).scaled(Vector3(1, h, 1))
			xf.append(Transform3D(b, Vector3(cx + rr(-0.6, 0.6), h * 0.5 - 0.05, cz + rr(-0.4, 0.4))))
			cols.append([Color("6f8f3f"), Color("86a24a"), Color("a39352")][j % 3])
	_multi(reed, xf, cols)
	var pad := CylinderMesh.new()
	pad.top_radius = 0.42
	pad.bottom_radius = 0.42
	pad.height = 0.03
	pad.radial_segments = 9
	var pxf: Array[Transform3D] = []
	var pcol: Array[Color] = []
	for i in 160:
		var s := rr(0.6, 1.3)
		pxf.append(Transform3D(Basis.from_euler(Vector3(0, rr(0, 6), 0)).scaled(Vector3(s, 1, s)), Vector3(rr(-200, 200), 0.075, rr(58.4, 59.8) if i % 2 else rr(70.2, 71.4))))
		pcol.append(Color("5b8a3c") if i % 5 else Color("e8d6e4"))
	_multi(pad, pxf, pcol)
	for i in 40:
		Build.box(self, Vector3(rr(0.4, 1.1), rr(0.2, 0.45), rr(0.4, 0.9)), Vector3(rr(-200, 200), 0, rr(55.6, 57.0)), C.stone3 if i % 2 else C.stone2, rr(0, 3))
	for i in 60:                                    # bushes along the far side, which nobody has ever been to
		var x := rr(-200, 200)
		Build.cone(self, rr(1.2, 2.2), rr(1.6, 3.2), Vector3(x, 0, rr(75.5, 82)), [C.leaf, C.leaf2, C.hedge3][i % 3], 6, rr(0, 3))


## Running water (the village's river, and the Riverside's): deep in the middle, shallow and foaming at the edges, with
## streaks drifting west. cz and half: where its middle is, and how far it is from the middle to each bank.
func _water(pos: Vector3, size: Vector2, cz: float, half: float) -> MeshInstance3D:
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	water.mesh = pm
	water.position = pos
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode specular_schlick_ggx;
uniform vec3 shallow : source_color = vec3(0.56, 0.80, 0.85);
uniform vec3 deep : source_color = vec3(0.26, 0.55, 0.68);
uniform vec3 foam : source_color = vec3(0.93, 0.97, 0.98);
uniform float cz = 65.0;
uniform float half = 7.8;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float wave(vec2 p, float t) {
	return sin(p.x * 0.42 + t * 1.1 + sin(p.y * 0.9 + t * 0.4) * 1.6) * 0.5 + sin(p.x * 0.13 - p.y * 0.7 + t * 0.7) * 0.5;
}
void fragment() {
	float across = clamp(abs(wp.z - cz) / half, 0.0, 1.0);
	vec3 c = mix(deep, shallow, across * across);
	vec2 p = vec2(wp.x + TIME * 1.6, wp.z);                 // the current runs west
	float r = wave(p, TIME);
	float streak = smoothstep(0.80, 0.97, r) * (1.0 - across * 0.6);
	float edge = smoothstep(0.86, 1.0, across) * (0.6 + 0.4 * sin(wp.x * 0.8 + TIME * 2.0));
	c = mix(c, foam, clamp(streak * 0.5 + edge * 0.45, 0.0, 1.0));
	ALBEDO = c;
	ROUGHNESS = 0.16;
	METALLIC = 0.12;
	SPECULAR = 0.6;
}
"""
	var wm := ShaderMaterial.new()
	wm.shader = sh
	wm.set_shader_parameter("cz", cz)
	wm.set_shader_parameter("half", half)
	water.material_override = wm
	return water


## The village green, north of the keep: grass, a maypole, the well, the stocks and a duck pond.
func _green() -> void:
	Build.box(self, Vector3(16.8, 0.05, 10.6), Vector3(-0.6, 0, -15.6), C.grass3)
	for i in 26:                                    # daisies and buttercups
		var x := rr(-8.6, 7.4)
		if absf(x) < 3.6: x += 7.2 * signf(x if x != 0.0 else 1.0)
		Build.box(self, Vector3(0.22, 0.06, 0.22), Vector3(clampf(x, -8.6, 7.6), 0.03, rr(-20.4, -11)), Color("f4f0e0") if i % 3 else Color("f0cd4a"))
	# the maypole, its ribbons pegged out round it
	var mp := Vector3(-6.2, 0, -16.0)
	Build.cyl(self, 0.13, 0.17, 7.2, mp, Color("e9e1cc"), 8)
	maypole = Node3D.new()
	maypole.position = mp
	add_child(maypole)
	Build.cyl(maypole, 0.5, 0.5, 0.2, Vector3(0, 6.6, 0), Color("6aa04e"), 10)
	var ribbon := [C.red, Color("3f77c4"), Color("e0a526"), Color("f0e3c3"), Color("4f9d57"), Color("8e55b5")]
	for k in 6:
		var a := k * TAU / 6.0
		var foot := Vector3(cos(a) * 2.8, 0, sin(a) * 2.8)
		var top := Vector3(cos(a) * 0.45, 6.6, sin(a) * 0.45)
		var len := foot.distance_to(top)
		var rb := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.12, len, 0.03)
		rb.mesh = bm
		rb.material_override = Build.mat(ribbon[k])
		var up := (top - foot).normalized()
		var side := up.cross(Vector3(-sin(a), 0, cos(a))).normalized()
		rb.transform = Transform3D(Basis(side, up, side.cross(up)), (top + foot) * 0.5)
		maypole.add_child(rb)
		Build.box(maypole, Vector3(0.1, 0.35, 0.1), foot, C.wood2)
	# the well
	var wp := Vector3(6.0, 0, -14.4)
	Build.cyl(self, 0.95, 1.05, 0.95, wp, C.stone2, 10)
	Build.cyl(self, 0.72, 0.72, 0.02, wp + Vector3(0, 0.9, 0), Color("2c3a44"), 10)
	for s in [-1.0, 1.0]:
		Build.box(self, Vector3(0.16, 2.2, 0.16), wp + Vector3(s * 0.9, 0, 0), C.timber)
	Build.box(self, Vector3(2.0, 0.1, 0.1), wp + Vector3(0, 1.85, 0), C.wood3)
	Build.roof(self, 1.5, 0.7, 2.3, wp + Vector3(0, 2.15, 0), C.thatch, PI / 2)
	Build.box(self, Vector3(0.36, 0.34, 0.36), wp + Vector3(0.3, 1.0, 0.0), C.wood2)
	# the stocks, by Robert Bailiff's, for the improvement of the village
	var sp := Vector3(-7.6, 0, -20.0)
	for s in [-1.0, 1.0]:
		Build.box(self, Vector3(0.18, 1.1, 0.18), sp + Vector3(s * 0.95, 0, 0), C.timber)
	Build.box(self, Vector3(2.1, 0.44, 0.2), sp + Vector3(0, 0.55, 0), C.wood3)
	for hx in [-0.5, 0.0, 0.5]:
		Build.box(self, Vector3(0.16, 0.16, 0.22), sp + Vector3(hx, 0.7, 0), Color("3a2c22"))
	Build.box(self, Vector3(1.4, 0.38, 0.4), sp + Vector3(0, 0, 0.9), C.wood2)               # a bench to watch from
	# the duck pond
	var pp := Vector3(5.6, 0, -19.0)
	Build.cyl(self, 1.9, 1.9, 0.04, pp, C.sand, 14)
	var pond := Build.cyl(self, 1.6, 1.6, 0.06, pp, C.water, 14)
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color("6aaec2")
	pm.roughness = 0.12
	pm.metallic = 0.2
	pond.material_override = pm
	_pond = pp
	for k in 3:                                                                                # (version 7.37) the ducks paddle about
		var dk := Node3D.new(); add_child(dk)
		Build.box(dk, Vector3(0.38, 0.22, 0.24), Vector3(0, 0.05, 0), Color("f2efe4") if k != 2 else Color("8a6a45"))
		Build.box(dk, Vector3(0.14, 0.18, 0.14), Vector3(0.18, 0.25, 0), Color("3c6f43") if k != 2 else Color("6b5236"))
		Build.box(dk, Vector3(0.12, 0.05, 0.08), Vector3(0.3, 0.33, 0), Color("e0a526"))
		Build.box(dk, Vector3(0.1, 0.06, 0.16), Vector3(-0.2, 0.18, 0), Color("e6e2d6") if k != 2 else Color("7a5c3e"), 0.0, 0.0, 0.5)   # a tail, cocked
		if k == 2: dk.scale = Vector3.ONE * 0.8                                                     # (a duck, and a smaller brown one)
		_ducks.append([dk, k * 2.1, [0.9, 0.55, 1.15][k], [0.35, -0.5, 0.25][k]])
	# the cottages' back gardens: a wattle fence and rows of cabbages
	for i in 4:
		var gx := -7.5 + i * 5.0
		for r in 2:
			for c in 4:
				Build.box(self, Vector3(0.36, 0.26, 0.36), Vector3(gx - 1.2 + c * 0.8, 0, 11.5 + r * 1.1), Color("6f9b45") if (c + r) % 2 else Color("82ab52"), rr(0, 1))
	for z in [11.0, 13.2]:
		Build.box(self, Vector3(19.4, 0.5, 0.08), Vector3(0, 0, z), C.wood2)


## The eastern downs: the old mill, its sails turning, and a few sheep who do not care about any of it.
func _downs() -> void:
	var mp := Vector3(D.MILL.x, 0, D.MILL.z)
	Build.cyl(self, 1.9, 2.5, 6.2, mp, C.stone, 10)
	Build.cyl(self, 1.95, 1.95, 0.25, mp + Vector3(0, 6.2, 0), C.timber, 10)
	Build.cone(self, 2.3, 2.4, mp + Vector3(0, 6.45, 0), C.thatch, 10)
	Build.box(self, Vector3(0.16, 1.9, 1.1), mp + Vector3(-2.42, 0.1, 0), C.timber)      # the door, facing the village
	for y in [2.4, 4.4]:
		Build.box(self, Vector3(0.12, 0.7, 0.6), mp + Vector3(-2.25 + y * 0.06, y, 0), Color("3a3f52"))
	mill_sails = Node3D.new()
	mill_sails.position = mp + Vector3(-2.6, 5.6, 0)
	add_child(mill_sails)
	Build.cyl(mill_sails, 0.28, 0.28, 0.5, Vector3(0.1, 0, 0), C.timber, 8, 0.0, 0.0, PI / 2)
	for k in 4:
		Build.box(mill_sails, Vector3(0.14, 5.4, 0.14), Vector3.ZERO, C.timber, 0.0, k * PI / 2)
		Build.box(mill_sails, Vector3(0.05, 4.4, 0.95), Vector3(-0.1, 0.6, 0).rotated(Vector3.RIGHT, k * PI / 2), C.cream, 0.0, k * PI / 2)
	# a sheepfold, and its sheep
	var fp := Vector3(D.MILL.x + 2, 0, D.MILL.z + 11)
	for i in 8:
		Build.box(self, Vector3(1.6, 0.8, 0.1), fp + Vector3(-5.6 + i * 1.6, 0, -3.5), C.wood2)
		Build.box(self, Vector3(1.6, 0.8, 0.1), fp + Vector3(-5.6 + i * 1.6, 0, 3.5), C.wood2)
	for i in 4:
		Build.box(self, Vector3(0.1, 0.8, 1.6), fp + Vector3(-6.4, 0, -2.4 + i * 1.6), C.wood2)
		Build.box(self, Vector3(0.1, 0.8, 1.6), fp + Vector3(6.4, 0, -2.4 + i * 1.6), C.wood2)
	for i in 7:
		var sh := Node3D.new()
		sh.position = fp + Vector3(rr(-5, 5), 0, rr(-2.6, 2.6))
		sh.rotation.y = rr(0, TAU)
		add_child(sh)
		Build.box(sh, Vector3(0.8, 0.55, 0.55), Vector3(0, 0.35, 0), Color("f1ede2"))
		Build.box(sh, Vector3(0.28, 0.3, 0.26), Vector3(0.5, 0.6, 0), Color("2f2a26"))
		for lx in [-0.25, 0.25]:
			for lz in [-0.16, 0.16]:
				Build.box(sh, Vector3(0.08, 0.36, 0.08), Vector3(lx, 0, lz), Color("2f2a26"))
	# the Herder, at the corner of his fold, with his crook (version 7.10)
	var hd := _npc(self, Vector3(D.HERDER.x, 0, D.HERDER.z), -PI / 2, Color("7c8450"), "cap", false)
	Build.box(hd, Vector3(0.07, 1.9, 0.07), Vector3(0.5, 0, 0.25), C.timber)
	Build.box(hd, Vector3(0.07, 0.07, 0.3), Vector3(0.5, 1.9, 0.38), C.timber)
	# and the offering plate by the east gate: a plate on a post
	var pl := Vector3(D.station("plate").x, 0, D.station("plate").z)
	Build.box(self, Vector3(0.14, 1.0, 0.14), pl, C.timber)
	Build.cyl(self, 0.36, 0.3, 0.06, pl + Vector3(0, 1.0, 0), Color("b9a27a"), 10)
	# a track from the east gate out to the mill, worn by the miller and nobody else
	for i in 26:
		Build.box(self, Vector3(rr(0.4, 0.9), 0.08, rr(0.4, 0.9)), Vector3(lerpf(48.0, D.MILL.x - 4, i / 25.0) + rr(-0.6, 0.6), 0, lerpf(D.GATE_Z, D.MILL.z, i / 25.0) + rr(-1, 1)), C.path2, rr(0, 3))


func _farms() -> void:
	for i in 6:
		Build.box(self, Vector3(24, 0.05, 3), Vector3(-58, 0, 22 + i * 3.6), [C.field1, C.field2, C.field3][i % 3])
	for i in 14:
		Build.box(self, Vector3(0.2, 0.9, 0.2), Vector3(-70.5 + i * 2, 0, 19.6), C.wood2)
		Build.box(self, Vector3(0.2, 0.9, 0.2), Vector3(-70.5 + i * 2, 0, 42.8), C.wood2)
	house(-47, 24, PI / 2, 5, 7, 3.6, Color("a9493b"), C.roof2, true, false, 2.6)
	# round bales lying on their sides, their rolled ends showing, and a stack of square ones
	var hay := Color("d9b65a")
	var hay_end := Color("e8cc78")
	for p in [Vector3(-48, 33, 0.3), Vector3(-46.2, 35.6, 1.4), Vector3(-49.2, 38.4, 2.2), Vector3(-63, 27.5, 0.9), Vector3(-56, 39.5, 2.6)]:
		var bale := Node3D.new()
		bale.position = Vector3(p.x, 0, p.y)
		bale.rotation.y = p.z
		add_child(bale)
		Build.cyl(bale, 0.85, 0.85, 1.25, Vector3(-0.625, 0.85, 0), hay, 12, 0.0, 0.0, -PI / 2)
		for sx in [-1.0, 1.0]:                                                 # each end: the face, then the rolled middle
			for e in [[0.78, 0.04, hay_end, 12], [0.42, 0.05, Color("c9a24a"), 10], [0.12, 0.06, Color("b8913e"), 8]]:
				var x0: float = 0.625 if sx > 0 else -0.625 - e[1]
				Build.cyl(bale, e[0], e[0], e[1], Vector3(x0, 0.85, 0), e[2], e[3], 0.0, 0.0, -PI / 2)
		for bx in [-0.3, 0.3]:                                                 # the twine
			Build.cyl(bale, 0.865, 0.865, 0.05, Vector3(bx - 0.025, 0.85, 0), Color("8a6a3c"), 12, 0.0, 0.0, -PI / 2)
	for i in 5:                                                                # square bales, stacked by the farmhouse
		var row := 0 if i < 3 else 1
		var bx: float = -44.6 + (i if row == 0 else i - 3 + 0.5) * 1.15
		Build.box(self, Vector3(1.1, 0.55, 0.62), Vector3(bx, row * 0.55, 29.4), hay if i % 2 else Color("cfac52"))
		Build.box(self, Vector3(0.04, 0.56, 0.64), Vector3(bx - 0.2, row * 0.55, 29.4), Color("8a6a3c"))
		Build.box(self, Vector3(0.04, 0.56, 0.64), Vector3(bx + 0.2, row * 0.55, 29.4), Color("8a6a3c"))
	# (the rocky outcrop and the mine move every morning: sites.gd draws them)



## The old workings under the steel mine: a room built far off to the south, where nobody can see it from the village.
## It is dark: only the rune veins glow, and the daylight down the ladder. A torch shows the rest.
func _mine_room() -> void:
	var M: Dictionary = D.ROOMS.mine
	var n := Node3D.new()
	n.position = Vector3(M.x, 0, M.z)
	add_child(n)
	var rock := Color("4a4652")
	var rock2 := Color("3c3945")
	var rock3 := Color("57525f")
	Build.box(n, Vector3(120, 0.1, 120), Vector3(0, 0.02, 0), Color("09080b"))                 # nothing beyond the walls
	Build.box(n, Vector3(M.hw * 2, 0.1, M.hd * 2), Vector3(0, 0.08, 0), Color("38343d"))
	var rg := RandomNumberGenerator.new()
	rg.seed = 4242
	for i in 26:                                                                              # loose stone on the floor
		Build.box(n, Vector3(rg.randf_range(0.3, 0.9), 0.12, rg.randf_range(0.3, 0.8)), Vector3(rg.randf_range(-6.2, 6.2), 0.12, rg.randf_range(-10, 10)), rock2 if i % 2 else rock3, rg.randf() * 3)
	for i in 9:                                                                               # the back wall, in lumps
		var x := -7.0 + i * 1.75
		Build.box(n, Vector3(2.0, rg.randf_range(3.4, 4.6), rg.randf_range(1.0, 1.7)), Vector3(x, 0, -M.hd - 0.5), rock if i % 2 else rock2, rg.randf_range(-0.15, 0.15))
	for sx in [-1.0, 1.0]:                                                                    # the sides
		for i in 12:
			var z := -10.4 + i * 1.9
			Build.box(n, Vector3(rg.randf_range(1.0, 1.6), rg.randf_range(2.0, 3.0), 2.1), Vector3(sx * (M.hw + 0.55), 0, z), rock2 if i % 2 else rock, rg.randf_range(-0.12, 0.12))
	for i in 9:                                                                               # a low lip at the front, so you can see in
		Build.box(n, Vector3(1.9, rg.randf_range(0.5, 0.9), 0.9), Vector3(-7.0 + i * 1.75, 0, M.hd + 0.4), rock)
	for b in M.box.slice(0, 4):                                                               # pit props
		var px: float = b[0] - M.x
		var pz: float = b[1] - M.z
		Build.box(n, Vector3(0.5, 3.3, 0.5), Vector3(px, 0, pz), C.timber)
	for pz in [3.0, -4.0]:
		Build.box(n, Vector3(7.6, 0.4, 0.5), Vector3(0, 3.3, pz), C.wood2)
	for sx in [-0.55, 0.55]:                                                                  # the rails, and the cart at the end of them
		Build.box(n, Vector3(0.1, 0.1, 17.0), Vector3(1.6 + sx, 0.14, -0.4), C.iron)
	for i in 12:
		Build.box(n, Vector3(1.6, 0.08, 0.26), Vector3(1.6, 0.1, -8.0 + i * 1.45), C.timber)
	var cart := Node3D.new(); cart.position = Vector3(1.6, 0, -7.6); n.add_child(cart)
	Build.box(cart, Vector3(1.5, 0.8, 1.2), Vector3(0, 0.35, 0), C.wood2)
	Build.box(cart, Vector3(1.3, 0.22, 1.0), Vector3(0, 1.1, 0), rock3)
	for sx in [-0.7, 0.7]:
		for sz in [-0.4, 0.4]:
			Build.cyl(cart, 0.26, 0.26, 0.1, Vector3(sx, 0.0, sz), C.iron, 8, 0, 0, PI / 2)
	# the ladder up, and the daylight coming down it
	var lx: float = M.at[0] - M.x
	var lz: float = M.at[1] - M.z
	for sx in [-0.3, 0.3]:
		Build.box(n, Vector3(0.1, 4.6, 0.1), Vector3(lx + sx, 0, lz + 0.9), C.wood, 0, -0.18)
	for i in 8:
		Build.box(n, Vector3(0.6, 0.07, 0.1), Vector3(lx, 0.4 + i * 0.52, lz + 0.9 + 0.09 * i * 0.9), C.wood3)
	var shaft := StandardMaterial3D.new()
	shaft.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shaft.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shaft.albedo_color = Color(0.85, 0.9, 1.0, 0.1)
	shaft.cull_mode = BaseMaterial3D.CULL_DISABLED
	Build.glow_box(n, Vector3(1.6, 6.0, 1.6), Vector3(lx, 0, lz + 0.3), shaft)
	var day := OmniLight3D.new()
	day.light_color = Color(0.8, 0.88, 1.0)
	day.omni_range = 6.5
	day.light_energy = 1.3
	day.position = Vector3(lx, 2.6, lz)
	n.add_child(day)
	# the veins: cold stones with marks on them, glowing a little
	for i in D.RUNE_VEINS.size():
		var v: Array = D.RUNE_VEINS[i]
		var g := Node3D.new()
		g.position = Vector3(v[0] - M.x, 0, v[1] - M.z)
		n.add_child(g)
		var gm := StandardMaterial3D.new()
		gm.albedo_color = Color("6f5fd6")
		gm.emission_enabled = true
		gm.emission = Color("8f7dff")
		gm.emission_energy_multiplier = 1.8
		for j in 6:
			var a := rg.randf() * TAU
			var c := Build.cone(g, rg.randf_range(0.14, 0.3), rg.randf_range(0.5, 1.3), Vector3(cos(a) * rg.randf_range(0.1, 0.8), rg.randf_range(0.0, 1.2), sin(a) * rg.randf_range(0.1, 0.5)), Color.WHITE, 4, rg.randf() * TAU)
			c.material_override = gm
			c.rotation.x = rg.randf_range(-0.5, 0.5); c.rotation.z = rg.randf_range(-0.5, 0.5)
		var l := OmniLight3D.new()
		l.light_color = Color(0.6, 0.5, 1.0)
		l.omni_range = 4.5
		l.light_energy = 0.9
		l.position = Vector3(0, 1.2, 0)
		g.add_child(l)
		_veins.append([g, gm, l])
	# and, up top, the way down (version 7.31: it was a little roof on four posts, like a bus shelter): a shaft in a collar of
	# stones, a headframe over it with a winding wheel and a bucket on its rope, the top of the ladder, a spoil heap, a cart
	# of rubble with a purple lump in it, a lantern, and a warning
	var dp := Vector3(M.door[0], 0, M.door[1])
	var rh := RandomNumberGenerator.new(); rh.seed = 731
	Build.box(self, Vector3(4.6, 0.05, 4.2), dp + Vector3(0, 0.02, 0), Color("8a7a5c"))                # trodden earth round it
	Build.cyl(self, 0.95, 0.95, 0.08, dp + Vector3(0, 0.04, 0), Color("15120f"), 14)                   # the hole
	var hg := StandardMaterial3D.new()                                                        # (version 7.21) and down the hole, the faint purple of the mithril
	hg.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hg.albedo_color = Color(0.56, 0.45, 1.0, 0.35)
	Build.cyl(self, 0.7, 0.7, 0.02, dp + Vector3(0, 0.1, 0), Color.WHITE, 14).material_override = hg
	var hl := OmniLight3D.new(); hl.light_color = Color(0.6, 0.48, 1.0); hl.omni_range = 3.2; hl.light_energy = 0.9
	hl.position = dp + Vector3(0, 0.5, 0); add_child(hl)
	_mine_glow = [hg, hl]
	for i in 12:                                                                              # the collar of stones
		var a := i * TAU / 12.0
		Build.box(self, Vector3(0.62, rh.randf_range(0.36, 0.5), 0.42), dp + Vector3(cos(a) * 1.18, 0, sin(a) * 1.18), C.stone3 if i % 2 else C.stone2, -a + PI / 2)
	# the headframe: an A of timbers either side, a beam across the top, the winding wheel, and the rope with its bucket
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Build.box(self, Vector3(0.18, 3.5, 0.18), dp + Vector3(sx * 1.55, 0, sz * 0.62), C.timber, 0.0, -sz * 0.19, 0.0)
		Build.box(self, Vector3(0.12, 0.12, 1.2), dp + Vector3(sx * 1.55, 1.4, 0), C.wood2)
	Build.box(self, Vector3(3.5, 0.2, 0.22), dp + Vector3(0, 3.3, 0), C.timber)
	Build.cyl(self, 0.62, 0.62, 0.1, dp + Vector3(0, 3.3, 0), C.wood3, 12, 0.0, 0.0, PI / 2).rotation = Vector3(PI / 2, 0, 0)
	Build.cyl(self, 0.16, 0.16, 0.14, dp + Vector3(0, 3.3, 0), C.iron, 8).rotation = Vector3(PI / 2, 0, 0)
	Build.box(self, Vector3(0.03, 1.9, 0.03), dp + Vector3(0.6, 1.5, 0.0), Color("a08562"))            # the rope, and the bucket on it
	Build.cyl(self, 0.2, 0.16, 0.3, dp + Vector3(0.6, 1.25, 0.0), C.wood2, 8)
	Build.box(self, Vector3(0.36, 0.04, 0.04), dp + Vector3(0.6, 1.56, 0.0), C.iron)
	Build.box(self, Vector3(0.5, 0.08, 0.08), dp + Vector3(1.75, 1.0, 0.0), C.timber)                 # and the winch handle
	for sx in [-0.28, 0.28]: Build.box(self, Vector3(0.08, 1.4, 0.08), dp + Vector3(sx - 0.3, -0.3, -0.55), C.wood, 0.0, -0.25)   # the top of the ladder
	for i in 3: Build.box(self, Vector3(0.62, 0.06, 0.08), dp + Vector3(-0.3, 0.25 + i * 0.32, -0.6 - i * 0.08), C.wood3)
	# the spoil heap, and a mcart of rubble on two rails, with a lump that glows purple
	for i in 9: Build.box(self, Vector3(rh.randf_range(0.4, 0.9), rh.randf_range(0.3, 0.7), rh.randf_range(0.4, 0.9)), dp + Vector3(2.6 + rh.randf_range(-0.8, 0.8), 0, -1.6 + rh.randf_range(-0.8, 0.6)), C.stone3.darkened(0.15) if i % 2 else Color("6d5a50"), rh.randf() * 3)
	for sz in [-0.35, 0.35]: Build.box(self, Vector3(3.4, 0.06, 0.08), dp + Vector3(-2.6, 0.04, 1.4 + sz), C.iron)
	for i in 6: Build.box(self, Vector3(0.14, 0.05, 1.0), dp + Vector3(-4.0 + i * 0.6, 0.02, 1.4), C.timber)
	var mcart := Vector3(-2.4, 0, 1.4)
	Build.box(self, Vector3(1.0, 0.55, 0.75), dp + mcart + Vector3(0, 0.22, 0), C.wood2)
	Build.box(self, Vector3(1.06, 0.08, 0.8), dp + mcart + Vector3(0, 0.74, 0), C.iron)
	for sx in [-0.32, 0.32]:
		for sz in [-0.38, 0.38]: Build.cyl(self, 0.14, 0.14, 0.06, dp + mcart + Vector3(sx, 0.14, sz), C.iron, 8).rotation = Vector3(PI / 2, 0, 0)
	for i in 4: Build.box(self, Vector3(0.26, 0.2, 0.24), dp + mcart + Vector3(rh.randf_range(-0.3, 0.3), 0.76, rh.randf_range(-0.2, 0.2)), C.stone3, rh.randf() * 3)
	var lump := Build.box(self, Vector3(0.2, 0.18, 0.2), dp + mcart + Vector3(0.15, 0.86, 0.05), Color.WHITE, 0.5)
	lump.material_override = Build.mat(Color("8f7dff"), 1.6)
	# a lantern on a post, lit at dusk, and a warning
	Build.box(self, Vector3(0.14, 2.0, 0.14), dp + Vector3(1.9, 0, 1.5), C.timber)
	Build.box(self, Vector3(0.5, 0.08, 0.08), dp + Vector3(1.7, 1.95, 1.5), C.timber)
	Build.box(self, Vector3(0.24, 0.3, 0.24), dp + Vector3(1.5, 1.6, 1.5), Color("ffd98a")).material_override = Build.mat(Color("f0a050"), 1.2)
	var ll := OmniLight3D.new(); ll.light_color = Color(1.0, 0.72, 0.4); ll.omni_range = 6.0; ll.light_energy = 0.0
	ll.position = dp + Vector3(1.5, 1.8, 1.5); add_child(ll); lanterns.append(ll)
	Build.box(self, Vector3(0.12, 1.2, 0.12), dp + Vector3(-1.6, 0, 2.0), C.timber)
	Build.box(self, Vector3(0.9, 0.5, 0.06), dp + Vector3(-1.6, 0.8, 2.06), C.wood3, 0.0, 0.0, 0.08)
	var wl := Label3D.new(); wl.text = "OLD MINE\nmind the hole"; wl.font_size = 40; wl.pixel_size = 0.0034; wl.modulate = Color("7a2224"); wl.double_sided = false
	wl.position = dp + Vector3(-1.6, 1.05, 2.1); wl.rotation.z = 0.08; add_child(wl)


## A cave across the river, as a room (version 7.21): rock floor, lumpy walls, a low lip at the front so you can see in,
## and daylight at the way out. Returns the room's node, at its middle.
func _cave_shell(k: String, seed_: int, rock: Color) -> Node3D:
	var M: Dictionary = D.ROOMS[k]
	var n := Node3D.new()
	n.position = Vector3(M.x, 0, M.z)
	add_child(n)
	var rg := RandomNumberGenerator.new(); rg.seed = seed_
	var rock2 := rock.darkened(0.18)
	var rock3 := rock.lightened(0.1)
	Build.box(n, Vector3(60, 0.1, 60), Vector3(0, 0.02, 0), Color("09080b"))                  # nothing beyond the walls
	Build.box(n, Vector3(M.hw * 2, 0.1, M.hd * 2), Vector3(0, 0.08, 0), rock.darkened(0.45))
	for i in 18:                                                                              # loose stone and grit
		Build.box(n, Vector3(rg.randf_range(0.15, 0.35), rg.randf_range(0.08, 0.2), rg.randf_range(0.15, 0.3)), Vector3(rg.randf_range(-M.hw + 0.6, M.hw - 0.6), 0.12, rg.randf_range(-M.hd + 0.6, M.hd - 0.6)), rock2 if i % 2 else rock3, rg.randf() * 3)
	var nb := int(M.hw * 2 / 1.6) + 1
	for i in nb:                                                                              # the back wall, in lumps, leaning in
		Build.box(n, Vector3(1.9, rg.randf_range(3.0, 4.2), rg.randf_range(1.0, 1.6)), Vector3(-M.hw + i * 1.6, 0, -M.hd - 0.5), rock if i % 2 else rock2, rg.randf_range(-0.2, 0.2), 0.12)
	for sx in [-1.0, 1.0]:                                                                    # the sides
		for i in int(M.hd * 2 / 1.7) + 1:
			Build.box(n, Vector3(rg.randf_range(1.0, 1.6), rg.randf_range(2.2, 3.4), 1.9), Vector3(sx * (M.hw + 0.55), 0, -M.hd + i * 1.7), rock2 if i % 2 else rock, rg.randf_range(-0.15, 0.15), 0.0, -sx * 0.1)
	for i in nb:                                                                              # the low lip at the front
		var x: float = -M.hw + i * 1.6
		if absf(x - (M.at[0] - M.x)) < 1.2: continue                                         # (the way out)
		Build.box(n, Vector3(1.8, rg.randf_range(0.5, 1.0), 0.9), Vector3(x, 0, M.hd + 0.4), rock)
	var shaft := StandardMaterial3D.new()                                                     # daylight, coming in at the way out
	shaft.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shaft.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shaft.albedo_color = Color(1.0, 0.96, 0.85, 0.05)
	shaft.cull_mode = BaseMaterial3D.CULL_DISABLED
	Build.glow_box(n, Vector3(1.8, 0.02, 1.6), Vector3(M.at[0] - M.x, 0.14, M.hd + 0.2), shaft)
	var day := OmniLight3D.new(); day.light_color = Color(1.0, 0.95, 0.85); day.omni_range = 4.0; day.light_energy = 0.8
	day.position = Vector3(M.at[0] - M.x, 1.8, M.hd); n.add_child(day)
	return n


## A torch in a bracket on a cave wall, always burning.
func _cave_torch(n: Node3D, at: Vector3, face: float) -> void:
	Build.box(n, Vector3(0.12, 0.7, 0.12), at, C.timber, 0.0, 0.0, face * 0.35)
	Build.cyl(n, 0.14, 0.09, 0.16, at + Vector3(face * 0.12, 0.62, 0), C.iron, 6)
	var f := Build.cone(n, 0.16, 0.5, at + Vector3(face * 0.12, 0.76, 0), Color.WHITE, 5)
	f.material_override = Build.mat(Color(1.0, 0.68, 0.24), 2.8)
	var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.66, 0.32); l.omni_range = 7.0; l.light_energy = 1.6
	l.position = at + Vector3(face * 0.4, 1.2, 0); n.add_child(l)
	_cave_flames.append([f, l])


## Garrick's Cave (version 7.21): a small cave, two torches, and the rubble heap with the chest somewhere under it.
func _tcave_room() -> void:
	var M: Dictionary = D.ROOMS.tcave
	var n := _cave_shell("tcave", 7211, Color("6e6458"))
	var rg := RandomNumberGenerator.new(); rg.seed = 7212
	var rb := Vector3(D.TITHE_RUBBLE.x - M.x, 0, D.TITHE_RUBBLE.z - M.z)
	for j in 26:                                                                              # the heap: rock on rock, the big ones underneath
		var big := j < 9
		var s := rg.randf_range(0.8, 1.4) if big else rg.randf_range(0.4, 0.8)
		var a := rg.randf() * TAU
		var rr := rg.randf_range(0.0, 1.1 if big else 0.9)
		Build.box(n, Vector3(s, s * rg.randf_range(0.6, 0.9), s * rg.randf_range(0.7, 1.0)), rb + Vector3(cos(a) * rr * 1.2, (0.0 if big else rg.randf_range(0.5, 1.2) * (1.2 - rr)), sin(a) * rr * 0.7),
			[Color("7a7064"), Color("675e53"), Color("8a8072")][j % 3], rg.randf() * 3, rg.randf_range(-0.3, 0.3), rg.randf_range(-0.3, 0.3))
	Build.box(n, Vector3(0.7, 0.18, 0.4), rb + Vector3(0.5, 0.35, 0.7), Color("6b4a2e"), 0.4, 0.3)    # the corner of something wooden, poking out
	Build.box(n, Vector3(0.08, 0.06, 0.42), rb + Vector3(0.75, 0.52, 0.72), C.iron, 0.4, 0.3)
	Build.box(n, Vector3(0.9, 0.12, 0.3), rb + Vector3(-1.5, 0.0, 1.0), C.wood3, 0.6)                    # a broken shovel, from a previous optimist
	Build.box(n, Vector3(0.08, 0.08, 1.1), rb + Vector3(-1.1, 0.06, 1.2), C.timber, 0.2)
	var bd: Array = M.box[1]                                                                  # the boulder in the corner
	Build.box(n, Vector3(1.2, 1.0, 1.1), Vector3(bd[0] - M.x, 0, bd[1] - M.z), Color("5e564c"), 0.5, 0.1)
	var om := Build.mat(Color("7d5fb3"), 0.9)                                                 # the day's piece of ore, glinting
	var ore := Build.box(n, Vector3(0.4, 0.3, 0.36), Vector3(D.TITHE_ORE.x - M.x, 0.05, D.TITHE_ORE.z - M.z), Color("7d5fb3"), 0.4)
	ore.material_override = om
	_cave_torch(n, Vector3(-M.hw + 0.25, 1.2, -1.4), 1.0)
	_cave_torch(n, Vector3(M.hw - 0.25, 1.2, -1.4), -1.0)


## The Rune Cave (version 7.21): three seams glowing blue along the back, torches, a statue of Saint Wilbur the Dog Lord
## with his dog, and something glinting behind a rock where nobody can reach it.
func _rcave_room() -> void:
	var M: Dictionary = D.ROOMS.rcave
	var n := _cave_shell("rcave", 7213, Color("62606e"))
	var rg := RandomNumberGenerator.new(); rg.seed = 7214
	for v in D.RUNE_SEAMS:                                                                    # the seams, in the back wall
		var m := Build.mat(Color("3f7ed8"), 1.6)
		var g := Node3D.new(); g.position = Vector3(v[0] - M.x, 0, -M.hd + 0.15); n.add_child(g)
		for j in 8:
			var c := Build.cone(g, rg.randf_range(0.18, 0.34), rg.randf_range(0.7, 1.4), Vector3(rg.randf_range(-0.7, 0.7), rg.randf_range(0.1, 1.8), rg.randf_range(0.0, 0.3)), Color.WHITE, 4, rg.randf() * TAU)
			c.material_override = m
			c.rotation.x = rg.randf_range(0.2, 0.9); c.rotation.z = rg.randf_range(-0.5, 0.5)
		var l := OmniLight3D.new(); l.light_color = Color(0.4, 0.62, 1.0); l.omni_range = 3.6; l.light_energy = 0.8
		l.position = Vector3(0, 1.2, 0.6); g.add_child(l)
		_seams.append([g, m])
	var rk: Array = M.box[0]                                                                  # the rock in the corner, and behind it, out of reach, a glint
	var rp := Vector3(rk[0] - M.x, 0, rk[1] - M.z)
	Build.box(n, Vector3(2.5, 1.5, 2.1), rp, Color("54525e"), 0.3)
	Build.box(n, Vector3(1.4, 0.9, 1.2), rp + Vector3(-0.5, 1.45, 0.35), Color("5e5c68"), 0.9, 0.2)
	for j in 6:                                                                               # (a little heap of gold, just showing over the top of it)
		var tm := Build.mat(Color("f2c94c"), 1.2)
		var t := Build.box(n, Vector3(0.24, 0.14, 0.24), rp + Vector3(0.3 + (j % 3) * 0.26, 1.5 + (j / 3) * 0.13, -0.5 - (j % 2) * 0.22), Color("f2c94c"), j * 0.7)
		t.material_override = tm
		_twinkle.append([t, tm])
	var gl_ := OmniLight3D.new(); gl_.light_color = Color(1.0, 0.85, 0.4); gl_.omni_range = 2.2; gl_.light_energy = 0.7
	gl_.position = rp + Vector3(0.7, 2.4, -0.4); n.add_child(gl_)
	var sp: Array = M.box[1]                                                                  # Saint Wilbur, the Dog Lord, with his dog
	var s := Node3D.new(); s.position = Vector3(sp[0] - M.x, 0, sp[1] - M.z); s.rotation.y = PI * 0.5; s.scale = Vector3.ONE * 1.35; n.add_child(s)
	var stn := Color("9a968c")
	Build.box(s, Vector3(1.1, 0.5, 1.1), Vector3(0, 0, 0), stn.darkened(0.15))
	Build.box(s, Vector3(0.6, 1.1, 0.45), Vector3(-0.15, 0.5, 0), stn)                            # robed
	Build.box(s, Vector3(0.34, 0.34, 0.32), Vector3(-0.15, 1.6, 0), stn.lightened(0.05))
	Build.box(s, Vector3(0.14, 0.5, 0.14), Vector3(0.18, 1.0, 0.1), stn, 0.0, 0.0, -0.9)          # an arm, down to the dog's head
	var hm := TorusMesh.new(); hm.inner_radius = 0.16; hm.outer_radius = 0.2; hm.rings = 16; hm.ring_segments = 5
	var halo := MeshInstance3D.new(); halo.mesh = hm; halo.position = Vector3(-0.15, 2.05, 0)
	halo.material_override = Build.mat(Color(1.0, 0.86, 0.45), 1.2); s.add_child(halo)
	Build.box(s, Vector3(0.24, 0.38, 0.34), Vector3(0.32, 0.5, 0.1), stn)                         # the dog, sitting
	Build.box(s, Vector3(0.2, 0.2, 0.26), Vector3(0.32, 0.88, 0.2), stn.lightened(0.05))
	Build.box(s, Vector3(0.06, 0.12, 0.06), Vector3(0.26, 1.0, 0.18), stn)
	Build.box(s, Vector3(0.06, 0.12, 0.06), Vector3(0.38, 1.0, 0.18), stn)
	for j in 3: Build.box(s, Vector3(0.1, 0.12, 0.1), Vector3(-0.4 + j * 0.3, 0.5, 0.5), Color("e8dcc0"))    # candle stubs, left by somebody
	var pr: Array = M.box[2]                                                                  # a prop holding the roof up, more or less
	Build.box(n, Vector3(0.3, 3.2, 0.3), Vector3(pr[0] - M.x, 0, pr[1] - M.z), C.timber, 0.0, 0.05)
	_cave_torch(n, Vector3(-M.hw + 0.25, 1.2, -2.0), 1.0)
	_cave_torch(n, Vector3(M.hw - 0.25, 1.2, 0.6), -1.0)
	_cave_torch(n, Vector3(-M.hw + 0.25, 1.2, 2.2), 1.0)


## Somebody to talk to, made of boxes: coat, head, and something on the head. Seated ones have no legs to speak of.
func _npc(parent: Node3D, pos: Vector3, rot_y: float, coat: Color, hat: String, seated: bool = true, skin: Color = Color("e0b48c")) -> Node3D:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = rot_y
	parent.add_child(g)
	var y0 := 0.42 if seated else 0.5
	if not seated:
		for sx in [-0.14, 0.14]: Build.box(g, Vector3(0.2, 0.5, 0.22), Vector3(sx, 0, 0), Color("3a2f28"))
	else:
		Build.box(g, Vector3(0.5, 0.2, 0.5), Vector3(0, 0.4, 0.2), coat.darkened(0.2))                # a lap
	Build.box(g, Vector3(0.64, 0.78, 0.42), Vector3(0, y0, 0), coat)
	for sx in [-0.4, 0.4]: Build.box(g, Vector3(0.16, 0.5, 0.18), Vector3(sx, y0 + 0.22, 0.08), coat, 0, -0.5)
	Build.box(g, Vector3(0.4, 0.4, 0.38), Vector3(0, y0 + 0.8, 0.02), skin)
	match hat:
		"hood":
			Build.box(g, Vector3(0.5, 0.5, 0.5), Vector3(0, y0 + 0.78, -0.04), coat.darkened(0.25))
			Build.box(g, Vector3(0.34, 0.3, 0.1), Vector3(0, y0 + 0.82, 0.2), Color("15121a"))        # nothing to see in there
		"bonnet":
			Build.box(g, Vector3(0.46, 0.2, 0.44), Vector3(0, y0 + 1.14, -0.02), Color("efe6cf"))
			Build.box(g, Vector3(0.5, 0.3, 0.12), Vector3(0, y0 + 0.86, -0.2), Color("efe6cf"))
		"cap":
			Build.box(g, Vector3(0.44, 0.14, 0.44), Vector3(0, y0 + 1.18, 0), Color("5b4130"))
			Build.box(g, Vector3(0.3, 0.05, 0.2), Vector3(0, y0 + 1.18, 0.28), Color("5b4130"))
		"jester":                                   # a soft cap, red and green halves, with its points drooping
			Build.box(g, Vector3(0.22, 0.24, 0.44), Vector3(-0.11, y0 + 1.14, 0), Color("c0262e"))
			Build.box(g, Vector3(0.22, 0.24, 0.44), Vector3(0.11, y0 + 1.14, 0), Color("2f8a46"))
			Build.box(g, Vector3(0.14, 0.34, 0.14), Vector3(-0.3, y0 + 0.98, 0), Color("c0262e"), 0, 0, 0.5)
			Build.box(g, Vector3(0.14, 0.34, 0.14), Vector3(0.3, y0 + 0.98, 0), Color("2f8a46"), 0, 0, -0.5)
		"bald":
			Build.box(g, Vector3(0.42, 0.1, 0.3), Vector3(0, y0 + 0.86, -0.14), Color("8a8478"))
			Build.box(g, Vector3(0.3, 0.16, 0.06), Vector3(0, y0 + 0.86, 0.2), Color("8a8478"))       # and a moustache to make up for it
	return g


## Inside the Thorny Rose: a room to walk into (it is really far off to the south, like the old workings). The bar and the
## innkeeper, a fire, Old Marge and Tam the Carter at their tables, a stranger in the corner, the gambler, and a bookshelf.
func _inn_room() -> void:
	var M: Dictionary = D.ROOMS.inn
	var n := Node3D.new()
	n.position = Vector3(M.x, 0, M.z)
	add_child(n)
	var plaster := Color("d9c9a3")
	var board := Color("8a6a45")
	Build.box(n, Vector3(120, 0.1, 120), Vector3(0, 0.02, 0), Color("120d0a"))
	Build.box(n, Vector3(M.hw * 2, 0.1, M.hd * 2), Vector3(0, 0.08, 0), board)
	for i in 8:                                                                                 # floorboards
		Build.box(n, Vector3(0.06, 0.02, M.hd * 2), Vector3(-7.0 + i * 2.0, 0.18, 0), Color("6f5335"))
	Build.box(n, Vector3(4.4, 0.03, 3.0), Vector3(0, 0.19, 2.4), Color("7d2f2a"))                # a rug that has seen things
	Build.box(n, Vector3(3.8, 0.035, 2.4), Vector3(0, 0.19, 2.4), Color("9b4a35"))
	# walls: the back one full height, the sides lower, the front only a sill so you can see in
	Build.box(n, Vector3(M.hw * 2 + 0.6, 3.4, 0.3), Vector3(0, 0, -M.hd - 0.15), plaster)
	for i in 6:
		Build.box(n, Vector3(0.22, 3.4, 0.36), Vector3(-8.0 + i * 3.2, 0, -M.hd - 0.12), C.timber)
	Build.box(n, Vector3(M.hw * 2 + 0.6, 0.24, 0.36), Vector3(0, 3.3, -M.hd - 0.12), C.timber)
	for sx in [-1.0, 1.0]:
		Build.box(n, Vector3(0.3, 2.5, M.hd * 2), Vector3(sx * (M.hw + 0.15), 0, 0), plaster)
		for i in 4:
			Build.box(n, Vector3(0.36, 2.5, 0.22), Vector3(sx * (M.hw + 0.12), 0, -5.6 + i * 3.7), C.timber)
	for sx in [-1.0, 1.0]:
		Build.box(n, Vector3(M.hw - 1.0, 0.5, 0.3), Vector3(sx * (M.hw + 1.0) / 2.0, 0, M.hd + 0.15), plaster)
		Build.box(n, Vector3(0.24, 2.3, 0.3), Vector3(sx * 0.95, 0, M.hd + 0.15), C.timber)          # the door posts
	Build.box(n, Vector3(2.2, 0.22, 0.3), Vector3(0, 2.3, M.hd + 0.15), C.timber)
	Build.box(n, Vector3(1.5, 0.04, 0.5), Vector3(0, 0.14, M.hd - 0.1), C.path2)                    # the worn step
	# the bar, the barrels behind it, and the innkeeper
	Build.box(n, Vector3(9.2, 1.05, 1.1), Vector3(0, 0, -4.7), C.wood2)
	Build.box(n, Vector3(9.5, 0.12, 1.3), Vector3(0, 1.05, -4.7), C.wood3)
	for i in 4:
		Build.cyl(n, 0.5, 0.5, 1.0, Vector3(-6.4 + i * 1.15, 1.2, -5.5), C.wood, 9, 0, 0, PI / 2)
	for i in 5:
		Build.cyl(n, 0.1, 0.09, 0.2, Vector3(-3.0 + i * 1.4, 1.17, -4.5 + (i % 2) * 0.2), Color("b9bcc4"), 7)     # tankards
	Build.box(n, Vector3(5.0, 0.1, 0.4), Vector3(2.4, 2.1, -5.7), C.wood)                             # a shelf of bottles
	for i in 7:
		Build.cyl(n, 0.07, 0.1, 0.34, Vector3(0.4 + i * 0.66, 2.2, -5.7), [Color("3f6b3a"), Color("7a4a22"), Color("4f6480")][i % 3], 6)
	_npc(n, Vector3(0, 0, -5.5), 0.0, Color("7a5a3a"), "bald", false)
	Build.box(n, Vector3(0.7, 0.5, 0.06), Vector3(0, 0.6, -5.27), Color("efe6cf"))                    # his apron
	# the fire, on the west wall, and Old Marge beside it with her knitting
	Build.box(n, Vector3(0.7, 2.0, 2.4), Vector3(-M.hw + 0.35, 0, 3.3), C.stone2)
	Build.box(n, Vector3(0.5, 1.0, 1.5), Vector3(-M.hw + 0.5, 0, 3.3), Color("1b1612"))
	Build.box(n, Vector3(0.9, 0.16, 2.7), Vector3(-M.hw + 0.4, 2.0, 3.3), C.stone3)
	var flame := StandardMaterial3D.new()
	flame.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame.albedo_color = Color(1.0, 0.62, 0.18)
	for i in 3:
		Build.cone(n, 0.22 - i * 0.04, 0.6 + i * 0.12, Vector3(-M.hw + 0.62, 0.1, 2.9 + i * 0.4), Color.WHITE, 5).material_override = flame
	_inn_fire = OmniLight3D.new()
	_inn_fire.light_color = Color(1.0, 0.6, 0.28)
	_inn_fire.omni_range = 11.0
	_inn_fire.position = Vector3(-M.hw + 1.4, 1.2, 3.3)
	n.add_child(_inn_fire)
	for at in [Vector3(-4.6, 0, 0.9), Vector3(4.4, 0, 1.2)]:                                          # two round tables, with stools
		Build.cyl(n, 0.85, 0.85, 0.1, at + Vector3(0, 0.78, 0), C.wood3, 10)
		Build.cyl(n, 0.14, 0.2, 0.78, at, C.wood2, 6)
		for a in [0.9, 2.6, 4.4]:
			Build.cyl(n, 0.26, 0.26, 0.42, at + Vector3(cos(a) * 1.35, 0, sin(a) * 1.35), C.wood, 7)
		Build.cyl(n, 0.1, 0.09, 0.2, at + Vector3(0.3, 0.88, -0.1), Color("b9bcc4"), 7)
	_npc(n, Vector3(-4.6, 0, -0.35), 0.0, Color("8a6f8f"), "bonnet")
	Build.box(n, Vector3(0.5, 0.06, 1.5), Vector3(-4.6, 0.72, 0.2), Color("9a9a9a"), 0.2)             # the knitting, which is long, and grey
	_npc(n, Vector3(4.4, 0, -0.1), 0.0, Color("5d6b3f"), "cap")
	# the stranger's corner, a long way from the fire: a small table and a chair of his own (version 7.22: he had been sat in the barrels)
	Build.box(n, Vector3(1.1, 0.72, 0.9), Vector3(6.2, 0, 4.3), C.wood2)
	Build.box(n, Vector3(1.2, 0.06, 1.0), Vector3(6.2, 0.72, 4.3), C.wood3)
	Build.cyl(n, 0.1, 0.09, 0.2, Vector3(6.0, 0.78, 4.1), Color("b9bcc4"), 7)                        # a drink that has not gone down
	Build.cyl(n, 0.05, 0.05, 0.14, Vector3(6.4, 0.78, 4.5), Color("e8dcc0"), 6)                      # and a stub of candle
	Build.box(n, Vector3(0.6, 0.42, 0.6), Vector3(7.1, 0, 4.3), C.wood)                               # his chair
	Build.box(n, Vector3(0.1, 0.8, 0.6), Vector3(7.38, 0.42, 4.3), C.wood)
	_npc(n, Vector3(7.05, 0, 4.3), -PI * 0.5, Color("3b3340"), "hood")
	# the gambler's table: a pack of cards and three cups
	Build.box(n, Vector3(1.8, 0.8, 1.4), Vector3(6.6, 0, -3.4), C.wood2)
	Build.box(n, Vector3(1.9, 0.05, 1.5), Vector3(6.6, 0.8, -3.4), Color("3f6b3a"))
	for i in 3:
		Build.cyl(n, 0.1, 0.14, 0.2, Vector3(6.2 + i * 0.36, 0.85, -3.2), Color("8a5a34"), 7)
	Build.box(n, Vector3(0.22, 0.08, 0.3), Vector3(7.1, 0.85, -3.6), Color("efe6cf"), 0.3)
	_npc(n, Vector3(7.3, 0, -4.3), -0.6, Color("4a2f52"), "hood")
	# the bookshelf, with its one book
	Build.box(n, Vector3(0.6, 2.6, 2.4), Vector3(-M.hw + 0.35, 0, -0.7), C.wood2)
	for sy in [0.7, 1.4, 2.1]:
		Build.box(n, Vector3(0.66, 0.08, 2.3), Vector3(-M.hw + 0.37, sy, -0.7), C.wood3)
	Build.box(n, Vector3(0.5, 0.02, 0.9), Vector3(-M.hw + 0.42, 0.78, -0.7), Color("a8916b"))         # where the book was (version 7.11: Prospero took it back)
	# Prospero, the old jester, on a stool by the fire, with his cap and bells on the floor beside him
	Build.cyl(n, 0.26, 0.26, 0.42, Vector3(-6.6, 0, 4.6), C.wood, 7)
	_npc(n, Vector3(-6.6, 0, 4.6), PI * 0.62, Color("6b2a4a"), "jester")
	Build.box(n, Vector3(0.3, 0.16, 0.3), Vector3(-5.9, 0.1, 5.2), Color("c0262e"), 0.4)
	Build.box(n, Vector3(0.1, 0.1, 0.1), Vector3(-5.7, 0.12, 5.4), Color("f2c94c"))
	# light: lanterns over the bar and the room, warm
	for at in [Vector3(-3.2, 2.9, -3.2), Vector3(3.6, 2.9, -2.6), Vector3(1.0, 2.9, 2.6)]:
		Build.box(n, Vector3(0.3, 0.36, 0.3), at, Color("ffd98a")).material_override = Build.mat(Color("f0a050"), 1.4)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.82, 0.55)
		l.omni_range = 10.0
		l.light_energy = 1.5
		l.position = at
		n.add_child(l)


## The far bank (version 7.12; redrawn in 7.14): the Riverside, a long way off the map like the inn and the mine. A small
## hamlet inside a fence with four gates, its market round a bonfire, the druid's cottage with a tree growing out of it, a
## pen with a cow and a donkey, chickens, a well and two of the hamlet's folk. Outside: the two caves, each in a hill of
## its own and signed, the far ruin in the fields, the road south to Hallowshire Town with a broken cart at the start of it,
## and the river along the north, running as the village's does. And on the village bank, the raft (or the wood for it).
func _riverside() -> void:
	var M: Dictionary = D.ROOMS.riverside
	var c0 := Vector3(M.x, 0, M.z)
	var rg := RandomNumberGenerator.new()
	rg.seed = 7140
	var r := func(a: float, b: float) -> float: return rg.randf_range(a, b)
	# --- the ground: fields and hedgerows round the hamlet, and the grass inside its fence
	var north: float = M.z - M.hd - 0.6                                                   # (version 7.21: the fields stop at the riverbank, and no longer cover the river)
	Build.box(self, Vector3(M.hw * 2 + 60, 0.1, M.z + M.hd + 35 - north), Vector3(M.x, -0.02, (north + M.z + M.hd + 35) / 2.0), Color("86a85a"))
	Build.box(self, Vector3(M.hw * 2, 0.1, M.hd * 2), c0 + Vector3(0, 0.0, 0), Color("8fb062"))
	for i in 160:                                                                        # the grass is not a carpet: tufts and patches
		Build.box(self, Vector3(r.call(1.0, 4.0), 0.03, r.call(1.0, 3.0)), Vector3(r.call(M.x - M.hw, M.x + M.hw), 0.03, r.call(M.z - M.hd + 3, M.z + M.hd)), [C.grass2, C.grass3, Color("7f9f52"), Color("98b86a")][i % 4], r.call(0, 3))
	var fields := [[-128.0, 338.0, 22.0, 18.0, C.field1], [-128.0, 352.0, 22.0, 9.0, C.field3], [-206.0, 326.0, 8.0, 12.0, C.field3], [-120.0, 322.0, 14.0, 7.0, C.field2]]
	for fd in fields:
		Build.box(self, Vector3(fd[2], 0.04, fd[3]), Vector3(fd[0], 0.02, fd[1]), fd[4])
		for k in int(fd[3] / 1.2):                                                       # furrows
			Build.box(self, Vector3(fd[2] - 0.6, 0.05, 0.16), Vector3(fd[0], 0.03, fd[1] - fd[3] / 2 + 0.6 + k * 1.2), Color(fd[4]).darkened(0.12))
	for h in [[-140.0, 330.0, 26.0, 0.0], [-117.0, 338.0, 18.0, PI / 2], [-200.0, 333.0, 14.0, 0.0], [-210.0, 318.0, 18.0, PI / 2]]:   # hedgerows
		var hd := Vector3(h[0], 0, h[1])
		for k in int(h[2] / 1.4):
			var off := Vector3(-h[2] / 2 + k * 1.4, 0, 0).rotated(Vector3.UP, h[3])
			Build.cone(self, r.call(0.9, 1.2), r.call(1.4, 1.9), hd + off, [C.hedge, C.hedge2, C.hedge3][k % 3], 6, r.call(0, 3))
	Build.box(self, Vector3(35.0, 0.06, 29.0), Vector3(-160, 0.03, 311), Color("a3b86e"))   # the hamlet's own green, inside the fence, worn
	for i in 40:                                                                         # trees, round the edge of the countryside
		var a := rg.randf() * TAU
		var e := Vector3(cos(a) * (M.hw + r.call(-2, 10)), 0, sin(a) * (M.hd + r.call(-2, 10)))
		if e.z < -M.hd + 4 or (absf(e.x) < 5 and e.z > 0): continue                      # (not in the river, nor across the road)
		_tree(c0 + e, r.call(0.9, 1.4), i)
	for t in [Vector3(-206, 0, 296), Vector3(-114, 0, 296), Vector3(-200, 0, 352), Vector3(-136, 0, 350), Vector3(-174, 0, 354), Vector3(-115, 0, 326)]:
		_tree(t, r.call(1.1, 1.5), int(t.x))
	for i in 10:                                                                         # hay bales in the fields
		Build.cyl(self, 0.6, 0.6, 1.1, Vector3(r.call(-138, -118), 0.6, r.call(331, 356)), C.straw, 10, r.call(0, 3), 0, PI / 2)
	# --- the river along the north, as the village's runs, with its banks, reeds and lily pads
	var rz: float = M.z - M.hd - 8.5
	add_child(_water(Vector3(M.x, 0.05, rz), Vector2(M.hw * 2 + 80, 16.0), rz, 8.0))
	Build.box(self, Vector3(M.hw * 2 + 80, 0.05, 2.6), Vector3(M.x, 0.07, M.z - M.hd + 0.4), C.sand)   # (raised above the grass, version 7.21)
	Build.box(self, Vector3(M.hw * 2 + 80, 0.05, 2.4), Vector3(M.x, 0.0, rz - 8.6), C.sand)
	for i in 50:
		Build.box(self, Vector3(r.call(2, 5), 0.055, r.call(0.6, 1.6)), Vector3(r.call(M.x - M.hw - 30, M.x + M.hw + 30), 0, M.z - M.hd + r.call(1.0, 2.0)), C.sand if i % 3 else C.grass3, r.call(-0.2, 0.2))
	var reed := BoxMesh.new(); reed.size = Vector3(0.06, 1.0, 0.06)
	var xf: Array[Transform3D] = []
	var cols: Array[Color] = []
	for i in 46:
		var cx: float = r.call(M.x - M.hw - 25, M.x + M.hw + 25)
		if absf(cx - M.x) < 4: continue                                                  # (not across the landing)
		var cz: float = (M.z - M.hd - r.call(0.6, 1.6)) if i % 3 else (rz - 7.2 + r.call(0, 1))
		for j in 7:
			var hh: float = r.call(0.7, 1.6)
			xf.append(Transform3D(Basis.from_euler(Vector3(r.call(-0.18, 0.18), 0, r.call(-0.18, 0.18))).scaled(Vector3(1, hh, 1)), Vector3(cx + r.call(-0.6, 0.6), hh * 0.5 - 0.05, cz + r.call(-0.4, 0.4))))
			cols.append([Color("6f8f3f"), Color("86a24a"), Color("a39352")][j % 3])
	_multi(reed, xf, cols)
	var pad := CylinderMesh.new(); pad.top_radius = 0.42; pad.bottom_radius = 0.42; pad.height = 0.03; pad.radial_segments = 9
	var pxf: Array[Transform3D] = []
	var pcol: Array[Color] = []
	for i in 46:
		var s: float = r.call(0.6, 1.3)
		pxf.append(Transform3D(Basis.from_euler(Vector3(0, r.call(0, 6), 0)).scaled(Vector3(s, 1, s)), Vector3(r.call(M.x - M.hw - 25, M.x + M.hw + 25), 0.075, M.z - M.hd - r.call(2.2, 3.6) if i % 2 else rz - r.call(4.5, 6.5))))
		pcol.append(Color("5b8a3c") if i % 5 else Color("e8d6e4"))
	_multi(pad, pxf, pcol)
	for i in 30:                                                                         # bushes on the far side
		Build.cone(self, r.call(1.2, 2.2), r.call(1.6, 3.2), Vector3(r.call(M.x - M.hw - 30, M.x + M.hw + 30), 0, rz - r.call(10, 16)), [C.leaf, C.leaf2, C.hedge3][i % 3], 6, r.call(0, 3))
	# --- the landing: a jetty out into the river, and the raft tied up at it
	var lp := Vector3(M.at[0], 0, M.at[1])
	for k in 6: Build.box(self, Vector3(3.2, 0.18, 0.9), lp + Vector3(0, 0.12, -1.0 - k * 0.95), C.wood2 if k % 2 else C.wood3)
	for sx in [-1.7, 1.7]:
		for k in 3: Build.box(self, Vector3(0.24, 1.0, 0.24), lp + Vector3(sx, -0.3, -0.6 - k * 2.2), C.timber)
	_raft_far = _raft_node(lp + Vector3(0, 0, -7.4))
	# --- paths: from the north gate to the market, and on to the south gate and the road; and to the east and west gates
	var path := func(a: Vector3, b: Vector3, n: int, w: float) -> void:
		for k in n:
			var t := k / float(maxi(1, n - 1))
			var at := a.lerp(b, t)
			Build.box(self, Vector3(r.call(w * 0.6, w), 0.07, r.call(0.6, 1.0)), at + Vector3(r.call(-0.5, 0.5), 0.02, r.call(-0.3, 0.3)), C.path2 if k % 3 else C.path, r.call(-0.3, 0.3))
	path.call(lp + Vector3(0, 0, 0.5), Vector3(-160, 0, 302), 14, 2.6)
	path.call(Vector3(-160, 0, 318), Vector3(-160, 0, 362), 34, 3.2)                    # and on, as the road south
	path.call(Vector3(-166, 0, 308), Vector3(-186, 0, 308), 14, 2.0)
	path.call(Vector3(-154, 0, 308), Vector3(-134, 0, 308), 14, 2.0)
	path.call(Vector3(-178, 0, 329), Vector3(-190, 0, 340), 10, 1.6)                    # to the far ruin
	for k in 26:                                                                         # the road's two ruts
		for sx in [-0.9, 0.9]: Build.box(self, Vector3(0.3, 0.075, 0.9), Vector3(-160 + sx, 0.03, 328 + k * 1.3), Color("b49a62"))
	# --- the market: cobbles round the bonfire
	for i in 70:
		var a := rg.randf() * TAU
		var d: float = r.call(1.8, 6.4)
		Build.box(self, Vector3(r.call(0.4, 0.7), 0.06, r.call(0.4, 0.7)), Vector3(-160 + cos(a) * d, 0.03, 309 + sin(a) * d * 0.9), C.stone if i % 2 else C.stone2, r.call(0, 3))
	_bonfire(Vector3(D.CAMPFIRE.x, 0, D.CAMPFIRE.z))
	# the merchant who never leaves: a stall with a striped awning
	var st := Vector3(-168, 0, 303)
	Build.box(self, Vector3(3.2, 1.0, 1.2), st, C.wood2)
	for sx in [-1.5, 1.5]: Build.box(self, Vector3(0.14, 2.4, 0.14), st + Vector3(sx, 0, 0.5), C.timber)
	for k in 6: Build.box(self, Vector3(0.6, 0.1, 1.9), st + Vector3(-1.5 + k * 0.6, 2.4, 0.2), Color("3f6b8f") if k % 2 else Color("efe6cf"))
	for i in 4: Build.box(self, Vector3(0.45, 0.3, 0.32), st + Vector3(-1.1 + i * 0.75, 1.0, 0), [C.wood, C.stone, C.iron, Color("3f7ed8")][i])
	Build.box(self, Vector3(0.6, 0.5, 0.6), st + Vector3(2.2, 0, -0.2), C.wood3)
	_npc(self, st + Vector3(0, 0, -0.9), 0.0, Color("4b5a3a"), "cap", false)
	# the travelling merchant: his cart, with a canvas cover
	var ct := Vector3(-152, 0, 303)
	Build.box(self, Vector3(2.6, 0.9, 1.4), ct + Vector3(0, 0.6, 0), C.wood)
	for sx in [-1.2, 1.2]: Build.cyl(self, 0.6, 0.6, 0.18, ct + Vector3(sx, 0.6, 0.78), C.timber, 10, 0, PI / 2)
	Build.cyl(self, 0.75, 0.75, 2.4, ct + Vector3(0, 1.5, 0), Color("cdb98f"), 10, PI / 2, 0, PI / 2)
	_npc(self, ct + Vector3(1.8, 0, 0.6), -PI / 2, Color("6a4a7a"), "hood", false)
	# --- the druid: his cottage, with a tree growing out of it, flowers and mushrooms round it, and his table of potions
	_druid_cottage(Vector3(-174, 0, 316.5))
	# --- three houses, with window boxes, gardens and smoke
	house(-174.5, 300.0, 0.0, 4.0, 3.6, 2.2, C.cream2, C.thatch, false, true)
	house(-149.0, 322.6, 0.0, 5.2, 4.4, 2.3, C.cream, C.roof3, false, true)
	house(-145.5, 299.4, 0.0, 4.8, 4.0, 2.2, C.cream2, C.roof2, false, true)
	for hp in [Vector3(-174.5, 0, 302.0), Vector3(-149, 0, 320.2), Vector3(-145.5, 0, 301.6)]:
		for sx in [-1.2, 1.2]:                                                           # window boxes, full of flowers
			Build.box(self, Vector3(0.9, 0.22, 0.3), hp + Vector3(sx, 1.0, -0.05), C.wood2)
			for f in 4: Build.box(self, Vector3(0.14, 0.14, 0.14), hp + Vector3(sx - 0.33 + f * 0.22, 1.22, -0.05), [Color("e05a7a"), Color("f2c94c"), Color("f0f0ff"), Color("b36ad8")][f])
	for i in 3: Build.cyl(self, 0.32, 0.36, 0.8, Vector3(-166.6 + i * 0.75, 0, 325.4), C.wood, 8)   # barrels
	_washing(Vector3(-153, 0, 325), Vector3(-145, 0, 325))
	# --- the well, and the two folk of the hamlet
	var wl := Vector3(-155, 0, 316)
	Build.cyl(self, 0.9, 0.95, 0.8, wl, C.stone2, 10)
	Build.cyl(self, 0.7, 0.7, 0.05, wl + Vector3(0, 0.75, 0), Color("2c4a5a"), 10)
	for sx in [-0.8, 0.8]: Build.box(self, Vector3(0.14, 1.9, 0.14), wl + Vector3(sx, 0, 0), C.timber)
	Build.roof(self, 2.2, 0.7, 1.4, wl + Vector3(0, 1.9, 0), C.roof2, PI / 2)
	Build.cyl(self, 0.18, 0.15, 0.3, wl + Vector3(0.3, 1.0, 0), C.wood, 7)
	_npc(self, Vector3(-155.0, 0, 317.5), PI, Color("4a3f5a"), "bonnet", false)          # Widow Thrupp
	_npc(self, Vector3(-150.6, 0, 318.0), PI, Color("8a6a3a"), "cap", false)             # Young Ned
	# --- the pen, with Dorothy the cow and the Donkey in it, and the chickens loose about the market
	_pen(Vector3(-147.5, 0, 314))
	for i in 7:
		var ch := _chicken(i)
		var at := Vector3(r.call(-166, -153), 0, r.call(306, 321))
		ch.position = at
		_chickens.append([ch, at, at, r.call(0, 2)])
	# --- the fence round the hamlet, with its four gates, and torches at them and round the market
	_hamlet_fence()
	for tp in [Vector3(-162.4, 0, 295.6), Vector3(-157.6, 0, 295.6), Vector3(-162.4, 0, 326.4), Vector3(-157.6, 0, 326.4), Vector3(-178.4, 0, 305.6), Vector3(-178.4, 0, 310.4),
			Vector3(-141.6, 0, 305.6), Vector3(-141.6, 0, 310.4), Vector3(-166.5, 0, 312.5), Vector3(-153.5, 0, 312.5), Vector3(-166.5, 0, 306.0), Vector3(-153.5, 0, 306.0), Vector3(-187.0, 0, 303.0), Vector3(-133.0, 0, 303.0)]:
		_torch(tp)
	# --- the two caves, each in a hill of its own, and signed
	_hill(Vector3(-196, 0, 308), 9.0, true)                                              # Garrick's cave, to the west
	_hill(Vector3(-124, 0, 308), 9.0, false)                                             # the Rune Cave, to the east
	_npc(self, Vector3(-183.0, 0, 302.4), PI * 0.5, Color("7a3a2a"), "bald", false)      # Garrick, at the mouth of his cave (version 7.21)
	var sf := Vector3(-137.0, 0, 302.4)                                                  # and a shady fellow, leaning on a post by the other one
	Build.box(self, Vector3(0.16, 1.6, 0.16), sf + Vector3(0.45, 0, -0.35), C.timber)
	_npc(self, sf, -PI * 0.5, Color("3b3540"), "hood", false, Color("c9a07c")).rotation.z = 0.12
	_rcave_boards = Node3D.new(); add_child(_rcave_boards)                               # boarded up, until he is paid
	for k in 4:
		Build.box(_rcave_boards, Vector3(0.12, 0.34, 4.6), Vector3(-133.6, 0.5 + k * 0.7, 308.0), C.wood2 if k % 2 else C.wood3, 0.0, (0.12 if k % 2 else -0.1))
	_rcave_props = Node3D.new(); add_child(_rcave_props)
	for z in [304.0, 308.0, 312.0]:                                                      # props and planks, once it is made fit
		Build.box(_rcave_props, Vector3(0.22, 3.0, 0.22), Vector3(-135.0, 0, z), C.timber)
	Build.box(_rcave_props, Vector3(0.22, 0.22, 8.4), Vector3(-135.0, 2.9, 308), C.timber)
	Build.box(_rcave_props, Vector3(2.4, 0.08, 1.2), Vector3(-136.5, 0.05, 308), C.wood3)
	# --- the far ruin, out in the fields to the south-west: nothing in it bites
	for i in 9:
		Build.box(self, Vector3(r.call(1.0, 3.0), r.call(0.6, 2.2), 0.6), Vector3(r.call(-204, -176), 0, r.call(335, 351)), C.stone2 if i % 2 else C.stone3, r.call(0, 3))
	for sp in D.RIVER_SPOTS:
		for j in 4: Build.box(self, Vector3(r.call(0.5, 1.1), r.call(0.3, 0.6), r.call(0.5, 1.0)), Vector3(sp[0] + r.call(-0.7, 0.7), 0, sp[1] + r.call(-0.7, 0.7)), C.stone if j % 2 else C.stone2, r.call(0, 3))
	# --- the road to Hallowshire Town: a signpost, and a broken cart at the start of it
	var sg := Vector3(-163.6, 0, 331.0)
	Build.box(self, Vector3(0.16, 2.2, 0.16), sg, C.timber)
	Build.box(self, Vector3(1.6, 0.36, 0.08), sg + Vector3(0.5, 1.7, 0), C.wood3, 0, 0, -0.06)
	Build.box(self, Vector3(0.3, 0.3, 0.08), sg + Vector3(1.4, 1.73, 0), C.wood3, 0, 0, PI / 4)
	var bc := Vector3(-155.5, 0, 333.0)                                                  # the cart: down on one side, a wheel off, its load spilt
	Build.box(self, Vector3(3.0, 0.8, 1.6), bc + Vector3(0, 0.25, 0), C.wood2, 0.25, 0, 0.18)
	Build.cyl(self, 0.62, 0.62, 0.16, bc + Vector3(0.5, 0.62, 0.95), C.timber, 10, 0.25, PI / 2)
	Build.cyl(self, 0.62, 0.62, 0.16, bc + Vector3(1.9, 0.08, 1.9), C.timber, 10, 0.6, 0, 0)  # the one that came off
	Build.box(self, Vector3(0.12, 0.12, 2.6), bc + Vector3(-1.8, 0.1, -0.6), C.timber, 0.5)
	for k in 3: Build.box(self, Vector3(0.6, 0.5, 0.6), bc + Vector3(-0.4 + k * 0.8, 0, -1.4 - (k % 2) * 0.5), C.wood3, k * 0.6)
	Build.cyl(self, 0.32, 0.36, 0.8, bc + Vector3(1.6, 0, -1.1), C.wood, 8, 0, PI / 2)
	# --- and on the village bank: the raft, or what there is of it so far
	var dr := Vector3(M.door[0], 0, M.door[1])
	_raft = _raft_node(dr + Vector3(0, 0, 3.2))
	_raft_pile = Node3D.new(); add_child(_raft_pile)
	for i in 6: Build.cyl(_raft_pile, 0.25, 0.25, 3.2, dr + Vector3(-1.5 + (i % 3) * 0.55, 0.25 + floorf(i / 3.0) * 0.45, 0), C.wood, 7, PI / 2, 0, PI / 2)
	# (version 7.15) the building site, so it can be found: a sandy slipway, stakes and rope round it, trestles, a sign and a flag
	Build.box(self, Vector3(7.0, 0.05, 6.0), dr + Vector3(0, 0.02, 1.2), C.sand)
	for k in 5: Build.box(self, Vector3(6.0, 0.06, 0.4), dr + Vector3(0, 0.04, -1.0 + k * 1.1), C.wood3 if k % 2 else C.wood2)   # the slipway's planks
	var corners := [Vector3(-3.4, 0, -1.8), Vector3(3.4, 0, -1.8), Vector3(3.4, 0, 4.2), Vector3(-3.4, 0, 4.2)]
	for i in 4:
		Build.box(self, Vector3(0.16, 1.0, 0.16), dr + corners[i], C.timber)
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % 4]
		if i == 1 or i == 3: continue                                                     # (open at the ends: the water side, and the way in)
		Build.box(self, Vector3(0.04, 0.04, a.distance_to(b)), dr + (a + b) / 2 + Vector3(0, 0.85, 0), Color("d8c8a0"), atan2(b.x - a.x, b.z - a.z))
	for sx in [-1.6, 1.6]:                                                                # trestles
		Build.box(self, Vector3(0.12, 0.7, 2.4), dr + Vector3(sx, 0, 1.2), C.wood2)
	var sgp := dr + Vector3(-4.2, 0, -2.6)                                                 # the sign, facing the village
	Build.box(self, Vector3(0.16, 2.2, 0.16), sgp, C.timber)
	Build.box(self, Vector3(1.8, 0.8, 0.08), sgp + Vector3(0, 1.5, -0.1), C.wood3)
	Build.box(self, Vector3(1.2, 0.14, 0.09), sgp + Vector3(0, 1.82, -0.12), Color("5b3a22"))
	Build.box(self, Vector3(0.9, 0.14, 0.09), sgp + Vector3(0, 1.58, -0.12), Color("5b3a22"))
	var fp := dr + Vector3(3.6, 0, -2.2)                                                   # a tall pole with a red flag, seen from far off
	Build.box(self, Vector3(0.12, 4.2, 0.12), fp, C.timber)
	_raft_flag = Node3D.new(); _raft_flag.position = fp + Vector3(0, 3.7, 0); add_child(_raft_flag)
	Build.box(_raft_flag, Vector3(1.1, 0.6, 0.04), Vector3(0.6, -0.3, 0), C.red)


## A low-poly tree: a trunk and two or three layers of leaves.
func _tree(at: Vector3, s: float, i: int) -> void:
	Build.cyl(self, 0.22 * s, 0.32 * s, 1.6 * s, at, C.trunk, 6)
	if i % 3 == 0:
		Build.cone(self, 1.7 * s, 2.6 * s, at + Vector3(0, 1.2 * s, 0), C.hedge3, 7)
		Build.cone(self, 1.2 * s, 2.2 * s, at + Vector3(0, 2.6 * s, 0), C.leaf, 7)
	else:
		var m := Build.cyl(self, 1.3 * s, 1.5 * s, 1.6 * s, at + Vector3(0, 1.4 * s, 0), C.leaf if i % 2 else C.leaf2, 7)
		m.rotation.y = i
		Build.cyl(self, 0.7 * s, 1.2 * s, 0.9 * s, at + Vector3(0, 3.0 * s, 0), C.leaf2 if i % 2 else C.leaf, 7)


## The bonfire in the market: a ring of stones, logs stacked in a cone, and big flames that dance (see _process).
func _bonfire(at: Vector3) -> void:
	for i in 10: Build.box(self, Vector3(0.45, 0.32, 0.45), at + Vector3(cos(i * TAU / 10) * 1.2, 0, sin(i * TAU / 10) * 1.2), C.stone3, i)
	for i in 7: Build.box(self, Vector3(0.2, 1.9, 0.2), at + Vector3(cos(i * TAU / 7) * 0.65, 0, sin(i * TAU / 7) * 0.65), C.trunk, -i * TAU / 7, 0, 0.38).rotation = Vector3(0.38 * sin(i * TAU / 7), 0, -0.38 * cos(i * TAU / 7))
	Build.box(self, Vector3(1.3, 0.06, 1.3), at + Vector3(0, 0.02, 0), Color("2a1d14"))
	var flame := Build.mat(Color(1.0, 0.55, 0.15), 2.4)
	var flame2 := Build.mat(Color(1.0, 0.85, 0.35), 2.8)
	for i in 5:
		var f := Build.cone(self, 0.55 - i * 0.07, 1.4 + i * 0.25, at + Vector3(cos(i * 2.4) * 0.25, 0.15, sin(i * 2.4) * 0.25), Color.WHITE, 5, i)
		f.material_override = flame if i % 2 else flame2
		_bonfire_flames.append(f)
	_bonfire_light = OmniLight3D.new(); _bonfire_light.light_color = Color(1.0, 0.62, 0.3); _bonfire_light.omni_range = 14.0; _bonfire_light.light_energy = 1.8
	_bonfire_light.position = at + Vector3(0, 1.6, 0); add_child(_bonfire_light)


## A torch on a post: it is lit at dusk, and its light is one of the village's lanterns (see main.gd).
func _torch(at: Vector3) -> void:
	Build.box(self, Vector3(0.14, 1.7, 0.14), at, C.timber)
	Build.cyl(self, 0.16, 0.1, 0.18, at + Vector3(0, 1.7, 0), C.iron, 6)
	var f := Build.cone(self, 0.14, 0.42, at + Vector3(0, 1.86, 0), Color.WHITE, 5)
	f.material_override = Build.mat(Color(1.0, 0.7, 0.25), 2.6)
	_torch_flames.append(f)
	var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.68, 0.34); l.omni_range = 7.5; l.light_energy = 0.0
	l.position = at + Vector3(0, 2.1, 0); add_child(l)
	lanterns.append(l)


## The fence round the hamlet: posts and two rails, with an open gate in each side.
func _hamlet_fence() -> void:
	var x0 := -178.0
	var x1 := -142.0
	var z0 := 296.0
	var z1 := 326.0
	var run := func(a: Vector3, b: Vector3) -> void:
		var n := int(a.distance_to(b) / 1.6)
		var dirv := (b - a).normalized()
		var ang := atan2(dirv.x, dirv.z)
		for k in n + 1:
			Build.box(self, Vector3(0.18, 1.1, 0.18), a + dirv * (k * a.distance_to(b) / maxf(1, n)), C.timber)
		for y in [0.45, 0.85]:
			Build.box(self, Vector3(0.08, 0.12, a.distance_to(b)), (a + b) / 2 + Vector3(0, y, 0), C.wood2, ang)
	run.call(Vector3(x0, 0, z0), Vector3(-162, 0, z0)); run.call(Vector3(-158, 0, z0), Vector3(x1, 0, z0))
	run.call(Vector3(x0, 0, z1), Vector3(-162, 0, z1)); run.call(Vector3(-158, 0, z1), Vector3(x1, 0, z1))
	run.call(Vector3(x0, 0, z0), Vector3(x0, 0, 306)); run.call(Vector3(x0, 0, 310), Vector3(x0, 0, z1))
	run.call(Vector3(x1, 0, z0), Vector3(x1, 0, 306)); run.call(Vector3(x1, 0, 310), Vector3(x1, 0, z1))
	for g in [[Vector3(-162, 0, z0), 0.0, 1], [Vector3(-162, 0, z1), 0.0, -1], [Vector3(x0, 0, 306), PI / 2, 1], [Vector3(x1, 0, 306), PI / 2, -1]]:   # the gates, standing open
		var gn := Node3D.new(); gn.position = g[0]; gn.rotation.y = g[1]; add_child(gn)
		for leaf in [0, 1]:
			var hinge := Vector3(0, 0, 0) if leaf == 0 else Vector3(4, 0, 0)
			var lf := Node3D.new(); lf.position = hinge; lf.rotation.y = (1.2 if leaf == 0 else PI - 1.2) * g[2]; gn.add_child(lf)
			for y in [0.4, 0.8]: Build.box(lf, Vector3(1.9, 0.12, 0.08), Vector3(0.95, y, 0), C.wood3)
			Build.box(lf, Vector3(0.1, 1.0, 0.08), Vector3(1.85, 0, 0), C.wood3)
			Build.box(lf, Vector3(2.0, 0.1, 0.08), Vector3(0.95, 0.4, 0), C.wood3, 0, 0, 0.36)


## A small hill with a cave in its side. The west one is Garrick's (a chest-shaped heap, a money box on a post and a
## sign that says so); the east one is the Rune Cave (blue light at the back, and a sign with a rune on it).
func _hill(at: Vector3, rad: float, garrick: bool) -> void:
	var g := Node3D.new(); g.position = at; add_child(g)
	var face := 1.0 if garrick else -1.0                                                # which way the mouth faces: into the hamlet
	Build.cyl(g, rad * 0.98, rad * 1.12, 2.2, Vector3.ZERO, Color("7f9f52"), 10)          # a rounded hill: turf in layers, lumpy
	Build.cyl(g, rad * 0.8, rad * 0.98, 2.2, Vector3(-face * 0.4, 2.2, 0.3), Color("8aa85a"), 9, 0.3)
	Build.cyl(g, rad * 0.55, rad * 0.8, 2.0, Vector3(-face * 0.9, 4.4, -0.4), Color("93b062"), 9, 0.6)
	Build.cyl(g, rad * 0.25, rad * 0.55, 1.4, Vector3(-face * 1.3, 6.4, 0.2), Color("9cb86c"), 8, 0.9)
	for k in 5:                                                                          # shoulders, so it is not a cake
		var a := k * 1.3 + (0.2 if garrick else 0.9)
		if cos(a) * face > 0.3: continue                                                 # (none in front of the mouth)
		Build.cyl(g, rad * 0.32, rad * 0.45, 2.6, Vector3(cos(a) * rad * 0.62, 0, sin(a) * rad * 0.62), Color("86a656"), 8, a)
	var rock := Color("6e6878") if not garrick else Color("7a6f62")
	for i in 7:                                                                          # rocks showing through the turf
		var a := i * 0.9 + (0.4 if garrick else 1.1)
		Build.box(g, Vector3(1.6, 1.2, 1.3), Vector3(cos(a) * rad * 0.85, 0.4 + (i % 3) * 1.4, sin(a) * rad * 0.85), rock, a, 0.2, 0.15)
	for k in 3: _tree(at + Vector3(-face * (2.5 + k * 2.0), 4.2 + k * 0.9, -3.4 + k * 3.2), 0.7, k + (1 if garrick else 0))
	# the mouth, on the side towards the hamlet: a dark opening in a frame of rock and timber
	var m := Vector3(face * rad * 1.0, 0, 0)
	Build.box(g, Vector3(1.4, 3.0, 4.2), m + Vector3(-face * 0.55, 0, 0), Color("1a1620"))     # the dark of the cave
	Build.box(g, Vector3(2.4, 1.2, 5.8), m + Vector3(-face * 0.6, 3.0, 0), rock)
	Build.box(g, Vector3(2.4, 0.5, 4.8), m + Vector3(-face * 0.7, 4.2, 0), Color("7f9f52"))
	for sz in [-2.3, 2.3]:
		Build.box(g, Vector3(1.4, 3.4, 1.0), m + Vector3(-face * 0.3, 0, sz), rock, 0.2 * sz)
		Build.box(g, Vector3(0.22, 2.8, 0.22), m + Vector3(face * 0.3, 0, sz * 0.82), C.timber)
	Build.box(g, Vector3(0.22, 0.22, 4.2), m + Vector3(face * 0.3, 2.75, 0), C.timber)
	var sign_ := m + Vector3(face * 1.8, 0, 3.4)                                        # the sign, beside the mouth
	Build.box(g, Vector3(0.14, 1.9, 0.14), sign_, C.timber)
	Build.box(g, Vector3(0.08, 0.7, 1.4), sign_ + Vector3(face * 0.1, 1.3, 0), C.wood3)
	if garrick:
		Build.box(g, Vector3(0.1, 0.24, 0.8), sign_ + Vector3(face * 0.16, 1.55, 0), Color("a8362c"))     # (it says PAY HERE, in red)
		Build.box(g, Vector3(0.14, 1.1, 0.14), m + Vector3(face * 3.0, 0, -2.2), C.timber)                 # the money box
		Build.box(g, Vector3(0.5, 0.4, 0.4), m + Vector3(face * 3.0, 1.1, -2.2), Color("5b4130"))
		Build.box(g, Vector3(0.3, 0.06, 0.06), m + Vector3(face * 3.0, 1.52, -2.2), Color("f2c94c"))
	else:
		var rn := Build.box(g, Vector3(0.1, 0.4, 0.4), sign_ + Vector3(face * 0.16, 1.45, 0), Color("3f7ed8"))   # a rune, painted on
		rn.material_override = Build.mat(Color("3f7ed8"), 1.2)
		var gl := OmniLight3D.new(); gl.light_color = Color(0.4, 0.62, 1.0); gl.omni_range = 6.0; gl.light_energy = 1.2
		gl.position = m + Vector3(face * 0.8, 1.2, 0); g.add_child(gl)


## Dorothy and the Donkey, in a pen with a hay rack and a water trough.
func _pen(at: Vector3) -> void:
	var hw := 4.3
	var hd := 3.2
	for k in 12:
		var t := k / 11.0
		for e in [[Vector3(-hw + t * hw * 2, 0, -hd)], [Vector3(-hw + t * hw * 2, 0, hd)], [Vector3(-hw, 0, -hd + t * hd * 2)], [Vector3(hw, 0, -hd + t * hd * 2)]]:
			Build.box(self, Vector3(0.14, 1.0, 0.14), at + e[0], C.timber)
	for y in [0.4, 0.8]:
		Build.box(self, Vector3(hw * 2, 0.1, 0.07), at + Vector3(0, y, -hd), C.wood2)
		Build.box(self, Vector3(hw * 2, 0.1, 0.07), at + Vector3(0, y, hd), C.wood2)
		Build.box(self, Vector3(0.07, 0.1, hd * 2), at + Vector3(-hw, y, 0), C.wood2)
		Build.box(self, Vector3(0.07, 0.1, hd * 2), at + Vector3(hw, y, 0), C.wood2)
	Build.box(self, Vector3(8.4, 0.04, 6.2), at + Vector3(0, 0.03, 0), Color("a08a5a"))
	Build.box(self, Vector3(1.8, 0.5, 0.6), at + Vector3(2.6, 0, -2.4), C.wood2)                  # the trough
	Build.box(self, Vector3(1.6, 0.06, 0.4), at + Vector3(2.6, 0.48, -2.4), C.water)
	Build.box(self, Vector3(1.0, 0.9, 1.0), at + Vector3(-3.2, 0, -2.2), C.straw)                 # the hay
	_cow = _beast(at + Vector3(-1.2, 0, 0.4), false)
	_donkey = _beast(at + Vector3(1.8, 0, 0.9), true)


## A cow (black and white, with horns) or a donkey (grey-brown, with long ears). Its head and tail move (see _process).
func _beast(at: Vector3, donkey: bool) -> Node3D:
	var n := Node3D.new(); n.position = at; n.rotation.y = 0.7 if donkey else -0.5; add_child(n)
	var hide := Color("8a7c6c") if donkey else Color("f1ede2")
	var dark := Color("4a3f36") if donkey else Color("2f2a26")
	var s := 0.85 if donkey else 1.0
	Build.box(n, Vector3(0.8, 0.7, 1.6) * s, Vector3(0, 0.7 * s, 0), hide)
	if not donkey:
		Build.box(n, Vector3(0.82, 0.4, 0.5), Vector3(0, 0.9, 0.2), dark)                        # the patches
		Build.box(n, Vector3(0.82, 0.3, 0.4), Vector3(0, 0.8, -0.5), dark)
		Build.box(n, Vector3(0.3, 0.14, 0.24), Vector3(0, 0.55, -0.4), Color("f0b0b8"))          # (and her udder)
	for lx in [-0.28, 0.28]:
		for lz in [-0.6, 0.6]: Build.box(n, Vector3(0.18, 0.7, 0.18) * s, Vector3(lx * s, 0, lz * s), dark)
	var head := Node3D.new(); head.position = Vector3(0, 1.15 * s, 0.85 * s); n.add_child(head)
	Build.box(head, Vector3(0.44, 0.44, 0.6) * s, Vector3(0, -0.2, 0.2), hide)
	Build.box(head, Vector3(0.46, 0.22, 0.24) * s, Vector3(0, -0.28, 0.52 * s), Color("d9b0a0") if not donkey else Color("cfc6b8"))
	if donkey:
		for ex in [-0.13, 0.13]: Build.box(head, Vector3(0.1, 0.5, 0.1), Vector3(ex, 0.12, 0.05), hide, 0, -0.2, ex * 1.6)
		Build.box(head, Vector3(0.08, 0.3, 0.7), Vector3(0, -0.05, -0.4), dark)                   # the mane
	else:
		for ex in [-0.3, 0.3]: Build.box(head, Vector3(0.08, 0.08, 0.24), Vector3(ex, 0.1, 0.0), Color("efe6cf"), 0, 0, ex * 2)
	var tail := Node3D.new(); tail.position = Vector3(0, 1.2 * s, -0.8 * s); n.add_child(tail)
	Build.box(tail, Vector3(0.07, 0.6, 0.07), Vector3(0, -0.6, 0), dark)
	n.set_meta("head", head); n.set_meta("tail", tail)
	return n


## A hen: white or brown, with a red comb. Its head goes down to peck (see _process).
func _chicken(i: int) -> Node3D:
	var n := Node3D.new(); add_child(n)
	var col: Color = [Color("f6f2e8"), Color("a2643a"), Color("f6f2e8"), Color("d9a560")][i % 4]
	Build.box(n, Vector3(0.28, 0.24, 0.36), Vector3(0, 0.16, 0), col)
	Build.box(n, Vector3(0.18, 0.2, 0.08), Vector3(0, 0.26, -0.2), col, 0, -0.4)                      # the tail
	for lx in [-0.06, 0.06]: Build.box(n, Vector3(0.03, 0.16, 0.03), Vector3(lx, 0, 0), Color("e0a030"))
	var head := Node3D.new(); head.position = Vector3(0, 0.36, 0.16); n.add_child(head)
	Build.box(head, Vector3(0.14, 0.16, 0.14), Vector3(0, -0.04, 0), col)
	Build.box(head, Vector3(0.04, 0.08, 0.1), Vector3(0, 0.12, 0), Color("d0302c"))
	Build.box(head, Vector3(0.05, 0.04, 0.08), Vector3(0, 0.0, 0.1), Color("e0a030"))
	n.set_meta("head", head)
	return n


## The druid's cottage: low stone walls under a turf roof, with a great tree growing up through the middle of it, ivy,
## flowers and toadstools round about, herbs drying under the eaves, a lit window, and his table of potions in front.
func _druid_cottage(at: Vector3) -> void:
	var n := Node3D.new(); n.position = at; add_child(n)
	Build.box(n, Vector3(6.4, 0.4, 6.4), Vector3.ZERO, C.stone2)
	Build.box(n, Vector3(6.0, 2.2, 6.0), Vector3(0, 0.4, 0), Color("b0a48c"))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]: Build.box(n, Vector3(0.36, 2.2, 0.36), Vector3(sx * 2.92, 0.4, sz * 2.92), C.timber)
	Build.roof(n, 6.8, 1.6, 6.8, Vector3(0, 2.6, 0), Color("3e5a3a"))                                       # a turf roof
	Build.box(n, Vector3(0.12, 1.6, 1.0), Vector3(3.02, 0.4, 0.0), C.timber)                                 # the door, towards his table
	var win := Build.box(n, Vector3(0.1, 0.7, 0.7), Vector3(3.02, 1.2, -1.7), Color("ffd98a"))
	win.material_override = window_mat
	# the tree, growing up through the roof, with roots over the walls
	Build.cyl(n, 0.55, 0.9, 6.4, Vector3(-0.6, 0, 0.4), C.trunk, 8)
	for a in [0.4, 2.1, 3.9, 5.2]:
		Build.box(n, Vector3(0.4, 0.4, 2.6), Vector3(-0.6 + cos(a) * 1.4, 0.0, 0.4 + sin(a) * 1.4), C.trunk, a, 0.3)
	for b in [[1.5, 5.6, 0.0, 0.6], [-1.6, 5.4, 1.2, -0.7], [0.3, 6.0, -1.4, 0.5]]:
		Build.box(n, Vector3(0.3, 2.4, 0.3), Vector3(-0.6 + b[0] * 0.3, b[1] - 1.2, 0.4 + b[2] * 0.3), C.trunk, 0, b[3] * 0.6, b[3])
	for c in [[0.0, 6.4, 0.4, 3.2], [1.8, 6.0, -1.0, 2.2], [-2.2, 6.2, 1.6, 2.4], [-0.6, 7.6, 0.4, 2.4], [1.2, 7.0, 2.0, 1.8]]:
		Build.cyl(n, c[3] * 0.7, c[3], c[3] * 0.9, Vector3(-0.6 + c[0], c[1], 0.4 + c[2]), C.leaf if int(c[1]) % 2 else C.leaf2, 8, c[0])
	for i in 18:                                                                                            # ivy, and its flowers
		var y := 0.6 + (i % 6) * 0.3
		var z := -2.6 + (i / 6) * 2.4
		Build.box(n, Vector3(0.08, 0.5, 0.5), Vector3(3.04, y, z + 0.3 * sin(i)), C.leaf if i % 2 else C.hedge3)
		if i % 3 == 0: Build.box(n, Vector3(0.1, 0.12, 0.12), Vector3(3.08, y + 0.2, z), Color("f6f0ff"))
	# flowers and toadstools round the cottage
	var fr := RandomNumberGenerator.new(); fr.seed = 4401
	for i in 40:
		var a := fr.randf() * TAU
		var d := fr.randf_range(3.6, 5.0)
		var p := Vector3(cos(a) * d, 0, sin(a) * d)
		if p.x > 2.6 and absf(p.z) < 2.4: continue                                                           # (not on his doorstep)
		Build.box(n, Vector3(0.06, 0.3, 0.06), p, C.leaf)
		Build.box(n, Vector3(0.16, 0.14, 0.16), p + Vector3(0, 0.3, 0), [Color("e05a7a"), Color("f2c94c"), Color("f0f0ff"), Color("b36ad8"), Color("6aa8f0")][i % 5])
	for t in [Vector3(-3.6, 0, 3.2), Vector3(-4.2, 0, 2.4), Vector3(3.8, 0, 3.6), Vector3(-3.4, 0, -3.8), Vector3(4.2, 0, -3.4)]:
		Build.cyl(n, 0.06, 0.08, 0.35, t, Color("efe6cf"), 6)
		Build.cyl(n, 0.08, 0.32, 0.22, t + Vector3(0, 0.34, 0), Color("c0262e"), 8)
		Build.box(n, Vector3(0.06, 0.04, 0.06), t + Vector3(0.12, 0.5, 0.05), Color("ffffff"))
	# herbs drying under the eaves, and a lantern by the door
	for i in 5: Build.cone(n, 0.14, 0.5, Vector3(3.3, 1.6, -1.0 + i * 0.5), [C.leaf, Color("8a6ab0"), C.leaf2, Color("c0a040"), C.leaf][i], 5)
	Build.box(n, Vector3(0.24, 0.32, 0.24), Vector3(3.3, 1.9, 0.8), Color("ffd98a")).material_override = Build.mat(Color("f0a050"), 1.4)
	# his table, in the market, with potions glowing on it, and the druid himself behind it
	var tb := Vector3(5.4, 0, 0)
	Build.box(n, Vector3(1.0, 0.9, 3.0), tb, C.wood2)
	Build.box(n, Vector3(1.2, 0.08, 3.2), tb + Vector3(0, 0.9, 0), C.wood3)
	for i in 6:
		var pc: Color = [Color("e04040"), Color("4080e0"), Color("40c060"), Color("e0a030"), Color("b050d0"), Color("40c060")][i]
		Build.cyl(n, 0.1, 0.13, 0.3, tb + Vector3(fr.randf_range(-0.3, 0.3), 0.98, -1.2 + i * 0.48), pc, 7).material_override = Build.mat(pc, 1.2)
	for i in 3: Build.box(n, Vector3(0.3, 0.16, 0.3), tb + Vector3(0.2, 0.98, -0.8 + i * 0.8), C.leaf if i % 2 else Color("8a6ab0"))
	_druid(n, tb + Vector3(-1.6, 0, 0))


## The druid: a long green robe and hood, a white beard to his belt, a crown of antlers, and a staff with a glowing stone.
func _druid(parent: Node3D, at: Vector3) -> void:
	var g := Node3D.new(); g.position = at; g.rotation.y = PI / 2; parent.add_child(g)
	var robe := Color("3f5f34")
	Build.cyl(g, 0.34, 0.5, 1.2, Vector3.ZERO, robe, 8)
	Build.box(g, Vector3(0.62, 0.6, 0.42), Vector3(0, 1.1, 0), robe)
	for sx in [-0.38, 0.38]: Build.box(g, Vector3(0.18, 0.62, 0.2), Vector3(sx, 0.95, 0.08), robe, 0, -0.4)
	Build.box(g, Vector3(0.36, 0.38, 0.36), Vector3(0, 1.66, 0.02), Color("d9b48c"))
	Build.box(g, Vector3(0.46, 0.5, 0.46), Vector3(0, 1.64, -0.06), robe.darkened(0.2))                         # the hood
	Build.box(g, Vector3(0.3, 0.6, 0.12), Vector3(0, 1.22, 0.22), Color("f0eee8"))                               # the beard
	for sx in [-1.0, 1.0]:                                                                                   # the antlers
		Build.box(g, Vector3(0.06, 0.4, 0.06), Vector3(sx * 0.16, 2.0, 0), Color("d8c8a0"), 0, 0, -sx * 0.4)
		Build.box(g, Vector3(0.05, 0.28, 0.05), Vector3(sx * 0.3, 2.26, 0), Color("d8c8a0"), 0, 0, -sx * 0.9)
		Build.box(g, Vector3(0.05, 0.24, 0.05), Vector3(sx * 0.24, 2.34, 0.06), Color("d8c8a0"), 0, 0.5, -sx * 0.2)
	Build.box(g, Vector3(0.07, 2.2, 0.07), Vector3(0.5, 0, 0.18), C.timber)                                     # his staff
	var orb := Build.box(g, Vector3(0.16, 0.16, 0.16), Vector3(0.5, 2.2, 0.18), Color("80f0a0"))
	orb.material_override = Build.mat(Color("80f0a0"), 2.0)


## A washing line between two posts, with the hamlet's washing on it.
func _washing(a: Vector3, b: Vector3) -> void:
	for p in [a, b]: Build.box(self, Vector3(0.12, 2.0, 0.12), p, C.timber)
	Build.box(self, Vector3(a.distance_to(b), 0.03, 0.03), (a + b) / 2 + Vector3(0, 1.9, 0), Color("efe6cf"))
	for k in 5:
		var t := (k + 0.5) / 5.0
		Build.box(self, Vector3(0.7, 0.6, 0.04), a.lerp(b, t) + Vector3(0, 1.28, 0), [Color("c0503c"), Color("efe6cf"), Color("5a7ab0"), Color("e0c060"), Color("efe6cf")][k])


## The Riverside, alive: the bonfire dances, the torches are lit after dusk, the hens wander and peck, the cow and the
## donkey look about and swish their tails, and now and then one of them says so (heard only when you are near).
func _hamlet_step(delta: float) -> void:
	if _cow == null: return
	var now := Time.get_ticks_msec() / 1000.0
	for i in _brazier_flames.size():                                                      # the braziers at the north gate
		var bf: MeshInstance3D = _brazier_flames[i]
		bf.scale = Vector3(1.0 + 0.1 * sin(now * 8.0 + i), 0.85 + 0.25 * absf(sin(now * 6.1 + i * 1.9)), 1.0 + 0.1 * cos(now * 7.3 + i))
	for i in _bonfire_flames.size():
		var f: MeshInstance3D = _bonfire_flames[i]
		f.scale = Vector3(1.0 + 0.12 * sin(now * 7.0 + i), 0.85 + 0.25 * absf(sin(now * 5.3 + i * 1.7)), 1.0 + 0.12 * cos(now * 6.1 + i))
	_bonfire_light.light_energy = (1.0 + 2.2 * night) * (0.85 + 0.15 * sin(now * 11.0) + 0.08 * sin(now * 29.0))
	for i in _cave_flames.size():                                                         # the caves' torches: always burning
		var cf: Array = _cave_flames[i]
		(cf[0] as MeshInstance3D).scale = Vector3.ONE * (0.9 + 0.15 * sin(now * 9.0 + i * 1.3))
		(cf[1] as OmniLight3D).light_energy = 1.6 * (0.88 + 0.12 * sin(now * 11.0 + i) + 0.06 * sin(now * 27.0 + i * 2.0))
	if _mine_glow.size():                                                                 # the mine's glow breathes, slowly
		var mg := 0.5 + 0.5 * sin(now * 1.1)
		(_mine_glow[0] as StandardMaterial3D).albedo_color.a = 0.25 + 0.15 * mg
		(_mine_glow[1] as OmniLight3D).light_energy = 0.6 + 0.5 * mg
	for i in _twinkle.size():                                                             # the glint behind the rock: now and then, catching the light
		var tw: Array = _twinkle[i]
		var p_ := maxf(0.0, sin(now * 1.7 + i * 2.1)) ** 8
		(tw[1] as StandardMaterial3D).emission_energy_multiplier = 1.2 + 6.0 * p_
	var lit := night > 0.25
	for i in _torch_flames.size():
		var f: MeshInstance3D = _torch_flames[i]
		f.visible = lit
		if lit: f.scale = Vector3.ONE * (0.9 + 0.15 * sin(now * 9.0 + i * 1.3))
	for c in _chickens:
		var n: Node3D = c[0]
		var at: Vector3 = c[1]
		var goal: Vector3 = c[2]
		c[3] -= delta
		var head: Node3D = n.get_meta("head")
		if at.distance_to(goal) < 0.15:
			head.rotation.x = 1.1 * maxf(0.0, sin(now * 14.0)) if c[3] > 0.0 and c[3] < 0.8 else 0.0   # peck, peck
			if c[3] <= 0.0:
				c[3] = randf_range(1.0, 3.0)
				c[2] = Vector3(clampf(at.x + randf_range(-3, 3), -166.0, -153.0), 0, clampf(at.z + randf_range(-3, 3), 306.0, 321.0))
				if absf(c[2].x + 160.0) < 2.0 and absf(c[2].z - 310.0) < 2.0: c[2] = at   # (not into the bonfire)
		else:
			var dv := (goal - at).normalized()
			at += dv * minf(at.distance_to(goal), delta * 1.3)
			c[1] = at
			n.rotation.y = atan2(dv.x, dv.z)
			head.rotation.x = 0.15 * sin(now * 18.0)
		n.position = at + Vector3(0, absf(sin(now * 18.0)) * 0.04 if at.distance_to(goal) >= 0.15 else 0.0, 0)
	for b in [_cow, _donkey]:
		var h: Node3D = b.get_meta("head")
		var t: Node3D = b.get_meta("tail")
		var k := 0.0 if b == _cow else 2.0
		h.rotation = Vector3(0.35 * maxf(0.0, sin(now * 0.4 + k)), 0.4 * sin(now * 0.23 + k), 0)   # grazing, and looking about
		t.rotation.z = 0.35 * sin(now * 2.2 + k)
	for i in 3:
		_beast_t[i] -= delta
		if _beast_t[i] <= 0:
			match i:
				0: _beast_t[i] = randf_range(14, 26); Sound.play("moo", 0.8, Vector2(_cow.position.x, _cow.position.z))
				1: _beast_t[i] = randf_range(18, 34); Sound.play("bray", 0.8, Vector2(_donkey.position.x, _donkey.position.z))
				2:
					_beast_t[i] = randf_range(2.5, 6.0)
					var c: Array = _chickens[randi() % _chickens.size()]
					Sound.play("cluck", 0.5, Vector2(c[1].x, c[1].z))


# ---------------------------------------------------------------- mole hills (version 7.16)
var _moles: Array = []                    # [hill node, mole node, seconds of popping left]
var _mole_sig := ""

## Put the day's mole hills where the rules say (a hill that has popped is flattened a little, its mole gone home).
func set_moles(ml: Array) -> void:
	var sig := str(ml.map(func(m): return [roundi(m[0]), roundi(m[1]), m[2]]))
	if sig == _mole_sig: return
	_mole_sig = sig
	while _moles.size() < ml.size():
		var h := Node3D.new(); add_child(h)
		Build.cyl(h, 0.25, 0.75, 0.42, Vector3.ZERO, Color("6b4a2f"), 9)
		for k in 5: Build.box(h, Vector3(0.22, 0.12, 0.2), Vector3(cos(k * 1.3) * 0.7, 0, sin(k * 1.3) * 0.7), Color("7a5a38"), k)
		var mo := Node3D.new(); h.add_child(mo); mo.visible = false
		Build.box(mo, Vector3(0.32, 0.36, 0.3), Vector3(0, 0, 0), Color("3a3430"))
		Build.box(mo, Vector3(0.1, 0.08, 0.1), Vector3(0, 0.24, 0.16), Color("f0a0b0"))            # its pink nose
		for sx in [-0.17, 0.17]: Build.box(mo, Vector3(0.12, 0.05, 0.1), Vector3(sx, 0.12, 0.12), Color("f0c0c8"))   # and its digging hands
		_moles.append([h, mo, 0.0])
	for i in _moles.size():
		var h: Node3D = _moles[i][0]
		h.visible = i < ml.size()
		if i < ml.size():
			h.position = Vector3(float(ml[i][0]), 0, float(ml[i][1]))
			h.scale = Vector3(1, 0.55 if ml[i][2] else 1.0, 1)

## A mole pops out of the hill at (x, z), looks about, and goes back down.
func mole_pop(x: float, z: float) -> void:
	for m in _moles:
		if Vector2(m[0].position.x - x, m[0].position.z - z).length() < 0.5:
			m[2] = 1.8


func _raft_node(at: Vector3) -> Node3D:
	var r := Node3D.new(); r.position = at; add_child(r)
	for i in 6: Build.cyl(r, 0.28, 0.28, 4.2, Vector3(-1.4 + i * 0.56, 0.12, 0), C.wood if i % 2 else C.wood2, 7, 0, PI / 2)
	Build.box(r, Vector3(3.6, 0.1, 0.3), Vector3(0, 0.42, -1.2), C.timber)
	Build.box(r, Vector3(3.6, 0.1, 0.3), Vector3(0, 0.42, 1.2), C.timber)
	Build.box(r, Vector3(0.1, 2.6, 0.1), Vector3(1.6, 0.3, 1.6), C.timber)
	return r

## The raft and the Rune Cave as the rules have them: built or not, and how much of the raft's wood is in.
func set_riverside(built: bool, wood: int, cave: bool, seams: Array) -> void:
	if _raft == null: return
	_raft.visible = built; _raft_far.visible = built
	_raft_pile.visible = not built and wood > 0
	if _raft_flag: _raft_flag.rotation.y = sin(Time.get_ticks_msec() / 700.0) * 0.35
	_raft_pile.scale = Vector3.ONE * clampf(0.4 + wood / float(D.RAFT.wood), 0.4, 1.2)
	_rcave_props.visible = cave
	_rcave_boards.visible = not cave
	for i in mini(seams.size(), _seams.size()):
		_seams[i][1].emission_energy_multiplier = (1.6 + 0.5 * sin(Time.get_ticks_msec() / 380.0 + i)) if int(seams[i]) > 0 else 0.15


## How much is left in each rune vein today: a worked-out vein goes dull.
func set_veins(left: Array) -> void:
	for i in mini(left.size(), _veins.size()):
		var full: bool = left[i] > 0
		_veins[i][0].scale = Vector3.ONE * (1.0 if full else 0.6)
		_veins[i][1].emission_energy_multiplier = (1.5 + 0.5 * sin(Time.get_ticks_msec() / 400.0 + i * 2.0)) if full else 0.15
		_veins[i][2].light_energy = 0.9 if full else 0.1


## The gatepost inside the north gate, where the Lord of Ashhollow's letters are nailed up, and the rider who brings them.
func _gatepost() -> void:
	var at := Vector3(-4.2, 0, -19.4)
	Build.box(self, Vector3(0.3, 2.3, 0.3), at, C.timber)
	Build.box(self, Vector3(0.42, 0.12, 0.42), at + Vector3(0, 2.3, 0), C.wood3)
	letter_paper = Node3D.new()
	letter_paper.position = at + Vector3(0, 1.15, 0.17)
	letter_paper.visible = false
	add_child(letter_paper)
	Build.box(letter_paper, Vector3(0.62, 0.78, 0.03), Vector3(0, 0, 0), Color("f3ead2"), 0, 0, 0.06)
	for i in 5:                                     # his handwriting, and his seal
		Build.box(letter_paper, Vector3(0.44 - (i % 2) * 0.1, 0.035, 0.012), Vector3(-0.02, 0.6 - i * 0.1, 0.02), Color("3b3340"), 0, 0, 0.06)
	Build.cyl(letter_paper, 0.07, 0.07, 0.03, Vector3(0.16, 0.1, 0.03), Color("8e1f1f"), 8, 0, PI / 2)
	Build.box(letter_paper, Vector3(0.05, 0.05, 0.05), Vector3(0, 0.74, 0.02), C.iron)
	rider = Node3D.new()
	rider.visible = false
	add_child(rider)
	var black := Color("26222e")
	var coat := Color("5a2330")
	Build.box(rider, Vector3(0.62, 0.66, 1.7), Vector3(0, 0.95, 0), black)                    # the horse
	Build.box(rider, Vector3(0.36, 0.95, 0.46), Vector3(0, 1.3, 0.92), black, 0, 0.55)
	Build.box(rider, Vector3(0.3, 0.34, 0.7), Vector3(0, 2.0, 1.42), black, 0, 0.25)
	for sx in [-0.2, 0.2]:
		Build.box(rider, Vector3(0.14, 0.95, 0.16), Vector3(sx, 0, 0.62), black, 0, -0.2)
		Build.box(rider, Vector3(0.14, 0.95, 0.16), Vector3(sx, 0, -0.66), black, 0, 0.2)
		Build.box(rider, Vector3(0.07, 0.07, 0.04), Vector3(sx * 0.5, 2.2, 1.74), Color("9bff7a"))   # its eyes
	Build.box(rider, Vector3(0.14, 0.7, 0.14), Vector3(0, 0.95, -0.95), black, 0, -0.5)        # tail
	Build.box(rider, Vector3(0.56, 0.72, 0.36), Vector3(0, 1.6, -0.05), coat)                  # the rider, to the collar
	Build.box(rider, Vector3(0.7, 0.16, 0.44), Vector3(0, 2.3, -0.05), Color("3a3144"))
	Build.cyl(rider, 0.1, 0.12, 0.1, Vector3(0, 2.46, -0.05), Color("d9d2c0"), 7)              # and no further
	Build.box(rider, Vector3(0.74, 0.9, 0.06), Vector3(0, 1.3, -0.32), Color("43182a"), 0, -0.25)   # cloak
	for sx in [-0.34, 0.34]:
		Build.box(rider, Vector3(0.16, 0.6, 0.18), Vector3(sx, 1.05, 0.08), coat)
	Build.box(rider, Vector3(0.14, 0.14, 0.5), Vector3(0.36, 1.86, 0.2), coat)                 # an arm, holding out a letter
	Build.box(rider, Vector3(0.03, 0.2, 0.28), Vector3(0.36, 1.98, 0.5), Color("f3ead2"))


## A letter has come: the headless rider gallops down the castle road to the gate, stops, and goes home.
func rider_come() -> void:
	_rider_t = 0.0


func ring_bell() -> void:
	_bell_swing = 1.0


func hit_dummy(i: int) -> void:
	if i >= 0 and i < _dummy_hit.size(): _dummy_hit[i] = 1.0


## The nights of the bells (main.gd): the priest has lit every candle he owns, and the chapel's windows blaze.
func set_bells(on: bool) -> void:
	_bells_on = on

func _chapel_step(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var cols := [Color(1.0, 0.25, 0.2), Color(0.3, 0.5, 1.0), Color(1.0, 0.78, 0.25), Color(0.7, 0.4, 1.0)]
	for i in _glass.size():
		var m: StandardMaterial3D = _glass[i]
		if _bells_on:                             # each window flares and flickers on its own beat, as candle after candle is lit
			var f: float = 0.55 + 0.45 * sin(t * (5.0 + i * 1.3) + i * 2.0) * sin(t * (2.3 + i * 0.7))
			var flash: float = 2.5 if fmod(t * 0.9 + i * 0.37, 1.7) < 0.12 else 0.0
			m.emission_energy_multiplier = 1.4 + 1.4 * f + flash * 0.5
		else:
			m.emission_energy_multiplier = 0.9
	for sp in _spill:
		(sp[0] as Node3D).visible = _bells_on
		if _bells_on:
			var e: float = (_glass[sp[2]] as StandardMaterial3D).emission_energy_multiplier
			var smat: StandardMaterial3D = sp[1]
			var sc := smat.albedo_color; sc.a = clampf(0.12 * e, 0.0, 0.85); smat.albedo_color = sc
	for j in _chapel_lights.size():
		var cl: OmniLight3D = _chapel_lights[j]
		if _bells_on:
			var k: int = (int(t * 1.6) + j * 2) % cols.size()
			cl.light_color = (cols[k] as Color).lerp(cols[(k + 1) % cols.size()], fmod(t * 1.6, 1.0))
			cl.light_energy = 2.2 + 0.9 * sin(t * 9.0 + j) * sin(t * 4.1)
		else:
			cl.light_energy = 0.0

func _ducks_step(delta: float) -> void:            # round the pond, each at its own pace, bobbing, and now and then turning back
	var t := Time.get_ticks_msec() / 1000.0
	for dk in _ducks:
		var a: float = dk[1] + t * dk[3] + 0.4 * sin(t * 0.3 + dk[1])
		var r: float = dk[2] + 0.15 * sin(t * 0.5 + dk[1] * 3.0)
		var n: Node3D = dk[0]
		n.position = _pond + Vector3(cos(a) * r, 0.02 + 0.02 * sin(t * 2.4 + dk[1]), sin(a) * r)
		n.rotation.y = -a + (PI if dk[3] > 0 else 0.0)                             # facing the way it is going
		n.rotation.z = 0.06 * sin(t * 2.4 + dk[1])

func _process(delta: float) -> void:
	_chapel_step(delta)
	_ducks_step(delta)
	_lord_step(delta)
	_crows_step(delta)
	_haunts_step(delta)
	if bell:
		_bell_swing = maxf(0.0, _bell_swing - delta * 0.45)
		bell.rotation.x = sin(Time.get_ticks_msec() / 1000.0 * 7.0) * 0.55 * _bell_swing
	for i in dummies.size():
		_dummy_hit[i] = maxf(0.0, _dummy_hit[i] - delta * 2.5)
		dummies[i].rotation.x = sin(_dummy_hit[i] * 14.0) * 0.25 * _dummy_hit[i]
	if _rider_t >= 0.0 and rider:
		_rider_t += delta
		var t := _rider_t
		var go := 3.4                                 # seconds each way
		var z := lerpf(-70.0, VN - 2.8, clampf(t / go, 0, 1)) if t < go + 2.2 else lerpf(VN - 2.8, -70.0, clampf((t - go - 2.2) / go, 0, 1))
		var moving := t < go or t > go + 2.2
		rider.visible = true
		rider.position = Vector3(1.0, absf(sin(t * 13.0)) * 0.16 if moving else 0.0, z)
		rider.rotation = Vector3(-0.12 if moving else 0.0, PI if t > go + 2.2 else 0.0, 0)
		if t > go * 2 + 2.2:
			_rider_t = -1.0; rider.visible = false
	if storm and _evil_now >= 3:
		storm.rotation.y += delta * 0.35
		_storm_light.light_energy = (1.2 + night * 4.0) * (0.8 + 0.2 * sin(Time.get_ticks_msec() / 130.0))
	if _inn_fire: _inn_fire.light_energy = 2.0 + 0.5 * sin(Time.get_ticks_msec() / 90.0) + 0.3 * sin(Time.get_ticks_msec() / 37.0)
	if mill_sails: mill_sails.rotation.x += delta * 0.55
	_hamlet_step(delta)
	for m in _moles:                                 # a mole, popping up and going down again
		if m[2] > 0:
			m[2] = maxf(0.0, m[2] - delta)
			var t: float = 1.0 - m[2] / 1.8
			m[1].visible = m[2] > 0
			m[1].position = Vector3(0, -0.2 + 0.62 * sin(minf(1.0, t * 1.6) * PI * 0.5) * (1.0 - smoothstep(0.75, 1.0, t)), 0)
			m[1].rotation.y = sin(t * 9.0) * 0.6
	if maypole: maypole.rotation.y += delta * 0.12
