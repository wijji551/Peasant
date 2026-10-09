extends Node3D
## Thornhallow: Thirty Nights (it began as "Defend the Village!").  The game in Godot.
##
## The rules (scripts/rules/) run the game: days and nights, gathering, building, books, items, the inn,
## the priest, the ruins and the dead. Everything here only shows what the rules say and passes on what
## the player presses. Everything is made in code, so there is nothing to wire up in the editor.

const World := preload("res://scripts/world.gd")
const Figure := preload("res://scripts/view/figure.gd")
const Dead := preload("res://scripts/view/dead.gd")
const Fx := preload("res://scripts/view/fx.gd")
const Minimap := preload("res://scripts/ui/minimap.gd")
const Labels := preload("res://scripts/ui/labels.gd")
const TreesView := preload("res://scripts/view/trees.gd")
const SitesView := preload("res://scripts/view/sites.gd")
const DefencesView := preload("res://scripts/view/defences.gd")
const Hud := preload("res://scripts/hud.gd")
const Menus := preload("res://scripts/ui/menus.gd")
const Build := preload("res://scripts/build.gd")
const Atmos := preload("res://scripts/view/atmos.gd")
const SoundNode := preload("res://scripts/audio/sound.gd")

const STEP := 1.0 / 30.0         # the rules run thirty times a second, as in the web version
const SAVE_PATH := "user://dtv-save.json"

# the look of day, night and the moment between
const SUN_DAY := Color(1.0, 0.94, 0.8)
const SUN_NIGHT := Color(0.5, 0.6, 1.0)
const SUN_DUSK := Color(1.0, 0.6, 0.35)
const AMB_DAY := Color(0.62, 0.66, 0.62)
const AMB_NIGHT := Color(0.17, 0.22, 0.4)
const AMB_DUSK := Color(0.6, 0.42, 0.4)
const FOG_DAY := Color(0.8, 0.86, 0.68)
const FOG_NIGHT := Color(0.05, 0.07, 0.13)
const FOG_DUSK := Color(0.9, 0.6, 0.4)
const SUN_FROM_DAY := Vector3(-26, 44, 20)
const SUN_FROM_NIGHT := Vector3(22, 46, -16)
const EDGE := {"hedge": "The thorn hedge. Nothing gets through it, which is how the village got its name.",
	"stakes": "Past the stakes the ground belongs to the castle. Nobody sensible goes further.",
	"river": "The river is too cold and too deep."}

var R: Rules
var me: E.Player
var world: Node3D
var hud: CanvasLayer
var menus
var win: Control                 # the one window in the middle (hud.window)
var camera: Camera3D
var sun: DirectionalLight3D
var env: Environment
var trees_view: Node3D
var sites_view: Node3D
var defences_view: Node3D
var dead_view: Node3D
var minimap: Control
var labels: Control
var atmos: Node3D                # mist, rain, wisps, crows and lightning (only for looking at)

var screen := "home"             # "home" or "game"
static var next_len := D.MONTH   # how long the next new game is: the month (30 nights) or the short game (7)
var _acc := 0.0
var _clock := 0.0
var _atk_cd := 0.0
var _figs := {}                  # "p<id>" or "q<id>" -> figure
var _drops := {}                 # drop id -> node
var _fx: Node3D                  # bits, and things in flight
var _keep_a := 1.0
var _focus := Vector3(0, 0, -4)
var _zoom := 1.0
var _pan_t := -1.0                   # the look up at the castle as night falls: how far through it (-1: not looking)
var _fog_back := 0.0                 # how much further off than usual the camera is, so the haze can keep its distance
var _title_art: TextureRect          # the title screen's picture
# The view can be turned round the player, tilted and brought closer. Each has where it is and where it is going, so it glides.
const CAM_PITCH0 := 0.8672          # the tilt the game began with: looking down from 66 up and 56 back
const CAM_PITCH_MIN := 0.56         # as low as it goes (about 32 degrees), and as near overhead (about 78)
const CAM_PITCH_MAX := 1.36
var _cam_yaw := 0.0                 # 0: from the south, with north up the screen
var _cam_pitch := CAM_PITCH0
var _cam_zoom := 1.0
var _yaw_goal := 0.0
var _pitch_goal := CAM_PITCH0
var _zoom_goal := 1.0
var _prev_phase := ""
var _dawn_seen := -1
var _dawn_t := 0.0
var _weather_forced := false
var _panel := ""                 # which notice is open: a place's id, or "pack"
var _page := ""
var _build_sel := ""
var _ghost: MeshInstance3D
var _ring: MeshInstance3D
var _edge := ""
var _edge_t := 0.0
var _end_t := 0.0
var _end_shown := false
var _frame := 0
var _bot := false
var _home_t := 0.0
var _keep_hc_seen := 0


func _ready() -> void:
	Settings.load_all()
	Keys.setup()
	world = World.new()
	add_child(world)
	_lights()
	camera = Camera3D.new()
	camera.fov = 20.0
	camera.near = 5.0
	camera.far = 520.0
	add_child(camera)
	camera.make_current()
	R = Rules.new()
	R.save_hook = _save
	_fx = Fx.new(); add_child(_fx)
	atmos = Atmos.new(); add_child(atmos); atmos.setup(world)
	add_child(SoundNode.new())
	trees_view = TreesView.new(); trees_view.fx = _fx; add_child(trees_view)
	sites_view = SitesView.new(); add_child(sites_view)
	defences_view = DefencesView.new(); defences_view.fx = _fx; add_child(defences_view)
	dead_view = Dead.new(); dead_view.fx = _fx; add_child(dead_view)
	_ghost = MeshInstance3D.new(); _ghost.mesh = BoxMesh.new(); add_child(_ghost); _ghost.visible = false
	var gm := StandardMaterial3D.new()
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost.material_override = gm
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new(); tm.inner_radius = 0.86; tm.outer_radius = 1.0; tm.rings = 24; tm.ring_segments = 4
	_ring.mesh = tm
	var rm := StandardMaterial3D.new(); rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; rm.albedo_color = Color(1, 0.95, 0.72)
	_ring.material_override = rm
	add_child(_ring)
	hud = Hud.new()
	add_child(hud)
	win = hud.window
	win.closed.connect(_window_closed)
	hud.build_pressed.connect(func(k):
		if screen == "game" and me.state == "ok":
			if k == "contr": _next_contraption()
			else: _build_sel = "" if _build_sel == k else k)
	hud.pack_pressed.connect(func(): if screen == "game" and me.state == "ok": _open_pack())
	hud.menu_pressed.connect(func(): menus.menu())
	hud.skills_pressed.connect(func(): if screen == "game": _open_skills())
	menus = Menus.new(self, win)
	labels = Labels.new()
	labels.camera = camera
	labels.hud = hud
	hud.root.add_child(labels)
	hud.root.move_child(labels, 0)                       # under the readouts
	minimap = Minimap.new()
	hud.map_slot.add_child(minimap)
	minimap.R = R
	labels.R = R
	DisplayServer.window_set_title(D.GAME)
	Net.ensure(get_tree()).attach(self)
	Net.me.changed.connect(_net_changed)
	_bot = OS.get_environment("DTV_BOT") != ""
	var test := OS.get_environment("DTV_LOAD") != "" or OS.get_environment("DTV_NEW") != "" or OS.get_environment("DTV_DEMO") != "" or OS.get_environment("DTV_BOT") != "" or OS.get_environment("DTV_PHASE") != ""
	if Net.me.is_client():                              # a joined game, started again by the host: wait for it
		_home(true)
		menus.lobby()
	elif OS.get_environment("DTV_HOME") == "" and (test or _go_straight):
		_go_straight = false
		begin(null if OS.get_environment("DTV_NEW") != "" or OS.get_environment("DTV_DEMO") != "" else (_go_save if _go_save else read_save()))
	else:
		_home()
		if Net.me.is_host(): menus.lobby()


static var _go_straight := false     # set when the scene is reloaded to start a game straight away
static var _go_save = null


## The saved morning, if there is one that this version can read.
func read_save():
	if not FileAccess.file_exists(SAVE_PATH): return null
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	return d if d is Dictionary and d.get("v") == 3 and d.get("players", []).size() else null


func _save(d: Dictionary) -> void:
	if d.is_empty():                                      # the week is over: nothing to carry on from
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d))


func in_game() -> bool:
	return screen == "game"


# ---------------------------------------------------------------- home and starting
func _home(quiet: bool = false) -> void:
	screen = "home"
	hud.playing(false)
	if _title_art == null:                               # the title picture, behind the menu
		_title_art = TextureRect.new()
		_title_art.texture = load("res://art/title.jpg")
		_title_art.set_anchors_preset(Control.PRESET_FULL_RECT)
		_title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var layer := CanvasLayer.new()
		layer.layer = hud.layer - 1                      # under the readouts and the window
		add_child(layer)
		layer.add_child(_title_art)
	if not quiet: menus.home()


## Hosting or joined: the lobby, or what is happening, has changed.
func _net_changed() -> void:
	if screen != "game" and (win.is_open("lobby") or Net.me.online()):
		menus.lobby.call_deferred()


## A joined game: the host's first picture of the village has arrived. In we go.
func client_enter() -> void:
	me = R.player_by_id(Net.me.my_id)
	if me == null: return
	minimap.me = me
	labels.me = me
	screen = "game"
	hud.playing(true)
	win.close()
	_dawn_seen = -1
	_prev_phase = ""
	_focus = Vector3(me.x, 0, me.z)
	atmos.pick(R.gseed, R.day)


## A joined game: the host is starting again (a new week, or the same day again). Clear the village and wait.
func client_restart() -> void:
	get_tree().reload_current_scene()


## A joined game: the host has gone. Back to the home screen, which says so.
func host_left(_why: String) -> void:   # Net.status says why, on the home screen
	get_tree().reload_current_scene()


## Back to the home screen: start the scene again, clean.
func to_home() -> void:
	if Net.me.online(): Net.me.leave()                   # leaving a game played together leaves the village too
	get_tree().reload_current_scene()


## Start playing: carry on from a saved morning, or (save null) a new village.
func begin(save) -> void:
	if Net.me.is_client(): return                         # only the host starts things
	if screen == "game":                                 # a game is running: start again from a clean scene
		Net.me.restart()
		_go_straight = true
		_go_save = save
		if save == null: DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		get_tree().reload_current_scene()
		return
	var nm: String = Settings.name if Settings.name != "" else "Peasant"
	var info := [{"id": 1, "name": nm, "col": Settings.col}]
	if Net.me.is_host(): info = Net.me.infos()
	if save and not Net.me.is_host():
		info[0].name = save.players[0].name
		info[0].col = int(save.players[0].get("col", Settings.col))
		R.load_game(save, info)
	else:
		R.new_game(info, D.WEEK if OS.get_environment("DTV_SHORT") != "" else next_len)
	_go_save = null
	me = R.player_by_id(Net.me.my_id) if Net.me.is_host() else R.players[0]
	minimap.me = me
	labels.me = me
	screen = "game"
	hud.playing(true)
	win.close()
	_dawn_seen = -1
	_prev_phase = ""
	atmos.pick(R.gseed, R.day)
	if Net.me.is_host(): Net.me.send_roster()
	if OS.get_environment("DTV_PHASE") == "night":       # for testing: go straight to night
		R.dusk_falls(); R.timeLeft = 0.5
	if OS.get_environment("DTV_DEMO") != "":            # for testing: a village with a bit of everything in it, for pictures
		_demo()
	_focus = Vector3(me.x, 0, me.z)


func _dusk_line() -> String:
	match Rules.boss_of(R.day, R.last_day):
		D.U_STEWARD: return "The bell rings. Somebody at the castle is polishing the silver."
		D.U_COACH: return "The bell rings. Far off, a whip cracks, and wheels start to turn."
		D.U_CAPTAIN: return "The bell rings. Up at the castle, someone is shouting orders."
		D.U_LORD: return "The bell rings for the last time this month. The castle doors are open."
	if R.weather == "moon": return "The bell rings. A full moon is up, and something at Ashhollow is howling."
	return ["The bell rings. Something is stirring at Ashhollow Castle.",
		"The bell rings. The castle has hung out its banners, and something green is burning along the walls.",
		"The bell rings. Thorns have come up round Ashhollow, as tall as trees.",
		"The bell rings. The sky over Ashhollow is turning like a millwheel."][Rules.week_of(R.mday()) - 1]


## Start a new game of the given length (D.MONTH or D.WEEK).
func begin_new(nights: int) -> void:
	next_len = nights
	begin(null)


func _demo() -> void:
	_dawn_seen = R.dawn.seq
	for s in R.structs:
		s.built = true; s.mhp = D.SHP[s.k]; s.hp = s.mhp * (0.6 if s.slot == 2 else 1.0); s.re = s.slot == 4
	me.wood = 40; me.bodies = 2; me.bbod = 1; me.food = 6; me.coin = 30; me.stone = 12
	R.try_place(me, "barricade", me.x - 3, me.z - 8, 0)
	R.try_place(me, "spikes", me.x + 3, me.z - 8, 0)
	me.bodies = 2
	me.wpn = 4; me.head = 19; me.body = 22; me.off = 25; me.trk = 28; me.inv = [6, 13, 15]
	me.books[0] = 3; me.books[4] = 7; me.books[6] = 3; me.xp[0] = 300.0; me.spare = 4.6
	for i in 4:
		var q: E.Peasant = R.peasants[i]
		q.owner = me.id; q.state = "follow"; q.armed = i % 2
	R.drop_item(15, me.x + 2, me.z + 2); R.drop_item(7, me.x - 2, me.z + 2)
	for t in R.trees.slice(0, 40): t.set_state(1 if t.i % 3 else 2, 0)
	R.tv += 1
	for i in 8:
		var u := R.spawn_undead(i % 4 if i % 4 != 3 else 0, -2.0 + i * 0.8, -6.0)
		u.state = "walk"
	if OS.get_environment("DTV_CONTR") != "":           # for pictures: one of every contraption, in a row
		me.books[2] = 7; me.holy = 1
		var xs := [-14.0, -9.0, -4.0, 4.0, 9.0, 14.0]
		for i in D.CONTRAPTIONS.size():
			var k: String = D.CONTRAPTIONS[i]
			var s := R.mk_struct(k, xs[i], -12.0 if k != "logs" else -30.0, 0, true, D.SHP[k], D.SHP[k], -1)
			R.structs.append(s)
		R.sv += 1
	if OS.get_environment("DTV_DEAD") != "":            # for pictures: one of every kind of dead, in a row, standing still
		R.undead.clear()
		var ks := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
		for i in ks.size():
			var u := R.spawn_undead(ks[i], 36.0 + i * 2.7 if ks[i] < 10 else 42.0 + (ks[i] - 10) * 7.0, -8.0 if ks[i] < 10 else -16.0)
			u.state = "walk"; u.stun = 999; u.r = 0
		R.boss = null


func _lights() -> void:
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


# ---------------------------------------------------------------- input
func _input(e: InputEvent) -> void:
	# the handbook is waiting for a key to give to an action
	if win.is_open("menu") and menus.rebinding != "" and e is InputEventKey and e.pressed and not e.echo:
		get_viewport().set_input_as_handled()
		menus.take_key(e.physical_keycode)
	# looking around: the mouse wheel pressed in, or the look key held, and the mouse moved
	if screen == "game" and e is InputEventMouseMotion and ((e.button_mask & MOUSE_BUTTON_MASK_MIDDLE) or Keys.held("look")) and not win.is_open("menu"):
		_yaw_goal -= e.relative.x * 0.006
		_pitch_goal = clampf(_pitch_goal + e.relative.y * 0.004, CAM_PITCH_MIN, CAM_PITCH_MAX)


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey or e is InputEventMouseButton) or not e.is_pressed() or e.is_echo():
		return
	if Keys.is_act(e, "mute"):
		Settings.muted = not Settings.muted
		Settings.save()
		Sound.apply_settings()
		hud.banner("Sound off" if Settings.muted else "Sound on", "%s turns it back on." % Keys.name("mute") if Settings.muted else "", 1.2)
		return
	if _pan_t >= 0.0 and _pan_t < 6.0 and (Keys.is_act(e, "attack") or (e is InputEventKey and e.physical_keycode == KEY_ESCAPE)):
		_pan_t = 6.0                                       # seen it: back to the village
		return
	if e is InputEventKey and e.physical_keycode == KEY_ESCAPE:   # closes whatever is open; with nothing open, the handbook
		if win.visible:
			if win.closable: win.close()
		elif _build_sel != "": _build_sel = ""
		elif screen == "game": menus.menu()
		return
	if screen != "game":
		return
	if e is InputEventMouseButton and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		if not win.visible: _zoom_goal = clampf(_zoom_goal * (0.9 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 0.9), 0.5, 1.4)   # the wheel: nearer, further
		return
	if Keys.is_act(e, "cam_reset") and not win.visible:
		_yaw_goal = roundf(_yaw_goal / TAU) * TAU; _pitch_goal = CAM_PITCH0; _zoom_goal = 1.0
		return
	var dg := -1
	if e is InputEventKey and e.physical_keycode >= KEY_0 and e.physical_keycode <= KEY_9:
		dg = e.physical_keycode - KEY_0
	if win.is_open("notice"):
		if dg >= 0: option((dg + 9) % 10)
		elif not Keys.is_act(e, "interact"): _game_key(e, -1)
		return
	if win.is_open("pack"):
		if dg >= 1 and dg <= D.PACK_MAX: inv_do("eq", dg - 1)
		elif Keys.is_act(e, "pack"): win.close()
		else: _game_key(e, -1)
		return
	if win.is_open("skills"):
		if Keys.is_act(e, "skills"): win.close()
		else: _game_key(e, -1)
		return
	if win.is_open("dawn") and (Keys.is_act(e, "interact") or Keys.is_act(e, "ready")):
		win.close()
	if win.visible and win.kind != "dawn":
		return
	_game_key(e, dg)


func _game_key(e: InputEvent, dg: int) -> void:   # the keys that act in the world
	var p := me
	if Keys.is_act(e, "ready") and R.phase == "day":
		p.ready = not p.ready
		if Net.me.is_client(): cmd({"t": "rdy", "v": p.ready})
		hud.banner("Ready for the night" if p.ready else "Not ready after all", "", 1.2)
	if Keys.is_act(e, "skills"):
		_open_skills()
		return
	if p.state != "ok":
		return
	if Keys.is_act(e, "pack"):
		_open_pack()
	elif Keys.is_act(e, "trick") or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT):
		if p.abCd > 0: return
		R.aim_assist(p); cmd({"t": "abl", "r": p.r})
	elif Keys.is_act(e, "swap"):
		var i := -1
		for j in p.inv.size():
			if D.IT[p.inv[j]].s == "w" and Rules.can_use(p, p.inv[j]):
				i = j; break
		if i < 0:
			Sound.play("no"); hud.banner("No other weapon", "There is no weapon in your backpack that you can use.", 1.5)
		else:
			hud.banner(D.it_cap(p.inv[i]), "", 0.8); cmd({"t": "act", "a": "eq", "arg": i})
	elif Keys.is_act(e, "carry"):
		if p.trk != 28 and p.trk != 26:
			Sound.play("no"); hud.banner("Nothing to use", "A slop bucket or a handbell goes here. The ruins have them.", 1.5)
		elif not (p.trk == 26 and p.useCd > 0):
			R.aim_assist(p); cmd({"t": "use", "r": p.r})
	elif Keys.is_act(e, "toilet"):
		if p.tbCd > 0: Sound.play("no"); hud.banner("Not yet", "The posse needs %d more seconds, and a drink of water." % ceili(p.tbCd), 1.3)
		elif not p.posse: Sound.play("no"); hud.banner("No posse", "An emergency toilet break needs a posse.", 1.3)
		else: cmd({"t": "tb"})
	elif Keys.is_act(e, "power1") or Keys.is_act(e, "power2"):
		var i := 0 if Keys.is_act(e, "power1") else 1
		var c := Rules.class_of(p)
		if c < 0:
			Sound.play("no"); hud.banner("No calling", "Powers come from a calling. The Holy Book, in the library, makes you an apprentice priest.", 2.0)
		else:
			var pw: Dictionary = D.CLASSES[c].powers[i]
			var cd: float = p.p1Cd if i == 0 else p.p2Cd
			if Rules.rk(p, D.CLASSES[c].book) < pw.rank: Sound.play("no"); hud.banner("Not yet", "%s comes at rank %d of %s." % [pw.full, pw.rank, D.BOOKS[D.CLASSES[c].book].name], 1.8)
			elif cd > 0: Sound.play("no"); hud.banner("Not yet", "%s is ready again in %d seconds." % [pw.n, ceili(cd)], 1.2)
			else:
				if i == 0: R.aim_assist(p)
				cmd({"t": "pw", "i": i, "r": p.r})
	elif Keys.is_act(e, "orders"):
		if Rules.rk(p, 6) < 3: Sound.play("no"); hud.banner("No orders yet", "Orders need rank 3 of How to Win Peasants and Lead Them.", 1.7)
		else:
			var nxt := (p.order + 1) % 3
			cmd({"t": "ord"}); hud.banner(["Follow me", "Hold here", "Charge!"][nxt], "", 0.9)
	elif Keys.is_act(e, "build"):
		var b := _builds_now()
		var i := b.find(_build_sel)
		_build_sel = b[i + 1] if i + 1 < b.size() else ""
	elif dg >= 1 and dg <= D.BUILDS.size():
		var k: String = D.BUILDS[dg - 1]
		_build_sel = "" if _build_sel == k or not _builds_now().has(k) else k
	elif dg == D.BUILDS.size() + 1:
		_next_contraption()
	elif (Keys.is_act(e, "interact") or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT)) and _build_sel != "":
		_place_ghost()
	elif Keys.is_act(e, "eat"):
		if p.food < 1: Sound.play("no"); hud.banner("You have no food", "The farms and the river have some.", 1.3)
		else: cmd({"t": "eat"})
	elif Keys.is_act(e, "attack") and p.gk == 5:
		cmd({"t": "fish"})


func _builds_now() -> Array:
	return D.BUILDS.filter(func(k): return not D.COST[k].has("bodies") or me.bodies >= D.COST[k].bodies) + _contraptions_now()


func _contraptions_now() -> Array:
	return D.CONTRAPTIONS.filter(func(k): return Rules.can_contr(me, k))


## 5 (or the fifth card): the next contraption you can build, then none.
func _next_contraption() -> void:
	var c := _contraptions_now()
	if c.is_empty():
		Sound.play("no"); hud.banner("No contraptions yet", "Barricades for Beginners teaches them, from rank 1. A box of cogs from the tinker builds one without.", 2.0)
		_build_sel = ""
		return
	var i := c.find(_build_sel)
	_build_sel = c[i + 1] if i + 1 < c.size() else ""


func _ghost_pos() -> Dictionary:
	var rot := roundf(me.r / (PI / 4)) * (PI / 4)
	return {"x": me.x + sin(me.r) * 2.7, "z": me.z + cos(me.r) * 2.7, "rot": rot}


func _place_ghost() -> void:
	var k := _build_sel
	var g := _ghost_pos()
	var c := Rules.cost_of(me, k)
	if not Rules.has(me, c):
		Sound.play("no"); hud.banner("A %s needs %s" % [D.SNAME[k], D.cost_text(c)], "", 1.1)
		return
	if not R.valid_place(k, g.x, g.z, g.rot):
		if D.COST[k].has("bodies") and D.inside_village(g.x, g.z):
			Sound.play("no"); hud.banner("Not inside the village", "The fallen go outside the wall.", 1.5)
		return
	cmd({"t": "bld", "k": k, "x": g.x, "z": g.z, "rot": g.rot})


func _open_pack() -> void:
	if win.is_open("pack"):
		win.close()
		return
	_panel = "pack"
	_page = ""
	_build_sel = ""
	menus.pack(true)


func _open_skills() -> void:
	if win.is_open("skills"):
		win.close()
		return
	_panel = ""
	_build_sel = ""
	menus.skills(true)


func sell_spare() -> void:
	if Net.me.is_client():
		cmd({"t": "sell"})
		return
	var paid := R.sell_spare(me)
	if paid > 0:
		hud.feed("Your spare learning fetched %s." % D.coins(paid))
	menus.skills(true)


## Something our player did. Alone or hosting, it goes straight to the rules; in a joined game, to the host.
func cmd(m: Dictionary) -> void:
	if Net.me.is_client():
		if m.t == "atk": me.ac += 1                  # swing now; the host's answer comes a moment later
		Net.me.send_host(m)
	else:
		Net.apply(R, me, m)


func _window_closed(what: String) -> void:
	if screen == "home":                                  # the handbook, opened from the home screen: back to it (or the lobby)
		if Net.me.online(): menus.lobby.call_deferred()
		else: menus.home.call_deferred()
		return
	if what == "notice" or what == "pack":
		_panel = ""
		_page = ""


## A numbered option in a place's notice.
func option(i: int) -> void:
	if _panel == "" or _panel == "pack" or me == null:
		return
	var d := Notices.data(R, _panel, me, _page)
	if d.is_empty():
		return
	var opts: Array = d.o.filter(func(x): return not x.has("head") and not x.has("text"))
	if i < 0 or i >= opts.size():
		return
	var o: Dictionary = opts[i]
	if not o.ok:
		return
	if o.has("page"):
		_page = o.page
		menus.notice(_panel, _page, true)
	else:
		cmd({"t": "act", "a": o.a, "arg": o.get("arg")})


## Something done in the backpack: put on, put away, drop, bless.
func inv_do(a: String, arg) -> void:
	var p := me
	if a == "eq" and (arg >= p.inv.size()):
		return
	if a == "eq" and not D.SLOTK.has(D.IT[p.inv[arg]].s):                  # a paper: nothing to put on
		hud.banner(D.it_cap(p.inv[arg]), D.IT[p.inv[arg]].note + ".", 3.5)
		return
	if a == "eq" and not Rules.can_use(p, p.inv[arg]):
		Sound.play("no"); hud.banner("Not yet", "%s needs %s. The book is in the library." % [D.it_cap(p.inv[arg]), Notices.book_need(D.IT[p.inv[arg]].need)], 3.0)
		return
	if a == "uneq" and p.get(arg) == 0:
		hud.banner("The pitchfork stays", "It is what you hold when you hold nothing else.", 1.8)
		return
	if a == "uneq" and p.inv.size() >= D.PACK_MAX:
		Sound.play("no"); hud.banner("Your backpack is full", "Drop something, or leave it on the arms rack in the storehouse.", 2.2)
		return
	cmd({"t": "act", "a": a, "arg": arg})


# ---------------------------------------------------------------- the loop
func _process(delta: float) -> void:
	delta = minf(delta, 0.25)
	if _title_art: _title_art.visible = screen == "home"
	if screen == "home":                                 # behind the home screen: a slow look round the village
		_home_t += delta
		var a := _home_t * 0.05
		_focus = Vector3(sin(a) * 14, 0, -4 + cos(a) * 10)
		camera.position = _focus + Vector3(0, 66, 56) * 1.25
		camera.look_at(_focus + Vector3(0, 1, 0))
		trees_view.sync(R, delta)
		sites_view.sync(R)
		_apply_light(0.0)
		atmos.update(delta, 0.0, _focus)
		Sound.me.update(delta, 0.0, _focus, "clear", 0, 0.0, false)
		_test_hook()
		return
	var paused: bool = win.is_open("menu") and R.players.size() == 1 and not Net.me.online()   # alone, the game waits while you read the handbook
	if not paused:
		_acc += delta
		while _acc >= STEP:
			_acc -= STEP
			_tick()
	_draw(delta)
	_hud_update(delta)
	_test_hook()


## One step of the rules, with the player's keys.
func _tick() -> void:
	var p := me
	_clock += STEP
	_atk_cd = maxf(0, _atk_cd - STEP)
	var held_e := Keys.held("interact") and _build_sel == ""
	if _bot: held_e = false
	p.eHold = R.live() and held_e and (p.state == "ok" or p.state == "hide")
	if R.live() and p.state == "ok":
		var mx := 0.0
		var mz := 0.0
		if _bot:
			var v := _bot_move()
			mx = v.x; mz = v.y
		else:
			var ix := (1.0 if Keys.held("right") else 0.0) - (1.0 if Keys.held("left") else 0.0)
			var iz := (1.0 if Keys.held("down") else 0.0) - (1.0 if Keys.held("up") else 0.0)
			mx = ix * cos(_cam_yaw) + iz * sin(_cam_yaw)      # up is away from the camera, whichever way the view is turned
			mz = iz * cos(_cam_yaw) - ix * sin(_cam_yaw)
		var e := R.move_player(p, mx, mz, STEP, _clock)
		if e != "":
			_edge = e; _edge_t = 0.5
		var atk: bool = Keys.held("attack") or (Input.is_action_pressed("dtv_attack_mouse") and _build_sel == "" and not win.visible) or (_bot and R.phase == "night")
		if atk and _atk_cd <= 0 and p.gk != 5:
			var I: Dictionary = D.IT[p.wpn]
			_atk_cd = I.cd * (0.8 if I.rng and Rules.rk(p, 5) >= 5 else 1.0)
			R.aim_assist(p); cmd({"t": "atk", "r": p.r})
	if not Net.me.is_client():                           # a joined game does not run the rules: the host does
		R.step(STEP)
		if Net.me.is_host():
			Net.me.ev_out.append_array(R.ev)
			if Net.me.ev_out.size() > 80: Net.me.ev_out = Net.me.ev_out.slice(-80)
	for ev in R.ev:
		_event(ev)
	R.ev.clear()


## For testing: the player stands inside the north gate and fights whatever comes through.
func _bot_move() -> Vector2:
	var near: E.Undead = null
	var nd := 144.0
	for u in R.undead:
		if u.state == "rise": continue
		var d := D.d2(me.x, me.z, u.x, u.z)
		if d < nd and not R.wall_between(me.x, me.z, u.x, u.z):
			nd = d; near = u
	var goal := Vector2(near.x, near.z) if near else Vector2(0, -17)
	var to := goal - Vector2(me.x, me.z)
	if (near and to.length() < 1.9) or to.length() < 0.6:
		return Vector2.ZERO
	return to


# ---------------------------------------------------------------- what happened
func _event(ev: Array) -> void:   # things that happened this moment, from the rules
	var F = _fx
	match ev[0]:
		"msg": hud.feed(ev[1])
		"ruin": hud.banner("A ruin!", "One of the outer ruins, found. It is on the map now, for everyone.", 2.4); Sound.play("find")
		"arrow": F.fly(ev[1], ev[2], ev[3], ev[4], 0); Sound.play("swing", 0.5, Vector2(ev[1], ev[2]))
		"shot": F.fly(ev[1], ev[2], ev[3], ev[4], ev[5] + 1); Sound.play("swing", 0.5, Vector2(ev[1], ev[2]))
		"raise": F.puff(ev[1], 0.3, ev[2], 14, F.C_GHOST, 3); Sound.play("raise", 0.7, Vector2(ev[1], ev[2]))
		"dig": F.puff(ev[1], 0.2, ev[2], 16, F.C_WOOD, 3); Sound.play("stone", 0.9, Vector2(ev[1], ev[2]))
		"bellring": world.ring_bell(); Sound.play("bell", 1.0)
		"hop": F.puff(ev[1], 0.6, ev[2], 8, F.C_WOOD, 2.5)
		"burn": F.puff(ev[1], 1.2, ev[2], 3, F.C_FIRE, 2.2)
		"door": Sound.play("door", 0.8, Vector2(ev[1], ev[2]))
		"tenant":
			Sound.play("steward", 1.0, Vector2(ev[1], ev[2])); F.ring(ev[1], ev[2], 3.0, 20, F.C_DUST)
			hud.banner("The Previous Tenant", "Something big is getting up out of the rubble, in its nightshirt. Fight it, or run: it will not follow far.", 4.5)
		"chest":
			Sound.play("find"); hud.banner("A chest!", "A messenger lies beside it. He did not make it to Thornhallow. Hold %s to open it." % Keys.name("interact"), 4.0)
		"rider":
			world.rider_come(); Sound.play("hooves", 0.9)
			get_tree().create_timer(3.5).timeout.connect(func(): Sound.play("nail", 0.8))
			get_tree().create_timer(5.6).timeout.connect(func(): Sound.play("hooves", 0.6))
		"knock": Sound.play("knock", 1.0, Vector2(ev[1], ev[2]))
		"jeer": Sound.play("jeer", 1.0, Vector2(ev[1], ev[2]))
		"dummy":
			world.hit_dummy(int(ev[1])); F.puff(ev[2], 1.0, ev[3], 6, F.C_FOOD, 2.5); Sound.play("thump", 0.6, Vector2(ev[2], ev[3]))
		"bark": labels.bark(int(ev[1]), str(ev[2]))
		"pit": F.puff(ev[1], 0.2, ev[2], 14, F.C_WOOD, 3); Sound.play("thump", 1.0, Vector2(ev[1], ev[2])); Sound.play("groan%d" % (randi() % 3), 0.7, Vector2(ev[1], ev[2]))
		"logs":
			for i in 8:
				var f := i / 7.0
				F.puff(lerpf(ev[1], ev[3], f), 0.5, lerpf(ev[2], ev[4], f), 6, F.C_WOOD, 4)
			Sound.play("thump", 1.0, Vector2(ev[1], ev[2])); Sound.play("thunder0", 0.5, Vector2(ev[1], ev[2]))
		"smite": F.beam(ev[1], ev[2]); Sound.play("holy", 1.0, Vector2(ev[1], ev[2])); Sound.play("thunder1", 0.25, Vector2(ev[1], ev[2]))
		"pray": F.ring(ev[1], ev[2], 7, 40, F.C_HOLY); F.puff(ev[1], 1.8, ev[2], 18, F.C_GLAD, 2.5); Sound.play("holy", 0.9, Vector2(ev[1], ev[2])); Sound.play("ring", 0.4, Vector2(ev[1], ev[2]))
		"mist": F.puff(ev[1], 1.0, ev[2], 18, F.C_GHOST, 3.5); Sound.play("raise", 0.5, Vector2(ev[1], ev[2]))
		"smash": F.puff(ev[1], 0.8, ev[2], 16, F.C_WOOD, 5); Sound.play("thump", 1.0, Vector2(ev[1], ev[2]))
		"coin": F.puff(ev[1], 1.4, ev[2], 6, F.C_COIN, 2); Sound.play("coin", 1.0, Vector2(ev[1], ev[2]))
		"forge": F.puff(ev[1], 1.2, ev[2], 10, F.C_SPARK, 3.5); Sound.play("forge", 1.0, Vector2(ev[1], ev[2]))
		"build": F.puff(ev[1], 0.8, ev[2], 8, F.C_WOOD, 3); Sound.play("build", 1.0, Vector2(ev[1], ev[2]))
		"eat": F.puff(ev[1], 1.7, ev[2], 4, F.C_FOOD, 1.5); Sound.play("eat", 0.7, Vector2(ev[1], ev[2]))
		"fish": F.puff(ev[1], 0.3, ev[2], 10, F.C_SPLASH, 3); Sound.play("splash", 1.0, Vector2(ev[1], ev[2]))
		"bite":
			F.puff(R.JETTY.x, 0.2, R.JETTY.z + 2.6, 4, F.C_SPLASH, 1.5)
			if ev[1] == me.id: hud.banner("A bite!", "Press %s" % Keys.name("attack"), 1.0); Sound.play("pop")
		"abl":                                           # a weapon's trick: show where it landed
			var k: String = ev[1]
			var x: float = ev[2]
			var z: float = ev[3]
			var fx_ := sin(ev[4])
			var fz := cos(ev[4])
			match k:
				"smash": F.ring(x + fx_ * 1.6, z + fz * 1.6, 3.2, 22, F.C_DUST); Sound.play("thump", 1.0, Vector2(x, z))
				"flare": F.ring(x, z, 3.4, 30, F.C_FIRE); F.puff(x, 1.4, z, 16, F.C_FIRE, 4.5); Sound.play("swing", 1.0, Vector2(x, z))
				"clang": F.ring(x, z, 4, 18, F.C_SPARK); Sound.play("clang", 1.0, Vector2(x, z))
				"reap", "trip": F.ring(x, z, 2.6, 16, F.C_DUST if k == "trip" else F.C_WOOD); Sound.play("swing", 1.0, Vector2(x, z))
				"parry": F.puff(x + fx_ * 0.6, 1.3, z + fz * 0.6, 5, F.C_SPARK, 1.5); Sound.play("pop", 0.5, Vector2(x, z))
				_: F.puff(x + fx_ * 1.8, 1, z + fz * 1.8, 8, F.C_DUST if k == "bury" else F.C_SPARK, 3); Sound.play("swing", 0.8, Vector2(x, z))
		"parry": F.puff(ev[1], 1.3, ev[2], 10, F.C_SPARK, 4); Sound.play("clang", 0.7, Vector2(ev[1], ev[2]))
		"miss": F.puff(ev[1], 1.6, ev[2], 3, F.C_DUST, 2)
		"splat":
			F.ring(ev[1], ev[2], 4, 24, F.C_HOLY if ev[3] else F.C_POO)
			F.puff(ev[1], 0.4, ev[2], 14, F.C_POO, 4)
			Sound.play("splat", 1.0, Vector2(ev[1], ev[2]))
			if ev[3]: Sound.play("holy", 0.7, Vector2(ev[1], ev[2]))
		"ring": F.ring(ev[1], ev[2], 8, 30, F.C_HOLY); Sound.play("ring", 1.0, Vector2(ev[1], ev[2]))
		"holy": F.puff(ev[1], 1.4, ev[2], 12, F.C_HOLY, 2.5); Sound.play("holy", 1.0, Vector2(ev[1], ev[2]))
		"burst":
			F.ring(ev[1], ev[2], 3, 20, F.C_ALE)
			F.puff(ev[1], 1, ev[2], 14, F.C_WOOD, 5)
			Sound.play("cheer", 1.0, Vector2(ev[1], ev[2]))
		"found":
			F.puff(ev[3], 0.5, ev[4], 20 if ev[5] else 6, F.C_HOLY if ev[5] else F.C_DUST, 3)
			if ev[1] == me.id:
				Sound.play("relic" if ev[5] else "find")
				hud.banner("A find!" if ev[5] else "You found", str(ev[2]) + (". It is in your backpack: %s opens it." % Keys.name("pack") if ev[6] else ""), 3.8 if ev[5] else 2.8)
		"gone":
			dead_view.gone(ev[2], ev[3], ev[4], ev[5])
			Sound.play("steward" if ev[5] == 3 else "bone" if ev[5] else "hit", 0.8, Vector2(ev[3], ev[4]))


# ---------------------------------------------------------------- drawing
func shake_tree_near(x: float, z: float) -> void:   # a figure chopped: the tree it is chopping shivers
	trees_view.shake_near(x, z)


func _fig(key: String, player: bool) -> Node3D:
	var f = _figs.get(key)
	if f == null:
		f = Figure.new()
		f.is_player = player
		f.fx = _fx
		add_child(f)
		_figs[key] = f
	return f


func _draw(delta: float) -> void:
	var live := {}
	for p: E.Player in R.players:
		var key := "p%d" % p.id
		live[key] = true
		var pf = _fig(key, true)
		pf.dark = 1.0 if p.room == "mine" else R.nf
		pf.player(p, p == me)
	for q: E.Peasant in R.peasants:
		var key := "q%d" % q.id
		live[key] = true
		_fig(key, false).peasant(q, R.player_by_id(q.owner))
	for key in _figs.keys():
		if not live.has(key):
			_figs[key].queue_free()
			_figs.erase(key)
	dead_view.sync(R, delta)
	# things lying on the ground, which glint
	var seen_d := {}
	for d: E.Drop in R.drops:
		seen_d[d.id] = true
		var I: Dictionary = D.IT[d.it]
		if not _drops.has(d.id):
			var n := MeshInstance3D.new()
			n.mesh = Models.get_mesh(Models.gear_pool(d.it))
			var m := StandardMaterial3D.new()
			m.vertex_color_use_as_albedo = true
			m.albedo_color = Color(I.tint[0], I.tint[1], I.tint[2])
			n.material_override = m
			add_child(n)
			if I.s == "w":
				n.position = Vector3(d.x, 0.12, d.z - 0.5); n.rotation = Vector3(PI / 2, d.id, 0)
			else:
				n.position = Vector3(d.x + (0.0 if I.s == "h" else 0.5), -1.25 if I.s == "h" else -0.4 if I.s == "t" else -0.3, d.z); n.rotation.y = d.id
			_drops[d.id] = n
		if randf() < delta * (6.0 if I.tier == "relic" else 1.5):
			_fx.puff(d.x, 0.3, d.z, 1, _fx.C_HOLY if I.tier == "relic" else _fx.C_SPARK, 0.5)
	for id in _drops.keys():
		if not seen_d.has(id):
			_drops[id].queue_free()
			_drops.erase(id)
	trees_view.sync(R, delta)
	sites_view.sync(R)
	defences_view.sync(R, delta)
	# the keep hides whatever is just north of it from this camera: it goes see-through when there is something there to see
	var see := false
	if Settings.see_keep and D.d2(_focus.x, _focus.z, D.KEEP_X, D.KEEP_Z) < 400:
		var fwd := Vector2(-sin(_cam_yaw), -cos(_cam_yaw))     # the way the camera looks, along the ground
		var hid := func(e) -> bool:
			var v := Vector2(e.x - D.KEEP_X, e.z - D.KEEP_Z)
			var back := v.dot(fwd)
			return absf(v.dot(Vector2(-fwd.y, fwd.x))) < D.KEEP_H + 2 and back > -D.KEEP_H and back < D.KEEP_H + 9
		see = R.undead.any(func(u): return D.d2(u.x, u.z, D.KEEP_X, D.KEEP_Z) < 90) \
			or R.players.any(func(p): return (p.state == "ok" or p.state == "down") and hid.call(p)) \
			or R.drops.any(hid) or R.peasants.any(func(q): return q.state == "body" and hid.call(q))
	_keep_a = lerpf(_keep_a, 0.3 if see else 1.0, minf(1.0, delta * 7))
	if not see and _keep_a > 0.985: _keep_a = 1.0
	world.keep_alpha(_keep_a)
	world.letter_paper.visible = R.letters.size() > 0
	# the ring under whatever holding E would work on, and the ghost of a thing being placed
	var it = R.find_interact(me) if _build_sel == "" and R.live() and me.state == "ok" else null
	_ring.visible = it != null
	if it:
		var rad: float = it.rad
		_ring.position = Vector3(it.x, 0.12, it.z)
		_ring.rotation.y = it.get("rot", 0.0)
		_ring.scale = Vector3(rad, 1, 1.0 if it.get("wide", false) else rad)
		(_ring.material_override as StandardMaterial3D).albedo_color = Color(1, 0.95, 0.72) if it.ok else Color(0.9, 0.5, 0.4)
		if it.type == "station" and Keys.held("interact") and _panel != it.st.id:
			_panel = it.st.id; _page = ""
	if _build_sel != "" and (me.state != "ok" or not _builds_now().has(_build_sel)):
		_build_sel = ""
	_ghost.visible = _build_sel != ""
	if _ghost.visible:
		var g := _ghost_pos()
		var dim: Vector2 = D.SDIM[_build_sel]
		(_ghost.mesh as BoxMesh).size = Vector3(dim.x * 2, 1.2, dim.y * 2)
		_ghost.position = Vector3(g.x, 0.6, g.z)
		_ghost.rotation.y = g.rot
		var ok := Rules.has(me, Rules.cost_of(me, _build_sel)) and R.valid_place(_build_sel, g.x, g.z, g.rot)
		(_ghost.material_override as StandardMaterial3D).albedo_color = Color(0.6, 0.95, 0.5, 0.45) if ok else Color(0.95, 0.4, 0.35, 0.45)
	_camera(delta)
	_apply_light(R.nf)
	if not _weather_forced: atmos.weather = R.weather
	atmos.update(delta, R.nf, _focus)
	var near := 0
	for u: E.Undead in R.undead:
		if D.d2(u.x, u.z, _focus.x, _focus.z) < 22 * 22: near += 1
	Sound.me.update(delta, R.nf, _focus, atmos.weather, near, atmos.flash, R.live())
	if R.keepHc != _keep_hc_seen:
		_keep_hc_seen = R.keepHc
		if R.phase == "night": Sound.play("keep", 0.5)
	labels.focus = _focus


func _apply_light(nf: float) -> void:
	var k := 4.0 * nf * (1.0 - nf)                       # peaks at the moment of dusk
	var gl: float = atmos.gloom() if atmos else 0.0      # the weather: overcast, rain or mist take the shine off the day
	var fl: float = atmos.flash if atmos else 0.0        # lightning over the castle
	sun.light_color = SUN_DAY.lerp(SUN_NIGHT, nf).lerp(SUN_DUSK, k * 0.7).lerp(Color(0.78, 0.8, 0.84), gl * (1 - nf)).lerp(Color(0.85, 0.9, 1.0), fl)
	var moon := 1.0 if atmos and atmos.weather == "moon" else 0.0   # the full moon lights the night up silver
	var foggy := 1.0 if atmos and atmos.weather == "fog" else 0.0   # fog closes in at night: the castle road disappears
	sun.light_color = sun.light_color.lerp(Color(0.75, 0.85, 1.0), moon * nf)
	sun.light_energy = lerpf(0.8 - gl * 0.45, 0.34 + moon * 0.3, nf) + fl * 1.6
	sun.position = SUN_FROM_DAY.lerp(SUN_FROM_NIGHT, nf)
	sun.look_at(Vector3.ZERO)
	env.ambient_light_color = AMB_DAY.lerp(AMB_NIGHT, nf).lerp(AMB_DUSK, k * 0.7)
	env.ambient_light_energy = lerpf(0.32 - gl * 0.06, 0.5, nf) + fl * 0.5
	var fog := FOG_DAY.lerp(Color(0.48, 0.52, 0.54), gl).lerp(FOG_NIGHT, nf).lerp(FOG_DUSK, k * 0.7).lerp(Color(0.6, 0.65, 0.8), fl * 0.6)
	var back := _fog_back if screen == "game" else 0.0   # the haze keeps its distance from the player, not from the camera, when the view is brought nearer or taken further off
	env.fog_depth_begin = maxf(5.0, lerpf(95.0 - gl * 15.0, 70.0 - foggy * 50.0, nf) + back)
	env.fog_depth_end = lerpf(250.0 - gl * 40.0, 190.0 - foggy * 130.0, nf) + back
	env.adjustment_saturation = lerpf(1.1 - gl * 0.25, 0.8, nf)
	env.background_color = fog
	env.fog_light_color = fog
	var lit := smoothstep(0.3, 0.8, nf)                  # windows and lanterns come on as it gets dark
	world.window_mat.emission_energy_multiplier = 2.6 * lit
	world.window_mat.albedo_color = Color("3a3f52").lerp(Color("ffe6a8"), lit)
	world.keep_window_mat.emission_energy_multiplier = 2.6 * lit
	var kw := Color("3a3f52").lerp(Color("ffe6a8"), lit)
	kw.a = world.keep_window_mat.albedo_color.a
	world.keep_window_mat.albedo_color = kw
	for l in world.lanterns:
		l.light_energy = 2.4 * lit
	if screen == "game" and me and me.room == "mine":   # underground: no sun, no sky, no haze. What light there is, you brought
		sun.light_energy = 0.0
		env.ambient_light_color = Color(0.3, 0.27, 0.42)
		env.ambient_light_energy = 0.09
		env.background_color = Color(0.02, 0.02, 0.03)
		env.fog_light_color = env.background_color
		env.fog_depth_begin = 400.0
		env.fog_depth_end = 500.0
		env.adjustment_saturation = 1.0


## The view: looking down on the player, from the south to begin with (as in the web version). It can be turned
## round the player (the turn keys, or the mouse with the wheel pressed or the look key held), tilted, and zoomed.
func _camera(delta: float) -> void:
	var indoors: bool = me.room != ""
	if Vector2(me.x - _focus.x, me.z - _focus.z).length() > 60.0:      # through a door: the view goes with you at once
		_focus = Vector3(me.x, 0, me.z); _zoom = 0.38 if indoors else 1.0 + 0.12 * R.nf
	_focus = _focus.lerp(Vector3(me.x, 0, me.z), minf(1.0, delta * 6.0))
	_zoom = lerpf(_zoom, 0.38 if indoors else 1.0 + 0.12 * R.nf, minf(1.0, delta * 3.0))
	if indoors: _pan_t = -1.0
	world.set_veins(R.rune_left)
	atmos.indoors = indoors
	if not win.is_open("menu"):
		_yaw_goal += ((1.0 if Keys.held("cam_right") else 0.0) - (1.0 if Keys.held("cam_left") else 0.0)) * delta * 2.2
	var k := minf(1.0, delta * 14.0)
	_cam_yaw = lerpf(_cam_yaw, _yaw_goal, k); _cam_pitch = lerpf(_cam_pitch, _pitch_goal, k); _cam_zoom = lerpf(_cam_zoom, _zoom_goal, k)
	var dist := 108.2 * _zoom * _cam_zoom
	var look := _focus + Vector3(0, 1, 0)
	var yaw := _cam_yaw
	var pitch := _cam_pitch
	var pk := 0.0
	if _pan_t >= 0.0:                                     # night is falling: a long look up the road at Ashhollow, then back
		const UP := 2.6
		const HOLD := 3.4
		const DOWN := 2.2
		var before := _pan_t
		_pan_t += delta
		if before < UP and _pan_t >= UP:                  # as the castle comes into view, it answers
			atmos.flash = 1.0; Sound.play("thunder0", 0.9)
		pk = smoothstep(0.0, UP, _pan_t) if _pan_t < UP + HOLD else 1.0 - smoothstep(0.0, DOWN, _pan_t - UP - HOLD)
		if _pan_t >= UP + HOLD + DOWN or R.phase == "day" or not R.live():
			_pan_t = -1.0; pk = 0.0
		look = look.lerp(Vector3(0, 18.0, -113.0), pk)
		yaw = lerp_angle(wrapf(yaw, -PI, PI), 0.0, pk)
		pitch = lerpf(pitch, 0.22, pk)
		dist = lerpf(dist, 158.0, pk)
	labels.visible = pk < 0.05
	_fog_back = dist - 108.2 * _zoom + 70.0 * pk
	camera.position = look + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	camera.look_at(look)
	minimap.view = _cam_yaw
	world.night = R.nf
	world.set_evil(Rules.week_of(R.mday()) - 1)
	atmos.evil = Rules.week_of(R.mday()) - 1


# ---------------------------------------------------------------- the readouts and the window
func _hud_update(delta: float) -> void:
	var p := me
	var ph := R.phase
	if ph != _prev_phase:
		_prev_phase = ph
		match ph:
			"day":
				_end_shown = false
			"dusk":
				Sound.play("bell")
				hud.banner("Dusk", _dusk_line(), 6.5 if Settings.castle_pan else 5.0)
				if Settings.castle_pan and not _bot and OS.get_environment("DTV_SHOT") == "" and me.room == "": _pan_t = 0.0
				if win.is_open("dawn"): win.close()
			"night":
				hud.banner("Night %d" % R.day, "The dead are rising all along the graveyard, and some have brought bows." if R.day >= 4 else "The dead are rising all along the graveyard.", 4.5)
			"won", "lost":
				_end_t = 2.2
				Sound.play("won" if ph == "won" else "lost")
	if (ph == "won" or ph == "lost") and not _end_shown:
		_end_t -= delta
		if _end_t <= 0:
			_end_shown = true
			_build_sel = ""; _panel = ""
			menus.ending(ph == "won")
	if R.dawn.seq != _dawn_seen and ph == "day":         # a new morning: the dawn notice
		_dawn_seen = R.dawn.seq
		hud.banner("Day %d" % R.dawn.day, "", 2.6)
		if R.dawn.lines.size() and not win.is_open("menu"):
			_panel = ""
			atmos.pick(R.gseed, R.dawn.day)
			if R.dawn.day > 1: Sound.play("dawn")
			menus.dawn(R.dawn.day, R.dawn.lines + ([D.WEATHER_LINE[R.weather]] if D.WEATHER_LINE.get(R.weather, "") != "" else []))
			_dawn_t = 15.0
	if win.is_open("dawn"):
		_dawn_t -= delta
		if _dawn_t <= 0 or ph != "day": win.close()
	# a place's notice: open while you are beside it (and always, inside the Rose)
	if p.state == "inn" and R.live() and not win.is_open("menu") and not win.is_open("end"):
		_panel = "inn"
	if _panel != "" and _panel != "pack":
		var st := D.station(_panel)
		var near: bool = p.state == "inn" or (p.state == "ok" and not st.is_empty() and D.d2(p.x, p.z, st.x, st.z) <= pow(st.r + 1.6, 2))
		if not near or not R.live():
			_panel = ""; _page = ""
			if win.is_open("notice"): win.close()
		elif not win.visible or win.kind == "notice" or win.kind == "pack" or win.kind == "dawn":
			menus.notice(_panel, _page)
			if _panel == "letter" and R.letter_new and win.is_open("notice"):   # it has been read: take the "new" off it
				R.letter_new = false; cmd({"t": "act", "a": "lread"})
	elif win.is_open("notice"):
		win.close()
	if _panel == "pack":
		if p.state != "ok" or not R.live(): win.close()
		elif win.is_open("pack"): menus.pack()
	if win.is_open("skills"): menus.skills()
	# the prompt: what holding E would do
	var it = R.find_interact(p) if _build_sel == "" and R.live() else null
	var ptxt := ""
	if it and not (it.type == "station" and _panel != ""):
		ptxt = it.label
	if ptxt == "" and p.state == "ok" and _edge_t > 0:
		ptxt = EDGE.get(_edge, "")
	_edge_t -= delta
	if p.state == "down": ptxt = "You are down. A team-mate can revive you for %d more seconds." % ceili(p.downT)
	elif p.state == "dead": ptxt = "You are dead. A relative arrives at dawn."
	elif _build_sel != "": ptxt = "Press {interact} or click to place a %s (%s). {build} changes, Esc cancels." % [D.SNAME[_build_sel], D.cost_text(Rules.cost_of(p, _build_sel))]
	var rd := R.players.filter(func(o): return o.ready).size()
	var ready_line := ""
	if ph == "day":
		ready_line = ("You are ready (%d of %d). %s to change your mind." % [rd, R.players.size(), Keys.name("ready")]) if p.ready else "Press %s when you are ready for the night." % Keys.name("ready")
	hud.update(R, p, ptxt, p.prog if it and it.ok and p.gk != 5 else 0.0, it == null or it.ok, _build_sel, ready_line)


## For testing from the command line: DTV_SHOT=file.png saves a picture after DTV_SHOT_AT frames and stops.
## DTV_AT=x,z puts the player there first. DTV_LOG=1 prints how the night is going every ten seconds.
func _test_hook() -> void:
	_frame += 1
	if OS.get_environment("DTV_PAN") != "":         # for pictures: DTV_PAN=day holds the look up at the castle, as on that day
		R.day = int(OS.get_environment("DTV_PAN"))
		if R.phase != "day": _pan_t = 4.0
	if OS.get_environment("DTV_VIEW") != "":        # for pictures: DTV_VIEW=turn,tilt,zoom (degrees, degrees, times) turns the player's view
		var vw := OS.get_environment("DTV_VIEW").split(",")
		_yaw_goal = deg_to_rad(float(vw[0])); _pitch_goal = deg_to_rad(float(vw[1])); _zoom_goal = float(vw[2])
	if OS.get_environment("DTV_CAM") != "":         # for pictures: DTV_CAM=x,y,z,lookx,looky,lookz puts the camera there
		var c := OS.get_environment("DTV_CAM").split(",")
		camera.fov = 40.0
		camera.position = Vector3(float(c[0]), float(c[1]), float(c[2]))
		camera.look_at(Vector3(float(c[3]), float(c[4]), float(c[5])))
	if OS.get_environment("DTV_LOG") != "" and _frame % 600 == 0 and me:
		print("t=", floori(_frame / 60.0), "s ", R.phase, " day ", R.day, " undead ", R.undead.size(), " to rise ", R.wave, " kills ", R.stats.kills, " keep ", roundi(R.keepHp), " player ", me.state, " hp ", roundi(me.hp), " posse ", me.posse)
	var shot := OS.get_environment("DTV_SHOT")
	if shot == "":
		return
	var at := int(OS.get_environment("DTV_SHOT_AT")) if OS.get_environment("DTV_SHOT_AT") != "" else 60
	if OS.get_environment("DTV_TORCH") != "" and me: me.wpn = D.I_TORCH     # for pictures: a torch in hand
	if OS.get_environment("DTV_ROOM") != "" and _frame == at + 2 and me:      # for pictures: indoors, at DTV_ROOM=name[,x,z]
		var rm := OS.get_environment("DTV_ROOM").split(",")
		R.enter_room(me, rm[0])
		if rm.size() >= 3:
			me.x = float(rm[1]); me.z = float(rm[2])
	if OS.get_environment("DTV_BURN") != "" and _frame == at + 2 and me:      # for pictures: a few of the dead, alight
		for i in 5:
			var bu := R.spawn_undead(i % 2, me.x - 4.0 + i * 2.0, me.z - 3.0 - (i % 2))
			bu.state = "walk"; bu.stun = 999; bu.burn = 99.0; bu.bt = 99.0
	if OS.get_environment("DTV_FINDS") != "" and _frame == at + 2 and me:   # for pictures: the Previous Tenant and the lost chest, beside the player
		R.chest = {"x": me.x + 3.0, "z": me.z - 2.0, "from": 0, "road": 0, "seen": true, "open": false, "rot": 0.4}
		var tn := R.spawn_undead(D.U_TENANT, me.x - 3.5, me.z - 2.5)
		tn.state = "walk"; tn.stun = 999; tn.r = 0.3
		var sh := R.spawn_undead(0, me.x - 6.0, me.z - 2.5)
		sh.state = "walk"; sh.stun = 999; sh.r = 0.2
	if OS.get_environment("DTV_BAILIFF") != "" and _frame == at + 10:   # for pictures: Robert Bailiff, talking
		R.bail_line = D.BAILIFF_TALK[0][1]; R.bail_t = 30.0
	if OS.get_environment("DTV_LETTER") != "" and R.letters.is_empty():   # for pictures: letters from the castle, and the rider at DTV_LETTER frames
		for i in [0, 6, 5]: R.letters.append([i, R.letters.size() * 2 + 2])
		R.letter_new = true
	if OS.get_environment("DTV_LETTER") == "hold": world._rider_t = 4.0      # the rider, waiting at the gate
	elif OS.get_environment("DTV_LETTER") != "" and _frame == int(OS.get_environment("DTV_LETTER")): world.rider_come()
	if OS.get_environment("DTV_MERCHANT") != "" and _frame == 2:   # for pictures: a merchant in
		R.merchant = int(OS.get_environment("DTV_MERCHANT")); R.make_wares()
	if OS.get_environment("DTV_PRIEST") != "" and me:     # for pictures: an apprentice priest, smiting and praying
		if _frame == 2:
			me.books[D.B_HOLY] = 6; me.books[6] = 3; me.xp[D.B_HOLY] = 700.0; me.xslot = true
		if _frame == at + 24:
			me.p1Cd = 0; me.p2Cd = 0; R.do_power(me, 0); R.do_power(me, 1)
	if _frame == at and OS.get_environment("DTV_AT") != "" and me:
		var xz := OS.get_environment("DTV_AT").split(",")
		me.x = float(xz[0]); me.z = float(xz[1])
	if _frame == at and OS.get_environment("DTV_OPEN") != "":   # open a window for the picture
		var o := OS.get_environment("DTV_OPEN")
		if o == "pack": _open_pack()
		elif o == "skills": _open_skills()
		elif o == "host": Net.me.host("Matt", 2); menus.lobby()
		elif o == "none": win.close()
		elif o.begins_with("weather:"): R.weather = o.substr(8); atmos.weather = R.weather; _weather_forced = true; win.close()
		elif o == "menu": menus.menu()
		elif o == "keys": menus.menu("keys")
		elif o == "dawn": menus.dawn(R.day, R.dawn.lines); _dawn_t = 99.0
		elif o == "end": menus.ending(true)
		elif o.begins_with("notice:"):
			var st := D.station(o.substr(7))
			me.x = st.x; me.z = st.z
			_panel = st.id
	if _frame == at + 30:
		get_viewport().get_texture().get_image().save_png(shot)
		print("screen ", screen, " phase ", R.phase, " day ", R.day, " undead ", R.undead.size(), " window ", win.kind)
		get_tree().quit()
