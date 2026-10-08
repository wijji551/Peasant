extends Node3D
## Defend the Village!  A trial of the game in Godot.
##
## What is here: the village of Thornhallow, a peasant to walk about, a posse of three,
## day turning to night, and the dead rising in the graveyard and making for the keep.
## What is not: everything else in the web version (building, books, the inn, co-op...).
## Everything is made in code, in scripts/, so there is nothing to wire up in the editor.

const World := preload("res://scripts/world.gd")
const Peasant := preload("res://scripts/peasant.gd")
const Shambler := preload("res://scripts/shambler.gd")
const Hud := preload("res://scripts/hud.gd")

enum Phase { DAY, DUSK, NIGHT, LOST }

const DAY_LEN := 75.0            # seconds: short, because there is nothing to gather yet
const DUSK_LEN := 10.0
const KEEP_MAX := 1000.0
const NIGHT_FIRST := 16          # how many rise on night 1
const NIGHT_MORE := 7            # and how many more each night after
const RISE_FOR := 60.0           # seconds they keep rising

# the look of day, night and the moment between
const SUN_DAY := Color(1.0, 0.94, 0.8)
const SUN_NIGHT := Color(0.5, 0.6, 1.0)
const SUN_DUSK := Color(1.0, 0.6, 0.35)
const AMB_DAY := Color(0.62, 0.66, 0.62)
const AMB_NIGHT := Color(0.2, 0.25, 0.48)
const AMB_DUSK := Color(0.6, 0.42, 0.4)
const FOG_DAY := Color(0.8, 0.86, 0.68)
const FOG_NIGHT := Color(0.07, 0.09, 0.2)
const FOG_DUSK := Color(0.9, 0.6, 0.4)
const SUN_FROM_DAY := Vector3(-26, 44, 20)
const SUN_FROM_NIGHT := Vector3(22, 46, -16)

var phase: Phase = Phase.DAY
var day := 1
var time_left := DAY_LEN
var night_f := 0.0               # 0 by day, 1 at night
var keep_hp := KEEP_MAX
var peasants: Array = []         # the player first, then the posse
var shamblers: Array = []
var kills := 0

var world: Node3D
var player: CharacterBody3D
var hud: CanvasLayer
var camera: Camera3D
var sun: DirectionalLight3D
var env: Environment
var _focus := Vector3(0, 0, -4)
var _zoom := 1.0
var _rise_at: Array[float] = []  # when each of tonight's dead comes up
var _night_t := 0.0
var _end_t := 0.0
var _frame := 0


func _ready() -> void:
	world = World.new()
	add_child(world)

	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR     # the colours are chosen by eye, so leave them as they are
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 95.0
	env.fog_depth_end = 250.0
	env.fog_density = 1.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.15
	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 1.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 230.0
	sun.shadow_blur = 1.3
	add_child(sun)

	camera = Camera3D.new()
	camera.fov = 20.0
	camera.near = 5.0
	camera.far = 520.0
	add_child(camera)
	camera.make_current()

	var home: Dictionary = World.cottage(0)
	player = Peasant.new()
	player.is_player = true
	player.tunic = Color("c8443a")
	player.game = self
	player.position = home.door
	add_child(player)
	peasants.append(player)
	var places := [Vector3(-1.2, 0, -1.7), Vector3(1.2, 0, -1.7), Vector3(0, 0, -2.8)]
	for i in 3:
		var q := Peasant.new()
		q.tunic = Color("c8443a").lerp(Color("b79e75"), 0.35)
		q.game = self
		q.leader = player
		q.follow_offset = places[i]
		q.position = home.door + Vector3(-1.1 + i * 1.1, 0, -0.9)
		add_child(q)
		peasants.append(q)

	hud = Hud.new()
	add_child(hud)
	hud.banner("Day 1", "Thornhallow, in Hallowshire. The dead come down from the castle at night.", 5.0)
	_focus = player.position
	if OS.get_environment("DTV_PHASE") == "night":       # for testing: go straight to night
		time_left = 0.5
	player.bot = OS.get_environment("DTV_BOT") != ""       # for testing: the player fights by itself
	_apply_light(0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			get_tree().quit()
		elif event.physical_keycode == KEY_R and phase == Phase.DAY:
			time_left = 0.0


func _process(delta: float) -> void:
	match phase:
		Phase.DAY:
			night_f = maxf(0.0, night_f - delta / 6.0)
			time_left -= delta
			if time_left <= 0.0:
				phase = Phase.DUSK
				time_left = DUSK_LEN
				hud.banner("Dusk", "The bell rings. Something is stirring at Ashhollow Castle.", 5.0)
		Phase.DUSK:
			time_left -= delta
			night_f = clampf(1.0 - time_left / DUSK_LEN, 0.0, 1.0)
			if time_left <= 0.0:
				_start_night()
		Phase.NIGHT:
			_night(delta)
		Phase.LOST:
			_end_t -= delta
			if _end_t <= 0.0:
				get_tree().reload_current_scene()      # start again from day 1
				return
	_apply_light(night_f)
	_camera(delta)
	var left := shamblers.size() + _rise_at.size()
	var timer := ""
	match phase:
		Phase.DAY:
			timer = "Dusk in %d:%02d" % [int(ceil(time_left)) / 60, int(ceil(time_left)) % 60]
		Phase.DUSK:
			timer = "Night falls in %d" % int(ceil(time_left))
		Phase.NIGHT:
			timer = "%d of the dead left, %d still to rise" % [left, _rise_at.size()] if _rise_at.size() else "%d of the dead left" % left
		Phase.LOST:
			timer = "The keep has fallen"
	hud.show_state("Night %d" % day if phase == Phase.NIGHT or phase == Phase.LOST else ("Dusk" if phase == Phase.DUSK else "Day %d" % day), timer, keep_hp, KEEP_MAX, player.hp, player.MAX_HP)
	_test_hook()


func _start_night() -> void:
	phase = Phase.NIGHT
	night_f = 1.0
	_night_t = 0.0
	_rise_at.clear()
	var n := NIGHT_FIRST + NIGHT_MORE * (day - 1)
	for i in n:      # no waves: one after another, slowly at first and faster as the night goes on
		var f := (i + 0.5) / n
		_rise_at.append(3.0 + RISE_FOR * (-0.6 + sqrt(0.36 + 1.6 * f)) / 0.8)
	hud.banner("Night %d" % day, "The dead are rising all along the graveyard.", 4.5)


func _night(delta: float) -> void:
	_night_t += delta
	while _rise_at.size() and _rise_at[0] <= _night_t:
		_rise_at.pop_front()
		var s := Shambler.new()
		s.game = self
		var x := randf_range(-32.0, 32.0)
		s.lane = x
		s.position = Vector3(x, 0, -69.0 + randf_range(-4.5, 4.5))
		add_child(s)
		shamblers.append(s)
	if shamblers.is_empty() and _rise_at.is_empty():
		_dawn()


func _dawn() -> void:
	day += 1
	phase = Phase.DAY
	time_left = DAY_LEN
	for p in peasants:
		p.get_up(p.MAX_HP)
	hud.banner("Day %d" % day, "%d of the dead were put back down." % kills, 4.5)


func shambler_died(s: Node) -> void:
	shamblers.erase(s)
	kills += 1


func someone_fell(p: Node) -> void:
	if p == player:
		hud.banner("You are down", "You will be back on your feet in a moment.", 3.0)


func keep_hit(amount: float) -> void:
	if phase != Phase.NIGHT:
		return
	keep_hp -= amount
	if keep_hp <= 0.0:
		keep_hp = 0.0
		phase = Phase.LOST
		_end_t = 6.0
		hud.banner("The keep has fallen", "Robert Bailiff's door remains bolted.", 6.0)


func _apply_light(nf: float) -> void:
	var k := 4.0 * nf * (1.0 - nf)                       # peaks at the moment of dusk
	sun.light_color = SUN_DAY.lerp(SUN_NIGHT, nf).lerp(SUN_DUSK, k * 0.7)
	sun.light_energy = lerpf(0.8, 0.42, nf)
	sun.position = SUN_FROM_DAY.lerp(SUN_FROM_NIGHT, nf)
	sun.look_at(Vector3.ZERO)
	env.ambient_light_color = AMB_DAY.lerp(AMB_NIGHT, nf).lerp(AMB_DUSK, k * 0.7)
	env.ambient_light_energy = lerpf(0.32, 0.6, nf)
	var fog := FOG_DAY.lerp(FOG_NIGHT, nf).lerp(FOG_DUSK, k * 0.7)
	env.background_color = fog
	env.fog_light_color = fog
	var lit := smoothstep(0.3, 0.8, nf)                  # windows and lanterns come on as it gets dark
	world.window_mat.emission_energy_multiplier = 2.6 * lit
	world.window_mat.albedo_color = Color("3a3f52").lerp(Color("ffe6a8"), lit)
	for l in world.lanterns:
		l.light_energy = 2.4 * lit


## The view: looking down on the player from the south, as in the web version.
func _camera(delta: float) -> void:
	_focus = _focus.lerp(player.position, minf(1.0, delta * 6.0))
	_zoom = lerpf(_zoom, 1.0 + 0.12 * night_f, minf(1.0, delta * 3.0))
	camera.position = _focus + Vector3(0, 66, 56) * 1.25 * _zoom
	camera.look_at(_focus + Vector3(0, 1, 0))


## For testing from the command line: DTV_SHOT=file.png saves a picture after DTV_SHOT_AT frames and stops.
func _test_hook() -> void:
	_frame += 1
	if OS.get_environment("DTV_LOG") != "" and _frame % 600 == 0:
		print("t=", _frame / 60, "s phase ", Phase.keys()[phase], " day ", day, " dead walking ", shamblers.size(), " to rise ", _rise_at.size(), " kills ", kills, " keep ", keep_hp, " player hp ", player.hp, " posse up ", peasants.filter(func(p): return p.alive()).size() - 1, " nearest dead to keep ", shamblers.map(func(s): return snappedf(Vector2(s.position.x, s.position.z).length(), 0.1)).min() if shamblers.size() else -1)
	var shot := OS.get_environment("DTV_SHOT")
	if shot == "":
		return
	var at := int(OS.get_environment("DTV_SHOT_AT")) if OS.get_environment("DTV_SHOT_AT") != "" else 60
	if _frame == at:
		if OS.get_environment("DTV_AT") != "":
			var xz := OS.get_environment("DTV_AT").split(",")
			player.position = Vector3(float(xz[0]), 0, float(xz[1]))
	if _frame == at + 30:
		get_viewport().get_texture().get_image().save_png(shot)
		print("phase ", Phase.keys()[phase], " day ", day, " dead ", shamblers.size(), " kills ", kills, " keep ", keep_hp, " player ", player.position)
		get_tree().quit()
