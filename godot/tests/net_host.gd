extends SceneTree
## Co-op, the host's side. Run at the same time as net_client.gd (tools: tests/net_test.sh runs both).

var lines := []


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + "host: " + name + ("" if extra == null else "  [" + str(extra) + "]"))


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
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://dtv-save.json"))
	change_scene_to_file("res://main.tscn")
	await frames(10)
	var m = current_scene
	var relay := OS.get_environment("DTV_RELAY")
	Settings.relay = relay
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_code.txt"))
	var why: String = Net.me.host("Hosty", 0)
	ok("hosting starts", why == "" and Net.me.is_host(), why)
	await frames(3)
	ok("the lobby shows", m.win.is_open("lobby"))
	if relay != "":
		var got := await wait_for(func(): return Net.me.code.length() == 5, 10.0)
		ok("the village server gives the village a code", got and Net.me.via_relay, Net.me.code)
		var f := FileAccess.open("user://test_code.txt", FileAccess.WRITE)
		f.store_string(Net.me.code)
		f.close()
	else:
		ok("a code for the same network", Net.me.lan_code.length() == 8, Net.me.lan_code)
		ok("the code reads back as this computer's address", Net.decode(Net.me.lan_code) == Net.local_ip(), [Net.decode(Net.me.lan_code), Net.local_ip()])
	var joined := await wait_for(func(): return Net.me.lobby.size() == 2 and Net.me.lobby[1].name == "Joiny", 25.0)
	ok("a friend joins, with their name and colour", joined and Net.me.lobby[1].col == 3, Net.me.lobby)
	m.begin(null)
	await frames(5)
	ok("the week starts with both", m.screen == "game" and m.R.players.size() == 2)
	var them: E.Player = m.R.player_by_id(2)
	ok("the friend is a remote player", them != null and them.remote)
	var x0 := them.x if them else 0.0
	var ac0 := them.ac if them else 0
	var moved := await wait_for(func(): return them and absf(them.x - x0) > 1.5, 20.0)
	ok("the friend walks, and the host sees it", moved, them.x - x0 if them else null)
	var swung := await wait_for(func(): return them and them.ac > ac0, 15.0)
	ok("the friend swings, and the host's rules do it", swung)
	var bought := await wait_for(func(): return them and them.ready, 15.0)
	ok("the friend says they are ready", bought)
	m.R.dusk_falls(); m.R.timeLeft = 0.5                   # on to the night, so the dead go over the wire too
	var risen := await wait_for(func(): return m.R.undead.size() >= 2, 40.0)
	ok("night falls and the dead rise", risen, m.R.undead.size())
	await frames(600)
	Net.me.leave()
	await frames(10)
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("host: %d pass, %d fail" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
