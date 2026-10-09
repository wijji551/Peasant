extends SceneTree
## Clicks the home screen with the mouse, as a player would, with the game as the real current scene.
## Run in a window (not headless):  godot --path godot -s res://tests/click_test.gd

var lines := []


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func frames(n: int) -> void:
	for i in n: await process_frame


func find_button(n: Node, text: String) -> Button:
	if n is Button and (n as Button).text.begins_with(text) and (n as Button).is_visible_in_tree(): return n
	for c in n.get_children():
		var b := find_button(c, text)
		if b: return b
	return null


func click_at(q: Vector2, hold := 2) -> void:
	var p: Vector2 = root.get_final_transform() * q
	var mv := InputEventMouseMotion.new()
	mv.position = p; mv.global_position = p
	Input.parse_input_event(mv)
	await frames(2)
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = p; e.global_position = p
		Input.parse_input_event(e)
		await frames(hold if down else 2)


func click(text: String, hold := 2) -> bool:
	var b := find_button(current_scene, text)
	if b == null: return false
	await click_at(b.get_global_rect().get_center(), hold)
	return true


func _init() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://dtv-save.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings.json"))
	change_scene_to_file("res://main.tscn")
	await frames(10)
	var m = current_scene
	ok("home screen up", m.screen == "home" and m.win.is_open("home"))
	# a colour swatch (the third Button with a tooltip in the swatch row)
	var sw: Array = []
	_collect_swatches(m.win.body, sw)
	ok("eight swatches", sw.size() == 8, sw.size())
	if sw.size() == 8:
		await click_at(sw[3].get_global_rect().get_center())
		await frames(4)
		ok("clicking a swatch picks the colour", Settings.col == 3, Settings.col)
		_collect_swatches(m.win.body, sw)
		await click_at(sw[5].get_global_rect().get_center())
		await frames(4)
		ok("and again", Settings.col == 5, Settings.col)
	ok("handbook button clicked", await click("Handbook"))
	await frames(4)
	ok("handbook open", m.win.is_open("menu"), m.win.kind)
	ok("keys tab clicked", await click("Keys") or await click("Controls"))
	await frames(4)
	ok("options tab clicked", await click("Options"))
	await frames(4)
	ok("guide tab clicked", await click("Guide"))
	await frames(4)
	await click("✕")
	await frames(4)
	ok("back home", m.win.is_open("home"), m.win.kind)
	ok("new village clicked (mouse held down as the game starts)", await click("New village", 30))
	await frames(20)
	m = current_scene
	ok("game started", m != null and m.screen == "game", m.screen if m else "no scene")
	var fr: Rect2 = m.win._frame.get_global_rect()
	var vc: Vector2 = m.win.get_viewport_rect().size / 2
	ok("the dawn window after the home screen is in the middle", fr.get_center().distance_to(vc) < 30 and fr.size.x < 900, [fr, vc])
	Input.action_release("dtv_attack_mouse")
	m.win.close()
	await frames(5)
	await click_at(Vector2(640, 400), 20)
	await frames(10)
	ok("clicking in the game attacks without crashing", current_scene == m and m.screen == "game")
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d pass, %d fail" % [lines.size() - bad, bad])
	quit(1 if bad else 0)


func _collect_swatches(n: Node, out: Array) -> void:
	if n == current_scene.win.body: out.clear()
	for c in n.get_children():
		if c is Button and c.custom_minimum_size == Vector2(30, 30): out.append(c)
		_collect_swatches(c, out)
