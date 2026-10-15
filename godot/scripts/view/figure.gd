extends Node3D
## A peasant on screen: a player, one of a posse, a villager or a body. It only shows what the rules say:
## where they are, what they hold and wear, what they are working at, and when they swung or were hit.

const HOLYT := Color(1.3, 1.2, 0.75)
const CORPSE := Color(0.6, 0.56, 0.5)

var is_player := false
static var wind := 1.0                   # how hard the wind blows (main.gd, from the weather)
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
var _flag_mat: ShaderMaterial

static var _flag_sh: Shader
## A flag in the wind: each point moves out of the flat by more the further it is from the pole, in a ripple that runs
## along it; and a little up and down. gust: how hard the wind is (more when its bearer runs).
static func _flag_shader() -> Shader:
	if _flag_sh == null:
		_flag_sh = Shader.new()
		_flag_sh.code = """shader_type spatial;
render_mode cull_disabled;
uniform vec3 col : source_color = vec3(1.0);
uniform float phase = 0.0;
uniform float gust = 1.0;
void vertex() {
	float d = max(VERTEX.x + 0.27, 0.0);
	float t = TIME * 5.6 + phase;      // (version 7.21: one steady speed. Speeding it up with the wind jolted the whole wave about whenever you stopped)
	VERTEX.z += sin(t - VERTEX.x * 6.0) * 0.11 * d * gust;
	VERTEX.y += sin(t * 0.7 - VERTEX.x * 4.0) * 0.035 * d * gust - 0.05 * d * d;
	VERTEX.x -= 0.04 * d * d * (1.0 - 0.3 * gust);
}
void fragment() {
	ALBEDO = col * COLOR.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.15;
}
"""
	return _flag_sh
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
	_mi(_model, "torso" if is_player else "torso_bare", _body_mat)    # (version 7.24: villagers get their own hats and hair)
	_mi(_model, "tunic" if is_player else "tunic_bare", _tunic_mat)
	if is_player:
		_banner_mat = _mat(Color.WHITE)
		_mi(_model, "banner", _banner_mat)
		_flag_mat = ShaderMaterial.new()                 # the flag ripples in the wind, and harder when you run (version 7.19)
		_flag_mat.shader = _flag_shader()
		_flag_mat.set_shader_parameter("phase", randf() * TAU)
		_mi(_model, "banner_flag", _flag_mat)
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
	visible = p.state != "hide" and p.state != "swim"                          # (drinking at the bar of the Rose, you can be seen: it is a room now; a swimmer is under the water)
	var dt_ := get_process_delta_time()
	if fx and p.state == "swim" and randf() < dt_ * 5.0: fx.puff(p.x + randf_range(-0.5, 0.5), 0.1, p.z + randf_range(-0.5, 0.5), 2, fx.C_SPLASH, 1.1)   # in the river: a splash or two (version 7.24)
	if fx and p.state == "ok" and not p.ride and _mv > 0.7 and randf() < dt_ * 7.0: fx.puff(p.x - sin(p.r) * 0.3, 0.08, p.z - cos(p.r) * 0.3, 1, fx.C_DUST, 0.5)   # dust at your heels, running
	_place(p.x, p.z, p.r, false)
	_censer(p.trk == 27 and p.state == "ok" and p.room == "")
	_frozen = p.frozen > 0                                          # frozen with fright: rooted, and trembling
	_hop = sin(PI * (1.0 - p.jumpT / D.JUMP.t)) * 0.75 if p.jumpT > 0 else 0.0   # in the air      # the Smoking Censer: smoke, out as far as it works
	var kind: String = D.GK[p.gk] if p.gk < D.GK.size() else ""
	var c := _counts(p.ac, p.hc, p.cc)
	if c[2] and p.state != "inn": _work_fx(kind if kind != "" else "tree")
	if c[2] and p.state == "inn" and is_me: Sound.play("gulp")
	if c[0]:
		_atk = 1.0
		var I: Dictionary = D.IT[p.wpn]
		Sound.play("whoosh" if I.heavy and not I.rng else "swing", 0.7, Vector2(p.x, p.z))
		if fx and not I.rng and kind == "" and p.state == "ok":            # the sweep of the blade, or the dart of the fork
			var col: Color = Color(1.0, 0.62, 0.2) if I.fire else Color(0.72, 0.6, 1.0) if I.runed else Color(1.0, 0.88, 0.45) if I.holy or (p.bless & 1) or p.hb > 0 else Color(1.0, 0.8, 0.4) if p.charge > 0 else fx.WHITE
			fx.slash(p.x, p.z, p.r, I.reach * (1.12 if I.heavy else 1.0), clampf(acos(clampf(I.arc, -1.0, 1.0)), 0.5, 2.6) if I.swing else 0.17, col, true)
	if c[2]: _atk = 1.0
	if c[1] and p.state != "dead":
		Sound.play("hurt" if is_me else "hit", 0.8, Vector2(p.x, p.z))
		_flash = 1.0
		if fx: fx.puff(p.x, 1, p.z, 3, fx.C_BLOOD, 2)
	var tint := Color(D.PCOL[p.col % 8])
	_down = p.state == "down" or p.state == "dead"
	_dim = 0.6 if p.state == "dead" else 1.0
	_tunic_mat.albedo_color = tint
	_banner_mat.albedo_color = Color(0.36, 0.26, 0.18)
	_flag_mat.set_shader_parameter("col", tint)
	_flag_mat.set_shader_parameter("gust", (1.0 + 1.4 * _mv) * (0.5 + 0.5 * wind))   # (version 7.28: and the weather's wind)
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
	_set_gear([p.head, p.body, p.off, p.trk, p.feet])
	var jest: bool = Rules.class_of(p) == 1 and p.head < 0          # a jester wears the cap and bells, unless there is a helm in the way
	if jest and _jhat == null:
		_jhat = _mi(_model, "jhat", _mat(Color.WHITE))
	if _jhat: _jhat.visible = jest
	_set_carry(p.bodies, p.bbod)
	if fx:
		var dt := get_process_delta_time()
		if p.charge > 0 and randf() < dt * 30: fx.puff(p.x, 0.3, p.z, 1, fx.C_ALE, 1.5)
		if ((p.bless & 1) or D.IT[p.wpn].holy) and p.state == "ok" and randf() < dt * 3: fx.puff(p.x + sin(p.r) * 0.6, 1.9, p.z + cos(p.r) * 0.6, 1, fx.C_HOLY, 0.4)
		if p.prot > 0 and randf() < dt * 10: fx.puff(p.x + randf_range(-0.5, 0.5), 0.4, p.z + randf_range(-0.5, 0.5), 1, fx.C_GLAD, 0.6)   # prayed over
		if Rules.class_of(p) == 0 and p.state == "ok" and randf() < dt * 1.5: fx.puff(p.x, 2.1, p.z, 1, fx.C_HOLY, 0.2)   # an apprentice priest, faintly glowing
		if p.parry > 0 and randf() < dt * 14: fx.puff(p.x + sin(p.r) * 0.7, 1.2, p.z + cos(p.r) * 0.7, 1, fx.C_SPARK, 0.8)
		if p.tired > 0 and randf() < dt * 6: fx.puff(p.x + randf_range(-0.3, 0.3), 1.6, p.z + randf_range(-0.3, 0.3), 1, fx.C_SPLASH, 0.4)   # dripping
		if p.potI > 0 and randf() < dt * 24: fx.puff(p.x + randf_range(-0.6, 0.6), randf_range(0.3, 2.0), p.z + randf_range(-0.6, 0.6), 1, fx.C_FIRE, 1.6)   # the Last Warning
		if (p.potA > 0 or p.potS > 0 or p.potD > 0) and randf() < dt * 2: fx.puff(p.x, 2.2, p.z, 1, fx.C_GLAD, 0.3)
		if p.wpn == D.I_TITHE and p.state == "ok" and randf() < dt * 8: fx.puff(p.x + sin(p.r + 0.6) * 0.6, 1.8, p.z + cos(p.r + 0.6) * 0.6, 1, fx.C_FIRE, 0.7)   # the flail smoulders
	var mx := Rules.max_hp(p)
	if p.state == "down":
		_show_bar(1.4, 1.3, p.downT / (30.0 if Rules.rk(p, 9) >= 5 else 15.0), Color(0.86, 0.36, 0.26))
	elif p.hp < mx and p.state == "ok" and not is_me:
		_show_bar(2.5, 1.1, p.hp / mx, Color(0.56, 0.78, 0.36))
	else:
		_bar.visible = false
	_model.scale = Vector3.ONE * 1.2
	_lift = 0.6 if p.ride else 0.0                  # on a sheep: up on its back, and the sheep under
	_riding = p.ride
	if p.ride and _mount == null: _mount = _sheep_node(self, (p.slot * 5 + p.id) % D.SHEEP_NAMES.size())
	if _mount:
		_mount.visible = p.ride
		_mount.position = Vector3(0, -0.6, -0.05)
		_sheep_walk(_mount)
	_leg_l.rotation.z = -0.5 if p.ride else 0.0
	_leg_r.rotation.z = 0.5 if p.ride else 0.0


## Show a villager, one of a posse, or a body. own is their leader, or null.
func peasant(q: E.Peasant, own: E.Player) -> void:
	if q.kind == 3:                                   # a dog
		_dog_show(q, own)
		return
	if q.kind == 4:                                   # a sheep (when it is being ridden, the rider shows it)
		visible = q.state != "ride"
		_model.visible = false
		_bar.visible = false
		if _sheep == null: _sheep = _sheep_node(self, q.ni)
		_place(q.x, q.z, q.r, false)
		_sheep.rotation.y = 0.0
		_sheep_walk(_sheep)
		return
	visible = q.state != "gone" and q.state != "inn"
	_place(q.x, q.z, q.r, false)
	var kind := ""
	if q.state == "chop" and own:
		kind = D.GK[own.gk] if own.gk > 0 else own.workK
		if kind == "fish" or kind == "search": kind = ""
	_lift = 0.0
	if q.state == "post" and q.plat != 0:                          # up on a watch platform, or higher up in a watch tower
		_lift = 1.76
		for t in D.TOWER_SITES:
			if absf(q.x - t[0]) < 1.4 and absf(q.z - t[1]) < 1.4: _lift = 2.9
	var c := _counts(q.ac, q.hc, -1)
	if c[0]:
		_atk = 1.0
		if q.state == "post" and q.plat != 0: Sound.play("swing", 0.3, Vector2(q.x, q.z))
		elif q.state == "chop": _work_fx(kind if kind != "" else "tree")
		else:
			Sound.play("swing", 0.35, Vector2(q.x, q.z))
			if fx and q.state != "body":
				if q.kind == 1 or (q.kind == 0 and q.armed): fx.slash(q.x, q.z, q.r, 2.1, 0.17, Color(1.0, 0.97, 0.88, 0.7))   # a spear, or a pitchfork
				else: fx.slash(q.x, q.z, q.r, 1.6, 0.8, Color(1.0, 0.97, 0.88, 0.7))
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
	if _hat == null:                                  # who they are: a hat or hair of their own, a skin and a shade of tunic, from their name
		_hat = _mi(_model, HATS[(q.ni * 7 + 3) % HATS.size()], _mat(Color.WHITE))
		_skin = SKINS[(q.ni * 5 + 1) % SKINS.size()]
		_shade = 0.86 + 0.07 * ((q.ni * 3) % 5)
	_tunic_mat.albedo_color = CORPSE if _down else Color(0.22, 0.4, 0.28) if q.kind == 1 else (Color(D.PCOL[own.col % 8]) * _shade).lerp(Color(0.5, 0.45, 0.38), 0.45 if q.stray else 0.0) if own else Color(0.55, 0.5, 0.42) if q.stray else TUNICS[(q.ni * 11) % TUNICS.size()]
	_wobble = false
	_set_work(kind)
	var kg := Rules.kit_gear(q.kit, q.ni) if q.kind == 0 and q.kit > 0 else [-1, -1, -1]
	_set_held(kg[0] if kg[0] >= 0 else 2 if q.kind == 1 else 3 if q.kind == 2 else 2 if q.armed else 0, false)   # a kit's weapon, a guard's spear, a mercenary's mace
	_set_gear([kg[1], kg[2]] if kg[0] >= 0 else [19, 22] if q.kind == 1 else [22, 25] if q.kind == 2 else [])
	_hat.visible = not (kg[0] >= 0 and kg[1] >= 0) and q.kind != 1      # a helmet goes on instead
	if fx and q.prot > 0 and randf() < get_process_delta_time() * 8: fx.puff(q.x + randf_range(-0.4, 0.4), 0.4, q.z + randf_range(-0.4, 0.4), 1, fx.C_GLAD, 0.5)
	if q.hp < Rules.q_max(q) and not _down:
		_show_bar(2.1, 0.9, q.hp / Rules.q_max(q), Color(0.56, 0.78, 0.36))
	else:
		_bar.visible = false
	if fx and q.nv < 45 and not _down and q.state != "hide" and randf() < get_process_delta_time() * 5:
		fx.puff(q.x, 2, q.z, 1, fx.C_SPLASH, 0.8)            # sweating
	_model.scale = Vector3(0.9, 0.93, 0.9) if q.stray else Vector3.ONE   # a stray is a bit of a scrap of a thing
	_stray_patch(q.stray and not _down)


var _down := false
var _xray_t := 0.0
func _xray(n: Node) -> void:                       # Godot's own X-ray: shown through whatever is in front, but not through itself
	for c in n.get_children():
		if c is MeshInstance3D:
			var mm = (c as MeshInstance3D).material_override
			if mm is StandardMaterial3D and (mm as StandardMaterial3D).stencil_mode == BaseMaterial3D.STENCIL_MODE_DISABLED and (mm as StandardMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
				(mm as StandardMaterial3D).stencil_mode = BaseMaterial3D.STENCIL_MODE_XRAY
				(mm as StandardMaterial3D).stencil_color = Color(1.0, 0.95, 0.8, 0.35)
		if c.get_child_count() > 0 and not (c is OmniLight3D): _xray(c)
var _hat: MeshInstance3D                 # a villager's own hat or hair (version 7.24)
var _skin := Color.WHITE
var _shade := 1.0
const HATS := ["hat_straw", "hat_cap", "hat_hood", "hat_scarf", "hair_bald", "hat_felt", "hair_mop", "hat_straw", "hair_ginger", "hat_cap"]
const SKINS := [Color(1, 1, 1), Color(0.93, 0.86, 0.8), Color(0.8, 0.68, 0.58), Color(0.62, 0.48, 0.38), Color(1.04, 0.97, 0.93), Color(0.88, 0.78, 0.7)]
const TUNICS := [Color(0.72, 0.62, 0.46), Color(0.58, 0.52, 0.4), Color(0.62, 0.66, 0.5), Color(0.66, 0.5, 0.42), Color(0.55, 0.58, 0.62), Color(0.76, 0.7, 0.56), Color(0.5, 0.46, 0.5)]
var _bar_y := 2.0
var _dim := 1.0
var _wobble := false


var _bar_f := 1.0
var _riding := false                 # astride a sheep: the legs sit still either side of it, and the sheep does the walking (version 7.20)
var _lift := 0.0                    # how far off the ground this figure stands (on a watch platform)


func _show_bar(y: float, w: float, frac: float, col: Color) -> void:
	_bar_y = y
	var f := clampf(frac, 0, 1)
	_bar_f = f if not _bar.visible or absf(f - _bar_f) > 0.5 else lerpf(_bar_f, f, 0.25)      # it slides to a new value: no flicker
	f = _bar_f
	_bar.visible = true
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
	# relics and rune weapons glow: the metal itself, a soft halo round it, and a little light on whatever is near
	var special: bool = (D.IT[id].tier == "relic" or D.IT[id].runed) and pool != "axe" and pool != "rod"
	if special != (_glow_col.a > 0.0) or (special and id != _glow_id):
		_glow_id = id
		_glow_col = glow_of(id) if special else Color(0, 0, 0, 0)
		_held_mat.emission_enabled = special
		_held_mat.emission = Color(_glow_col.r, _glow_col.g, _glow_col.b)
		if special and _halo == null:
			_halo = halo(_glow_col, 1.5)
			_halo.position = Vector3(0, 0.95, 0.1)
			_hand.add_child(_halo)
			_glow_light = OmniLight3D.new()
			_glow_light.omni_range = 4.5
			_glow_light.position = Vector3(0, 0.9, 0.2)
			_hand.add_child(_glow_light)
		if _halo:
			_halo.visible = special
			_glow_light.visible = special
			if special:
				(_halo.material_override as StandardMaterial3D).albedo_color = _glow_col
				_glow_light.light_color = Color(_glow_col.r, _glow_col.g, _glow_col.b)
	_held_swing = (D.IT[id].swing or pool == "sling") and pool != "axe"
	if pool == "axe": _held_swing = true
	_held_pool = pool


var _held_swing := false
var _glow_col := Color(0, 0, 0, 0)       # the glow of a relic or a rune weapon in the hand (clear: none)
var _glow_id := -1
var _frozen := false
var _hop := 0.0
var _smoke: Node3D          # the Smoking Censer's smoke, made the first time it is carried


## The Smoking Censer: a ring on the ground at the edge of what it reaches, and smoke rising everywhere inside it.
func _censer(on: bool) -> void:
	if on and _smoke == null:
		_smoke = Node3D.new()
		add_child(_smoke)
		var reach: float = D.CENSER.reach
		for rim in [false, true]:
			var ps := CPUParticles3D.new()
			ps.amount = 54 if rim else 38
			ps.lifetime = 3.4
			ps.preprocess = 2.0
			ps.local_coords = false
			ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
			ps.emission_ring_axis = Vector3.UP
			ps.emission_ring_radius = reach
			ps.emission_ring_inner_radius = reach - 0.6 if rim else 0.5
			ps.emission_ring_height = 0.2
			ps.direction = Vector3.UP
			ps.spread = 30.0
			ps.gravity = Vector3(0.12, 0.2, 0.0)
			ps.initial_velocity_min = 0.25
			ps.initial_velocity_max = 0.6
			ps.scale_amount_min = 0.7
			ps.scale_amount_max = 1.25
			var curve := Curve.new()
			curve.add_point(Vector2(0, 0.9)); curve.add_point(Vector2(1, 2.6))
			ps.scale_amount_curve = curve
			var grad := Gradient.new()
			grad.set_color(0, Color(0.82, 0.84, 0.95, 0.62))
			grad.set_color(1, Color(0.82, 0.84, 0.95, 0.0))
			ps.color_ramp = grad
			var sm := SphereMesh.new()
			sm.radius = 0.45; sm.height = 0.9; sm.radial_segments = 6; sm.rings = 3
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.vertex_color_use_as_albedo = true
			sm.material = mat
			ps.mesh = sm
			ps.position.y = 0.3
			ps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_smoke.add_child(ps)
		var edge := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = reach - 0.09; tm.outer_radius = reach + 0.09; tm.rings = 48; tm.ring_segments = 4
		edge.mesh = tm
		var em := StandardMaterial3D.new()
		em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		em.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		em.albedo_color = Color(0.86, 0.88, 1.0, 0.45)
		edge.material_override = em
		edge.scale = Vector3(1, 0.3, 1)
		edge.position.y = 0.07
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_smoke.add_child(edge)
	if _smoke and _smoke.visible != on:
		_smoke.visible = on
		for c in _smoke.get_children():
			if c is CPUParticles3D: c.emitting = on


var _halo: MeshInstance3D
var _glow_light: OmniLight3D


## The colour a relic or a rune weapon glows: gold for most relics, silver for the silvered ones, violet for runes.
static func glow_of(id: int) -> Color:
	var I: Dictionary = D.IT[id]
	if I.has("glow"): return Color(I.glow[0], I.glow[1], I.glow[2], 0.55)    # (version 7.23) the relic boots: green, blue and red, each its own
	if I.tier == "rune": return Color(0.4, 0.66, 1.0, 0.55)      # rune glows blue; mithril purple
	if I.runed: return Color(0.62, 0.42, 1.0, 0.55)
	var t: Array = I.tint
	if t[2] > t[0]: return Color(0.7, 0.85, 1.0, 0.5)             # the Silvered Sword, the Censer: a cold light
	return Color(1.0, 0.82, 0.35, 0.55)


static var _halo_tex: GradientTexture2D
## A soft disc of light that always faces the view: the halo round something that glows.
static func halo(col: Color, size: float) -> MeshInstance3D:
	if _halo_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.35))
		_halo_tex = GradientTexture2D.new()
		_halo_tex.gradient = g
		_halo_tex.fill = GradientTexture2D.FILL_RADIAL
		_halo_tex.fill_from = Vector2(0.5, 0.5)
		_halo_tex.fill_to = Vector2(1.0, 0.5)
		_halo_tex.width = 64; _halo_tex.height = 64
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.albedo_texture = _halo_tex
	m.albedo_color = col
	m.disable_fog = true
	m.disable_receive_shadows = true
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
var _held_pool := ""


func _set_gear(ids: Array) -> void:
	var sig := str(ids)
	if sig == _gear_sig: return
	_gear_sig = sig
	for c in _gear.get_children(): c.queue_free()
	for b in _boots: b.queue_free()
	_boots = []
	_blessed = []
	var glow_feet := Color(0, 0, 0, 0)
	for id in ids:
		if id < 0: continue
		var t: Array = D.IT[id].tint
		var gm := _mat(Color(t[0], t[1], t[2]))
		if D.IT[id].tier == "relic" or D.IT[id].runed:     # a worn relic glows, steadily; so does mithril and rune armour
			var gc := glow_of(id)
			gm.emission_enabled = true
			gm.emission = Color(gc.r, gc.g, gc.b)
			gm.emission_energy_multiplier = 0.45 if D.IT[id].has("glow") else 0.7    # (coloured boots: enough to glow, not so much it goes white)
		if D.IT[id].has("glow"):                           # and a little pool of their own light on the ground round your feet
			glow_feet = Color(D.IT[id].glow[0], D.IT[id].glow[1], D.IT[id].glow[2])
		if D.IT[id].blessed:                               # blessed for good: the rune blue, and a halo above (version 7.20)
			_blessed.append(gm)
		if D.IT[id].s == "f":                              # boots go on the feet, one on each leg, and walk with them (version 7.18)
			for leg in [_leg_l, _leg_r]:
				var bm := _mi(leg, "boot", gm)
				bm.position = Vector3(0, -0.46, 0.0)
				_boots.append(bm)
			continue
		var mi := _mi(_gear, Models.gear_pool(id), gm)
		mi.set_meta("slot", D.IT[id].s)
	if glow_feet.a > 0.0 and _feet_light == null:
		_feet_light = OmniLight3D.new(); _feet_light.omni_range = 1.8; _feet_light.light_energy = 1.1
		_feet_light.position = Vector3(0, 0.25, 0.1); _model.add_child(_feet_light)
	if _feet_light:
		_feet_light.visible = glow_feet.a > 0.0
		if glow_feet.a > 0.0: _feet_light.light_color = glow_feet
	if _blessed.size() and _holy_halo == null:             # and an angel's ring over the head, like the priest's, that breathes gold and white
		_holy_halo = MeshInstance3D.new()
		var tm := TorusMesh.new(); tm.inner_radius = 0.2; tm.outer_radius = 0.26; tm.rings = 20; tm.ring_segments = 6
		_holy_halo.mesh = tm
		_halo_mat = StandardMaterial3D.new()
		_halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_halo_mat.albedo_color = Color(1.0, 0.86, 0.45, 0.85)
		_holy_halo.material_override = _halo_mat
		_holy_halo.position = Vector3(0, 2.08, 0)
		_model.add_child(_holy_halo)
		_holy_light = OmniLight3D.new(); _holy_light.light_color = Color(1.0, 0.9, 0.6); _holy_light.omni_range = 3.2
		_holy_light.position = Vector3(0, 2.0, 0); _model.add_child(_holy_light)
	if _holy_halo:
		_holy_halo.visible = _blessed.size() > 0
		_holy_light.visible = _blessed.size() > 0


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


# ---------------------------------------------------------------- a dog (Dogs, and Other Bad Ideas)
var _dog: Node3D
var _dog_legs: Array = []
var _dog_tail: Node3D
var _dog_seen := [-1, -1]

var _sheep: Node3D                   # a sheep, trotting after its player
var _mount: Node3D                   # the sheep a player is riding
var _patch: Node3D                   # a stray's patches
var _jhat: MeshInstance3D            # a jester's cap and bells
var _boots: Array = []               # the boots, one on each leg
var _blessed: Array = []             # the materials of blessed armour worn, which glow and breathe
var _holy_halo: MeshInstance3D
var _holy_light: OmniLight3D
var _halo_mat: StandardMaterial3D
var _feet_light: OmniLight3D             # relic boots: a little of their colour on the ground (version 7.23)
var _collar: MeshInstance3D          # a dog's collar, and its material
var _collar_mat: StandardMaterial3D

## A sheep: fleece, a dark face and four dark legs (the legs are kept in its "legs" meta, to walk).
func _sheep_node(parent: Node3D, ni: int) -> Node3D:
	var n := Node3D.new(); parent.add_child(n)
	var wool := _mat(Color(0.95, 0.93, 0.86) if ni % 4 != 3 else Color(0.36, 0.32, 0.3))   # one in four is a black sheep
	var face := _mat(Color(0.18, 0.16, 0.15))
	_mi(n, "sheep", wool)
	_mi(n, "sheep_face", face)
	var legs := []
	for lp in [Vector3(-0.17, 0.36, 0.3), Vector3(0.17, 0.36, 0.3), Vector3(-0.17, 0.36, -0.3), Vector3(0.17, 0.36, -0.3)]:
		var l := Node3D.new(); l.position = lp; n.add_child(l)
		_mi(l, "sheep_leg", face)
		legs.append(l)
	n.set_meta("legs", legs)
	return n

func _sheep_walk(n: Node3D) -> void:
	var legs: Array = n.get_meta("legs")
	for i in legs.size():
		legs[i].rotation.x = sin(_walk + (PI if i % 3 == 0 else 0.0)) * 0.55 * _mv

func _stray_patch(on: bool) -> void:
	if on and _patch == null:
		_patch = Node3D.new(); _model.add_child(_patch)
		var m := _mat(Color(0.42, 0.33, 0.24))
		_mi(_patch, "patches", m)
	if _patch: _patch.visible = on

func _dog_show(q: E.Peasant, own: E.Player) -> void:
	visible = true
	_model.visible = false
	_bar.visible = false
	if _dog == null:
		_dog = Node3D.new(); add_child(_dog)
		var coat := _mat(Color(0.55, 0.38, 0.22) if q.ni % 3 == 0 else Color(0.82, 0.74, 0.6) if q.ni % 3 == 1 else Color(0.25, 0.22, 0.2))
		_mi(_dog, "dog", coat)
		for lp in [Vector3(-0.13, 0.32, 0.26), Vector3(0.13, 0.32, 0.26), Vector3(-0.13, 0.32, -0.26), Vector3(0.13, 0.32, -0.26)]:
			var l := Node3D.new(); l.position = lp; _dog.add_child(l)
			_mi(l, "dog_leg", coat)
			_dog_legs.append(l)
		_dog_tail = Node3D.new(); _dog_tail.position = Vector3(0, 0.55, -0.38); _dog.add_child(_dog_tail)
		_mi(_dog_tail, "dog_tail", coat)
	_place(q.x, q.z, q.r, false)
	_dog.rotation.y = 0.0                              # (the figure itself turns to face where the dog faces: version 7.18)
	if _collar == null:                                # a collar, red; gold and glowing on a dog led by Saint Wilbur's Dog Lead
		_collar_mat = _mat(Color(0.7, 0.16, 0.14))
		_collar = _mi(_dog, "dog_collar", _collar_mat)
	var led: bool = own != null and own.trk == D.I_LEAD
	_collar_mat.albedo_color = Color(1.3, 1.05, 0.45) if led else Color(0.7, 0.16, 0.14)
	_collar_mat.emission_enabled = led
	if led: _collar_mat.emission = Color(1.0, 0.8, 0.35); _collar_mat.emission_energy_multiplier = 0.9
	var down := q.state == "down"
	_dog.rotation.z = lerpf(_dog.rotation.z, 1.4 if down else 0.0, 0.2)
	for i in _dog_legs.size():
		_dog_legs[i].rotation.x = sin(_walk + (PI if i % 3 == 0 else 0.0)) * 0.6 * _mv
	_dog_tail.rotation.z = sin(Time.get_ticks_msec() / 90.0) * (0.6 if q.state != "down" else 0.0)
	if q.ac != _dog_seen[0]:
		if _dog_seen[0] >= 0:
			Sound.play("growl" if randf() < 0.5 else "swing", 0.5, Vector2(q.x, q.z))
			if fx: fx.puff(q.x + sin(q.r) * 0.7, 0.5, q.z + cos(q.r) * 0.7, 3, fx.C_DUST, 1.2)   # a snap of the jaws (version 7.24)
		_dog_seen[0] = q.ac
	if q.hc != _dog_seen[1]:
		if _dog_seen[1] >= 0: Sound.play("hit", 0.4, Vector2(q.x, q.z))
		_dog_seen[1] = q.hc


func _process(delta: float) -> void:
	var before := position
	var want := Vector3(_x, _lift + _hop, _z)
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
	var swing_ := 0.0 if _riding else sin(_walk) * 0.7 * _mv
	_leg_l.rotation.x = -0.55 + sin(_walk * 2.0) * 0.06 * _mv if _riding else swing_   # astride: legs forward round the fleece, jogging a little
	_leg_r.rotation.x = -0.55 + sin(_walk * 2.0 + 1.0) * 0.06 * _mv if _riding else -swing_
	rotation.y = lerp_angle(rotation.y, _r, minf(1.0, delta * 16.0))
	if _frozen: rotation.y += sin(now * 47.0) * 0.06
	_model.rotation = Vector3(-1.45 * _fall + stoop + (0.08 * _mv if _riding else 0.0), 0, (sin(_walk) * 0.03 if _riding else sin(_walk) * 0.07) * _mv + wob)
	_model.position.y = (absf(sin(_walk * 2.0)) * 0.06 if _riding else absf(sin(_walk)) * 0.14) * _mv + _fall * 0.2
	_model.position.z = sin(_atk * PI) * 0.22 if _tool == "" and not _down else 0.0     # into the blow, and back
	var f := (1.0 + _flash * 1.2) * _dim
	_body_mat.albedo_color = Color(f * _skin.r, f * _skin.g, f * _skin.b)
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
	elif _held_pool == "great":                          # (version 7.30) both hands, in front: up over the shoulder, and a great sweep across
		_hand.position = Vector3(0.22 - s2 * 0.3, 0.66, 0.3 + s2 * 0.3)
		_hand.rotation = Vector3(0.35 + s2 * 1.3, -s2 * 1.5, -0.25 + s2 * 0.4)
	else:
		_hand.position = Vector3(0.42, 0.6, 0.14 + s2 * (0.25 if _held_swing else 0.55))
		_hand.rotation = Vector3(0.12 + s2 * (1.7 if _held_swing else 1.4), -s2 * 0.9 if _held_swing else 0.0, 0)
	if _blessed.size():                                  # blessed armour: the halo slowly breathes between gold and white
		var hp_ := 0.5 + 0.5 * sin(now * 1.3 + get_instance_id() % 5)
		if _holy_halo:
			_halo_mat.albedo_color = Color(1.0, 0.84, 0.4, 0.8).lerp(Color(1.0, 0.98, 0.9, 0.95), hp_)
			_holy_halo.position.y = 2.08 + 0.03 * sin(now * 1.3)
			_holy_halo.visible = not _down
			_holy_light.light_energy = (0.15 + 0.45 * dark) * (0.6 + 0.4 * hp_)
		if fx and not _down and randf() < delta * 1.5:
			fx.puff(global_position.x + randf_range(-0.2, 0.2), 2.1, global_position.z + randf_range(-0.2, 0.2), 1, fx.C_HOLY, 0.3)
	if _glow_col.a > 0.0 and _halo:                      # the glow breathes
		var pulse := 0.75 + 0.25 * sin(now * 3.2 + get_instance_id() % 7)
		_held_mat.emission_energy_multiplier = 0.9 + 0.9 * pulse
		_halo.scale = Vector3.ONE * (0.85 + 0.25 * pulse)
		_halo.visible = _hand.visible
		_glow_light.visible = _hand.visible
		_glow_light.light_energy = (0.5 + 1.3 * dark) * pulse
		if fx and _hand.visible and randf() < delta * 5.0:
			var wp := _hand.global_position + Vector3(randf_range(-0.3, 0.3), randf_range(0.5, 1.4), randf_range(-0.3, 0.3))
			fx.puff(wp.x, wp.y, wp.z, 1, [Color(_glow_col.r, _glow_col.g, _glow_col.b)], 0.5)
	_carry.visible = not _down
	if _bar.visible:                                     # the bar turns to face the view as one piece, so its fill stays inside it
		var cam := get_viewport().get_camera_3d()
		_bar.global_transform = Transform3D(cam.global_basis.orthonormalized() if cam else Basis.IDENTITY, global_position + Vector3(0, _bar_y, 0))
