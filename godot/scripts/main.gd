extends Node3D
## Defend the Village!  The game in Godot.
##
## The rules (scripts/rules/) run the game: days and nights, gathering, building, books, items, the inn,
## the priest, the ruins and the dead. Everything here only shows what the rules say and passes on what
## the player presses. Everything is made in code, so there is nothing to wire up in the editor.

const World := preload("res://scripts/world.gd")
const Figure := preload("res://scripts/view/figure.gd")
const Dead := preload("res://scripts/view/dead.gd")
const TreesView := preload("res://scripts/view/trees.gd")
const SitesView := preload("res://scripts/view/sites.gd")
const DefencesView := preload("res://scripts/view/defences.gd")
const Hud := preload("res://scripts/hud.gd")
const Build := preload("res://scripts/build.gd")

const STEP := 1.0 / 30.0         # the rules run thirty times a second, as in the web version
const SAVE_PATH := "user://dtv-save.json"

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
const EDGE := {"hedge": "The thorn hedge. Nothing gets through it, which is how the village got its name.",
	"stakes": "Past the stakes the ground belongs to the castle. Nobody sensible goes further.",
	"river": "The river is too cold and too deep."}

var R: Rules
var me: E.Player
var world: Node3D
var hud: CanvasLayer
var camera: Camera3D
var sun: DirectionalLight3D
var env: Environment
var trees_view: Node3D
var sites_view: Node3D
var defences_view: Node3D

var _acc := 0.0
var _clock := 0.0
var _atk_cd := 0.0
var _figs := {}                  # "p<id>" or "q<id>" -> figure
var _seen := {}                  # figure key -> [ac, hc]
var _deads := {}                 # undead id -> node
var _drops := {}                 # drop id -> node
var _fx: Node3D                  # shots, arrows and the like, which fade on their own
var _focus := Vector3(0, 0, -4)
var _zoom := 1.0
var _prev_phase := ""
var _dawn_seen := -1
var _panel := ""                 # which notice is open: a place's id, or "pack"
var _page := ""
var _build_sel := ""
var _ghost: MeshInstance3D
var _ring: MeshInstance3D
var _edge := ""
var _edge_t := 0.0
var _started := false
var _end_t := 0.0
var _frame := 0
var _bot := false


func _ready() -> void:
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
	trees_view = TreesView.new(); add_child(trees_view)
	sites_view = SitesView.new(); add_child(sites_view)
	defences_view = DefencesView.new(); add_child(defences_view)
	_fx = Node3D.new(); add_child(_fx)
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
	hud.option.connect(_option)
	_bot = OS.get_environment("DTV_BOT") != ""
	_start()


## Carry on from the saved morning if there is one, or start a new village. (The home screen comes with the menus stage.)
func _start() -> void:
	var info := [{"id": 1, "name": "Peasant", "col": 0}]
	var saved = null
	if FileAccess.file_exists(SAVE_PATH) and OS.get_environment("DTV_NEW") == "":
		saved = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if saved is Dictionary and saved.get("v") == 3 and saved.get("players", []).size():
		info[0].name = saved.players[0].name
		R.load_game(saved, info)
		hud.feed("Carrying on from the morning of day %d. (Start the game with DTV_NEW=1 for a new village.)" % R.day)
	else:
		R.new_game(info)
	me = R.players[0]
	if OS.get_environment("DTV_PHASE") == "night":       # for testing: go straight to night
		R.dusk_falls(); R.timeLeft = 0.5
	_focus = Vector3(me.x, 0, me.z)
	_started = true


func _save(d: Dictionary) -> void:
	if d.is_empty():                                      # the week is over: nothing to carry on from
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d))


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
func _unhandled_input(e: InputEvent) -> void:
	if not _started or not (e is InputEventKey or e is InputEventMouseButton) or not e.is_pressed() or e.is_echo():
		return
	if e is InputEventKey and e.physical_keycode == KEY_ESCAPE:   # closes whatever is open
		if hud.dawn_open(): hud.close_dawn()
		elif _build_sel != "": _build_sel = ""
		elif _panel != "" and me.state != "inn": _panel = ""
		else: get_tree().quit()
		return
	var p := me
	if Keys.is_act(e, "ready") and R.phase == "day":
		p.ready = not p.ready
		hud.close_dawn()
		hud.banner("Ready for the night" if p.ready else "Not ready after all", "", 1.2)
	var dg := -1
	if e is InputEventKey and e.physical_keycode >= KEY_0 and e.physical_keycode <= KEY_9:
		dg = e.physical_keycode - KEY_0
	if dg >= 0 and _panel != "":
		_option((dg + 9) % 10)
		return
	if p.state != "ok":
		return
	if Keys.is_act(e, "pack"):
		_open("pack")
	elif Keys.is_act(e, "trick") or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT):
		if p.abCd > 0: return
		R.aim_assist(p); R.do_ability(p)
	elif Keys.is_act(e, "swap"):
		var i := -1
		for j in p.inv.size():
			if D.IT[p.inv[j]].s == "w" and Rules.can_use(p, p.inv[j]):
				i = j; break
		if i < 0:
			hud.banner("No other weapon", "There is no weapon in your pack that you can use.", 1.5)
		else:
			hud.banner(D.it_cap(p.inv[i]), "", 0.8); R.do_act(p, "eq", i)
	elif Keys.is_act(e, "carry"):
		if p.trk != 28 and p.trk != 26:
			hud.banner("Nothing to use", "A slop bucket or a handbell goes here. The ruins have them.", 1.5)
		elif not (p.trk == 26 and p.useCd > 0):
			R.aim_assist(p); R.do_use(p)
	elif Keys.is_act(e, "toilet"):
		if p.tbCd > 0: hud.banner("Not yet", "The posse needs %d more seconds, and a drink of water." % ceili(p.tbCd), 1.3)
		elif not p.posse: hud.banner("No posse", "An emergency toilet break needs a posse.", 1.3)
		else: R.do_toilet(p)
	elif Keys.is_act(e, "orders"):
		if Rules.rk(p, 6) < 3: hud.banner("No orders yet", "Orders need rank 3 of How to Win Peasants and Lead Them.", 1.7)
		else:
			R.do_order(p); hud.banner(["Follow me", "Hold here", "Charge!"][p.ord], "", 0.9)
	elif Keys.is_act(e, "build"):
		var b := _builds_now()
		var i := b.find(_build_sel)
		_build_sel = b[i + 1] if i + 1 < b.size() else ""
		_panel = ""
	elif dg >= 1 and dg <= D.BUILDS.size():
		var k: String = D.BUILDS[dg - 1]
		_build_sel = "" if _build_sel == k or not _builds_now().has(k) else k
		_panel = ""
	elif (Keys.is_act(e, "interact") or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT)) and _build_sel != "":
		_place_ghost()
	elif Keys.is_act(e, "eat"):
		if p.food < 1: hud.banner("You have no food", "The farms and the river have some.", 1.3)
		else: R.do_eat(p)
	elif Keys.is_act(e, "attack") and p.gk == 5:
		R.do_fish(p)


func _builds_now() -> Array:
	return D.BUILDS.filter(func(k): return not D.COST[k].has("bodies") or me.bodies >= D.COST[k].bodies)


func _ghost_pos() -> Dictionary:
	var rot := roundf(me.r / (PI / 4)) * (PI / 4)
	return {"x": me.x + sin(me.r) * 2.7, "z": me.z + cos(me.r) * 2.7, "rot": rot}


func _place_ghost() -> void:
	var k := _build_sel
	var g := _ghost_pos()
	var c := Rules.cost_of(me, k)
	if not Rules.has(me, c):
		hud.banner("A %s needs %s" % [D.SNAME[k], D.cost_text(c)], "", 1.1)
		return
	if not R.valid_place(k, g.x, g.z, g.rot):
		if D.COST[k].has("bodies") and D.inside_village(g.x, g.z):
			hud.banner("Not inside the village", "The fallen go outside the wall.", 1.5)
		return
	R.try_place(me, k, g.x, g.z, g.rot)


func _open(id: String) -> void:
	_panel = "" if _panel == id else id
	_page = ""
	_build_sel = ""


func _option(i: int) -> void:   # a numbered option in the open notice
	if _panel == "" or me == null:
		return
	if _panel == "pack" and _page == "" and i < me.inv.size():
		if not Rules.can_use(me, me.inv[i]):
			hud.banner("Not yet", "%s needs %s. The book is in the library." % [D.it_cap(me.inv[i]), Notices.book_need(D.IT[me.inv[i]].need)], 3.0)
			return
	var d := Notices.data(R, _panel, me, _page)
	if d.is_empty():
		return
	var opts: Array = d.o.filter(func(o): return not o.has("head"))
	if i < 0 or i >= opts.size():
		return
	var o: Dictionary = opts[i]
	if not o.ok:
		return
	if o.has("page"):
		_page = o.page
	else:
		R.do_act(me, o.a, o.get("arg"))


# ---------------------------------------------------------------- the loop
func _process(delta: float) -> void:
	if not _started:
		return
	delta = minf(delta, 0.25)
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
			mx = (1.0 if Keys.held("right") else 0.0) - (1.0 if Keys.held("left") else 0.0)
			mz = (1.0 if Keys.held("down") else 0.0) - (1.0 if Keys.held("up") else 0.0)
		var e := R.move_player(p, mx, mz, STEP, _clock)
		if e != "":
			_edge = e; _edge_t = 0.5
		var atk: bool = Keys.held("attack") or (Input.is_action_pressed("dtv_attack_mouse") and _build_sel == "" and not hud.notice_open()) or (_bot and R.phase == "night")
		if atk and _atk_cd <= 0 and p.gk != 5:
			var I: Dictionary = D.IT[p.wpn]
			_atk_cd = I.cd * (0.8 if I.rng and Rules.rk(p, 5) >= 5 else 1.0)
			R.aim_assist(p); R.do_attack(p)
	R.step(STEP)
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
func _event(ev: Array) -> void:
	match ev[0]:
		"msg":
			hud.feed(ev[1])
		"shot":                                          # a stone, an arrow, a bolt, a bucket
			_tracer(Vector3(ev[1], 1.2, ev[2]), Vector3(ev[3], 1.0, ev[4]), [Color("d8cfb8"), Color("f0e2b0"), Color("c2a46a"), Color("8a6a40")][clampi(ev[5], 0, 3)])
		"arrow":
			_tracer(Vector3(ev[1], 1.3, ev[2]), Vector3(ev[3], 1.0, ev[4]), Color("ff9a5a"))
		"found":
			if ev[1] == me.id:
				hud.banner("Found: " + str(ev[2]), "", 2.4)
		"bite":
			if ev[1] == me.id:
				hud.banner("A bite!", "Press %s" % Keys.name("attack"), 1.0)
		"gone":
			var n = _deads.get(ev[2])
			if n:
				n.die()
				_deads.erase(ev[2])
		"abl":
			_puff(Vector3(ev[2], 0.2, ev[3]), Color("fff0c0"), 2.2)
		"ring":
			_puff(Vector3(ev[1], 0.2, ev[2]), Color("ffe080"), 8.0)
		"burst", "holy":
			_puff(Vector3(ev[1], 0.2, ev[2]), Color("fff4c8"), 2.5)
		"raise":
			_puff(Vector3(ev[1], 0.2, ev[2]), Color("b4a0ff"), 1.5)


func _tracer(a: Vector3, b: Vector3, c: Color) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var l := a.distance_to(b)
	bm.size = Vector3(0.08, 0.08, maxf(0.1, l))
	m.mesh = bm
	m.material_override = Build.mat(c, 1.2)
	_fx.add_child(m)
	m.position = (a + b) / 2
	if l > 0.01:
		m.look_at_from_position((a + b) / 2, b, Vector3.UP)
	m.set_meta("t", 0.18)


func _puff(at: Vector3, c: Color, r: float) -> void:
	var m := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.8; tm.outer_radius = 1.0; tm.rings = 24; tm.ring_segments = 4
	m.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = c
	m.material_override = mat
	_fx.add_child(m)
	m.position = at
	m.set_meta("t", 0.5)
	m.set_meta("grow", r)


# ---------------------------------------------------------------- drawing
func _fig(key: String, tunic: Color, player: bool) -> Node3D:
	var f = _figs.get(key)
	if f == null:
		f = Figure.new()
		f.tunic = tunic
		f.is_player = player
		add_child(f)
		_figs[key] = f
		_seen[key] = [-1, -1]
	return f


func _counts(key: String, f: Node3D, ac: int, hc: int) -> void:   # a new swing or a new hit since last time
	var s: Array = _seen[key]
	if s[0] >= 0 and ac != s[0]: f.swing()
	if s[1] >= 0 and hc != s[1]: f.hit()
	_seen[key] = [ac, hc]


func _draw(delta: float) -> void:
	var live := {}
	for p: E.Player in R.players:
		var key := "p%d" % p.id
		live[key] = true
		var f := _fig(key, Color(D.PCOL[p.col % 8]), true)
		f.visible = p.state != "inn" and p.state != "hide"
		f.place(p.x, p.z, p.r)
		f.down = p.state == "down" or p.state == "dead"
		f.hold(p.wpn)
		f.wear(p.head, p.body, p.off, p.trk, p.bodies)
		_counts(key, f, p.ac + p.cc, p.hc)
	for q: E.Peasant in R.peasants:
		var key := "q%d" % q.id
		live[key] = true
		var own := R.player_by_id(q.owner)
		var tunic := Color(D.PCOL[own.col % 8]).lerp(Color("b79e75"), 0.35) if own else Color("b79e75")
		var f := _fig(key, tunic, false)
		if f.tunic != tunic:                          # changed hands: build it again in the new colour
			f.queue_free(); _figs.erase(key)
			f = _fig(key, tunic, false)
		f.visible = q.state != "inn" and q.state != "gone"
		f.place(q.x, q.z, q.r)
		f.down = q.state == "body"
		f.hold(-1 if q.state == "body" else 2 if q.armed else 0)
		_counts(key, f, q.ac, q.hc)
	for key in _figs.keys():
		if not live.has(key):
			_figs[key].queue_free()
			_figs.erase(key)
			_seen.erase(key)
	var seen_u := {}
	for u: E.Undead in R.undead:
		seen_u[u.id] = true
		var n = _deads.get(u.id)
		if n == null:
			n = Dead.new()
			n.kind = u.k
			add_child(n)
			_deads[u.id] = n
			n.set_meta("c", [u.ac, u.hc])
		n.place(u.x, u.z, u.r)
		n.state = u.state
		var c: Array = n.get_meta("c")
		if u.ac != c[0]: n.swing()
		if u.hc != c[1]: n.hit()
		n.set_meta("c", [u.ac, u.hc])
	for id in _deads.keys():
		if not seen_u.has(id):                        # cleared without a death (dawn, or a test)
			_deads[id].queue_free()
			_deads.erase(id)
	var seen_d := {}
	for d: E.Drop in R.drops:
		seen_d[d.id] = true
		if not _drops.has(d.id):
			var n := Node3D.new()
			add_child(n)
			n.position = Vector3(d.x, 0, d.z)
			var I: Dictionary = D.IT[d.it]
			var col := Color(I.tint[0], I.tint[1], I.tint[2]) * Color("c9b98a") if I.tier == "relic" else Color("9a8a70")
			var b := Build.box(n, Vector3(0.6, 0.18, 0.4), Vector3.ZERO, col, randf() * 3)
			if I.tier == "relic": b.material_override = Build.mat(col, 1.2)
			_drops[d.id] = n
	for id in _drops.keys():
		if not seen_d.has(id):
			_drops[id].queue_free()
			_drops.erase(id)
	trees_view.sync(R, delta)
	sites_view.sync(R)
	defences_view.sync(R)
	for m in _fx.get_children():
		var t: float = m.get_meta("t") - delta
		m.set_meta("t", t)
		if m.has_meta("grow"):
			var s: float = m.get_meta("grow") * (1.0 - t / 0.5) + 0.3
			m.scale = Vector3(s, 1, s)
			m.material_override.albedo_color.a = clampf(t / 0.5, 0, 1)
		if t <= 0: m.queue_free()
	# the ring under whatever holding E would work on, and the ghost of a thing being placed
	var it = R.find_interact(me) if _build_sel == "" and R.live() and me.state == "ok" else null
	_ring.visible = it != null
	if it:
		var rad: float = it.rad
		_ring.position = Vector3(it.x, 0.12, it.z)
		_ring.rotation.y = it.get("rot", 0.0)
		_ring.scale = Vector3(rad, 1, rad if not it.get("wide", false) else 1.0)
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
	_apply_light(R.nf)
	_camera(delta)


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
	_focus = _focus.lerp(Vector3(me.x, 0, me.z), minf(1.0, delta * 6.0))
	_zoom = lerpf(_zoom, 1.0 + 0.12 * R.nf, minf(1.0, delta * 3.0))
	camera.position = _focus + Vector3(0, 66, 56) * 1.25 * _zoom
	camera.look_at(_focus + Vector3(0, 1, 0))


# ---------------------------------------------------------------- the readouts
func _fmt(s: float) -> String:
	var n := maxi(0, ceili(s))
	return "%d:%02d" % [n / 60, n % 60]


func _hud_update(delta: float) -> void:
	var p := me
	var ph := R.phase
	if ph != _prev_phase:
		_prev_phase = ph
		match ph:
			"dusk":
				hud.banner("Dusk", "The bell rings. Somebody at the castle is polishing the silver." if R.day == D.LAST_DAY else "The bell rings. Something is stirring at Ashhollow Castle.", 5.0)
				hud.close_dawn(); _panel = ""
			"night":
				hud.banner("Night %d" % R.day, "The dead are rising all along the graveyard.", 4.5)
			"won":
				hud.banner("Thornhallow stands", "Seven nights held. The castle has gone quiet, for now.", 12.0)
				hud.show_dawn("The week is over", R.dawn.lines + ["Thornhallow held for seven nights. Close the game and start again for a new village."])
			"lost":
				hud.banner("The keep has fallen", "Robert Bailiff’s door remains bolted.", 8.0)
				_end_t = 8.0
	if ph == "lost":
		_end_t -= delta
		if _end_t <= 0:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
			get_tree().reload_current_scene()
			return
	if R.dawn.seq != _dawn_seen and ph == "day":         # a new morning: the dawn notice
		_dawn_seen = R.dawn.seq
		if R.dawn.lines.size():
			hud.show_dawn("Day %d of %d" % [R.dawn.day, D.LAST_DAY], R.dawn.lines)
		hud.banner("Day %d" % R.dawn.day, "", 2.6)
	var timer := ""
	match ph:
		"day": timer = "Dusk in " + _fmt(R.timeLeft)
		"dusk": timer = "Night falls in " + _fmt(R.timeLeft)
		"night": timer = ("%d undead left · %d still to rise" % [R.left, R.wave] if R.wave > 0 else "%d undead left · the last have risen" % R.left) if R.left > 0 else "The graveyard is quiet"
		"won": timer = "The week is over"
		"lost": timer = "The keep has fallen"
	var ptext := "Dusk" if ph == "dusk" else "Night %d" % R.day if ph == "night" or ph == "lost" else "Day %d of %d" % [R.day, D.LAST_DAY]
	hud.show_state(ptext, timer, R.keepHp, D.KEEP_HP, p.hp, Rules.max_hp(p))
	# what you carry, and the little readouts
	var c := Rules.cap(p)
	var res := "Wood %d · Stone %d · Iron %d · Food %d   (carry %d)\n%s" % [p.wood, p.stone, p.iron, p.food, c, D.coins(p.coin)]
	var W: Dictionary = D.IT[p.wpn]
	var A: Dictionary = D.AB[W.ab]
	var nv := 100.0
	for q in R.peasants:
		if q.owner == p.id and q.state != "body" and q.state != "hide" and q.nv < nv: nv = q.nv
	var lines := []
	lines.append("In hand: %s%s.  %s: %s%s" % [W.n, " (blessed)" if p.bless & 1 else "", Keys.name("trick"), A.n, " in %ds" % ceili(p.abCd) if p.abCd > 0 else ", ready"])
	var worn := [p.head, p.body, p.off].filter(func(id): return id >= 0).map(func(id): return D.IT[id].n)
	if worn.size(): lines.append("Wearing: " + ", ".join(worn))
	if p.trk >= 0: lines.append("Carrying (%s): %s%s" % [Keys.name("carry"), D.IT[p.trk].n, " (blessed)" if p.bless & 2 else ""])
	lines.append("Posse %d / %d%s%s · Pack %d / %d (%s)" % [p.posse, R.posse_max(p), (" · " + ["following", "holding", "charging"][p.ord]) if Rules.rk(p, 6) >= 3 and p.posse else "",
		" · about to run" if p.posse and nv < 40 else " · uneasy" if p.posse and nv < 70 else "", p.inv.size(), D.PACK_MAX, Keys.name("pack")])
	if p.bodies: lines.append("Bodies %d / %d%s" % [p.bodies, D.MAX_BODIES, " (%d blessed)" % p.bbod if p.bbod else ""])
	if p.state == "inn" or p.cg > 0 or p.charge > 0 or p.hang > 0:
		lines.append("Charging %ds" % ceili(p.charge) if p.charge > 0 else "Hangover %ds" % ceili(p.hang) if p.hang > 0 else "Courage %d%%" % p.cg)
	var books := []
	for b in 10:
		if p.books[b]: books.append("%s %d" % [D.BOOKS[b].name, p.books[b]])
	lines.append("Books: " + (", ".join(books) if books.size() else "none yet. The library has one for you."))
	if R.boss: lines.append("The Steward: %d / %d" % [maxi(0, ceili(R.boss.hp)), roundi(R.boss.mhp)])
	hud.show_res(res, "\n".join(lines))
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
	hud.show_prompt(Keys.fill(ptxt), p.prog if it and it.ok and p.gk != 5 else 0.0, it == null or it.ok)
	# the open notice, if you are still beside the place
	if p.state == "inn" and R.live(): _panel = "inn"
	if _panel != "":
		var st := D.station(_panel)
		var near: bool = p.state == "inn" or (p.state == "ok" and (_panel == "pack" or (not st.is_empty() and D.d2(p.x, p.z, st.x, st.z) <= pow(st.r + 1.6, 2))))
		if not near or not R.live():
			_panel = ""; _page = ""
	if _panel != "":
		hud.show_notice(Notices.data(R, _panel, p, _page), "Press the number, or click." + ("" if p.state == "inn" else " Walk away or press Esc to close."))
	else:
		hud.show_notice({}, "")
	var rd := R.players.filter(func(o): return o.ready).size()
	hud.show_hint(("You are ready (%d of %d). Press %s to change your mind." % [rd, R.players.size(), Keys.name("ready")] if p.ready else "Press %s when you are ready for the night" % Keys.name("ready")) if ph == "day" else
		"%s to move · %s or click to attack · %s or right-click: your weapon’s trick · %s eats" % ["W A S D", Keys.name("attack"), Keys.name("trick"), Keys.name("eat")])


## For testing from the command line: DTV_SHOT=file.png saves a picture after DTV_SHOT_AT frames and stops.
## DTV_AT=x,z puts the player there first. DTV_LOG=1 prints how the night is going every ten seconds.
func _test_hook() -> void:
	_frame += 1
	if OS.get_environment("DTV_LOG") != "" and _frame % 600 == 0:
		print("t=", _frame / 60, "s ", R.phase, " day ", R.day, " undead ", R.undead.size(), " to rise ", R.wave, " kills ", R.stats.kills, " keep ", roundi(R.keepHp), " player ", me.state, " hp ", roundi(me.hp), " posse ", me.posse)
	var shot := OS.get_environment("DTV_SHOT")
	if shot == "":
		return
	var at := int(OS.get_environment("DTV_SHOT_AT")) if OS.get_environment("DTV_SHOT_AT") != "" else 60
	if _frame == at and OS.get_environment("DTV_AT") != "":
		var xz := OS.get_environment("DTV_AT").split(",")
		me.x = float(xz[0]); me.z = float(xz[1])
	if _frame == at + 30:
		get_viewport().get_texture().get_image().save_png(shot)
		print("phase ", R.phase, " day ", R.day, " undead ", R.undead.size(), " kills ", R.stats.kills, " keep ", R.keepHp, " player ", Vector2(me.x, me.z))
		get_tree().quit()
