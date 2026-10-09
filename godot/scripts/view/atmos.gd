extends Node3D
## The weather and the mood: mist that creeps over the ground at night and never quite leaves the castle,
## rain on some days, will-o'-wisps over the graveyard and round the castle at night, crows circling the
## towers, and now and then lightning over Ashhollow. Only for looking at: the rules know nothing of this.
##
## main.gd calls update() every frame with how dark it is (0 day, 1 night) and where the camera is looking.

const MIST_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform sampler2D noise : repeat_enable, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(0.82, 0.86, 0.9, 1.0);
uniform vec4 haunt_tint : source_color = vec4(0.55, 0.68, 0.55, 1.0);
uniform float amount = 0.0;        // over the whole map
uniform float haunt = 0.25;        // extra, from the stakes up to the castle
uniform float speed = 0.012;
uniform float scale = 0.018;
uniform float seed = 0.0;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 uv = wp.xz * scale + vec2(seed);
	float n1 = texture(noise, uv + vec2(TIME * speed, TIME * speed * 0.4)).r;
	float n2 = texture(noise, uv * 2.3 - vec2(TIME * speed * 0.7, -TIME * speed * 0.3)).r;
	float n = n1 * 0.65 + n2 * 0.35;
	float north = smoothstep(-52.0, -78.0, wp.z);
	float a = (amount + haunt * north) * smoothstep(0.32, 0.78, n);
	ALBEDO = mix(tint.rgb, haunt_tint.rgb, north);
	ALPHA = clamp(a, 0.0, 0.8);
}
"""

const WEATHER := ["clear", "clear", "clear", "overcast", "rain", "clear", "mist", "overcast", "rain", "clear"]
const WEATHER_LINE := {
	"clear": "",
	"overcast": "The sky is the colour of old porridge today.",
	"rain": "It is raining. The dead do not mind; the peasants do.",
	"mist": "A thick mist has come up off the river. Mind where you put your feet.",
}

var weather := "clear"
var flash := 0.0                    # lightning: 1 at the strike, fading; main.gd brightens the sky by it
var _mists: Array[ShaderMaterial] = []
var _rain: CPUParticles3D
var _wisps: Array[CPUParticles3D] = []
var _crows: Array[Node3D] = []
var _t := 0.0
var _bolt_t := 8.0
var _rng := RandomNumberGenerator.new()
var _haunt_lights: Array = []       # the green braziers at the castle gate (world.gd)
var _haunt_mat: StandardMaterial3D  # the castle's windows that glow at night (world.gd)


func setup(world: Node3D) -> void:
	_haunt_lights = world.haunt_lights
	_haunt_mat = world.haunt_mat
	for c in world.chimneys:                 # a thread of smoke from every chimney
		var sm := _make_smoke()
		sm.position = c
		add_child(sm)


func _ready() -> void:
	var tex := NoiseTexture2D.new()
	tex.seamless = true
	tex.width = 256
	tex.height = 256
	tex.generate_mipmaps = true
	var fn := FastNoiseLite.new()
	fn.frequency = 0.012
	fn.fractal_octaves = 4
	tex.noise = fn
	var sh := Shader.new()
	sh.code = MIST_SHADER
	for layer in 2:                      # two sheets of mist, drifting at different speeds
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(240, 210)
		mi.mesh = pm
		mi.position = Vector3(0, 0.45 + layer * 0.75, -36)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("noise", tex)
		m.set_shader_parameter("speed", 0.010 + layer * 0.006)
		m.set_shader_parameter("scale", 0.016 + layer * 0.008)
		m.set_shader_parameter("seed", layer * 0.37)
		mi.material_override = m
		add_child(mi)
		_mists.append(m)
	_rain = _make_rain()
	add_child(_rain)
	# will-o'-wisps: over the graveyard, and up round the castle
	for area in [[Vector3(0, 1.2, -68.5), Vector3(36, 0.8, 4.5)], [Vector3(0, 6.0, -100), Vector3(30, 3, 14)]]:
		var w := _make_wisps(area[0], area[1])
		add_child(w)
		_wisps.append(w)
	for i in 7:
		var c := _make_crow()
		add_child(c)
		_crows.append(c)


## The weather for a day: the same on every computer, from the game's seed.
func pick(game_seed: int, day: int) -> void:
	_rng.seed = game_seed * 7 + day * 191
	weather = "clear" if day == 1 else WEATHER[_rng.randi() % WEATHER.size()]


func weather_line() -> String:
	return WEATHER_LINE.get(weather, "")


## How much darker and greyer the day is for the weather, for main.gd's lighting.
func gloom() -> float:
	return {"clear": 0.0, "overcast": 0.35, "rain": 0.55, "mist": 0.3}.get(weather, 0.0)


func update(delta: float, nf: float, focus: Vector3) -> void:
	_t += delta
	var night := smoothstep(0.35, 0.9, nf)
	var amount := 0.06 + night * 0.36 + (0.38 if weather == "mist" else 0.0) + (0.1 if weather == "rain" else 0.0)
	for m in _mists:
		m.set_shader_parameter("amount", amount)
		m.set_shader_parameter("haunt", 0.3 + night * 0.4)
		m.set_shader_parameter("tint", Color(0.84, 0.87, 0.9).lerp(Color(0.5, 0.57, 0.68), night))
		m.set_shader_parameter("haunt_tint", Color(0.62, 0.66, 0.6).lerp(Color(0.3, 0.52, 0.36), night))
	_rain.emitting = weather == "rain"
	_rain.global_position = focus + Vector3(0, 26, 4)
	for w in _wisps:
		w.emitting = night > 0.4
	# crows wheel round the towers, flapping now and then
	for i in _crows.size():
		var c := _crows[i]
		var a := _t * (0.35 + i * 0.03) + i * 0.9
		var r := 13.0 + (i % 3) * 4.0
		c.position = Vector3(cos(a) * r, 27 + (i % 4) * 2.2 + sin(_t * 0.7 + i) * 1.2, -116 + sin(a) * r * 0.8)
		c.rotation.y = -a
		var flap := sin(_t * 9.0 + i * 2.0) * 0.5 if fmod(_t + i, 5.0) < 1.6 else 0.12
		c.get_child(0).rotation.z = flap
		c.get_child(1).rotation.z = -flap
	# the green fires at the castle gate, and its windows, burn brighter at night
	for l in _haunt_lights:
		l.light_energy = (0.6 + night * 2.6) * (0.85 + 0.15 * sin(_t * 11.0 + l.position.x))
	if _haunt_mat:
		_haunt_mat.emission_energy_multiplier = 0.2 + night * 3.2
	# lightning over Ashhollow, at night only
	flash = maxf(0.0, flash - delta * 3.5)
	if night > 0.6:
		_bolt_t -= delta
		if _bolt_t <= 0:
			flash = 1.0
			_bolt_t = _rng.randf_range(9.0, 26.0)
		elif _bolt_t < 0.25 and _bolt_t > 0.2 and _rng.randf() < 0.5:
			flash = 0.6                  # sometimes a second flicker just before
	else:
		_bolt_t = maxf(_bolt_t, 6.0)


func _make_rain() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 2200
	p.lifetime = 0.9
	p.preprocess = 1.0
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(48, 1, 40)
	p.direction = Vector3(0.12, -1, 0.05)
	p.spread = 2.0
	p.gravity = Vector3(0, -20, 0)
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 36.0
	var m := BoxMesh.new()
	m.size = Vector3(0.09, 1.8, 0.09)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.82, 0.88, 1.0, 0.6)
	m.material = mat
	p.mesh = m
	p.emitting = false
	return p


func _make_wisps(at: Vector3, extents: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = at
	p.amount = 28
	p.lifetime = 7.0
	p.preprocess = 4.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.gravity = Vector3(0, 0.06, 0)
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.7
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0)); curve.add_point(Vector2(0.2, 1)); curve.add_point(Vector2(0.8, 1)); curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	var m := SphereMesh.new()
	m.radius = 0.2; m.height = 0.4; m.radial_segments = 8; m.rings = 4
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.62, 1.0, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 1.0, 0.6)
	mat.emission_energy_multiplier = 3.0
	m.material = mat
	p.mesh = m
	p.emitting = false
	return p


func _make_smoke() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 10
	p.lifetime = 5.0
	p.preprocess = 5.0
	p.direction = Vector3(0.35, 1, 0.1)
	p.spread = 12.0
	p.gravity = Vector3(0.25, 0.15, 0)
	p.initial_velocity_min = 0.7
	p.initial_velocity_max = 1.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4)); curve.add_point(Vector2(1, 2.4))
	p.scale_amount_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(0.85, 0.83, 0.8, 0.55))
	grad.set_color(1, Color(0.85, 0.83, 0.8, 0.0))
	p.color_ramp = grad
	var m := SphereMesh.new()
	m.radius = 0.35; m.height = 0.7; m.radial_segments = 6; m.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	m.material = mat
	p.mesh = m
	return p


func _make_crow() -> Node3D:
	var n := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.07, 0.09)
	mat.roughness = 1.0
	for s in [-1.0, 1.0]:                # two wings, hinged at the body
		var hinge := Node3D.new()
		n.add_child(hinge)
		var w := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(1.1, 0.06, 0.5)
		w.mesh = bm
		w.material_override = mat
		w.position = Vector3(s * 0.55, 0, 0)
		hinge.add_child(w)
	var body := MeshInstance3D.new()
	var b := BoxMesh.new(); b.size = Vector3(0.22, 0.2, 0.8)
	body.mesh = b
	body.material_override = mat
	n.add_child(body)
	return n
