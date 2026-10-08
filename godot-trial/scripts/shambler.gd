extends CharacterBody3D
## One of the dead. It rises in the graveyard, walks down to the gate, and makes for the keep
## unless somebody living comes close enough to be more interesting.

const Build := preload("res://scripts/build.gd")
const World := preload("res://scripts/world.gd")

const MAX_HP := 46.0
const SPEED := 1.5
const DAMAGE := 8.0
const KEEP_DAMAGE := 3.0
const WAIT := 1.3

var hp := MAX_HP
var game: Node = null
var lane := 0.0                 # which stretch of the way down it keeps to
var rise_t := 1.2
var dying := false
var facing := 0.0

var _attack_cd := 0.0
var _walk := 0.0
var _swipe := 0.0
var _flash := 0.0
var _die_t := 0.0
var _model: Node3D
var _skin: StandardMaterial3D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.48
	cap.height = 1.7
	cs.shape = cap
	cs.position.y = 0.85
	add_child(cs)
	_attack_cd = randf()
	_model = Node3D.new()
	_model.scale = Vector3(1.1, 1.1, 1.1)
	add_child(_model)
	_skin = StandardMaterial3D.new()
	_skin.albedo_color = Color("8bab86")
	_skin.roughness = 1.0
	var dark := Color("3d4138")
	Build.box(_model, Vector3(0.24, 0.5, 0.26), Vector3(-0.17, 0, 0), dark)
	Build.box(_model, Vector3(0.24, 0.5, 0.26), Vector3(0.17, 0, 0), dark)
	Build.box(_model, Vector3(0.72, 0.74, 0.46), Vector3(0, 0.48, 0.04), Color("5e6455"), 0.0, 0.22)
	for part in [[Vector3(0.46, 0.42, 0.44), Vector3(0.04, 1.14, 0.22), 0.15], [Vector3(0.16, 0.16, 0.72), Vector3(-0.43, 0.92, 0.44), -0.12], [Vector3(0.16, 0.16, 0.72), Vector3(0.43, 0.86, 0.44), 0.1]]:
		var mi := Build.box(_model, part[0], part[1], Color("8bab86"), 0.0, part[2])
		mi.material_override = _skin
	# its eyes glow
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color("e4ffb0")
	eye.emission_enabled = true
	eye.emission = Color("c8ff70")
	eye.emission_energy_multiplier = 2.5
	Build.glow_box(_model, Vector3(0.09, 0.07, 0.05), Vector3(-0.07, 1.3, 0.47), eye)
	Build.glow_box(_model, Vector3(0.09, 0.07, 0.05), Vector3(0.15, 1.33, 0.46), eye)
	_model.position.y = -1.7


func fighting() -> bool:
	return not dying and rise_t <= 0.0


func hurt(amount: float, from: Vector3) -> void:
	if dying:
		return
	hp -= amount
	_flash = 1.0
	_attack_cd = minf(WAIT, _attack_cd + 0.25)          # a hit delays its next swing a little
	var away := position - from
	away.y = 0.0
	if away.length() > 0.01:
		position += away.normalized() * 0.3
	if hp <= 0.0:
		dying = true
		collision_layer = 0
		if game:
			game.shambler_died(self)


func _physics_process(delta: float) -> void:
	if dying:
		return
	if rise_t > 0.0:
		rise_t -= delta
		return
	_attack_cd = maxf(0.0, _attack_cd - delta)
	# somebody living within seven strides?
	var prey: Node3D = null
	var best := 49.0
	for p in game.peasants:
		if not p.alive():
			continue
		var d := position.distance_squared_to(p.position)
		if d < best:
			best = d
			prey = p
	var goal := _way_to_keep()
	if prey:
		goal = prey.position
	var to := goal - position
	to.y = 0.0
	if to.length() > 0.05:
		facing = lerp_angle(facing, atan2(to.x, to.z), minf(1.0, delta * 6.0))
	if prey and to.length() < 1.55:
		if _attack_cd <= 0.0:
			_attack_cd = WAIT
			_swipe = 1.0
			prey.hurt(DAMAGE)
		velocity = Vector3.ZERO
		return
	if prey == null and absf(position.x) < World.KEEP_H + 1.0 and absf(position.z) < World.KEEP_H + 1.05:
		facing = lerp_angle(facing, atan2(-position.x, -position.z), 0.3)       # at the keep: hammer on it
		if _attack_cd <= 0.0:
			_attack_cd = WAIT
			_swipe = 1.0
			game.keep_hit(KEEP_DAMAGE)
		velocity = Vector3.ZERO
		return
	velocity = to.normalized() * SPEED if to.length() > 0.1 else Vector3.ZERO
	# keep from standing inside one another
	for o in game.shamblers:
		if o == self or not o.fighting():
			continue
		var gap: Vector3 = position - o.position
		gap.y = 0.0
		var d := gap.length()
		if d < 0.95 and d > 0.001:
			velocity += gap / d * (0.95 - d) * 4.0
	move_and_slide()
	position.y = 0.0


## Down the field to the gate, through it, and on to the keep's north face.
func _way_to_keep() -> Vector3:
	if position.z < World.VN - 0.8:
		if absf(position.x) > 1.9:
			return Vector3(clampf(lane * 0.09, -1.8, 1.8), 0, World.VN - 4.0)
		return Vector3(position.x, 0, World.VN + 3.0)
	if position.z < World.VN + 2.0:
		return Vector3(position.x, 0, World.VN + 3.0)
	return Vector3(clampf(lane * 0.14, -World.KEEP_H + 0.6, World.KEEP_H - 0.6), 0, -World.KEEP_H - 0.3)


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 6.0)
	_swipe = maxf(0.0, _swipe - delta * 3.5)
	_skin.albedo_color = Color("8bab86").lerp(Color.WHITE, _flash * 0.85)
	if dying:
		_die_t += delta
		_model.rotation.x = -minf(1.4, _die_t * 6.0)
		_model.position.y = -maxf(0.0, _die_t - 0.5) * 1.6
		if _die_t > 1.5:
			queue_free()
		return
	if velocity.length() > 0.2:
		_walk += delta * 5.0
	var up := clampf(1.0 - rise_t / 1.2, 0.0, 1.0)
	_model.position.y = -1.7 * (1.0 - up)
	_model.rotation = Vector3(0.08 + sin(_swipe * PI) * 0.5, facing, sin(_walk * 0.8) * 0.11)
