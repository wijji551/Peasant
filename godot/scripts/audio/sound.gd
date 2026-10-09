class_name Sound
extends Node
## Everything you hear. Three channels under the master volume: Effects, Ambience and Music, each with its own
## volume in the options; M mutes the lot. The sounds are files in sounds/, made by tools/make_sounds.py.
##
##   Sound.play("chop", 1.0, Vector2(x, z))   an effect; with a place, it is quieter further from the camera,
##                                            and not heard at all from across the map
##   update(nf, focus, weather, undead_near)  main.gd, every frame: the ambience and the music follow the time
##                                            of day, the weather and how close the camera is to the castle

const EFFECTS := ["bell", "bone", "build", "caw0", "caw1", "cheer", "chop", "clang", "coin", "dawn", "door", "eat",
	"find", "forge", "groan0", "groan1", "groan2", "gulp", "hit", "holy", "hooves", "hurt", "iron", "jeer", "keep", "knock",
	"lost", "nail", "no", "owl", "page", "pick", "pluck", "pop", "raise", "rally", "rattle", "relic", "ring", "splash", "splat",
	"steward", "stone", "swing", "thump", "thunder0", "thunder1", "won"]
const LOOPS := {"day": "amb_day", "night": "amb_night", "rain": "amb_rain", "castle": "amb_castle",
	"music_day": "music_day", "music_night": "music_night"}
const VARY := ["chop", "hit", "bone", "swing", "stone", "pick", "build", "splash", "thump", "splat", "groan0", "groan1", "groan2", "rattle", "caw0", "caw1"]
const HEAR := 34.0               # further from the camera than this, an effect is not heard

static var me: Sound
var focus := Vector2.ZERO
var _fx: Dictionary = {}          # name -> AudioStream
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _last: Dictionary = {}        # name -> when it last played, so a crowd of the same sound is one sound
var _loops: Dictionary = {}       # name -> AudioStreamPlayer
var _t := 0.0
var _owl_t := 20.0
var _caw_t := 6.0
var _groan_t := 3.0
var _thunder := -1.0


func _ready() -> void:
	me = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Effects", "Ambience", "Music"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	for n in EFFECTS:
		_fx[n] = load("res://sounds/sfx_%s.wav" % n)
	for i in 20:
		var p := AudioStreamPlayer.new()
		p.bus = "Effects"
		add_child(p)
		_pool.append(p)
	for k in LOOPS:
		var s: AudioStreamWAV = load("res://sounds/%s.wav" % LOOPS[k])
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate)
		var p := AudioStreamPlayer.new()
		p.stream = s
		p.bus = "Music" if k.begins_with("music") else "Ambience"
		p.volume_db = -80.0
		add_child(p)
		p.play()
		_loops[k] = [p, 0.0]          # the player, and how loud it is now (0 to 1)
	apply_settings()


## The volumes and the mute, from Settings. The options call this when anything changes.
static func apply_settings() -> void:
	var m := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(m, _db(Settings.vol / 100.0))
	AudioServer.set_bus_mute(m, Settings.muted or Settings.vol <= 0)
	for b in [["Effects", Settings.fx_vol], ["Ambience", Settings.amb_vol], ["Music", Settings.music_vol]]:
		var i := AudioServer.get_bus_index(b[0])
		if i >= 0:
			AudioServer.set_bus_volume_db(i, _db(b[1] / 100.0))
			AudioServer.set_bus_mute(i, b[1] <= 0)


static func _db(v: float) -> float:
	return linear_to_db(maxf(v, 0.0001))


## Play an effect. at: where it happened (x, z), or leave it out for a sound of your own (a click, a refusal).
static func play(name: String, vol: float = 1.0, at: Vector2 = Vector2.INF) -> void:
	if me == null or not me._fx.has(name):
		return
	var now := Time.get_ticks_msec()
	if now - int(me._last.get(name, -1000)) < 55:
		return
	if at != Vector2.INF:
		var d := at.distance_to(me.focus)
		if d > HEAR:
			return
		vol *= clampf(1.15 - d / HEAR, 0.25, 1.0)
	me._last[name] = now
	var p: AudioStreamPlayer = me._pool[me._next]
	me._next = (me._next + 1) % me._pool.size()
	p.stream = me._fx[name]
	p.volume_db = linear_to_db(maxf(vol, 0.0001))
	p.pitch_scale = randf_range(0.92, 1.08) if VARY.has(name) else 1.0
	p.play()


## Ambience and music. nf: 0 by day, 1 at night. weather: "clear", "overcast", "rain" or "mist".
## undead_near: how many of the dead are close to the camera. flash: lightning, from atmos.gd.
func update(delta: float, nf: float, focus_: Vector3, weather: String, undead_near: int, flash: float, playing: bool) -> void:
	_t += delta
	focus = Vector2(focus_.x, focus_.z)
	var night := smoothstep(0.3, 0.85, nf)
	var castle := clampf(1.0 - (focus.y + 60.0) / 45.0, 0.0, 1.0)      # nearer the castle, louder its drone
	_fade("day", (1.0 - night) * (0.75 if weather == "rain" else 1.0) * 0.7, delta)
	_fade("night", night * 0.8, delta)
	_fade("rain", 0.8 if weather == "rain" else 0.0, delta)
	_fade("castle", clampf(castle * 0.9 + night * 0.25, 0.0, 1.0) * 0.8, delta)
	_fade("music_day", (1.0 - night) * 0.6, delta * 0.5)
	_fade("music_night", night * 0.65, delta * 0.5)
	if not playing:
		return
	# now and then: an owl at night, crows by the castle, the dead groaning when they are close
	_owl_t -= delta
	if _owl_t <= 0:
		_owl_t = randf_range(25, 60)
		if night > 0.6: play("owl", 0.5)
	_caw_t -= delta
	if _caw_t <= 0:
		_caw_t = randf_range(5, 14)
		if castle > 0.3 or randf() < 0.2: play("caw%d" % (randi() % 2), 0.25 + castle * 0.5)
	_groan_t -= delta
	if _groan_t <= 0:
		_groan_t = randf_range(1.2, 3.5) / maxf(1.0, sqrt(undead_near))
		if undead_near > 0:
			play(["groan0", "groan1", "groan2", "rattle"][randi() % 4], minf(0.9, 0.35 + undead_near * 0.05))
	# thunder follows the lightning, a little later
	if flash >= 0.99 and _thunder < 0:
		_thunder = randf_range(0.6, 2.0)
	if _thunder >= 0:
		_thunder -= delta
		if _thunder < 0:
			play("thunder%d" % (randi() % 2), 0.9)


func _fade(k: String, want: float, delta: float) -> void:
	var e: Array = _loops[k]
	e[1] = move_toward(e[1], want, delta * 0.5)
	(e[0] as AudioStreamPlayer).volume_db = linear_to_db(maxf(e[1], 0.0001))
