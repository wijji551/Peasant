extends Node3D
## The dead on screen. Two hundred of them at once is normal by the end of the week, so each kind is one
## MultiMesh: every one of them is a transform and a colour, as in the web version. A flash when hit, a lean
## back when stunned or pinned, greener when frightened, redder when cracked open by a Shatter.

const KINDS := ["shamb", "skel", "archer", "steward", "ghoul", "digger", "bats", "guard", "wraith", "ram", "hearse", "captain", "lord"]
const SCALE := [1.1, 1.05, 1.05, 1.65, 1.15, 1.1, 1.1, 1.2, 1.25, 1.1, 1.15, 1.6, 1.55]
const MAX := [260, 260, 160, 4, 160, 120, 120, 120, 80, 8, 2, 2, 2]

var fx: Node3D                       # for the puffs when they are hit and when they go
var _body := []                      # MultiMesh per kind
var _eyes := []
var _v := {}                         # undead id -> what the view remembers: [x, z, r, walk, atk, flash, ac, hc, rise, pile, mv]


func _ready() -> void:
	for k in KINDS.size():
		_body.append(_mm(Models.get_mesh(KINDS[k]), MAX[k], _ghostly() if k == D.U_WRAITH else null))
		_eyes.append(_mm(Models.get_mesh(KINDS[k] + "_eyes"), MAX[k], Models.glow()))


static var _ghost_mat: Material
static func _ghostly() -> Material:   # wraiths: see-through, faintly glowing
	if _ghost_mat == null:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.emission_enabled = true
		m.emission = Color(0.35, 0.45, 0.6)
		m.emission_energy_multiplier = 0.6
		m.roughness = 1.0
		_ghost_mat = m
	return _ghost_mat


func _mm(mesh: Mesh, n: int, mat: Material) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = n
	mm.visible_instance_count = 0
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	if mat: mi.material_override = mat
	add_child(mi)
	return mm


func gone(id: int, x: float, z: float, k: int) -> void:   # put down for good: a burst of bits
	_v.erase(id)
	if fx:
		var big: bool = D.UN[k].boss or D.UN[k].ram
		var c = fx.C_STEWARD if big or k == D.U_WRAITH else fx.C_BONE if D.UN[k].bony else fx.C_GHOST if k == D.U_BATS else fx.C_ROT
		fx.puff(x, 2.2 if k == D.U_BATS else 0.5, z, 40 if big else 12, c, 6.0 if big else 3.5)


func sync(R: Rules, delta: float) -> void:
	var n := []
	n.resize(KINDS.size()); n.fill(0)
	var seen := {}
	var now := Time.get_ticks_msec() / 1000.0
	for u: E.Undead in R.undead:
		seen[u.id] = true
		var v: Array = _v.get(u.id, [])
		if v.is_empty():
			v = [u.x, u.z, u.r, randf() * 6, 0.0, 0.0, u.ac, u.hc, 0.0, 0.0, 0.0]
			_v[u.id] = v
		var px: float = v[0]
		var pz: float = v[1]
		v[0] = lerpf(v[0], u.x, minf(1.0, delta * 14)); v[1] = lerpf(v[1], u.z, minf(1.0, delta * 14))
		v[2] = lerp_angle(v[2], u.r, minf(1.0, delta * 12))
		var sp := Vector2(v[0] - px, v[1] - pz).length() / maxf(delta, 1e-3)
		v[10] = lerpf(v[10], minf(1.0, sp / 2.2), minf(1.0, delta * 9))
		if v[10] > 0.06: v[3] += delta * (5 + sp * 1.5)
		var did_atk: bool = u.ac != v[6]
		if did_atk: v[6] = u.ac; v[4] = 1.0
		if u.hc != v[7]:
			v[7] = u.hc; v[5] = 1.0
			if fx and u.state != "rise":
				fx.puff(u.x, 2.2 if u.k == D.U_BATS else 1.0, u.z, 3, fx.C_BONE if D.UN[u.k].bony or D.UN[u.k].ram else fx.C_SPARK if D.UN[u.k].armour else fx.C_ROT, 2.5)
		v[4] = maxf(0, v[4] - delta * 4.2); v[5] = maxf(0, v[5] - delta * 7)
		v[8] = minf(1.0, v[8] + delta / 1.2) if u.state == "rise" else maxf(0.0, v[8] - delta / 4.5) if u.state == "dig" else 1.0
		if u.state == "dig" and fx and randf() < delta * 6: fx.puff(u.x, 0.2, u.z, 2, fx.C_WOOD, 1.5)
		var k := u.k
		if n[k] >= MAX[k]: continue
		var f: float = 1 + v[5] * 1.5
		var dz := -0.45 if u.stun > 0 or u.pin > 0 else 0.0           # dazed ones lean back
		var col := Color(f * (1.5 if u.vuln > 0 else 1.0), f * (1.25 if u.fear > 0 else 0.75 if u.vuln > 0 else 1.0), f * (0.7 if u.fear > 0 or u.vuln > 0 else 1.0))
		if u.stun > 0 and fx and randf() < delta * 5: fx.puff(u.x, 2, u.z, 1, fx.C_SPARK, 0.7)
		var y: float = -1.6 * (1 - v[8])
		var walk: float = v[3]
		var atk: float = v[4]
		var mv: float = v[10]
		var xf: Transform3D
		var s: float = SCALE[k]
		if k == D.U_BATS:                                           # a swarm: up in the air, fluttering
			var fl := sin(now * 9.0 + u.id) * 0.12
			xf = _xf(v[0], 2.2 + sin(now * 2.3 + u.id) * 0.35 + fl, v[1], v[2] + sin(now * 1.7 + u.id) * 0.4, fl, fl * 2, Vector3(s, s * (1 + fl), s))
		elif k == D.U_WRAITH:                                       # drifting a little off the ground
			xf = _xf(v[0], y + 0.25 + sin(now * 1.6 + u.id) * 0.12, v[1], v[2], dz * 0.5 + sin(atk * PI) * 0.4, sin(now * 1.1 + u.id) * 0.06, Vector3(s, s, s))
			col.a = 0.55
		elif k == D.U_RAM:                                          # carried at a trot
			xf = _xf(v[0], absf(sin(walk * 1.2)) * 0.08 * mv, v[1], v[2], sin(atk * PI) * -0.15, sin(walk * 1.2) * 0.03, Vector3(s, s, s))
		elif k == D.U_COACH:                                        # the hearse rocks along
			xf = _xf(v[0], absf(sin(walk * 2.0)) * 0.06 * mv, v[1], v[2], sin(atk * PI) * 0.1, sin(walk * 1.3) * 0.04 * mv, Vector3(s, s, s))
		elif k == 0 or k == D.U_DIGGER:
			xf = _xf(v[0], y, v[1], v[2], 0.08 + dz + sin(atk * PI) * 0.5, sin(walk * 0.8) * 0.11, Vector3(s, s, s))
		elif k == 3 or k == D.U_CAPTAIN or k == D.U_LORD:
			var cast := sin(now / 0.26) * 0.06 if u.state == "atk" and mv < 0.1 else 0.0
			if did_atk and fx: fx.puff(u.x, 2.6, u.z, 8, fx.C_GHOST, 2.5)
			xf = _xf(v[0], y * 1.6 + absf(sin(walk * 0.7)) * 0.08 * mv, v[1], v[2], dz * 0.5 + sin(atk * PI) * 0.3, cast, Vector3(s, s + cast, s))
		elif u.state == "pile":                                     # a heap of bones, which shivers before it gets up
			v[9] += delta
			var sh := sin(v[9] * 45) * 0.05 if v[9] > 2.4 else 0.0
			xf = _xf(v[0] + sh, 0, v[1], v[2], 0, 0, Vector3(1.35, 0.2, 1.35))
			col = Color(f * 0.85, f * 0.85, f * 0.85)
		else:
			v[9] = 0.0
			xf = _xf(v[0], y + absf(sin(walk)) * 0.1 * mv, v[1], v[2], dz + sin(atk * PI) * (-0.2 if k == 2 else 0.45), sin(walk) * 0.08, Vector3(s, s, s))
		_body[k].set_instance_transform(n[k], xf)
		_body[k].set_instance_color(n[k], col)
		_eyes[k].set_instance_transform(n[k], xf)
		_eyes[k].set_instance_color(n[k], Color(1, 1, 1) if u.state != "pile" else Color(0, 0, 0, 0))
		n[k] += 1
	for k in KINDS.size():
		_body[k].visible_instance_count = n[k]
		_eyes[k].visible_instance_count = n[k]
	for id in _v.keys():
		if not seen.has(id): _v.erase(id)


static func _xf(x: float, y: float, z: float, ry: float, rx: float, rz: float, sc: Vector3) -> Transform3D:
	return Transform3D(Basis.from_euler(Vector3(rx, ry, rz)).scaled_local(sc), Vector3(x, y, z))
