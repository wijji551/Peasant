extends Node3D
## A peasant on screen: a player, one of a posse, a villager or a body. It only shows what the rules say:
## where they are, what they hold and wear, what they are working at, and when they swung or were hit.

const HOLYT := Color(1.3, 1.2, 0.75)
const CORPSE := Color(0.6, 0.56, 0.5)

var is_player := false
var dark := 0.0                     # how dark it is where this figure stands (0 day, 1 night): a torch shows more in the dark
var _torch: OmniLight3D
var fx: Node3D

var _x := 0.0
var _z := 0.0
var _r := 0.0
var _first := true
var _walk := 0.0
var _mv := 0.0
var _atk := 0.0
var _flash := 0.0
var _fall := 0.0
var _seen := [-1, -1, -1]            # ac, hc, cc last time
var _model: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _hand: Node3D
var _held_mi: MeshInstance3D
var _held := ""
var _tunic_mat: StandardMaterial3D
var _body_mat: StandardMaterial3D
var _held_mat: StandardMaterial3D
var _banner_mat: StandardMaterial3D
var _gear: Node3D
var _gear_sig := ""
var _carry: Node3D
var _carry_sig := ""
var _bar: Node3D
var _bar_fill: MeshInstance3D
var _bar_mat: StandardMaterial3D
var _tool := ""


func _ready() -> void:
	_model = Node3D.new()
	add_child(_model)
	_body_mat = _mat(Color.WHITE)
	_tunic_mat = _mat(Color.WHITE)
	_held_mat = _mat(Color.WHITE)
	_leg_l = Node3D.new(); _leg_l.position = Vector3(-0.14, 0.46, 0); _model.add_child(_leg_l)
	_leg_r = Node3D.new(); _leg_r.position = Vector3(0.14, 0.46, 0); _model.add_child(_leg_r)
	_mi(_leg_l, "leg", _body_mat)
	_mi(_leg_r, "leg", _body_mat)
	_mi(_model, "torso", _body_mat)
	_mi(_model, "tunic", _tunic_mat)
	if is_player:
		_banner_mat = _mat(Color.WHITE)
		_mi(_model, "banner", _banner_mat)
	_hand = Node3D.new()
	_hand.position = Vector3(0.42, 0.6, 0.14)
	_model.add_child(_hand)
	_held_mi = MeshInstance3D.new()
	_held_mi.material_override = _held_mat
	_hand.add_child(_held_mi)
	_gear = Node3D.new(); _model.add_child(_gear)
	_carry = Node3D.new(); add_child(_carry)
	_bar = Node3D.new(); add_child(_bar); _bar.visible = false; _bar.top_level = true
	var bg := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(1, 0.26); bg.mesh = q
	bg.material_override = _bar_material(Color(0.14, 0.1, 0.1)); _bar.add_child(bg)
	_bar_fill = MeshInstance3D.new(); var q2 := QuadMesh.new(); q2.size = Vector2(1, 0.14); _bar_fill.mesh = q2
	_bar_mat = _bar_material(Color(0.56, 0.78, 0.36)); _bar_fill.material_override = _bar_mat; _bar.add_child(_bar_fill)
	_bar_fill.position.z = 0.01


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_color = c
	m.roughness = 1.0
	m.metallic_specular = 0.15
	return m


static func _bar_material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.no_depth_test = true
	m.render_priority = 2
	m.albedo_color = c
	return m


func _mi(parent: Node3D, mesh: String, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = Models.get_mesh(mesh)
	mi.material_override = m
	parent.add_child(mi)
	return mi


var _owner_seen := -1


func _counts(ac: int, hc: int, cc: int) -> Array:   # [swung, was hit, worked] since last time
	var out := [ac != _seen[0] and _seen[0] >= 0, hc != _seen[1] and _seen[1] >= 0, cc != _seen[2] and _seen[2] >= 0]
	_seen = [ac, hc, cc]
	return out


func _place(x: float, z: float, r: float, snap: bool) -> void:
	if _first or snap or Vector2(x - _x, z - _z).length() > 6:
		_x = x; _z = z; _r = r; _first = false
	_x = x; _z = z; _r = r


## Show a player, as the rules have them now.
func player(p: E.Player, is_me: bool) -> void:
	visible = p.state != "hide"                                                # (drinking at the bar of the Rose, you can be seen: it is a room now)
	_place(p.x, p.z, p.r, false)
	var kind: String = D.GK[p.gk] if p.gk < D.GK.size() else ""
	var c := _counts(p.ac, p.hc, p.cc)
	if c[2] and p.state != "inn": _work_fx(kind if kind != "" else "tree")
	if c[2] and p.state == "inn" and is_me: Sound.play("gulp")
	if c[0]:
		_atk = 1.0
		Sound.play("swing", 0.7, Vector2(p.x, p.z))
	if c[2]: _atk = 1.0
	if c[1] and p.state != "dead":
		Sound.play("hurt" if is_me else "hit", 0.8, Vector2(p.x, p.z))
		_flash = 1.0
		if fx: fx.puff(p.x, 1, p.z, 3, fx.C_BLOOD, 2)
	var tint := Color(D.PCOL[p.col % 8])
	_down = p.state == "down" or p.state == "dead"
	_dim = 0.6 if p.state == "dead" else 1.0
	_tunic_mat.albedo_color = tint
	_banner_mat.albedo_color = tint
	_wobble = p.hang > 0
	_set_work(kind)
	_set_held(p.wpn, (p.bless & 1) != 0 or p.hb > 0)
	var lit: bool = p.wpn == D.I_TORCH and visible and p.state != "dead"       # a burning torch lights the way
	if lit and _torch == null:
		_torch = OmniLight3D.new()
		_torch.light_color = Color(1.0, 0.72, 0.36)
		_torch.omni_range = 13.0
		_torch.position = Vector3(0.3, 1.9, 0.3)
		add_child(_torch)
	if _torch:
		_torch.visible = lit
		_torch.light_energy = (4.2 if p.room == "mine" else 0.5 + 2.1 * dark) * (0.9 + 0.1 * sin(Time.get_ticks_msec() / 70.0 + p.id))
		if lit and fx and randf() < get_process_delta_time() * 9: fx.puff(p.x + sin(p.r) * 0.5, 2.3, p.z + cos(p.r) * 0.5, 1, fx.C_FIRE, 0.8)
	_set_gear([p.head, p.body, p.off, p.trk])
	_set_carry(p.bodies, p.bbod)
	if fx:
		var dt := get_process_delta_time()
		if p.charge > 0 and randf() < dt * 30: fx.puff(p.x, 0.3, p.z, 1, fx.C_ALE, 1.5)
		if ((p.bless & 1) or D.IT[p.wpn].holy) and p.state == "ok" and randf() < dt * 3: fx.puff(p.x + sin(p.r) * 0.6, 1.9, p.z + cos(p.r) * 0.6, 1, fx.C_HOLY, 0.4)
		if p.prot > 0 and randf() < dt * 10: fx.puff(p.x + randf_range(-0.5, 0.5), 0.4, p.z + randf_range(-0.5, 0.5), 1, fx.C_GLAD, 0.6)   # prayed over
		if Rules.class_of(p) >= 0 and p.state == "ok" and randf() < dt * 1.5: fx.puff(p.x, 2.1, p.z, 1, fx.C_HOLY, 0.2)   # an apprentice priest, faintly glowing
		if p.parry > 0 and randf() < dt * 14: fx.puff(p.x + sin(p.r) * 0.7, 1.2, p.z + cos(p.r) * 0.7, 1, fx.C_SPARK, 0.8)
	var mx := Rules.max_hp(p)
	if p.state == "down":
		_show_bar(1.4, 1.3, p.downT / (30.0 if Rules.rk(p, 9) >= 5 else 15.0), Color(0.86, 0.36, 0.26))
	elif p.hp < mx and p.state == "ok" and not is_me:
		_show_bar(2.5, 1.1, p.hp / mx, Color(0.56, 0.78, 0.36))
	else:
		_bar.visible = false
	_model.scale = Vector3.ONE * 1.2


## Show a villager, one of a posse, or a body. own is their leader, or null.
func peasant(q: E.Peasant, own: E.Player) -> void:
	visible = q.state != "gone" and q.state != "inn"
	_place(q.x, q.z, q.r, false)
	var kind := ""
	if q.state == "chop" and own:
		kind = D.GK[own.gk] if own.gk > 0 else own.workK
		if kind == "fish" or kind == "search": kind = ""
	var c := _counts(q.ac, q.hc, -1)
	if c[0]:
		_atk = 1.0
		if q.state == "chop": _work_fx(kind if kind != "" else "tree")
		else: Sound.play("swing", 0.35, Vector2(q.x, q.z))
	var oid: int = q.owner
	if oid != _owner_seen:
		if _owner_seen == 0 and oid != 0 and own: Sound.play("rally", 0.8, Vector2(q.x, q.z))   # rallied to a posse
		_owner_seen = oid
	if c[1]:
		Sound.play("hit", 0.5, Vector2(q.x, q.z))
		_flash = 1.0
		if fx and q.state != "body": fx.puff(q.x, 1, q.z, 3, fx.C_BLOOD, 2)
	_down = q.state == "body"
	_dim = 0.6 if _down else 1.0
	_tunic_mat.albedo_color = CORPSE if _down else Color(0.22, 0.4, 0.28) if q.kind == 1 else Color(D.PCOL[own.col % 8]) if own else Color(0.72, 0.62, 0.46)
	_wobble = false
	_set_work(kind)
	_set_held(2 if q.kind == 1 else 3 if q.kind == 2 else 2 if q.armed else 0, false)   # a guard's spear, a mercenary's mace
	_set_gear([19, 22] if q.kind == 1 else [22, 25] if q.kind == 2 else [])
	if fx and q.prot > 0 and randf() < get_process_delta_time() * 8: fx.puff(q.x + randf_range(-0.4, 0.4), 0.4, q.z + randf_range(-0.4, 0.4), 1, fx.C_GLAD, 0.5)
	if q.hp < Rules.q_max(q) and not _down:
		_show_bar(2.1, 0.9, q.hp / Rules.q_max(q), Color(0.56, 0.78, 0.36))
	else:
		_bar.visible = false
	if fx and q.nv < 45 and not _down and q.state != "hide" and randf() < get_process_delta_time() * 5:
		fx.puff(q.x, 2, q.z, 1, fx.C_SPLASH, 0.8)            # sweating
	_model.scale = Vector3.ONE


var _down := false
var _bar_y := 2.0
var _dim := 1.0
var _wobble := false


func _show_bar(y: float, w: float, frac: float, col: Color) -> void:
	_bar.visible = true
	_bar_y = y
	var f := clampf(frac, 0, 1)
	_bar.get_child(0).scale = Vector3(w + 0.12, 1, 1)
	_bar_fill.scale = Vector3(maxf(0.02, w * f), 1, 1)
	_bar_fill.position.x = -(w - w * f) / 2.0
	_bar_mat.albedo_color = col


func _set_work(kind: String) -> void:
	_tool = kind


func _set_held(id: int, holy: bool) -> void:
	var pool: String = D.IT[id].pool
	if _tool == "fish": pool = "rod"
	elif _tool != "" and _tool != "food" and _tool != "search": pool = "axe"
	if pool != _held:
		_held = pool
		_held_mi.mesh = Models.get_mesh(pool)
	var t: Array = D.IT[id].tint
	_held_mat.albedo_color = HOLYT if holy else Color(t[0], t[1], t[2]) if pool != "axe" and pool != "rod" else Color.WHITE
	_held_swing = (D.IT[id].swing or pool == "sling") and pool != "axe"
	if pool == "axe": _held_swing = true
	_held_pool = pool


var _held_swing := false
var _held_pool := ""


func _set_gear(ids: Array) -> void:
	var sig := str(ids)
	if sig == _gear_sig: return
	_gear_sig = sig
	for c in _gear.get_children(): c.queue_free()
	for id in ids:
		if id < 0: continue
		var t: Array = D.IT[id].tint
		var mi := _mi(_gear, Models.gear_pool(id), _mat(Color(t[0], t[1], t[2])))
		mi.set_meta("slot", D.IT[id].s)


func _set_carry(n: int, blessed: int) -> void:   # bodies carried on the back, the blessed ones paler
	var sig := "%d|%d" % [n, blessed]
	if sig == _carry_sig: return
	_carry_sig = sig
	for c in _carry.get_children(): c.queue_free()
	for i in n:
		var b := Node3D.new()
		_carry.add_child(b)
		b.position = Vector3(0, 1.75 + i * 0.36, -0.25)
		b.rotation = Vector3(-1.45, PI / 2, 0)
		b.scale = Vector3.ONE * 0.9
		_mi(b, "body", _mat(Color(0.6, 0.6, 0.6)))
		_mi(b, "tunic", _mat(Color(1.1, 1.05, 0.75) if i < blessed else CORPSE))


func _work_fx(kind: String) -> void:   # a blow landed on a tree, a rock, the ore, or the turnips
	if fx == null or kind == "fish": return
	var x := _x + sin(_r) * 0.9
	var z := _z + cos(_r) * 0.9
	Sound.play({"tree": "chop", "search": "pick", "stone": "stone", "iron": "iron", "steel": "iron"}.get(kind, "pluck"), 0.7 if is_player else 0.4, Vector2(_x, _z))
	match kind:
		"tree": fx.puff(_x + sin(_r) * 1.2, 1, _z + cos(_r) * 1.2, 4, fx.C_WOOD, 2.5); get_parent().shake_tree_near(_x, _z)
		"search": fx.puff(x, 0.4, z, 4, fx.C_DUST, 2.2)
		"stone": fx.puff(x, 0.6, z, 3, fx.C_STONE, 2)
		"iron", "steel": fx.puff(x, 0.6, z, 3, fx.C_IRON, 2)
		_: fx.puff(x, 0.6, z, 3, fx.C_FOOD, 2)


func _process(delta: float) -> void:
	var before := position
	var want := Vector3(_x, 0, _z)
	position = want if before.distance_to(want) > 6 else before.lerp(want, minf(1.0, delta * 14.0))
	var sp := (position - before).length() / maxf(delta, 1e-4)
	_mv = lerpf(_mv, minf(1.0, sp / 2.2), minf(1.0, delta * 9.0))
	if _mv > 0.06: _walk += delta * (5.0 + sp * 1.5)
	_atk = maxf(0.0, _atk - delta * 4.2)
	_flash = maxf(0.0, _flash - delta * 7.0)
	_fall = lerpf(_fall, 1.0 if _down else 0.0, minf(1.0, delta * 9.0))
	var now := Time.get_ticks_msec() / 1000.0
	var stoop := 0.5 + sin(now / 0.18 + get_instance_id()) * 0.12 if _tool == "food" or _tool == "search" else 0.0
	var wob := sin(now / 0.17) * 0.22 if _wobble else 0.0
	var swing_ := sin(_walk) * 0.7 * _mv
	_leg_l.rotation.x = swing_
	_leg_r.rotation.x = -swing_
	rotation.y = lerp_angle(rotation.y, _r, minf(1.0, delta * 16.0))
	_model.rotation = Vector3(-1.45 * _fall + stoop, 0, sin(_walk) * 0.07 * _mv + wob)
	_model.position.y = absf(sin(_walk)) * 0.14 * _mv + _fall * 0.2
	var f := (1.0 + _flash * 1.2) * _dim
	_body_mat.albedo_color = Color(f, f, f)
	_hand.visible = not _down and stoop == 0.0
	for g in _gear.get_children():                       # a body on the ground keeps its hat and its coat
		var s: String = g.get_meta("slot")
		g.visible = not _down or s == "h" or s == "b"
	# the hand: a jab, a swing, a bow held out, or a rod held still
	var s2 := sin(_atk * PI)
	if _held_pool == "rod":
		_hand.position = Vector3(0.42, 0.7, 0.2); _hand.rotation = Vector3(1.15 + sin(now / 0.5) * 0.04, 0, 0)
	elif _held_pool == "axe":
		_hand.position = Vector3(0.42, 0.62, 0.16); _hand.rotation = Vector3(-1.0 + (1.0 - _atk) * 2.4 if _atk > 0 else 0.3, 0, 0)
	elif _held_pool == "bow":
		_hand.position = Vector3(0.36, 0.72, 0.42 - s2 * 0.12); _hand.rotation = Vector3(0.12, 0, 0)
	elif _held_pool == "xbow":
		_hand.position = Vector3(0.3, 0.62, 0.2 - s2 * 0.14); _hand.rotation = Vector3(-s2 * 0.2, 0, 0)
	else:
		_hand.position = Vector3(0.42, 0.6, 0.14 + s2 * (0.25 if _held_swing else 0.55))
		_hand.rotation = Vector3(0.12 + s2 * (1.7 if _held_swing else 1.4), -s2 * 0.9 if _held_swing else 0.0, 0)
	_carry.visible = not _down
	_bar.global_position = global_position + Vector3(0, _bar_y, 0)
