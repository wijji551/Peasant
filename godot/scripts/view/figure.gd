extends Node3D
## A peasant on screen: a player, one of a posse, or a villager. It only shows what the rules say:
## the game tells it where to stand, what it holds and wears, and when it swung or was hit.

const Build := preload("res://scripts/build.gd")

var tunic := Color("c8443a")
var is_player := false
var down := false                  # knocked down, dead, or a body on the ground
var moving := 0.0
var facing := 0.0
var carry := 0                     # bodies carried, drawn on the back

var _want := Vector3.ZERO
var _first := true
var _walk := 0.0
var _jab := 0.0
var _flash := 0.0
var _fall := 0.0
var _model: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _hand: Node3D                  # what is held hangs off this
var _held := -2
var _gear_sig := ""
var _gear: Node3D
var _tunic_mat: StandardMaterial3D
var _banner: Node3D


func _ready() -> void:
	_model = Node3D.new()
	var sc := 1.2 if is_player else 1.0
	_model.scale = Vector3(sc, sc, sc)
	add_child(_model)
	var legs := Color("4a3a2c")
	_leg_l = Node3D.new(); _leg_l.position = Vector3(-0.14, 0.46, 0); _model.add_child(_leg_l)
	Build.box(_leg_l, Vector3(0.2, 0.46, 0.22), Vector3(0, -0.46, 0), legs)
	_leg_r = Node3D.new(); _leg_r.position = Vector3(0.14, 0.46, 0); _model.add_child(_leg_r)
	Build.box(_leg_r, Vector3(0.2, 0.46, 0.22), Vector3(0, -0.46, 0), legs)
	_tunic_mat = StandardMaterial3D.new()
	_tunic_mat.albedo_color = tunic
	_tunic_mat.roughness = 1.0
	for part in [[Vector3(0.66, 0.6, 0.42), Vector3(0, 0.44, 0)], [Vector3(0.17, 0.5, 0.2), Vector3(-0.42, 0.52, 0)], [Vector3(0.17, 0.5, 0.2), Vector3(0.42, 0.52, 0)]]:
		Build.box(_model, part[0], part[1], tunic).material_override = _tunic_mat
	Build.box(_model, Vector3(0.67, 0.09, 0.43), Vector3(0, 0.5, 0), Color("9a8a78"))
	Build.box(_model, Vector3(0.42, 0.4, 0.4), Vector3(0, 1.03, 0.02), Color("e8b98f"))
	Build.box(_model, Vector3(0.1, 0.1, 0.06), Vector3(0, 1.15, 0.24), Color("d9a279"))
	Build.cyl(_model, 0.34, 0.34, 0.07, Vector3(0, 1.42, 0), Color("dcbc62"), 8)
	Build.cyl(_model, 0.17, 0.2, 0.2, Vector3(0, 1.49, 0), Color("dcbc62"), 8)
	_hand = Node3D.new()
	_hand.position = Vector3(0.42, 0.6, 0.14)
	_model.add_child(_hand)
	_gear = Node3D.new()
	_model.add_child(_gear)
	if is_player:                      # a tall banner in the player's colour, so you can tell who is who
		_banner = Node3D.new()
		_model.add_child(_banner)
		Build.box(_banner, Vector3(0.06, 2.7, 0.06), Vector3(-0.3, 0.55, -0.27), Color("5b4130"))
		Build.box(_banner, Vector3(1.0, 0.7, 0.06), Vector3(0.22, 2.55, -0.27), tunic)
		Build.box(_banner, Vector3(0.9, 0.1, 0.07), Vector3(0.22, 2.5, -0.27), tunic.lightened(0.4))
	hold(0)


## Where the rules say it is. The figure eases towards it, so a 30-a-second rule step still looks smooth.
func place(x: float, z: float, r: float, snap: bool = false) -> void:
	_want = Vector3(x, 0, z)
	if _first or snap or position.distance_to(_want) > 6.0:
		position = _want
		_first = false
	facing = r


func swing() -> void:
	_jab = 1.0

func hit() -> void:
	_flash = 1.0


## What it holds (an item number from D.IT, or -1 for nothing) and wears.
func hold(id: int) -> void:
	if id == _held:
		return
	_held = id
	for c in _hand.get_children(): c.queue_free()
	if id < 0:
		return
	var I: Dictionary = D.IT[id]
	var tint := Color(I.tint[0], I.tint[1], I.tint[2]) if I.tier == "relic" else Color.WHITE
	var wood := Color("8b6b47") * tint
	var iron := Color("70757f") * tint
	var h := _hand
	match I.pool:
		"fork":
			Build.box(h, Vector3(0.07, 1.75, 0.07), Vector3(0, -0.55, 0), wood)
			Build.box(h, Vector3(0.36, 0.06, 0.06), Vector3(0, 1.2, 0), iron)
			for x in [-0.15, 0.0, 0.15]: Build.box(h, Vector3(0.05, 0.32, 0.05), Vector3(x, 1.22, 0), iron)
		"sword":
			Build.box(h, Vector3(0.08, 0.3, 0.08), Vector3(0, -0.1, 0), Color("4a3a2c"))
			Build.box(h, Vector3(0.3, 0.06, 0.08), Vector3(0, 0.2, 0), iron)
			Build.box(h, Vector3(0.1, 0.95, 0.04), Vector3(0, 0.26, 0), Color("c9ccd4") * tint)
		"spear":
			Build.box(h, Vector3(0.07, 2.3, 0.07), Vector3(0, -0.7, 0), wood)
			Build.cone(h, 0.09, 0.4, Vector3(0, 1.6, 0), iron, 4)
		"mace":
			Build.box(h, Vector3(0.08, 0.95, 0.08), Vector3(0, -0.2, 0), wood)
			Build.box(h, Vector3(0.26, 0.26, 0.26), Vector3(0, 0.72, 0), iron)
		"bill":
			Build.box(h, Vector3(0.07, 2.1, 0.07), Vector3(0, -0.6, 0), wood)
			Build.box(h, Vector3(0.3, 0.42, 0.05), Vector3(0.1, 1.3, 0), iron)
		"hammer":
			Build.box(h, Vector3(0.08, 1.3, 0.08), Vector3(0, -0.35, 0), wood)
			Build.box(h, Vector3(0.5, 0.26, 0.26), Vector3(0, 0.92, 0), iron)
		"club":
			Build.cyl(h, 0.14, 0.06, 1.0, Vector3(0, -0.2, 0), Color("6b4a2f"), 6)
		"spade":
			Build.box(h, Vector3(0.07, 1.5, 0.07), Vector3(0, -0.5, 0), wood)
			Build.box(h, Vector3(0.3, 0.38, 0.04), Vector3(0, 0.95, 0), iron)
		"rake":
			Build.box(h, Vector3(0.06, 1.9, 0.06), Vector3(0, -0.6, 0), wood)
			Build.box(h, Vector3(0.5, 0.06, 0.06), Vector3(0, 1.3, 0), wood)
		"scythe":
			Build.box(h, Vector3(0.07, 1.9, 0.07), Vector3(0, -0.6, 0), wood)
			Build.box(h, Vector3(0.9, 0.1, 0.03), Vector3(0.4, 1.25, 0), iron, 0, 0, -0.25)
		"dagger":
			Build.box(h, Vector3(0.06, 0.45, 0.03), Vector3(0, 0.02, 0), Color("c9ccd4"))
		"pan":
			Build.box(h, Vector3(0.06, 0.5, 0.06), Vector3(0, -0.05, 0), Color("2e2a28"))
			Build.cyl(h, 0.24, 0.22, 0.08, Vector3(0, 0.55, 0), Color("2e2a28"), 10, 0, PI / 2)
		"sling":
			Build.box(h, Vector3(0.03, 0.55, 0.03), Vector3(0, -0.1, 0), Color("a08562"))
		"bow":
			Build.box(h, Vector3(0.06, 1.5, 0.06), Vector3(0, -0.25, 0.12), wood, 0, 0.12)
			Build.box(h, Vector3(0.02, 1.45, 0.02), Vector3(0, -0.22, 0), Color("e8e0c8"))
		"xbow":
			Build.box(h, Vector3(0.1, 0.1, 0.8), Vector3(0, 0.1, 0.2), wood)
			Build.box(h, Vector3(0.8, 0.07, 0.07), Vector3(0, 0.12, 0.5), iron)


func wear(head: int, body: int, off: int, trk: int, bodies: int) -> void:
	var sig := "%d|%d|%d|%d|%d" % [head, body, off, trk, bodies]
	if sig == _gear_sig:
		return
	_gear_sig = sig
	for c in _gear.get_children(): c.queue_free()
	var tint := func(id: int, base: Color) -> Color:
		var t: Array = D.IT[id].tint
		return base * Color(t[0], t[1], t[2])
	if head >= 0:
		Build.cyl(_gear, 0.26, 0.28, 0.24, Vector3(0, 1.27, 0.02), tint.call(head, Color.WHITE), 8)
	if body >= 0:
		Build.box(_gear, Vector3(0.7, 0.5, 0.46), Vector3(0, 0.52, 0), tint.call(body, Color.WHITE))
	if off >= 0:
		Build.cyl(_gear, 0.36, 0.36, 0.08, Vector3(-0.48, 0.75, 0.12), tint.call(off, Color.WHITE), 10, PI / 2, PI / 2)
	if trk >= 0:
		Build.cyl(_gear, 0.18, 0.14, 0.3, Vector3(-0.46, 0.25, 0.1), tint.call(trk, Color.WHITE), 7)
	for i in bodies:
		Build.box(_gear, Vector3(0.55, 0.3, 0.3), Vector3(0, 0.75 + i * 0.28, -0.4), Color("b8b09a"), i * 0.5)


func _process(delta: float) -> void:
	var before := position
	position = position.lerp(_want, minf(1.0, delta * 14.0))
	var sp := (position - before).length() / maxf(delta, 1e-4)
	moving = lerpf(moving, minf(1.0, sp / 2.2), minf(1.0, delta * 9.0))
	_jab = maxf(0.0, _jab - delta * 4.2)
	_flash = maxf(0.0, _flash - delta * 6.0)
	_fall = lerpf(_fall, 1.0 if down else 0.0, minf(1.0, delta * 9.0))
	if moving > 0.06:
		_walk += delta * (5.0 + sp * 1.5)
	var swing_ := sin(_walk) * 0.7 * moving
	_leg_l.rotation.x = swing_
	_leg_r.rotation.x = -swing_
	_model.rotation = Vector3(-1.45 * _fall, lerp_angle(_model.rotation.y, facing, minf(1.0, delta * 16.0)), sin(_walk) * 0.07 * moving)
	_model.position.y = absf(sin(_walk)) * 0.14 * moving + _fall * 0.2
	var s := sin(_jab * PI)
	_hand.position.z = 0.14 + s * 0.55
	_hand.rotation.x = 0.12 + s * 1.4
	_hand.visible = not down
	_tunic_mat.albedo_color = tunic.lerp(Color.WHITE, _flash * 0.8).darkened(0.35 * _fall)
