extends Node3D
## The dead on screen. Two hundred of them at once is normal by the end of the week, so each kind is one
## MultiMesh: every one of them is a transform and a colour, as in the web version. A flash when hit, a lean
## back when stunned or pinned, greener when frightened, redder when cracked open by a Shatter.

const KINDS := ["shamb", "skel", "archer", "steward", "ghoul", "digger", "bats", "guard", "wraith", "ram", "hearse", "captain", "lord", "tenant", "bloat", "pall", "hound", "chaplain", "cook", "wolf", "shadow"]
const SCALE := [1.1, 1.05, 1.05, 1.65, 1.15, 1.1, 1.1, 1.2, 1.25, 1.1, 1.15, 1.6, 1.55, 1.25, 1.15, 1.1, 1.0, 1.45, 1.55, 1.6, 1.6]
const MAX := [260, 260, 160, 4, 160, 120, 120, 120, 80, 8, 2, 2, 2, 4, 120, 120, 160, 2, 2, 2, 2]

var fx: Node3D                       # for the puffs when they are hit and when they go
var _body := []                      # MultiMesh per kind
var _eyes := []
var enraged := false                 # a night of the bells
var _v := {}                         # undead id -> what the view remembers: [x, z, r, walk, atk, flash, ac, hc, rise, pile, mv]


func _ready() -> void:
	for k in KINDS.size():
		_body.append(_mm(Models.get_mesh(KINDS[k]), MAX[k], _ghostly() if k == D.U_WRAITH or k == D.U_SHADOW else null if D.UN[k].boss else _evil()))
		_eyes.append(_mm(Models.get_mesh(KINDS[k] + "_eyes"), MAX[k], Models.glow()))


# ---------------------------------------------------------------- the Lord, in pieces (version 7.4)
var _lord: Node3D
var _lord_id := -1
var _cloak: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _pose := ""                      # what he is doing, from the events: "sweep_up", "sweep", "slam_up", "slam", "bats_up", "bats"
var _pose_t := 0.0


## Called from the events: the Lord winding up or letting go.
func lord_pose(p: String, t: float) -> void:
	_pose = p; _pose_t = t


func _lord_build() -> void:
	_lord = Node3D.new()
	add_child(_lord)
	var body := MeshInstance3D.new(); body.mesh = Models.get_mesh("lord_body"); _lord.add_child(body)
	_cloak = Node3D.new(); _cloak.position = Vector3(0, 1.9, -0.3); _lord.add_child(_cloak)
	var cm := MeshInstance3D.new(); cm.mesh = Models.get_mesh("lord_cloak"); _cloak.add_child(cm)
	_arm_l = Node3D.new(); _arm_l.position = Vector3(-0.4, 1.7, 0); _lord.add_child(_arm_l)
	var al := MeshInstance3D.new(); al.mesh = Models.get_mesh("lord_arm"); _arm_l.add_child(al)
	_arm_r = Node3D.new(); _arm_r.position = Vector3(0.4, 1.7, 0.05); _lord.add_child(_arm_r)
	var ar := MeshInstance3D.new(); ar.mesh = Models.get_mesh("lord_arm"); _arm_r.add_child(ar)
	var gb := MeshInstance3D.new(); gb.mesh = Models.get_mesh("lord_goblet"); _arm_r.add_child(gb)


func _lord_show(u: E.Undead, xf: Transform3D, col: Color, delta: float, now: float, mv: float, did_atk: bool) -> void:
	if _lord == null: _lord_build()
	_lord.visible = true; _lord_id = u.id
	_lord.transform = xf
	_pose_t = maxf(0.0, _pose_t - delta)
	if _pose_t <= 0: _pose = ""
	var walk := sin(now * 4.0) * 0.5 * mv
	# what each part wants to be doing: (cloak back-and-out, cloak width, left arm forward, right arm forward, arms out)
	var want := Vector4(0.12 + sin(now * 1.3) * 0.05 + mv * 0.25, 1.0, walk, -walk)
	var spread := 0.0
	match _pose:
		"sweep_up": want = Vector4(0.9, 1.35, 0.3, -2.4); spread = 0.4                 # the cloak gathered up, the arm drawn back
		"sweep": want = Vector4(1.3, 1.5, 0.3, 1.6); spread = 0.2                      # and swung across
		"slam_up": want = Vector4(0.5, 1.1, -2.8, -2.8)                                # both arms up
		"slam": want = Vector4(0.2, 1.0, 0.6, 0.6)                                     # and down
		"bats_up", "bats": want = Vector4(1.1, 1.6, -0.2, -0.2); spread = 1.3          # arms flung wide: here come the bats
	var k := minf(1.0, delta * (14.0 if _pose == "sweep" or _pose == "slam" else 7.0))
	_cloak.rotation.x = lerpf(_cloak.rotation.x, want.x, k)
	_cloak.scale.x = lerpf(_cloak.scale.x, want.y, k)
	_arm_l.rotation.x = lerpf(_arm_l.rotation.x, want.z, k)
	_arm_r.rotation.x = lerpf(_arm_r.rotation.x, want.w, k)
	_arm_l.rotation.z = lerpf(_arm_l.rotation.z, -spread, k)
	_arm_r.rotation.z = lerpf(_arm_r.rotation.z, spread, k)


## Every one of the dead that is not a boss: a mild, evil glow about the edges, which shows best at night.
static var _evil_mat: Material
static func _evil() -> Material:
	if _evil_mat == null:
		var sh := Shader.new()
		sh.code = """shader_type spatial;
uniform vec3 hue = vec3(0.42, 1.0, 0.36);
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.15;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.4);
	EMISSION = hue * (rim * 0.5 + 0.035);
}
"""
		var m := ShaderMaterial.new()
		m.shader = sh
		_evil_mat = m
	return _evil_mat


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
		if did_atk:
			v[6] = u.ac; v[4] = 1.0
			if fx and (k0(u.k) == 0) and u.state != "rise": fx.slash(u.x, u.z, u.r, 1.5 * SCALE[u.k], 0.75, Color(0.8, 0.14, 0.1, 0.75), false, 1.2 * SCALE[u.k])   # a claw, or a rusty blade
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
		var dz: float = (-0.45 if u.stun > 0 or u.pin > 0 else 0.0) - float(v[5]) * 0.4   # dazed ones lean back; so, for a moment, do the ones just hit
		var col := Color(f * (1.5 if u.vuln > 0 else 1.0), f * (1.25 if u.fear > 0 else 0.75 if u.vuln > 0 else 1.0), f * (0.7 if u.fear > 0 or u.vuln > 0 else 1.0))
		if u.stun > 0 and fx and randf() < delta * 5: fx.puff(u.x, 2, u.z, 1, fx.C_SPARK, 0.7)
		if enraged: col = Color(col.r * 1.3, col.g * 0.78, col.b * 0.78)      # a night of the bells: they see red, and look it
		if u.smoke > 0:                                             # in a censer's smoke: gone grey, and sluggish
			col = Color(col.r * 0.62, col.g * 0.7, col.b * 1.05)
		if u.burn > 0:                                              # alight: glowing, with flames coming off
			col = Color(col.r * 1.6, col.g * 0.95, col.b * 0.5)
			if fx and randf() < delta * 14: fx.puff(u.x + randf_range(-0.3, 0.3), randf_range(0.8, 1.8), u.z + randf_range(-0.3, 0.3), 1, fx.C_FIRE, 1.4)
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
		elif k == D.U_BLOAT:                                       # waddling, and wobbling as it goes
			var wob := sin(walk * 1.4) * 0.05 * mv
			xf = _xf(v[0], y, v[1], v[2], dz * 0.6 + sin(atk * PI) * 0.25, sin(walk * 0.7) * 0.14, Vector3(s * (1 + wob), s * (1 - wob), s * (1 + wob)))
		elif k == D.U_HOUND or k == D.U_WOLF:                     # loping, low to the ground (or, for the Gamekeeper, as low as he can manage)
			xf = _xf(v[0], y + absf(sin(walk * 1.6)) * 0.12 * mv, v[1], v[2], sin(walk * 1.6) * 0.08 * mv + sin(atk * PI) * 0.35, 0.0, Vector3(s, s, s))
		elif k == 0 or k == D.U_DIGGER:
			xf = _xf(v[0], y, v[1], v[2], 0.08 + dz + sin(atk * PI) * 0.5, sin(walk * 0.8) * 0.11, Vector3(s, s, s))
		elif k == 3 or k == D.U_CAPTAIN or k == D.U_LORD or k == D.U_CHAPLAIN:
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
		if k == D.U_LORD:                                          # the Lord moves properly: a figure of his own
			_lord_show(u, xf, col, delta, now, mv, did_atk)
			continue
		if k == D.U_SHADOW: col.a = 0.6 + sin(now * 3.0 + u.id) * 0.15
		_body[k].set_instance_transform(n[k], xf)
		_body[k].set_instance_color(n[k], col)
		_eyes[k].set_instance_transform(n[k], xf)
		_eyes[k].set_instance_color(n[k], Color(1, 1, 1) if u.state != "pile" else Color(0, 0, 0, 0))
		n[k] += 1
	if _lord and not seen.has(_lord_id): _lord.visible = false
	for k in KINDS.size():
		_body[k].visible_instance_count = n[k]
		_eyes[k].visible_instance_count = n[k]
	for id in _v.keys():
		if not seen.has(id): _v.erase(id)


## 0 for the dead that fight hand to hand (they get a slash drawn when they strike); 1 for the rest.
static func k0(k: int) -> int:
	return 1 if k == 2 or k == 3 or k == D.U_BATS or k == D.U_RAM or k == D.U_COACH or k == D.U_CAPTAIN or k == D.U_LORD or k == D.U_WRAITH else 0


static func _xf(x: float, y: float, z: float, ry: float, rx: float, rz: float, sc: Vector3) -> Transform3D:
	return Transform3D(Basis.from_euler(Vector3(rx, ry, rz)).scaled_local(sc), Vector3(x, y, z))
