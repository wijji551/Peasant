extends SceneTree
## The menus, driven as a player would: the home screen, starting, the pack, the handbook, changing a key,
## a place's notice, the dawn, Esc, and the end. Run:  godot --headless --path godot -s res://tests/ui_test.gd

var lines := []
var m


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func key(k: int) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = k as Key
	e.keycode = k as Key
	e.pressed = true
	Input.parse_input_event(e)
	var u := e.duplicate()
	u.pressed = false
	Input.parse_input_event(u)


func frames(n: int) -> void:
	for i in n: await process_frame


func _init() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://dtv-save.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings.json"))
	var scene: PackedScene = load("res://main.tscn")
	m = scene.instantiate()
	root.add_child(m)
	await frames(5)
	ok("the game opens on the home screen", m.screen == "home" and m.win.is_open("home"))
	ok("no carry-on button without a save", m.read_save() == null)
	ok("the readouts are hidden on the home screen", not m.hud._hotbar.visible)
	m.menus.menu("guide")
	await frames(2)
	ok("the handbook opens from home", m.win.is_open("menu"))
	m.win.close()
	await frames(3)
	ok("closing it goes back to the home screen", m.win.is_open("home"), m.win.kind)
	Settings.name = "Matt"
	Settings.col = 2
	m.begin(null)
	await frames(5)
	ok("New village starts the game", m.screen == "game" and m.R.phase == "day" and m.me.name == "Matt" and m.me.col == 2)
	ok("the dawn notice opens", m.win.is_open("dawn"))
	ok("it has the screen to itself", not m.hud._hotbar.visible)
	key(KEY_ESCAPE)
	await frames(3)
	ok("Esc closes the dawn", not m.win.visible)
	ok("and the readouts come back", m.hud._hotbar.visible)
	ok("a save was made at dawn", m.read_save() != null)
	key(KEY_I)
	await frames(3)
	ok("I opens the pack", m.win.is_open("pack"))
	ok("the pack does not cover the bar at the bottom", not m.hud.window._frame.get_global_rect().intersects(m.hud._hotbar.get_global_rect()), [m.hud.window._frame.get_global_rect(), m.hud._hotbar.get_global_rect()])
	m.me.inv = [6]
	await frames(3)
	key(KEY_1)
	await frames(3)
	ok("1 in the pack takes up the club (the pitchfork is never put away)", m.me.wpn == 6 and m.me.inv.is_empty(), [m.me.wpn, m.me.inv])
	key(KEY_I)
	await frames(3)
	ok("I closes the pack", not m.win.visible)
	key(KEY_ESCAPE)
	await frames(3)
	ok("Esc with nothing open opens the handbook", m.win.is_open("menu"))
	var t0: float = m.R.timeLeft
	await frames(30)
	ok("the game waits while the handbook is open", m.R.timeLeft == t0)
	m.menus.menu("keys")
	m.menus.rebinding = "eat"
	key(KEY_H)
	await frames(3)
	ok("a key can be changed", Keys.name("eat") == "H" and m.menus.rebinding == "", Keys.name("eat"))
	m.menus.rebinding = "pack"
	key(KEY_H)
	await frames(3)
	ok("giving a key to another action takes it from the first", Keys.name("pack") == "H" and Keys.keys_of("eat").is_empty(), m.menus.bind_msg)
	Keys.reset()
	ok("back to the usual keys", Keys.name("eat") == "F" and Keys.name("pack") == "I")
	key(KEY_ESCAPE)
	await frames(3)
	ok("Esc closes the handbook", not m.win.visible)
	# a place's notice: stand at the library and hold E
	var st := D.station("library")
	m.me.x = st.x; m.me.z = st.z
	Input.action_press("dtv_interact")
	await frames(20)
	Input.action_release("dtv_interact")
	await frames(3)
	ok("holding E at the library opens its notice", m.win.is_open("notice"), m.win.kind)
	ok("the notice keeps clear of the readouts", not m.hud.window._frame.get_global_rect().intersects(m.hud._hotbar.get_global_rect()))
	key(KEY_5)
	await frames(5)
	ok("pressing 5 takes up book five", m.me.books[4] == 1, m.me.books)
	m.me.x = st.x + 12
	await frames(10)
	ok("walking away closes the notice", not m.win.visible)
	# the end of the week
	m.R.phase = "won"
	await create_timer(3.0).timeout
	await frames(3)
	ok("the end of the week shows", m.win.is_open("end"), m.win.kind)
	# sound: three channels, M mutes, the sliders reach them
	ok("effects, ambience and music each have a channel", ["Effects", "Ambience", "Music"].all(func(b): return AudioServer.get_bus_index(b) > 0))
	var was_muted := Settings.muted
	key(KEY_M)
	await frames(2)
	ok("M mutes the sound", Settings.muted != was_muted and AudioServer.is_bus_mute(0) == Settings.muted)
	key(KEY_M)
	await frames(2)
	ok("and M again turns it back on", Settings.muted == was_muted and not AudioServer.is_bus_mute(0))
	Settings.set_volume("music_vol", 0); Sound.apply_settings()
	ok("music at nothing silences the music", AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	Settings.set_volume("music_vol", 50); Sound.apply_settings()
	ok("the tunes and the ambience loop", Sound.me._loops.values().all(func(e): return (e[0].stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD and e[0].playing))
	m.free()
	for l in lines: print(l)
	var fails := lines.filter(func(l): return not l.begins_with("PASS")).size()
	print("\n%d passed, %d failed" % [lines.size() - fails, fails])
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings.json"))
	quit(1 if fails else 0)
