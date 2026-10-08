extends Node3D
## The trees, drawn from the rules' list. Each tree is a standing tree, a stump, or a sapling;
## when the rules say the trees have changed (R.tv), every tree is put back in its right shape.

const C_TRUNK := Color("6b4a2f")
const C_LEAF := Color("5d9349")
const C_LEAF2 := Color("6aa04e")
const C_STUMP := Color("8a6a48")

var _trunks: MultiMesh
var _cones: MultiMesh
var _balls: MultiMesh
var _stumps: MultiMesh
var _tv := -1
var _shake := {}        # tree index -> seconds left of a shiver, when someone chops at it


func _ready() -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.2; trunk.bottom_radius = 0.28; trunk.height = 1.0; trunk.radial_segments = 5; trunk.rings = 1
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0; cone.bottom_radius = 1.0; cone.height = 1.0; cone.radial_segments = 6; cone.rings = 1
	var ball := SphereMesh.new()
	ball.radius = 1.0; ball.height = 2.0; ball.radial_segments = 7; ball.rings = 4
	var stump := CylinderMesh.new()
	stump.top_radius = 0.3; stump.bottom_radius = 0.36; stump.height = 0.4; stump.radial_segments = 6; stump.rings = 1
	_trunks = _multi(trunk)
	_cones = _multi(cone)
	_balls = _multi(ball)
	_stumps = _multi(stump)


func _multi(mesh: Mesh) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	m.metallic_specular = 0.15
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = m
	add_child(mmi)
	return mm


func shake(i: int) -> void:
	_shake[i] = 0.35


func sync(R: Rules, delta: float) -> void:
	var moved := false
	for i in _shake.keys():
		_shake[i] -= delta
		moved = true
		if _shake[i] <= 0:
			_shake.erase(i)
	if R.tv == _tv and not moved:
		return
	_tv = R.tv
	var trees: Array = R.trees
	var n := trees.size()
	if _trunks.instance_count != n:
		_trunks.instance_count = n; _stumps.instance_count = n
		_cones.instance_count = n * 3; _balls.instance_count = n * 2
	var hide := Transform3D(Basis().scaled(Vector3.ZERO), Vector3(0, -50, 0))
	for t: E.Trunk in trees:
		var i := t.i
		var s := t.s * (1.0 if t.st == 0 else 0.38)          # a sapling is a little tree
		var tilt := sin(_shake[i] * 40.0) * 0.06 if _shake.has(i) else 0.0
		var rot := Basis(Vector3.UP, t.rot) * Basis(Vector3.FORWARD, tilt)
		var at := Vector3(t.x, 0, t.z)
		var tint := C_LEAF2 if t.kind else C_LEAF
		tint = Color(tint.r * t.tint.r, tint.g * t.tint.g, tint.b * t.tint.b)
		if t.st == 1:                                        # a stump
			_stumps.set_instance_transform(i, Transform3D(Basis(Vector3.UP, t.rot).scaled(Vector3(t.s, t.s, t.s)), at + Vector3(0, 0.2 * t.s, 0)))
			_stumps.set_instance_color(i, C_STUMP)
			_trunks.set_instance_transform(i, hide)
			for k in 3: _cones.set_instance_transform(i * 3 + k, hide)
			for k in 2: _balls.set_instance_transform(i * 2 + k, hide)
			continue
		_stumps.set_instance_transform(i, hide)
		if t.kind == 0:                                      # a pine: three cones on a trunk
			_trunks.set_instance_transform(i, Transform3D(rot.scaled(Vector3(s, s * 1.1, s)), at + Vector3(0, 0.55 * s, 0)))
			var ks := [[1.25, 2.0, 0.8], [0.98, 1.8, 1.95], [0.62, 1.4, 3.0]]
			for k in 3:
				var q: Array = ks[k]
				_cones.set_instance_transform(i * 3 + k, Transform3D(rot.scaled(Vector3(q[0] * s, q[1] * s, q[0] * s)), at + rot * Vector3(0, (q[2] + q[1] * 0.5) * s, 0)))
				_cones.set_instance_color(i * 3 + k, tint)
			for k in 2: _balls.set_instance_transform(i * 2 + k, hide)
		else:                                                # a broadleaf: two lumps on a trunk
			_trunks.set_instance_transform(i, Transform3D(rot.scaled(Vector3(s * 1.1, s * 1.5, s * 1.1)), at + Vector3(0, 0.75 * s, 0)))
			_balls.set_instance_transform(i * 2, Transform3D(rot.scaled(Vector3.ONE * 1.35 * s), at + rot * Vector3(0, 2.4 * s, 0)))
			_balls.set_instance_transform(i * 2 + 1, Transform3D(rot.scaled(Vector3.ONE * 0.85 * s), at + rot * Vector3(0.7 * s, 3.2 * s, 0.25 * s)))
			_balls.set_instance_color(i * 2, tint); _balls.set_instance_color(i * 2 + 1, tint)
			for k in 3: _cones.set_instance_transform(i * 3 + k, hide)
		_trunks.set_instance_color(i, C_TRUNK)
