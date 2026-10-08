extends CharacterBody3D
## A peasant: the player, or one of the posse following them.

const Build := preload("res://scripts/build.gd")
const World := preload("res://scripts/world.gd")

const SPEED := 7.0
const MAX_HP := 100.0
const FORK_DAMAGE := 12.0
const FORK_REACH := 2.3
const FORK_WAIT := 0.42

var is_player := false
var tunic := Color("c8443a")
var hp := MAX_HP
var game: Node = null               # main.gd: the lists of who is where
var leader: Node3D = null           # the posse keep near this
var follow_offset := Vector3.ZERO
var down := false
var down_t := 0.0
var facing := PI                    # which way the model looks; +z is 0, as in the web version
var bot := false                    # for testing: play by itself

var _attack_cd := 0.0
var _walk := 0.0
var _moving := 0.0
var _jab := 0.0
var _flash := 0.0
var _fall := 0.0
var _model: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _weapon: Node3D
var _tunic_parts: Array[MeshInstance3D] = []


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 1.7
	cs.shape = cap
	cs.position.y = 0.85
	add_child(cs)
	_build_model()


func _build_model() -> void:
	_model = Node3D.new()
	var sc := 1.2 if is_player else 1.0
	_model.scale = Vector3(sc, sc, sc)
	add_child(_model)
	var legs := Color("4a3a2c")
	_leg_l = Node3D.new()
	_leg_l.position = Vector3(-0.14, 0.46, 0)
	_model.add_child(_leg_l)
	Build.box(_leg_l, Vector3(0.2, 0.46, 0.22), Vector3(0, -0.46, 0), legs)
	_leg_r = Node3D.new()
	_leg_r.position = Vector3(0.14, 0.46, 0)
	_model.add_child(_leg_r)
	Build.box(_leg_r, Vector3(0.2, 0.46, 0.22), Vector3(0, -0.46, 0), legs)
	# the tunic is its own material, so a hit can flash it
	var tm := StandardMaterial3D.new()
	tm.albedo_color = tunic
	tm.roughness = 1.0
	for part in [[Vector3(0.66, 0.6, 0.42), Vector3(0, 0.44, 0)], [Vector3(0.17, 0.5, 0.2), Vector3(-0.42, 0.52, 0)], [Vector3(0.17, 0.5, 0.2), Vector3(0.42, 0.52, 0)]]:
		var mi := Build.box(_model, part[0], part[1], tunic)
		mi.material_override = tm
		_tunic_parts.append(mi)
	Build.box(_model, Vector3(0.67, 0.09, 0.43), Vector3(0, 0.5, 0), Color("9a8a78"))
	Build.box(_model, Vector3(0.42, 0.4, 0.4), Vector3(0, 1.03, 0.02), Color("e8b98f"))
	Build.box(_model, Vector3(0.1, 0.1, 0.06), Vector3(0, 1.15, 0.24), Color("d9a279"))
	Build.cyl(_model, 0.34, 0.34, 0.07, Vector3(0, 1.42, 0), Color("dcbc62"), 8)
	Build.cyl(_model, 0.17, 0.2, 0.2, Vector3(0, 1.49, 0), Color("dcbc62"), 8)
	# the pitchfork, held at the hand
	_weapon = Node3D.new()
	_weapon.position = Vector3(0.42, 0.6, 0.14)
	_weapon.rotation.x = 0.12
	_model.add_child(_weapon)
	Build.box(_weapon, Vector3(0.07, 1.75, 0.07), Vector3(0, -0.55, 0), Color("8b6b47"))
	Build.box(_weapon, Vector3(0.36, 0.06, 0.06), Vector3(0, 1.2, 0), Color("70757f"))
	for x in [-0.15, 0.0, 0.15]:
		Build.box(_weapon, Vector3(0.05, 0.32, 0.05), Vector3(x, 1.22, 0), Color("70757f"))
	if is_player:       # a tall flag in the player's colour
		Build.box(_model, Vector3(0.06, 2.3, 0.06), Vector3(-0.3, 0.55, -0.27), tunic)
		Build.box(_model, Vector3(0.86, 0.56, 0.06), Vector3(0.14, 2.28, -0.27), tunic)


func alive() -> bool:
	return not down


func hurt(amount: float) -> void:
	if down:
		return
	hp -= amount
	_flash = 1.0
	if hp <= 0.0:
		hp = 0.0
		down = true
		down_t = 6.0 if is_player else 1e9      # the player gets up again; the posse stay down until dawn
		if game:
			game.someone_fell(self)


func get_up(health: float) -> void:
	down = false
	hp = health


func _physics_process(delta: float) -> void:
	_attack_cd = maxf(0.0, _attack_cd - delta)
	if down:
		down_t -= delta
		if is_player and down_t <= 0.0:
			get_up(50.0)
		velocity = Vector3.ZERO
		_moving = 0.0
		return
	var want := Vector3.ZERO
	if is_player:
		want = _bot_input() if bot else _player_input()
	else:
		want = _posse_brain()
	velocity = want
	move_and_slide()
	position.x = clampf(position.x, World.X_MIN, World.X_MAX)
	position.z = clampf(position.z, World.Z_MIN, World.Z_MAX)
	position.y = 0.0
	var flat := Vector2(want.x, want.z)
	if flat.length() > 0.2:
		facing = lerp_angle(facing, atan2(want.x, want.z), minf(1.0, delta * 14.0))
	_moving = lerpf(_moving, minf(1.0, flat.length() / 2.2), minf(1.0, delta * 9.0))


func _player_input() -> Vector3:
	var dir := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.z += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.z -= 1.0
	if Input.is_physical_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		attack(FORK_DAMAGE, FORK_REACH, FORK_WAIT)
	return dir.normalized() * SPEED if dir != Vector3.ZERO else Vector3.ZERO


## For testing: stand inside the north gate and fight whatever comes through.
func _bot_input() -> Vector3:
	var near: Node3D = null
	var nd := 144.0
	for s in game.shamblers:
		var d := position.distance_squared_to(s.position)
		if s.fighting() and d < nd:
			nd = d
			near = s
	var goal: Vector3 = near.position if near else Vector3(0, 0, -17)
	var to := goal - position
	to.y = 0.0
	if near and to.length() < 2.2:
		attack(FORK_DAMAGE, FORK_REACH, FORK_WAIT)
		return Vector3.ZERO
	return to.normalized() * SPEED if to.length() > 0.6 else Vector3.ZERO


## The posse: fight what is near their leader, otherwise keep their place behind them.
func _posse_brain() -> Vector3:
	if leader == null or game == null:
		return Vector3.ZERO
	var target: Node3D = null
	var best := 81.0
	for s in game.shamblers:
		if not s.fighting():
			continue
		var d := position.distance_squared_to(s.position)
		if d < best and leader.position.distance_squared_to(s.position) < 64.0:
			best = d
			target = s
	if target:
		var to := target.position - position
		to.y = 0.0
		if to.length() < 2.2:
			facing = lerp_angle(facing, atan2(to.x, to.z), 0.3)
			attack(6.0, 1.9, 0.9)
			return Vector3.ZERO
		return to.normalized() * 5.2
	var spot: Vector3 = leader.position + Basis(Vector3.UP, leader.facing) * follow_offset
	var gap := spot - position
	gap.y = 0.0
	var dist := gap.length()
	if dist < 0.45:
		return Vector3.ZERO
	return gap.normalized() * (8.2 if dist > 4.0 else 5.4)


## Jab at whatever is in front and in reach.
func attack(damage: float, reach: float, wait: float) -> void:
	if _attack_cd > 0.0 or game == null:
		return
	_attack_cd = wait
	_jab = 1.0
	if is_player:       # turn to the nearest of the dead in reach, so a blow is not wasted
		var near: Node3D = null
		var nd := (reach + 1.5) * (reach + 1.5)
		for s in game.shamblers:
			var d := position.distance_squared_to(s.position)
			if s.fighting() and d < nd:
				nd = d
				near = s
		if near:
			facing = atan2(near.position.x - position.x, near.position.z - position.z)
	var fwd := Vector3(sin(facing), 0, cos(facing))
	for s in game.shamblers.duplicate():
		if not s.fighting():
			continue
		var to: Vector3 = s.position - position
		to.y = 0.0
		var dist := to.length()
		if dist > reach + 0.5:
			continue
		if dist > 0.8 and to.normalized().dot(fwd) < 0.5:
			continue
		s.hurt(damage, position)


func _process(delta: float) -> void:
	_jab = maxf(0.0, _jab - delta * 4.2)
	_flash = maxf(0.0, _flash - delta * 6.0)
	_fall = lerpf(_fall, 1.0 if down else 0.0, minf(1.0, delta * 9.0))
	if _moving > 0.06:
		_walk += delta * (5.0 + velocity.length() * 1.5)
	var swing := sin(_walk) * 0.7 * _moving
	_leg_l.rotation.x = swing
	_leg_r.rotation.x = -swing
	_model.rotation = Vector3(-1.45 * _fall, facing, sin(_walk) * 0.07 * _moving)
	_model.position.y = absf(sin(_walk)) * 0.14 * _moving + _fall * 0.2
	var s := sin(_jab * PI)
	_weapon.position.z = 0.14 + s * 0.55
	_weapon.rotation.x = 0.12 + s * 1.4
	_weapon.visible = not down
	var mat := _tunic_parts[0].material_override as StandardMaterial3D
	mat.albedo_color = tunic.lerp(Color.WHITE, _flash * 0.8).darkened(0.35 * _fall)
