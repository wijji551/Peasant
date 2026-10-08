extends SceneTree
## A time-limited bot plays the whole week solo to see how hard it is. Travel costs walking time; fighting uses real movement.
## Run:  godot --headless --path godot -s res://tests/bot_week.gd -- [steady|walls]
## The same bot as the web version's test/bot-week.js, so the two can be compared.

var R: Rules
var me: E.Player
var mode := "steady"
var keys := {}          # what the bot is holding: up, down, left, right, attack, interact
var atk_cd := 0.0
var clock := 0.0

const STEP := 1.0 / 30.0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size(): mode = args[0]
	seed(int(Time.get_unix_time_from_system()))
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Bot", "col": 0}])
	me = R.players[0]
	var log := run()
	for l in log: print(l)
	quit()


func tick() -> void:   # one moment: the bot's keys move it, then the rules run
	var p := me
	atk_cd = maxf(0, atk_cd - STEP)
	clock += STEP
	p.eHold = R.live() and keys.get("interact", false) and (p.state == "ok" or p.state == "hide")
	if R.live() and p.state == "ok":
		var mx := (1.0 if keys.get("right") else 0.0) - (1.0 if keys.get("left") else 0.0)
		var mz := (1.0 if keys.get("down") else 0.0) - (1.0 if keys.get("up") else 0.0)
		R.move_player(p, mx, mz, STEP, clock)
		if keys.get("attack") and atk_cd <= 0 and p.gk != 5:
			var I: Dictionary = D.IT[p.wpn]
			atk_cd = I.cd * (0.8 if I.rng and Rules.rk(p, 5) >= 5 else 1.0)
			R.aim_assist(p); R.do_attack(p)
	R.step(STEP)
	R.ev.clear()


# run the world for sec seconds, or until f returns false
func fast(sec: float, f: Callable = Callable()) -> void:
	var t := 0.0
	while t < sec:
		if f.is_valid() and f.call() == false:
			return
		tick()
		t += STEP


func day_ok() -> bool:
	return R.phase == "day" and R.timeLeft > 14

func go(x: float, z: float) -> void:
	var d := Vector2(x - me.x, z - me.z).length()
	fast(d / 7 * 1.25)            # walking time, with a quarter extra for detours
	me.x = x; me.z = z
	fast(0.4)

func hold(sec: float, stop: Callable = Callable()) -> void:
	keys.interact = true
	fast(sec, func(): return false if (stop.is_valid() and stop.call()) or not day_ok() else null)
	keys.interact = false
	fast(0.1)

func cap_n() -> int:
	return 30 if me.books[0] >= 2 else 20

func wood(n: int) -> void:
	n = mini(n, cap_n())
	var g := 0
	while g < 30 and me.wood < n and day_ok():
		g += 1
		var ref := Vector2(me.x, me.z) if me.x < -30 else Vector2(-36, -6)
		var best: E.Trunk = null
		var bd := 1e9
		for t in R.trees:
			if t.alive and t.x < -33 and t.x > -60:
				var d := Vector2(t.x, t.z).distance_to(ref)
				if d < bd:
					bd = d; best = t
		if best == null: return
		go(best.x + 1.5, best.z)
		hold(25, func(): return me.wood >= n or not best.alive)

func get_res(res: String, n: int) -> void:
	n = mini(n, cap_n())
	if me.get(res) >= n or not day_ok(): return
	if res == "wood":
		wood(n); return
	var at := Vector2(R.QUARRY.x - R.QUARRY.hw - 1.2, R.QUARRY.z) if res == "stone" else Vector2(R.MINE.x - R.MINE.dir * 0.8, R.MINE.z) if res == "iron" else Vector2(-56, 30)
	go(at.x, at.y)
	hold(120, func(): return me.get(res) >= n)

func act(st: String, a: String, arg = null) -> void:
	var s := D.station(st)
	go(s.x, s.z)
	R.do_act(me, a, arg)
	fast(0.2)

func posse() -> int:
	return R.peasants.filter(func(q): return q.owner == me.id and q.state != "body").size()

func slots() -> Array:
	var a := R.structs.filter(func(s): return s.slot >= 0)
	a.sort_custom(func(a1, b1): return absf(a1.x) < absf(b1.x))
	return a

func fight() -> Dictionary:
	var st := {"t": 0.0, "min": 100.0}       # lambdas copy plain locals, so the tallies live in a dictionary
	fast(900, func():
		var m := me
		if R.phase != "night": return false
		st.t += STEP
		st.min = minf(st.min, m.hp if m.state == "ok" else 0.0)
		if m.state != "ok": return null
		if m.hp < 55 and m.food > 0: R.do_eat(m)
		keys.attack = true
		if mode != "walls" and m.abCd <= 0 and R.undead.any(func(u): return u.state != "rise" and Vector2(u.x - m.x, u.z - m.z).length() < 2.4 and not R.wall_between(m.x, m.z, u.x, u.z)):
			R.aim_assist(m); R.do_ability(m)
		var bu: E.Undead = null
		var bd := 1e9
		for u in R.undead:
			if u.state == "rise" or (u.z < -34 and u.k != 3): continue
			var dd := Vector2(u.x, u.z).length() + Vector2(u.x - m.x, u.z - m.z).length() * 0.3 - (6.0 if u.k == 2 else 0.0) - (10.0 if u.k == 3 else 0.0)
			if dd < bd:
				bd = dd; bu = u
		var tx := bu.x if bu else 0.0
		var tz := bu.z if bu else -19.0
		if bu and R.wall_between(m.x, m.z, bu.x, bu.z):   # go round by the gate
			var out := m.z > -22
			if absf(m.x) > 1.6:
				tx = 0; tz = -20.4 if out else -24.0
			else:
				tx = 0; tz = -25.0 if out else -19.0
		var dx := tx - m.x
		var dz := tz - m.z
		var far := Vector2(dx, dz).length() > (1.7 if bu and tx == bu.x else 0.5)
		keys.right = far and dx > 0.3; keys.left = far and dx < -0.3; keys.down = far and dz > 0.3; keys.up = far and dz < -0.3
		return null)
	keys.clear()
	return st


func run() -> Array:
	var log := []
	var n := 1
	while n <= 7 and R.phase == "day":
		var did := []
		if n == 1: act("library", "book", 0)
		var nb := me.books.filter(func(r): return r > 0).size()
		if nb < 3 and me.books[0] >= 2 and not me.books[2]: act("library", "book", 2)
		nb = me.books.filter(func(r): return r > 0).size()
		if nb < 3 and me.books[2] >= 2 and not me.books[3]: act("library", "book", 3)
		for i in 12:
			if posse() >= R.pm or not day_ok(): break
			var q = null
			for o in R.peasants:
				if o.state == "idle":
					q = o; break
			if q == null: break
			go(q.x + 1, q.z); keys.interact = true; fast(0.45); keys.interact = false; fast(0.1)
		# 1. the north side: build what is missing, repair what is hurt
		for s in slots():
			if not day_ok(): break
			if not s.built:
				wood(20 if s.k == "gate" else 15)
				if me.wood >= (12 if me.books[2] else 15):
					go(s.x, s.z + 1.8); hold(3, func(): return s.built); did.append("built")
			elif s.hp < s.mhp - 1:
				wood(8); go(s.x, s.z + 1.8); hold(3, func(): return s.hp >= s.mhp); did.append("repaired")
		if mode != "walls":
			# 2. food, and the slum if the posse is short
			if n >= 2 and day_ok():
				get_res("food", 10); did.append("food %d" % me.food)
				while posse() < R.pm and me.food >= 5 and day_ok():
					act("slum", "recruit"); did.append("recruit")
				if me.food < 6: get_res("food", 8)
			# 3. iron for arms, one step a day
			var wants := [null, null, ["forge", 2, {"iron": 4, "wood": 4}], ["forge", 19, {"iron": 5}], ["forge", 22, {"iron": 10}], ["forge", 25, {"iron": 4, "wood": 4}], ["armp", null, {"iron": 9, "wood": 6}], ["armp", null, {"iron": 9, "wood": 6}]]
			var want = wants[n]
			if want and day_ok():
				get_res("iron", want[2].iron)
				if want[2].has("wood"): get_res("wood", want[2].wood)
				if day_ok():
					act("smithy", want[0], want[1])
					if want[0] == "armp":
						R.do_act(me, "armp"); R.do_act(me, "armp")
					did.append(want[0] + ("" if want[1] == null else str(want[1])))
			# 4. stone facing while time lasts
			for s in slots():
				if n < 3 or not day_ok() or R.timeLeft < 70: break
				if s.built and not s.re and s.k == "wall":
					get_res("stone", 10)
					if me.stone >= 10 and day_ok():
						go(s.x, s.z + 1.8); hold(3, func(): return s.re); did.append("faced")
		var t_used := roundi(360 - R.timeLeft)
		me.ready = true; fast(0.3); fast(21, func(): return R.phase == "dusk")
		if R.phase != "night":
			log.append("day %d: did not reach night, phase %s" % [n, R.phase]); break
		me.x = 0; me.z = -19
		var plan := "%s over %ds" % ["/".join(R.night.c.map(func(v): return str(v))), R.night.dur]
		var p0 := posse()
		var keep0 := R.keepHp
		var r := fight()
		var north := ""
		for s in slots(): north += ("S" if s.re else "w") if s.built else "_"
		log.append("night %d: %s in %ds | horde %s | day took %ds: %s | posse %d->%d | player low %d %s food %d | keep %d->%d | north %s | %s, wpn %d armour %d/%d/%d books %s" % [
			n, "held" if R.phase == "day" or R.phase == "won" else R.phase.to_upper(), roundi(r.t), plan, t_used, ", ".join(did) if did.size() else "-",
			p0, posse(), roundi(r.min), "" if me.state == "ok" else "(" + me.state + ")", me.food, roundi(keep0), roundi(R.keepHp), north,
			me.dn, me.wpn, me.head, me.body, me.off, "".join(me.books.map(func(v): return str(v)))])
		if R.phase != "day": break
		n += 1
	if R.phase == "night":
		log.append("STUCK NIGHT: undead %d, still to rise %d" % [R.undead.size(), R.night.q.size()])
	log.append("end: %s day %d, kills %d, peasants lost %d" % [R.phase, R.day, R.stats.kills, R.stats.lost])
	return log
