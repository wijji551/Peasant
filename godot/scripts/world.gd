extends Node3D
## The map of Thornhallow, built from simple shapes.
## Same layout and measurements as the web version: x runs east, z runs south, north is -z.

const Build := preload("res://scripts/build.gd")

const VW := 28.0          # half the village's width
const VN := -22.0         # the north wall
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
var _evil: Array[Node3D] = []             # the castle's worse and worse looks, one set a week
var _evil_now := -1
var _castle_lit: StandardMaterial3D       # the one window that is always lit
var storm: Node3D                         # the sky turning over the castle, in the last week
var _storm_light: OmniLight3D
var night := 0.0                          # how dark it is (main.gd keeps this up to date)
var _bell_swing := 0.0
var _dummy_hit: Array[float] = [0.0, 0.0, 0.0]

var _log_xf: Array[Transform3D] = []
var _log_col: Array[Color] = []


func _ready() -> void:
	rng.seed = 1337
	window_mat = StandardMaterial3D.new()
	window_mat.albedo_color = Color("3a3f52")
	window_mat.emission_enabled = true
	window_mat.emission = Color("ffd98a")
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
	_farms()
	_downs()


func rr(a: float, b: float) -> float:
	return rng.randf_range(a, b)


## A lantern: a small glowing box and a light that main.gd turns up at night.
func lantern(pos: Vector3, reach: float = 14.0) -> void:
	Build.glow_box(self, Vector3(0.45, 0.45, 0.45), pos, window_mat)
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
	Build.cyl(self, 30, 42, 7, HILL, Color("87a65d"), 14)
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
	_evil_build(n)


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


## How far gone the castle is: 0 in the first week, to 3 in the last.
func set_evil(level: int) -> void:
	if level == _evil_now: return
	_evil_now = level
	for i in _evil.size(): _evil[i].visible = level > i
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
	# west and east: the thorn hedge the village is named for
	for sx in [-1.0, 1.0]:
		var z := -64.0
		while z <= 55.0:
			var h := rr(1.7, 2.7)
			var hx: float = sx * (D.X1 + 2.3 + rr(-0.3, 0.3))
			Build.box(self, Vector3(rr(2.6, 3.6), h, 3.3), Vector3(hx, 0, z), [C.hedge, C.hedge2, C.hedge3][int(absf(z)) % 3], rr(-0.12, 0.12))
			Build.cone(self, 0.55, 1.1, Vector3(hx - sx * rr(0.2, 1.1), h - 0.2, z + rr(-1, 1)), C.hedge2, 4, rr(0, 3))
			z += 2.9


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
	# two braziers on the road outside the north gate
	for s in [-1.0, 1.0]:
		Build.cyl(self, 0.3, 0.42, 1.5, Vector3(s * 4.4, 0, -24.6), C.stone3, 6)
		Build.cyl(self, 0.55, 0.34, 0.4, Vector3(s * 4.4, 1.5, -24.6), C.iron, 6)
		lantern(Vector3(s * 4.4, 1.85, -24.6), 16.0)
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
func _multi(mesh: Mesh, xfs: Array[Transform3D], cols: Array[Color]) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_color(i, cols[i])
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	m.metallic_specular = 0.15
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
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
	# the old ruins and the priest's chapel
	_chapel()
	for i in 9:
		Build.box(self, Vector3(rr(1, 2.6), rr(0.5, 2.3), 0.5), Vector3(rr(8.3, 13.2), 0, rr(-18.2, -12.4)), C.stone2 if i % 2 else C.stone3, rr(0, 3))
	for p in [Vector2(9.2, -16), Vector2(8.4, -11.6)]:
		Build.cyl(self, 0.36, 0.42, rr(1.4, 2.6), Vector3(p.x, 0, p.y), C.stone2, 6)
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
	var glass := [Build.mat(Color("c23b3b"), 0.9), Build.mat(Color("3b6fc2"), 0.9), Build.mat(Color("e0b13a"), 0.9)]
	for sx in [-1.0, 1.0]:
		for i in 2:
			var zz := -0.95 + i * 1.9
			var g: Material = glass[(i + (1 if sx > 0 else 0)) % 3]
			Build.box(n, Vector3(0.12, 1.9, 0.62), Vector3(sx * (w / 2 + 0.02), 1.15, zz), Color("4a4438"))
			Build.glow_box(n, Vector3(0.12, 1.6, 0.44), Vector3(sx * (w / 2 + 0.05), 1.25, zz), g)
			var tip := Build.glow_box(n, Vector3(0.12, 0.32, 0.32), Vector3(sx * (w / 2 + 0.05), 2.82, zz), g)
			tip.rotation.x = PI / 4                                                            # the pointed top
	# the front: a pointed doorway, a round window above it, and the bell tower over all
	Build.box(n, Vector3(1.5, 2.3, 0.2), Vector3(0, 0.35, d / 2 + 0.02), trim)
	Build.box(n, Vector3(1.1, 2.0, 0.22), Vector3(0, 0.35, d / 2 + 0.04), Color("4b2f1e"))
	var arch := Build.box(n, Vector3(0.8, 0.8, 0.22), Vector3(0, 1.95, d / 2 + 0.04), Color("4b2f1e"))
	arch.rotation.z = PI / 4
	Build.box(n, Vector3(0.08, 1.9, 0.24), Vector3(0, 0.35, d / 2 + 0.06), Color("8a6a3c"))
	var rose := Build.cyl(n, 0.62, 0.62, 0.12, Vector3(0, 3.0, d / 2 + 0.02), trim, 12, 0.0, PI / 2)
	rose.position = Vector3(0, 3.0, d / 2 + 0.06)
	var rg := Build.cyl(n, 0.5, 0.5, 0.12, Vector3(0, 3.0, d / 2 + 0.1), Color.WHITE, 12, 0.0, PI / 2)
	rg.material_override = Build.mat(Color("8f5bc2"), 1.0)
	rg.position = Vector3(0, 3.0, d / 2 + 0.1)
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
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(420, 15.6)
	water.mesh = pm
	water.position = Vector3(0, 0.05, 65)
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode specular_schlick_ggx;
uniform vec3 shallow : source_color = vec3(0.56, 0.80, 0.85);
uniform vec3 deep : source_color = vec3(0.26, 0.55, 0.68);
uniform vec3 foam : source_color = vec3(0.93, 0.97, 0.98);
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float wave(vec2 p, float t) {
	return sin(p.x * 0.42 + t * 1.1 + sin(p.y * 0.9 + t * 0.4) * 1.6) * 0.5 + sin(p.x * 0.13 - p.y * 0.7 + t * 0.7) * 0.5;
}
void fragment() {
	float across = clamp(abs(wp.z - 65.0) / 7.8, 0.0, 1.0);
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
	water.material_override = wm
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
	for d in [Vector3(0.6, 0, -0.4), Vector3(-0.5, 0, 0.5)]:
		Build.box(self, Vector3(0.38, 0.22, 0.24), pp + d + Vector3(0, 0.05, 0), Color("f2efe4"))
		Build.box(self, Vector3(0.14, 0.18, 0.14), pp + d + Vector3(0.18, 0.25, 0), Color("3c6f43"))
		Build.box(self, Vector3(0.12, 0.05, 0.08), pp + d + Vector3(0.3, 0.33, 0), Color("e0a526"))
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
	# and, up top, the way down: a timber frame over a hole, by the mouth of the steel mine
	var dp := Vector3(M.door[0], 0, M.door[1])
	Build.box(self, Vector3(1.9, 0.06, 1.9), dp + Vector3(0, 0.03, 0), Color("15120f"))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Build.box(self, Vector3(0.22, 2.3, 0.22), dp + Vector3(sx * 1.0, 0, sz * 1.0), C.timber)
	for sz in [-1.0, 1.0]:
		Build.box(self, Vector3(2.4, 0.2, 0.24), dp + Vector3(0, 2.3, sz * 1.0), C.wood2)
	Build.box(self, Vector3(2.2, 0.12, 2.2), dp + Vector3(0, 2.5, 0), C.wood3)
	for sx in [-0.3, 0.3]:
		Build.box(self, Vector3(0.1, 1.6, 0.1), dp + Vector3(sx, 0, 0.5), C.wood, 0, 0.2)
	for i in 3:
		Build.box(self, Vector3(0.6, 0.07, 0.1), dp + Vector3(0, 0.35 + i * 0.45, 0.5 - i * 0.09), C.wood3)


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
	# the stranger's corner, a long way from the fire
	Build.box(n, Vector3(1.8, 0.8, 1.0), Vector3(-7.5, 0, -5.0), C.wood2)
	Build.cyl(n, 0.1, 0.09, 0.2, Vector3(-7.2, 0.8, -4.8), Color("b9bcc4"), 7)
	_npc(n, Vector3(-7.45, 0, -5.55), 0.5, Color("3b3340"), "hood")
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
	Build.box(n, Vector3(0.5, 0.56, 0.9), Vector3(-M.hw + 0.42, 0.78, -0.7), Color("8e1f25"), 0, 0, 0.06)
	Build.box(n, Vector3(0.52, 0.5, 0.08), Vector3(-M.hw + 0.42, 0.81, -0.7), Color("c9a13a"))
	# light: lanterns over the bar and the room, warm
	for at in [Vector3(-3.2, 2.9, -3.2), Vector3(3.6, 2.9, -2.6), Vector3(1.0, 2.9, 2.6)]:
		Build.box(n, Vector3(0.3, 0.36, 0.3), at, Color("ffd98a")).material_override = Build.mat(Color("ffd98a"), 2.2)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.82, 0.55)
		l.omni_range = 10.0
		l.light_energy = 1.5
		l.position = at
		n.add_child(l)


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


func _process(delta: float) -> void:
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
		var z := lerpf(-70.0, -24.8, clampf(t / go, 0, 1)) if t < go + 2.2 else lerpf(-24.8, -70.0, clampf((t - go - 2.2) / go, 0, 1))
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
	if maypole: maypole.rotation.y += delta * 0.12
