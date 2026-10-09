extends SceneTree
## Co-op, the joining side. Run at the same time as net_host.gd.

var lines := []


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + "client: " + name + ("" if extra == null else "  [" + str(extra) + "]"))


func frames(n: int) -> void:
	for i in n: await process_frame


func wait_for(f: Callable, seconds: float) -> bool:
	var t := 0.0
	while t < seconds:
		if f.call(): return true
		await process_frame
		t += 1.0 / 60.0
	return false


func _init() -> void:
	change_scene_to_file("res://main.tscn")
	await frames(30)                                       # give the host a moment to open
	var relay := OS.get_environment("DTV_RELAY")
	Settings.relay = relay
	var where := Net.local_ip()
	if relay != "":                                         # the host's code, as if read out
		await wait_for(func(): return FileAccess.file_exists("user://test_code.txt"), 20.0)
		await frames(5)
		where = FileAccess.get_file_as_string("user://test_code.txt").strip_edges()
		ok("we have the host's village code", where.length() == 5, where)
	var why: String = Net.me.join(where, "Joiny", 3)
	ok("joining starts", why == "", why)
	var got_id := await wait_for(func(): return Net.me.my_id == 2, 20.0)
	ok("the host lets us in", got_id, Net.me.my_id)
	var in_lobby := await wait_for(func(): return Net.me.lobby.size() == 2, 10.0)
	ok("the lobby shows both of us", in_lobby, Net.me.lobby)
	var started := await wait_for(func(): return current_scene.screen == "game", 40.0)
	var m = current_scene
	ok("the host starts, and we are in the village", started)
	if not started:
		_end()
		return
	ok("we are player 2, in our colour", m.me != null and m.me.id == 2 and m.me.col == 3)
	ok("the host's player is here too", m.R.players.size() == 2 and m.R.player_by_id(1) != null)
	var structs := await wait_for(func(): return m.R.structs.size() >= 7, 10.0)
	ok("the defences came over", structs, m.R.structs.size())
	ok("the peasants came over", m.R.peasants.size() >= 5, m.R.peasants.size())
	m.win.close()
	var x0: float = m.me.x
	Input.action_press("dtv_right")
	await frames(90)
	Input.action_release("dtv_right")
	ok("we walk (here at once, not waiting for the host)", m.me.x - x0 > 1.5, m.me.x - x0)
	await frames(20)
	Input.action_press("dtv_attack")
	await frames(6)
	Input.action_release("dtv_attack")
	await frames(20)
	m.cmd({"t": "rdy", "v": true})
	var dead := await wait_for(func(): return is_instance_valid(m) and m.R.undead.size() >= 2 and m.R.phase == "night", 45.0)
	ok("night falls here too, and the dead come over", dead, [m.R.phase, m.R.undead.size()])
	var gone_ok := true
	for u in m.R.undead:
		if absf(u.x) > 120 or u.z < -140: gone_ok = false
	ok("the dead are where the host has them", gone_ok)
	var host_left := await wait_for(func(): return current_scene and current_scene.screen == "home" and not Net.me.online(), 40.0)
	ok("when the host closes the village, we are back home", host_left)
	_end()


func _end() -> void:
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("client: %d pass, %d fail" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
