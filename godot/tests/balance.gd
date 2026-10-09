extends SceneTree
## A measuring stick, not a test: the same night fought by 1, 2, 4 and 8 players with the same kit each, to see whether
## more players have it easier or harder. Each player gets a full posse and the gear a careful village would have by
## then; the north wall is built (stone-faced from night 3, the gate banded from night 8). Nobody repairs or builds.
## Run:  godot --headless --path godot -s res://tests/balance.gd -- 1,7,14 1,2,4,8

var R: Rules
const STEP := 1.0 / 30.0


func kit(p: E.Player, d: int) -> void:
	p.food = 6
	if d >= 3:
		p.wpn = 2; p.head = 19; p.books[3] = 1; p.books[4] = 2
	if d >= 8:
		p.body = 22; p.off = 25; p.books[4] = 3
	if d >= 15:
		p.wpn = 40; p.head = 44; p.body = 45; p.off = 46; p.books[3] = 4; p.books[4] = 5
		p.holy = 1; p.bless = 1                       # a class of holy studies, and a blessed weapon, for the wraiths
	if d >= 22: p.books[4] = 7
	p.hp = Rules.max_hp(p)


func setup(d: int, n: int) -> void:
	R = Rules.new()
	var infos := []
	for i in n: infos.append({"id": i + 1, "name": "P%d" % (i + 1), "col": i})
	R.new_game(infos)
	R.day = d; R.weather = "clear"
	for s in R.structs:
		if s.slot < 0: continue
		s.built = true; s.mhp = D.SHP[s.k]
		if (s.k == "wall" and d >= 3) or (s.k == "gate" and d >= 8):
			s.re = true; s.mhp = float(roundi(s.mhp * D.REINF[s.k].mul))
		s.hp = s.mhp
	for p in R.players:
		kit(p, d)
		var got := 0
		for q in R.peasants:
			if q.owner == 0 and q.state == "idle" and got < R.pm:
				q.owner = p.id; q.state = "follow"; got += 1
				if d >= 6: q.armed = 1
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	for i in n:
		R.players[i].x = (i - (n - 1) / 2.0) * 2.0; R.players[i].z = -19.0


func run(d: int, n: int) -> String:
	setup(d, n)
	var heads: int = R.night.total
	var keep0 := R.keepHp
	var cds := []; cds.resize(n); cds.fill(0.0)
	var was := []; was.resize(n); was.fill("ok")
	var downs := 0
	var peak := 0
	var t := 0.0
	while R.phase == "night" and t < 600:
		for i in n:
			var m: E.Player = R.players[i]
			cds[i] = maxf(0, cds[i] - STEP)
			if m.state != was[i]:
				if m.state == "down": downs += 1
				was[i] = m.state
			if m.state != "ok": continue
			if m.hp < 55 and m.food > 0: R.do_eat(m)
			if m.abCd <= 0 and R.undead.any(func(u): return u.state != "rise" and Vector2(u.x - m.x, u.z - m.z).length() < 2.4 and not R.wall_between(m.x, m.z, u.x, u.z)):
				R.aim_assist(m); R.do_ability(m)
			m.eHold = false
			var mate: E.Player = null                 # a team-mate is down nearby: get them up
			for o in R.players:
				if o.state == "down" and D.d2(o.x, o.z, m.x, m.z) < 144 and (mate == null or D.d2(o.x, o.z, m.x, m.z) < D.d2(mate.x, mate.z, m.x, m.z)): mate = o
			if mate:
				var md := Vector2(mate.x - m.x, mate.z - m.z)
				if md.length() > 1.0: R.move_player(m, signf(md.x) if absf(md.x) > 0.3 else 0.0, signf(md.y) if absf(md.y) > 0.3 else 0.0, STEP, t)
				else: m.eHold = true
				continue
			var home_x := lerpf(-15.0, 15.0, (i + 0.5) / n) if n > 1 else 0.0    # each has a stretch of the wall to mind
			var bu: E.Undead = null
			var bd := 1e9
			for u in R.undead:
				if u.state == "rise" or (u.z < -34 and not D.UN[u.k].boss): continue
				var dd := Vector2(u.x, u.z).length() + Vector2(u.x - m.x, u.z - m.z).length() * 0.6 + absf(u.x - home_x) * 0.5
				if dd < bd:
					bd = dd; bu = u
			var tx := bu.x if bu else (i - (n - 1) / 2.0) * 3.0
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
			R.move_player(m, (1.0 if far and dx > 0.3 else 0.0) - (1.0 if far and dx < -0.3 else 0.0), (1.0 if far and dz > 0.3 else 0.0) - (1.0 if far and dz < -0.3 else 0.0), STEP, t)
			if cds[i] <= 0:
				cds[i] = D.IT[m.wpn].cd
				R.aim_assist(m); R.do_attack(m)
		R.step(STEP); R.ev.clear()
		peak = maxi(peak, R.undead.size())
		if OS.get_environment("BAL_LOG") != "" and fmod(t, 10.0) < STEP:
			print("  t%3d: up %3d, to rise %3d, kills %3d, boss %s | " % [t, R.undead.size(), R.night.q.size(), R.night.kills, ("%d@%d,%d" % [R.boss.hp, R.boss.x, R.boss.z]) if R.boss else "-"],
				R.players.map(func(p): return "%s %d@%d,%d" % [p.state, p.hp, p.x, p.z]), " posse ", R.peasants.filter(func(q): return q.owner > 0 and q.state != "body").size(), " keep ", roundi(R.keepHp))
		t += STEP
	if R.phase == "night":                           # stuck: say what is left, and where
		print("  STUCK night %d, %d players: to rise %d; left " % [d, n, R.night.q.size()], R.undead.map(func(u): return "%s:%s@%d,%d hp%d" % [D.UN[u.k].name, u.state, u.x, u.z, u.hp]).slice(0, 12),
			"; players ", R.players.map(func(p): return "%s@%d,%d" % [p.state, p.x, p.z]))
	var up := 0
	var wall_hp := 0.0
	var wall_max := 0.0
	for s in R.structs:
		if s.slot >= 0:
			wall_max += s.mhp
			if s.built:
				up += 1; wall_hp += s.hp
	var alive := R.players.filter(func(p): return p.state == "ok").size()
	return "night %2d, %d player%s: %-5s in %3ds | %4d heads, peak %3d at once | keep -%4d (%2d%%) | downed %d, standing %d/%d | peasants lost %2d/%2d (%2d%%) | wall %d/7 up, %2d%% left" % [
		d, n, " " if n == 1 else "s", "held" if R.phase != "night" and R.phase != "lost" else R.phase.to_upper(), roundi(t), heads, peak, roundi(keep0 - R.keepHp), roundi((keep0 - R.keepHp) / keep0 * 100),
		downs, alive, n, R.stats.lost, n * R.pm, roundi(R.stats.lost * 100.0 / (n * R.pm)), up, roundi(wall_hp / wall_max * 100)]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var nights := (args[0] if args.size() > 0 else "1,7,14").split(",")
	var counts := (args[1] if args.size() > 1 else "1,2,4,8").split(",")
	seed(12345)
	for d in nights:
		for n in counts:
			print(run(int(d), int(n)))
	quit()
