extends Node3D
## One of the dead on screen: a shambler, a skeleton, a skeleton archer or the Steward.
## Like the peasants, it only shows what the rules say.

const Build := preload("res://scripts/build.gd")

var kind := 0
var state := "rise"
var facing := 0.0
var dying := false

var _want := Vector3.ZERO
var _first := true
var _walk := 0.0
var _swipe := 0.0
var _flash := 0.0
var _die_t := 0.0
var _up := 0.0
var _model: Node3D
var _skin: StandardMaterial3D
var _base := Color("8bab86")


func _ready() -> void:
	_model = Node3D.new()
	add_child(_model)
	_skin = StandardMaterial3D.new()
	_skin.roughness = 1.0
	var eye := StandardMaterial3D.new()
	eye.emission_enabled = true
	eye.emission_energy_multiplier = 2.5
	match kind:
		0:                                               # a shambler: hunched, green-grey, arms out
			_base = Color("8bab86")
			_model.scale = Vector3.ONE * 1.1
			var dark := Color("3d4138")
			Build.box(_model, Vector3(0.24, 0.5, 0.26), Vector3(-0.17, 0, 0), dark)
			Build.box(_model, Vector3(0.24, 0.5, 0.26), Vector3(0.17, 0, 0), dark)
			Build.box(_model, Vector3(0.72, 0.74, 0.46), Vector3(0, 0.48, 0.04), Color("5e6455"), 0.0, 0.22)
			for part in [[Vector3(0.46, 0.42, 0.44), Vector3(0.04, 1.14, 0.22), 0.15], [Vector3(0.16, 0.16, 0.72), Vector3(-0.43, 0.92, 0.44), -0.12], [Vector3(0.16, 0.16, 0.72), Vector3(0.43, 0.86, 0.44), 0.1]]:
				Build.box(_model, part[0], part[1], _base, 0.0, part[2]).material_override = _skin
			eye.albedo_color = Color("e4ffb0"); eye.emission = Color("c8ff70")
			Build.glow_box(_model, Vector3(0.09, 0.07, 0.05), Vector3(-0.07, 1.3, 0.47), eye)
			Build.glow_box(_model, Vector3(0.09, 0.07, 0.05), Vector3(0.15, 1.33, 0.46), eye)
		1, 2:                                            # a skeleton (with a bow, for an archer): thin and quick
			_base = Color("e6dfc8")
			var bone := _base
			for x in [-0.12, 0.12]:
				Build.box(_model, Vector3(0.1, 0.62, 0.1), Vector3(x, 0, 0), bone).material_override = _skin
			Build.box(_model, Vector3(0.42, 0.12, 0.2), Vector3(0, 0.62, 0), bone).material_override = _skin
			Build.box(_model, Vector3(0.08, 0.5, 0.08), Vector3(0, 0.72, 0), bone).material_override = _skin
			for y in [0.85, 0.98, 1.1]:
				Build.box(_model, Vector3(0.44, 0.05, 0.26), Vector3(0, y, 0), bone).material_override = _skin
			for x in [-0.3, 0.3]:
				Build.box(_model, Vector3(0.08, 0.08, 0.6), Vector3(x, 1.08, 0.25), bone).material_override = _skin
			Build.box(_model, Vector3(0.34, 0.34, 0.34), Vector3(0, 1.24, 0.04), bone).material_override = _skin
			eye.albedo_color = Color("ffd0a0"); eye.emission = Color("ff7a3a")
			Build.glow_box(_model, Vector3(0.08, 0.06, 0.04), Vector3(-0.08, 1.4, 0.21), eye)
			Build.glow_box(_model, Vector3(0.08, 0.06, 0.04), Vector3(0.08, 1.4, 0.21), eye)
			if kind == 2:
				Build.box(_model, Vector3(0.05, 1.3, 0.05), Vector3(-0.32, 0.5, 0.55), Color("5b4130"), 0, 0.1)
		3:                                               # the Steward: tall, robed, crowned, in no hurry
			_base = Color("6a5a86")
			_model.scale = Vector3.ONE * 1.6
			Build.box(_model, Vector3(0.8, 1.1, 0.6), Vector3(0, 0, 0), _base).material_override = _skin
			Build.box(_model, Vector3(0.7, 0.4, 0.5), Vector3(0, 1.1, 0), Color("4d3b69"))
			Build.box(_model, Vector3(0.4, 0.4, 0.4), Vector3(0, 1.5, 0.04), Color("cfd6c0"))
			Build.cyl(_model, 0.24, 0.24, 0.18, Vector3(0, 1.9, 0.04), Color("d8b040"), 6)
			Build.box(_model, Vector3(0.06, 2.2, 0.06), Vector3(0.5, 0, 0.3), Color("2a2420"))
			eye.albedo_color = Color("d0c0ff"); eye.emission = Color("a080ff")
			Build.glow_box(_model, Vector3(0.08, 0.06, 0.04), Vector3(-0.08, 1.66, 0.25), eye)
			Build.glow_box(_model, Vector3(0.08, 0.06, 0.04), Vector3(0.08, 1.66, 0.25), eye)
	_skin.albedo_color = _base
	_model.position.y = -1.7


func place(x: float, z: float, r: float) -> void:
	_want = Vector3(x, 0, z)
	if _first or position.distance_to(_want) > 6.0:
		position = _want
		_first = false
	facing = r

func swing() -> void:
	_swipe = 1.0

func hit() -> void:
	_flash = 1.0

func die() -> void:
	dying = true


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 6.0)
	_swipe = maxf(0.0, _swipe - delta * 3.5)
	_skin.albedo_color = _base.lerp(Color.WHITE, _flash * 0.85)
	if dying:
		_die_t += delta
		_model.rotation.x = -minf(1.4, _die_t * 6.0)
		_model.position.y = -maxf(0.0, _die_t - 0.5) * 1.6
		if _die_t > 1.5:
			queue_free()
		return
	var before := position
	position = position.lerp(_want, minf(1.0, delta * 12.0))
	if (position - before).length() > delta * 0.2:
		_walk += delta * (5.0 if kind != 1 else 8.0)
	_up = minf(1.0, _up + delta / 1.2)                  # climbing out of the ground takes as long as the rules say
	var pile := state == "pile"
	_model.position.y = -1.7 * (1.0 - _up) if not pile else -0.55
	var wob := sin(Time.get_ticks_msec() * 0.02) * 0.15 if state == "stun" else 0.0
	_model.rotation = Vector3((1.2 if pile else 0.08 + sin(_swipe * PI) * 0.5), lerp_angle(_model.rotation.y, facing, minf(1.0, delta * 10.0)), sin(_walk * 0.8) * 0.11 + wob)
