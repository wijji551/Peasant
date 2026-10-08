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
