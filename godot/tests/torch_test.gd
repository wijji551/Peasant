extends SceneTree
## The burning torch, the old workings (a room you walk into, dark without the torch), runes, and rune-cut weapons.
## Run:  godot --headless --path godot -s res://tests/torch_test.gd

var R: Rules
var m: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func fast(sec: float, f: Callable = Callable()) -> float:
	var t := 0.0
	while t < sec:
		if f.is_valid() and f.call() == false: return t
		R.step(STEP); R.ev.clear(); t += STEP
	return t


func night() -> void:
	R.weather = "clear"
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()


func one(k: int, x: float, z: float) -> E.Undead:
	var u := R.spawn_undead(k, x, z)
	u.state = "walk"; u.t = 0; u.stun = 99
	return u


func _init() -> void:
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	var sm := D.station("smithy")
	m.x = sm.x; m.z = sm.z; m.wood = 3
	ok("anyone can make a torch", Rules.can_forge(m, D.I_TORCH) and Rules.forge_why(m, D.I_TORCH) == "")
	R.do_act(m, "forge", D.I_TORCH)
	ok("three wood, and it is in your hand", m.wpn == D.I_TORCH and m.wood == 0, [m.wpn, m.wood])
	ok("the smithy lists it, and the runes", Notices.data(R, "smithy", m, "").o.any(func(o): return o.get("arg") == D.I_TORCH) and Notices.data(R, "smithy", m, "").o.any(func(o): return o.get("a", "") == "etch"))
	# ---------- fire
	night()
	m.x = 0; m.z = -30; m.r = 0
	var a := one(0, 0, -28.6)
	var hp0 := a.hp
	m.atkCd = 0; R.do_attack(m)
	var after := a.hp
	ok("a blow from the torch sets them alight", a.burn > 3.5 and after < hp0, [a.burn, hp0 - after])
	var burns := 0
	var t := 0.0
	while t < 5.0:
		R.step(STEP); t += STEP
		burns += R.ev.filter(func(e): return e[0] == "burn").size()
		R.ev.clear()
	ok("and they go on burning for a few seconds after", a.burn <= 0 and burns >= 7 and after - a.hp >= D.BURN_DMG * 7 - 0.1, [burns, after - a.hp])
	var w := one(D.U_WRAITH, 0.6, -28.6)
	m.atkCd = 0; R.do_attack(m)
	ok("a wraith has nothing to burn", w.burn <= 0 and w.hp == w.mhp)
	R.undead.clear()
	var ring := [one(0, 2.4, -30), one(0, -2.4, -30), one(1, 0, -32.4)]
	m.abCd = 0; R.do_ability(m)
	ok("the trick (Flare) sets light to everything round you", ring.all(func(u): return u.burn > 0), ring.map(func(u): return u.burn))
	R.undead.clear()
	R.weather = "rain"
	var wet := one(0, 0, -28.6)
	m.atkCd = 0; m.r = 0; R.do_attack(m)
	ok("rain puts it out in half the time", wet.burn > 1.5 and wet.burn <= D.BURN_TIME * 0.5 + 0.01, wet.burn)
	R.undead.clear(); R.weather = "clear"
	fast(5.0, func(): return R.phase != "day")       # the night is over: morning
	# ---------- the old workings
	var M: Dictionary = D.ROOMS.mine
	m.x = M.door[0] + 0.5; m.z = M.door[1]
	var q: E.Peasant = R.peasants[0]
	q.owner = m.id; q.state = "follow"; q.x = m.x + 2; q.z = m.z + 2
	var it = R.find_interact(m)
	ok("by the steel mine, a way down", it != null and it.get("type") == "enter" and it.room == "mine", it)
	m.eHold = true
	fast(1.2)
	m.eHold = false
	ok("holding E goes down into the old workings", m.room == "mine" and absf(m.x - M.x) <= M.hw and absf(m.z - M.z) <= M.hd, [m.room, m.x, m.z])
	for i in 90: R.move_player(m, -1, 0, STEP, 0.0)
	ok("its walls hold you in", m.x >= M.x - M.hw and m.x < M.x - M.hw + 1.0, m.x)
	ok("and it is not the river down here", R.move_player(m, 0, 1, STEP, 0.0) == "")
	var z0 := one(0, m.x, -30.0)
	z0.stun = 0
	fast(1.0)
	ok("the dead cannot get at you there", z0.tg == 0)
	R.undead.clear()
	fast(4.0)
	ok("your posse waits at the top", D.d2(q.x, q.z, M.door[0], M.door[1]) < 36, [q.x, q.z])
	var v: Array = D.RUNE_VEINS[0]
	m.x = v[0] + 1.2; m.z = v[1]
	m.wpn = 0
	it = R.find_interact(m)
	ok("without a torch it is too dark to work a vein", it != null and it.get("type") == "rune" and not it.ok and "torch" in it.label, it)
	m.wpn = D.I_TORCH
	it = R.find_interact(m)
	ok("with one, it is not", it != null and it.ok, it)
	m.eHold = true
	fast(D.RUNE_TIME * 2 + 2.0)
	m.eHold = false
	ok("two runes to a vein, each day", m.rune == 2 and R.rune_left[0] == 0, [m.rune, R.rune_left])
	it = R.find_interact(m)
	ok("then it is worked out", it != null and not it.ok and "tomorrow" in it.label)
	m.x = M.at[0]; m.z = M.at[1] - 0.8
	it = R.find_interact(m)
	ok("the ladder goes back up", it != null and it.get("type") == "leave", it)
	m.eHold = true
	fast(1.2)
	m.eHold = false
	ok("to the daylight, by the mine", m.room == "" and D.d2(m.x, m.z, M.door[0], M.door[1]) < 9, [m.room, m.x, m.z])
	# dawn fetches everyone out
	R.enter_room(m, "mine")
	var day0 := R.day
	night()
	fast(5.0, func(): return R.phase != "day")
	ok("at dawn nobody is left down there", m.room == "" and R.day == day0 + 1 and R.rune_left[0] == D.RUNE_PER_VEIN, [m.room, R.day, R.rune_left])
	# ---------- runes cut into a weapon
	m.rune = 3; m.wpn = 2
	var I: Dictionary = D.IT[2]
	var d0 := Rules.dmg_of(m, I)
	m.x = 60; m.z = 30
	R.do_act(m, "etch")
	ok("runes are cut at the smithy, nowhere else", m.etch == -1 and m.rune == 3)
	m.x = sm.x; m.z = sm.z
	R.do_act(m, "etch")
	ok("three runes cut into the weapon in your hand", m.etch == 2 and m.rune == 0, [m.etch, m.rune])
	ok("a fifth more damage", is_equal_approx(Rules.dmg_of(m, I), d0 * 1.2), [d0, Rules.dmg_of(m, I)])
	night()
	m.x = 0; m.z = -30; m.r = 0
	var w2 := one(D.U_WRAITH, 0, -28.4)
	m.atkCd = 0; R.do_attack(m)
	ok("and it bites wraiths", w2.hp < w2.mhp, [w2.hp, w2.mhp])
	m.wpn = 0
	var w3 := one(D.U_WRAITH, 0.3, -28.4)
	m.atkCd = 0; R.do_attack(m)
	ok("which a plain pitchfork does not", w3.hp == w3.mhp)
	var sv := R.save_data()
	ok("runes and the cut weapon are saved", sv.players[0].has("rune") and int(sv.players[0].etch) == 2)
	var fails := 0
	for l in lines:
		if l.begins_with("FAIL"): fails += 1
		print(l)
	print("%d passed, %d failed" % [lines.size() - fails, fails])
	quit()
