extends Node3D
## Small effects: bits that fly up and bounce (chips of wood, bone, sparks, coins, splashes), rings of them,
## and things in flight (arrows, sling stones, what the posse threw, buckets). As in the web version.

const MAX_BITS := 480

# the colours of the bits
const C_BONE := [Color(0.92, 0.9, 0.82), Color(0.8, 0.78, 0.7)]
const C_ROT := [Color(0.5, 0.62, 0.48), Color(0.36, 0.4, 0.33), Color(0.7, 0.9, 0.6)]
const C_WOOD := [Color(0.6, 0.47, 0.3), Color(0.5, 0.38, 0.25), Color(0.78, 0.66, 0.44)]
const C_LEAF := [Color(0.36, 0.58, 0.29), Color(0.45, 0.65, 0.33), Color(0.6, 0.47, 0.3)]
const C_STONE := [Color(0.76, 0.74, 0.67), Color(0.6, 0.58, 0.54)]
const C_IRON := [Color(0.45, 0.42, 0.4), Color(0.75, 0.5, 0.3)]
const C_FOOD := [Color(0.82, 0.7, 0.34), Color(0.5, 0.7, 0.3)]
const C_SPLASH := [Color(0.56, 0.8, 0.86), Color(0.8, 0.92, 0.95)]
const C_COIN := [Color(0.95, 0.8, 0.3), Color(0.8, 0.6, 0.2)]
const C_GHOST := [Color(0.6, 1, 0.7), Color(0.8, 1, 0.85)]
const C_SPARK := [Color(1, 0.75, 0.3), Color(1, 0.9, 0.6)]
const C_FIRE := [Color(1.0, 0.55, 0.12), Color(1.0, 0.82, 0.25), Color(0.9, 0.25, 0.08)]
const C_HOLY := [Color(1, 0.95, 0.6), Color(1, 1, 0.9)]
const C_POO := [Color(0.42, 0.3, 0.16), Color(0.5, 0.42, 0.2), Color(0.36, 0.4, 0.18)]
const C_ALE := [Color(0.9, 0.7, 0.25), Color(1, 0.95, 0.8)]
const C_DUST := [Color(0.8, 0.76, 0.66), Color(0.66, 0.62, 0.55)]
const C_BLOOD := [Color(0.8, 0.2, 0.2)]
const C_GLAD := [Color(1, 0.93, 0.6)]
const C_STEWARD := [Color(0.15, 0.13, 0.18), Color(0.8, 0.84, 0.78)]

var _bits := []            # [pos, vel, life, colour, size]
var _mm: MultiMesh
var _flying := []          # [from, to, t, kind, node]
var _beams := []           # [node, life]: smites, columns of holy light
var _arcs := []            # [node, age, life, kind, facing, half angle, size]: the sweep of a blade, a thrust, a shockwave
var _arc_spare: Array[MeshInstance3D] = []
var _arc_n := 0

const MAX_ARCS := 72
const WHITE := Color(1.0, 0.97, 0.88)


## The sweep of a weapon through the air: a crescent in front of whoever swung, there for a fifth of a second.
## half is half the angle swept; a narrow one (a pitchfork, a spear) is drawn as a thrust. must: draw it even if
## that means taking an older one away (for the players; the crowd goes without when there are too many).
func slash(x: float, z: float, r: float, reach: float, half: float, col: Color = WHITE, must: bool = false, y: float = 1.25) -> void:
	var thrust := half < 0.3
	var n := _arc_node(_arc_mesh(half, 0.2 if thrust else 0.62), col, must)
	if n == null: return
	n.position = Vector3(x, y, z)
	n.rotation = Vector3(0, r, 0) if thrust else Vector3(0, r, randf_range(-0.22, 0.22))
	_arcs.append([n, 0.0, 0.16 if thrust else 0.21, 1 if thrust else 0, r, half, reach])
	_arc_step(_arcs[-1], 0.0)


## A ring racing outwards along the ground: something heavy has landed.
func shock(x: float, z: float, rad: float, col: Color = WHITE, life: float = 0.42) -> void:
	var n := _arc_node(_ring_mesh(), col, true)
	if n == null: return
	n.position = Vector3(x, 0.14, z)
	n.rotation = Vector3.ZERO
	_arcs.append([n, 0.0, life, 2, 0.0, 0.0, rad])
	_arc_step(_arcs[-1], 0.0)


func _arc_node(mesh: Mesh, col: Color, must: bool) -> MeshInstance3D:
	var n: MeshInstance3D
	if not _arc_spare.is_empty():
		n = _arc_spare.pop_back()
	elif _arc_n < MAX_ARCS:
		_arc_n += 1
		n = MeshInstance3D.new()
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.disable_fog = true
		m.disable_receive_shadows = true
		n.material_override = m
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(n)
	elif must and not _arcs.is_empty():
		var old: Array = _arcs.pop_front()
		n = old[0]
	else:
		return null
	n.mesh = mesh
	n.set_meta("col", col)
	n.visible = true
	return n


func _arc_step(a: Array, delta: float) -> void:
	a[1] += delta
	var n: MeshInstance3D = a[0]
	var k: float = clampf(a[1] / a[2], 0.0, 1.0)
	var e := 1.0 - (1.0 - k) * (1.0 - k)                      # fast, then easing
	var col: Color = n.get_meta("col")
	var size: float = a[6]
	match a[3]:
		0:                                                    # a swing: the crescent follows the blade round
			n.rotation.y = a[4] + lerpf(0.4, -0.08, e)
			var s := size * (0.92 + 0.12 * e)
			n.scale = Vector3(s, 1, s)
			col.a *= (1.0 - k) * minf(1.0, k * 9.0 + 0.35)
		1:                                                    # a thrust: it darts out
			var s := size * (0.5 + 0.62 * e)
			n.scale = Vector3(size * 0.9, 1, s)
			col.a *= (1.0 - k * k)
		_:                                                    # a shockwave
			var s := size * (0.2 + 0.8 * e)
			n.scale = Vector3(s, 1, s)
			col.a *= (1.0 - k) * (1.0 - k)
	(n.material_override as StandardMaterial3D).albedo_color = col


static var _arc_cache := {}
## A crescent lying flat, pointing along +Z, one unit long: no width at its two ends, soft on the inside, and
## brightest at the end the blade finishes at.
static func _arc_mesh(half: float, inner: float) -> ArrayMesh:
	var key := "%d:%d" % [roundi(half * 16), roundi(inner * 20)]
	if _arc_cache.has(key): return _arc_cache[key]
	var n := clampi(int(half * 2.0 / 0.13), 6, 40)
	var vs := PackedVector3Array()
	var cs := PackedColorArray()
	var ix := PackedInt32Array()
	for i in n + 1:
		var t := float(i) / n
		var a := lerpf(-half, half, t)
		var w := lerpf(1.0, inner, pow(sin(t * PI), 0.6))
		vs.append(Vector3(sin(a) * w, 0, cos(a) * w)); cs.append(Color(1, 1, 1, 0.0))
		vs.append(Vector3(sin(a), 0, cos(a))); cs.append(Color(1, 1, 1, 0.38 + 0.62 * pow(1.0 - t, 1.3)))      # (the weapon hand is on that side)
	for i in n:
		var b := i * 2
		ix.append_array(PackedInt32Array([b, b + 1, b + 2, b + 1, b + 3, b + 2]))
	_arc_cache[key] = _mesh_of(vs, cs, ix)
	return _arc_cache[key]


## A flat ring, one unit across: clear in the middle, bright near the rim, and soft at the very edge.
static func _ring_mesh() -> ArrayMesh:
	if _arc_cache.has("ring"): return _arc_cache["ring"]
	var n := 40
	var vs := PackedVector3Array()
	var cs := PackedColorArray()
	var ix := PackedInt32Array()
	for i in n + 1:
		var a := float(i) / n * TAU
		for band in [[0.62, 0.0], [0.93, 0.9], [1.0, 0.0]]:
			vs.append(Vector3(sin(a) * band[0], 0, cos(a) * band[0])); cs.append(Color(1, 1, 1, band[1]))
	for i in n:
		var b := i * 3
		ix.append_array(PackedInt32Array([b, b + 1, b + 3, b + 1, b + 4, b + 3, b + 1, b + 2, b + 4, b + 2, b + 5, b + 4]))
	_arc_cache["ring"] = _mesh_of(vs, cs, ix)
	return _arc_cache["ring"]


static func _mesh_of(vs: PackedVector3Array, cs: PackedColorArray, ix: PackedInt32Array) -> ArrayMesh:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_COLOR] = cs
	arr[Mesh.ARRAY_INDEX] = ix
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


## A column of holy light coming down from the sky: a smite.
func beam(x: float, z: float) -> void:
	var n := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.45; cm.bottom_radius = 0.95; cm.height = 16.0; cm.radial_segments = 12; cm.rings = 1
	n.mesh = cm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1.0, 0.85, 0.4, 1.0)
	m.disable_fog = true
	n.material_override = m
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.position = Vector3(x, 8.0, z)
	var l := OmniLight3D.new()                    # and the ground lit gold for a moment
	l.light_color = Color(1.0, 0.85, 0.45)
	l.light_energy = 5.0
	l.omni_range = 8.0
	l.position = Vector3(0, -7.0, 0)
	n.add_child(l)
	add_child(n)
	_beams.append([n, 0.55])
	puff(x, 0.4, z, 14, C_HOLY, 4.0)
	ring(x, z, 2.2, 14, C_HOLY)


func _ready() -> void:
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.mesh = Models.get_mesh("bit")
	_mm.instance_count = MAX_BITS
	_mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func puff(x: float, y: float, z: float, n: int, cols: Array, spd: float = 3.0) -> void:
	for i in n:
		if _bits.size() >= MAX_BITS: return
		var a := randf() * TAU
		var s := spd * (0.4 + randf())
		_bits.append([Vector3(x, y + randf() * 0.6, z), Vector3(cos(a) * s, 2 + randf() * 4, sin(a) * s), 0.5 + randf() * 0.5, cols[i % cols.size()], 0.6 + randf()])


func ring(x: float, z: float, rad: float, n: int, cols: Array) -> void:
	for i in n:
		if _bits.size() >= MAX_BITS: return
		var a := float(i) / n * TAU
		_bits.append([Vector3(x + cos(a) * rad * 0.3, 0.3, z + sin(a) * rad * 0.3), Vector3(cos(a) * rad * 2.2, 2.5, sin(a) * rad * 2.2), 0.45, cols[i % cols.size()], 1.0])


## Something in flight from one place to another over 0.4 seconds. kind: 0 arrow, 1 sling stone, 2 bolt or arrow,
## 3 what the posse threw, 4 a bucket. (The rules' shot kinds are one less than these.)
func fly(x1: float, z1: float, x2: float, z2: float, kind: int) -> void:
	var n := MeshInstance3D.new()
	match kind:
		1: n.mesh = Models.get_mesh("bit"); n.scale = Vector3.ONE * 0.9; n.material_override = _tint(Color(0.62, 0.6, 0.56))
		3: n.mesh = Models.get_mesh("bit"); n.scale = Vector3.ONE * 1.3; n.material_override = _tint(Color(0.4, 0.29, 0.15))
		4: n.mesh = Models.get_mesh("bucket"); n.material_override = _tint(Color(0.6, 0.48, 0.3))
		_: n.mesh = Models.get_mesh("arrow")
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(n)
	_flying.append([Vector3(x1, 0, z1), Vector3(x2, 0, z2), 0.0, kind, n])


static var _tints := {}
func _tint(c: Color) -> Material:
	if not _tints.has(c):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.albedo_color = c
		m.roughness = 1.0
		_tints[c] = m
	return _tints[c]


func _process(delta: float) -> void:
	var i := _bits.size() - 1
	while i >= 0:
		var b: Array = _bits[i]
		b[2] -= delta
		if b[2] <= 0:
			_bits.remove_at(i)
			i -= 1
			continue
		var v: Vector3 = b[1]
		v.y -= 16 * delta
		var p: Vector3 = b[0] + v * delta
		if p.y < 0.08:
			p.y = 0.08; v.y *= -0.35; v.x *= 0.6; v.z *= 0.6
		b[0] = p; b[1] = v
		i -= 1
	_mm.visible_instance_count = _bits.size()
	for j in _bits.size():
		var b: Array = _bits[j]
		var s: float = b[4] * minf(1.0, b[2] * 4)
		_mm.set_instance_transform(j, Transform3D(Basis.from_euler(Vector3(b[2] * 7, b[2] * 9, 0)).scaled(Vector3(s, s, s)), b[0]))
		_mm.set_instance_color(j, b[3])
	i = _arcs.size() - 1
	while i >= 0:
		var ar: Array = _arcs[i]
		_arc_step(ar, delta)
		if ar[1] >= ar[2]:
			(ar[0] as MeshInstance3D).visible = false
			_arc_spare.append(ar[0])
			_arcs.remove_at(i)
		i -= 1
	i = _beams.size() - 1
	while i >= 0:
		var bm: Array = _beams[i]
		bm[1] -= delta
		var node: MeshInstance3D = bm[0]
		if bm[1] <= 0:
			node.queue_free()
			_beams.remove_at(i)
		else:
			var f: float = bm[1] / 0.55
			node.scale = Vector3(f, 1.0, f)
			(node.material_override as StandardMaterial3D).albedo_color.a = f
			(node.get_child(0) as OmniLight3D).light_energy = 5.0 * f
		i -= 1
	i = _flying.size() - 1
	while i >= 0:
		var a: Array = _flying[i]
		a[2] += delta / 0.4
		var n: MeshInstance3D = a[4]
		if a[2] >= 1:
			n.queue_free()
			_flying.remove_at(i)
			i -= 1
			continue
		var t: float = a[2]
		var from: Vector3 = a[0]
		var to: Vector3 = a[1]
		var pos := from.lerp(to, t)
		pos.y = 1.2 + sin(t * PI) * 1.3
		match a[3]:
			1: n.position = pos + Vector3(0, 0.2, 0); n.rotation = Vector3(t * 14, t * 20, 0)
			3: n.position = pos + Vector3(0, 0.6, 0); n.rotation = Vector3(t * 22, t * 16, 0)
			4: n.position = pos + Vector3(0.5, 0.6, 0); n.rotation = Vector3(t * 12, t * 9, 0)
			_:
				n.position = pos
				var span := maxf(0.01, from.distance_to(to))
				n.rotation = Vector3(-atan2(cos(t * PI) * 1.3 * PI, span), atan2(to.x - from.x, to.z - from.z), 0)
		i -= 1
