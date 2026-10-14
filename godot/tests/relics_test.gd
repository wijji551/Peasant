extends SceneTree
## A relic for every book; leading that is learned by leading; and fishing worth the walk.
## Run:  godot --headless --path godot -s res://tests/relics_test.gd

var R: Rules
var m: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func fast(sec: float) -> void:
	var t := 0.0
	while t < sec:
		R.step(STEP); R.ev.clear(); t += STEP


func one(k: int, x: float, z: float) -> E.Undead:
	var u := R.spawn_undead(k, x, z)
	u.state = "walk"; u.t = 0; u.stun = 99; u.hp = 900; u.mhp = 900
	return u


func night() -> void:
	R.weather = "clear"
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()


func _init() -> void:
	seed(12345)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	# ---------- one for every book
	var books := {}
	for id in D.RELIC_LORE: books[D.RELIC_LORE[id][0]] = true
	ok("every book has a relic that goes with it", books.size() == D.BOOKS.size(), books.keys())
	ok("and every relic can turn up", D.RELICS.size() == D.RELIC_LORE.size() and D.RELICS.all(func(id): return D.IT[id].tier == "relic"), D.RELICS)
	ok("the four new ones are where the rules think they are", D.IT[D.I_BOW].n == "the Thunderer’s Crossbow" and D.IT[D.I_SCYTHE].n == "Saint Walstan’s Scythe" and D.IT[D.I_TROWEL].n == "the Mason’s Blessed Trowel" and D.IT[D.I_TONGS].n == "Saint Dunstan’s Tongs")
	ok("and nothing before them has moved", D.IT[D.I_TORCH].n == "burning torch" and D.IT[D.rune_of(1)].n == "mithril short sword" and D.IT[17].n == "the Silvered Sword")
	# ---------- the Thunderer's Crossbow (a bow until version 7.1)
	night()
	m.x = 0; m.z = -30; m.r = 0; m.wpn = D.I_BOW; m.books[5] = 0
	ok("anyone can draw it", Rules.can_use(m, D.I_BOW))
	var a := one(0, 0, -22.0)
	var b := one(0, 1.5, -20.5)
	var c := one(0, -1.5, -20.0)
	var d := one(0, 0.5, -18.5)
	var far := one(0, 12.0, -22.0)
	R.ev.clear()
	var tries := 0
	while a.hp == 900 and tries < 30:                       # (without the book a shot can miss)
		m.atkCd = 0; R.do_attack(m); tries += 1
	var zaps: Array = R.ev.filter(func(e): return e[0] == "zap")
	var struck := [b, c, d].filter(func(u): return u.hp < 900).size()
	ok("its arrow jumps on to two more of the dead", a.hp < 900 and zaps.size() == 2 and struck == 2 and far.hp == 900, [zaps.size(), struck])
	ok("at half strength", [b, c, d].all(func(u): return u.hp == 900 or absf((900 - u.hp) - (900 - a.hp) * 0.5) < 1.0), [900 - a.hp, 900 - b.hp, 900 - c.hp])
	for u in [a, b, c, d]: u.hp = 900
	m.books[5] = 2                                          # (rank 2: a shot never misses)
	R.ev.clear()
	m.atkCd = 0; R.do_attack(m)
	ok("with its book, to a third", [b, c, d].filter(func(u): return u.hp < 900).size() == 3 and R.ev.filter(func(e): return e[0] == "zap").size() == 3)
	R.undead.clear(); m.books[5] = 0
	# ---------- the Smoking Censer: it has to slow their blows as well as their feet, and be seen to
	m.wpn = 0; m.trk = 27; m.x = 0; m.z = -30
	var s1 := one(0, 0, -24.0)                              # six paces off: in the smoke
	var s2 := one(0, 0, -16.0)                              # fourteen: out of it
	var sb := one(D.U_STEWARD, 3.0, -25.0)                  # a boss, in it
	for u in [s1, s2, sb]: u.stun = 0
	R.step(STEP)
	ok("the dead within eight paces of the censer are in its smoke, and slowed", s1.smoke > 0 and s1.slow > 0, [s1.smoke, s1.slow])
	ok("the dead beyond it are not", s2.smoke == 0 and s2.slow == 0, [s2.smoke, s2.slow])
	ok("a boss is slowed on his feet, but not in his blows", sb.smoke == 0 and sb.slow > 0, [sb.smoke, sb.slow])
	s1.cd = 1.0; s2.cd = 1.0
	R.step(STEP)
	ok("in the smoke they strike half as often", absf((1.0 - s1.cd) - STEP * D.CENSER.strike) < 0.001 and absf((1.0 - s2.cd) - STEP) < 0.001, [1.0 - s1.cd, 1.0 - s2.cd])
	m.trk = -1
	fast(0.5)
	ok("and it clears when the censer is put down", s1.smoke == 0)
	ok("the relic crossbow is slow and heavy, and still anybody's", D.IT[D.I_BOW].cd > D.IT[14].cd and D.IT[D.I_BOW].dmg > D.IT[14].dmg and D.IT[D.I_BOW].pool == "xbow" and Rules.can_use(m, D.I_BOW))
	ok("a stone from a watch platform does five", D.PLAT.dmg == 5.0)
	R.undead.clear(); m.x = 0; m.z = -30
	# ---------- the Mason's Blessed Trowel
	fast(0.3)                                               # (the empty night ends, and everyone is sent home)
	var wall: E.Struct = R.structs[0]
	wall.built = true; wall.hp = wall.mhp - 50
	m.x = wall.x; m.z = wall.z + 3.0; m.wpn = 0; m.trk = D.I_TROWEL
	var h0 := wall.hp
	fast(5.0)
	ok("a wall near its carrier mends by itself", wall.hp > h0 + 10 and wall.hp <= h0 + 5 * D.TROWEL_MEND + 3.1, wall.hp - h0)
	m.x = wall.x + 40
	h0 = wall.hp
	fast(3.0)
	ok("but not from across the village", wall.hp == h0)
	m.books[2] = 1; wall.hp = wall.mhp - 50
	ok("with its book, your own repairs cost nothing", Rules.repair_cost(m, wall).wood == 0)
	m.x = wall.x; h0 = wall.hp
	fast(3.0)
	ok("and it mends twice as fast", wall.hp >= h0 + 3 * D.TROWEL_MEND * 2 - 0.1, wall.hp - h0)
	m.books[2] = 0; m.trk = -1
	# ---------- Saint Dunstan's Tongs
	var sword: Dictionary = D.IT[1]
	var plain := Rules.forge_cost(m, sword.cost)
	var d0 := Rules.dmg_of(m, sword)
	m.trk = D.I_TONGS
	var with := Rules.forge_cost(m, sword.cost)
	ok("forging costs a quarter less", with.iron == ceili(plain.iron * 0.75) and with.wood == ceili(plain.wood * 0.75), [plain, with])
	ok("the blade is no better for it, without the book", is_equal_approx(Rules.dmg_of(m, sword), d0))
	m.books[3] = 1; m.wpn = 1
	var d1 := Rules.dmg_of(m, sword)
	m.trk = -1
	ok("with the book, forged weapons hit a tenth harder", is_equal_approx(d1, Rules.dmg_of(m, sword) * 1.1), [d1, Rules.dmg_of(m, sword)])
	m.books[3] = 0; m.wpn = 0
	# ---------- Saint Walstan's Scythe
	m.books[0] = 1
	var t0 := Rules.gather_time(m, "tree")
	m.wpn = D.I_SCYTHE
	ok("with the Almanac, its carrier gathers faster", is_equal_approx(Rules.gather_time(m, "tree"), t0 * 0.8), [t0, Rules.gather_time(m, "tree")])
	m.books[0] = 0
	ok("without it, no faster", is_equal_approx(Rules.gather_time(m, "tree"), Rules.gather_time(R.players[0], "tree")))
	m.wpn = 0
	# ---------- leading is learned by leading
	R.undead.clear()
	fast(0.2)
	m.books[6] = 0; m.xp[6] = 0.0; m.order = 0
	R.do_order(m)
	ok("no orders without the book", m.order == 0)
	m.books[6] = 1
	var q: E.Peasant = null
	for o in R.peasants:
		if o.kind == 0 and o.owner == 0 and o.state != "body" and q == null: q = o
	q.owner = m.id; q.state = "follow"
	R.player_step(m, STEP)
	ok("a posse of one", m.posse >= 1, m.posse)
	R.do_order(m)
	ok("rank 1: hold", m.order == 1 and is_equal_approx(m.xp[6], D.ORDER_XP), [m.order, m.xp[6]])
	R.do_order(m)
	ok("and back to follow: no charge yet", m.order == 0)
	for i in 30: R.do_order(m)
	ok("the first ten orders of a day teach; the rest are just shouting", is_equal_approx(m.xp[6], D.ORDER_XP * D.ORDERS_DAY) or m.books[6] > 1, [m.xp[6], m.books[6]])
	m.books[6] = 3; m.order = 0
	R.do_order(m); R.do_order(m)
	ok("rank 3: charge", m.order == 2)
	m.books[6] = 1; m.xp[6] = 0.0; m.order = 0
	R.gather_one("tree", R.trees.filter(func(t): return t.alive)[0], m)
	ok("your own chopping teaches no leading", m.xp[6] == 0.0)
	# ---------- fishing
	m.books[1] = 0; m.fish = 0; m.gk = 5; m.bite = 1.0
	R.do_fish(m)
	ok("a catch is five fish", m.fish == D.FISH_FOOD and D.FISH_FOOD == 5, m.fish)
	m.books[1] = 3; m.fish = 0; m.gk = 5; m.bite = 1.0
	R.do_fish(m)
	ok("seven with the third rank of the book", m.fish == 7, m.fish)
	var coins := 0
	var runes := 0
	var things := 0
	m.books[1] = 0
	for i in 2000:
		m.fish = 0; m.gk = 5; m.bite = 1.0; m.inv = []
		var c0 := m.coin
		var r0 := m.mith
		m.mith = 0
		R.do_fish(m)
		if m.coin > c0: coins += 1
		if m.mith > 0: runes += 1
		if m.inv.size() > 0: things += 1
		m.mith = r0
		R.drops.clear()
	ok("the river gives back coin now and then", coins > 2000 * 0.10 and coins < 2000 * 0.20, coins)
	ok("a lump of mithril once in a long while", runes > 2000 * 0.015 and runes < 2000 * 0.06, runes)
	ok("and very rarely something somebody dropped", things > 5 and things < 70, things)
	# ---------- the dead last longer as the month goes on
	ok("week by week the dead take more putting down", Rules.hp_of(3) == D.DEAD_HP[0] and Rules.hp_of(10) == D.DEAD_HP[1] and Rules.hp_of(17) == D.DEAD_HP[2] and Rules.hp_of(25) == D.DEAD_HP[3] and D.DEAD_HP == [2.0, 4.5, 6.3, 8.4])
	ok("while what they hit for grows as before", is_equal_approx(Rules.tough_of(25), 1.3))
	R.day = 16; R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	var sh := R.spawn_undead(0, 0, -60)
	ok("a shambler of the third week has the third week's health", absf(sh.mhp / (D.UN[0].hp * R.crowd) - D.DEAD_HP[2] * (D.BELLS.hp if R.bells() else 1.0)) < 0.01, sh.mhp)
	# ---------- the nights of the bells
	var by_week := {2: 0, 3: 0, 4: 0}
	var bad_day := false
	for dd in range(1, 31):
		if Rules.bells_night(R.gseed, dd, D.MONTH):
			if dd < 8 or dd == 15 or D.BOSS_NIGHTS.has(dd): bad_day = true
			else: by_week[Rules.week_of(dd)] += 1
	ok("three nights of the bells a month: one in each week after the first", by_week == {2: 1, 3: 1, 4: 1} and not bad_day, by_week)
	ok("never a boss's night or the full moon, whatever the seed", range(1, 200).all(func(sd): return not Rules.bells_night(sd, 15, D.MONTH) and not Rules.bells_night(sd, 14, D.MONTH) and not Rules.bells_night(sd, 21, D.MONTH) and not Rules.bells_night(sd, 30, D.MONTH) and not Rules.bells_night(sd, 5, D.MONTH)))
	ok("the short game has one, on its fourth night", Rules.bells_night(7, 4, D.WEEK) and not Rules.bells_night(7, 3, D.WEEK))
	var bd := 0
	for dd in range(8, 14):
		if Rules.bells_night(R.gseed, dd, D.MONTH): bd = dd
	var RB := Rules.new()
	RB.new_game([{"id": 1, "name": "Matt", "col": 0}])
	RB.gseed = R.gseed; RB.day = bd; RB.weather = "clear"
	RB.dusk_falls(); RB.timeLeft = 0.01; RB.step(STEP)
	ok("on the night, the bells are rung", RB.phase == "night" and RB.bells() and RB.ev.any(func(e): return e[0] == "bells"), [bd, RB.phase])
	var su := RB.spawn_undead(0, 0, -60)
	ok("and the dead are enraged: more health, harder blows, quicker", absf(su.mhp / (D.UN[0].hp * RB.crowd) - D.DEAD_HP[1] * D.BELLS.hp) < 0.01 and is_equal_approx(RB.tough, 1.1 * D.BELLS.dmg) and is_equal_approx(RB.wspeed(), D.BELLS.speed), [su.mhp, RB.tough, RB.wspeed()])
	RB.day = bd + 1 if not Rules.bells_night(R.gseed, bd + 1, D.MONTH) else bd - 1
	ok("the night after is an ordinary one", not RB.bells())
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
