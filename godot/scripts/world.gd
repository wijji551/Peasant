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
const X_MIN := -92.0
const X_MAX := 92.0
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
	_graveyard_and_edges()
	_walls()
	_keep()
	_buildings()
	_farms()


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
		Build.box(self, Vector3(s, 0.01 + i * 0.0001, s * rr(0.6, 1.5)), Vector3(rr(-140, 140), 0, rr(-150, 95)), C.grass2 if i % 2 else C.grass3, rr(0, 3))
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
	# the river, south
	Build.box(self, Vector3(300, 0.03, 4), Vector3(0, 0, 56.5), C.sand)
	var river := Build.box(self, Vector3(300, 0.05, 14), Vector3(0, 0, 65), C.water)
	var wm := StandardMaterial3D.new()
	wm.albedo_color = C.water
	wm.roughness = 0.15
	wm.metallic = 0.2
	river.material_override = wm
	Build.box(self, Vector3(300, 0.06, 2.5), Vector3(0, 0, 62), C.water2)
	Build.box(self, Vector3(300, 0.06, 1.5), Vector3(0, 0, 68), C.water2)
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
	var sx_ := -90.0
	while sx_ <= 90.0:
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
			var hx: float = sx * (94.3 + rr(-0.3, 0.3))
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
	house(17, -14, 0, 4.4, 6.2, 3.4, C.stone, C.slate, true, false, 2.8)
	Build.box(self, Vector3(1, 1.5, 1), Vector3(17, 6.2, -12), C.stone2)
	Build.cone(self, 0.9, 1.2, Vector3(17, 7.7, -12), C.slate, 4, PI / 4)
	Build.box(self, Vector3(0.14, 1, 0.14), Vector3(17, 8.8, -12), C.stone3)
	Build.box(self, Vector3(0.6, 0.14, 0.14), Vector3(17, 9.3, -12), C.stone3)
	for i in 9:
		Build.box(self, Vector3(rr(1, 2.6), rr(0.5, 2.3), 0.5), Vector3(rr(8.3, 13.2), 0, rr(-18.2, -12.4)), C.stone2 if i % 2 else C.stone3, rr(0, 3))
	for p in [Vector2(9.2, -16), Vector2(8.4, -11.6)]:
		Build.cyl(self, 0.36, 0.42, rr(1.4, 2.6), Vector3(p.x, 0, p.y), C.stone2, 6)
	# the Thorny Rose
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
		Build.box(self, Vector3(0.18, 1.7, 0.18), Vector3(x, 0, 10.8), C.timber)
		Build.box(self, Vector3(1.1, 0.16, 0.16), Vector3(x, 1.15, 10.8), C.timber)
		Build.box(self, Vector3(0.5, 0.7, 0.4), Vector3(x, 0.75, 10.8), C.straw)
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
	Build.cyl(self, 0.2, 0.42, 0.6, Vector3(5.5, 1.85, -9.5), Color("c9962f"), 7)
	Build.box(self, Vector3(2, 1.2, 0.12), Vector3(-5.5, 0.75, -9.5), C.wood3)
	Build.box(self, Vector3(0.6, 0.8, 0.14), Vector3(-5.9, 0.95, -9.5), C.cream)
	# the cottages, one per player
	var roofs := [C.roof, C.thatch, C.roof3, C.roof2]
	for i in 8:
		var c := cottage(i)
		house(c.x, c.z, 0.0 if c.dir > 0 else PI, 3.7, 3.3, 2.0, C.cream if i % 2 else C.cream2, roofs[i % 4], false, i % 3 == 0, 1.9)


func _farms() -> void:
	for i in 6:
		Build.box(self, Vector3(24, 0.05, 3), Vector3(-58, 0, 22 + i * 3.6), [C.field1, C.field2, C.field3][i % 3])
	for i in 14:
		Build.box(self, Vector3(0.2, 0.9, 0.2), Vector3(-70.5 + i * 2, 0, 19.6), C.wood2)
		Build.box(self, Vector3(0.2, 0.9, 0.2), Vector3(-70.5 + i * 2, 0, 42.8), C.wood2)
	house(-47, 24, PI / 2, 5, 7, 3.6, Color("a9493b"), C.roof2, true, false, 2.6)
	for p in [Vector2(-48, 33), Vector2(-46.5, 36), Vector2(-49, 38.5)]:
		Build.cyl(self, 1.1, 1.3, 1.3, Vector3(p.x, 0, p.y), C.straw, 7)
		Build.cone(self, 1.3, 1.1, Vector3(p.x, 1.3, p.y), C.straw, 7)
	# (the rocky outcrop and the mine move every morning: sites.gd draws them)

