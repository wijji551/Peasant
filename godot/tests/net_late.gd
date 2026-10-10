extends SceneTree
## Co-op, somebody who turns up late: joins a week already going, drops out, and joins again.
## Run with net_host.gd and net_client.gd (tests/net_test.sh runs all three).

var lines := []


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + "late: " + name + ("" if extra == null else "  [" + str(extra) + "]"))


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
	await frames(30)
	var relay := OS.get_environment("DTV_RELAY")
	Settings.relay = relay if relay != "" else "none"
	var go := await wait_for(func(): return FileAccess.file_exists("user://test_started.txt"), 120.0)
	ok("the week is under way before we set out", go)
	await frames(20)
	var where := Net.local_ip()
	if relay != "": where = FileAccess.get_file_as_string("user://test_code.txt").strip_edges()
	var why: String = Net.me.join(where, "Latey", 5)
	ok("joining starts", why == "", why)
	var started := await wait_for(func(): return current_scene.screen == "game", 60.0)
	var m = current_scene
	ok("we are let into the week already going", started, [Net.me.status, Net.me.kicked])
	if not started:
		_end()
		return
	ok("as ourselves, with the others", m.me != null and m.me.name == "Latey" and m.R.players.size() == 3, m.R.players.map(func(p): return p.name))
	var structs := await wait_for(func(): return m.R.structs.size() >= 7 and m.R.peasants.size() >= 5, 15.0)
	ok("the village came over", structs, [m.R.structs.size(), m.R.peasants.size()])
	var got := await wait_for(func(): return m.me.wood == 13, 30.0)
	ok("what the host says we carry, we carry", got, m.me.wood)
	Net.me.leave()
	await frames(60)
	change_scene_to_file("res://main.tscn")
	await frames(60)
	why = Net.me.join(where, "Latey", 5)
	ok("joining again starts", why == "", why)
	var again := await wait_for(func(): return current_scene.screen == "game" and current_scene.me != null, 60.0)
	m = current_scene
	ok("and we are back in", again, [Net.me.status, Net.me.kicked])
	if again:
		var same := await wait_for(func(): return m.me.wood == 13 and m.me.books[3] == 2, 30.0)
		ok("with everything we had", same, [m.me.wood, m.me.books])
	await wait_for(func(): return current_scene and current_scene.screen == "home" and not Net.me.online(), 120.0)
	_end()


func _end() -> void:
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("late: %d pass, %d fail" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
