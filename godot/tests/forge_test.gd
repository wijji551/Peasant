extends SceneTree
## Version 7.6: the smithy's five tiers (crude, iron, steel, mithril, rune), what each makes, the posse kits, rune armour
## blessed for good, and old saves (whose runes are mithril now).
## Run:  godot --headless --path godot -s res://tests/forge_test.gd

var R: Rules
var m: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func fast(sec: float, fn: Callable = Callable()) -> void:
	var t := 0.0
	while t < sec:
		if fn.is_valid() and fn.call() == false: return
		R.step(STEP); R.ev.clear(); t += STEP


func _init() -> void:
	seed(76)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	m = R.players[0]
	R.weather = "clear"
	var sm := D.station("smithy")
	# ---------- every tier makes everything
	var full := true
	var missing := []
	for t in D.TIERS:
		for b in D.STEEL_W + D.BOWS + D.ARMOUR:
			var id: int = D.crude_of(b) if t == "crude" and b in D.STEEL_W else D.steel_of(b) if t == "steel" and not b in D.BOWS else D.tier_item(b, t)
			if id < 0 or D.IT[id].tier != t or D.IT[id].base != (b if t != "forged" else -1):
				full = false; missing.append([t, b])
	ok("five tiers, each with five weapons, a bow, a crossbow, a helm, a body and a shield", full, missing)
	ok("nothing that was there before has changed its number", D.IT[D.I_TORCH].n == "burning torch" and D.IT[D.I_BOW].n == "the Thunderer’s Crossbow" and D.IT[57].n == "Saint Dunstan’s Tongs" and D.IT[49].n == "mithril short sword")
	var sp := func(t: String) -> int: return D.IT[2 if t == "forged" else D.crude_of(2) if t == "crude" else D.steel_of(2) if t == "steel" else D.tier_item(2, t)].dmg
	ok("each tier hits harder than the one before", sp.call("crude") < sp.call("forged") and sp.call("forged") < sp.call("steel") and sp.call("steel") < sp.call("mithril") and sp.call("mithril") < sp.call("rune"), D.TIERS.map(sp))
	ok("mithril is the old rune, a good deal weaker (about half as good again as iron)", absf(D.IT[D.rune_of(5)].dmg - D.IT[5].dmg * 1.5) < 1 and D.IT[D.rune_of(5)].tier == "mithril", D.IT[D.rune_of(5)].dmg)
	ok("rune is a tenth better again", absf(float(sp.call("rune")) / sp.call("mithril") - 1.1) < 0.06)
	var sh := func(t: String) -> float: return D.IT[25 if t == "forged" else D.steel_of(25) if t == "steel" else D.tier_item(25, t)].cut
	ok("a shield in every tier, each better than the last", sh.call("crude") < sh.call("forged") and sh.call("forged") < sh.call("steel") and sh.call("steel") < sh.call("mithril") and sh.call("mithril") < sh.call("rune"), D.TIERS.map(sh))
	ok("crude bows and crossbows want no book; better ones do", D.IT[D.tier_item(13, "crude")].need.is_empty() and D.IT[D.tier_item(14, "crude")].need.is_empty() and D.IT[D.tier_item(13, "steel")].need == [5, 1])
	ok("and wear out like other crude arms", D.IT[D.tier_item(13, "crude")].wear == 1 and D.IT[D.tier_item(13, "crude") + 1].wear == 2 and D.IT[D.tier_item(13, "crude") + 1].base == 13)
	# ---------- who can forge what
	m.x = sm.x; m.z = sm.z
	ok("anyone can forge crude armour and a crude bow", Rules.can_forge(m, D.tier_item(25, "crude")) and Rules.can_forge(m, D.tier_item(13, "crude")))
	m.books[3] = 6
	ok("mithril at rank 7 of Hammer and Tongs, as rune was", not Rules.can_forge(m, D.tier_item(19, "mithril")) and (func(): m.books[3] = 7; return Rules.can_forge(m, D.tier_item(19, "mithril"))).call())
	var rs := D.tier_item(1, "rune")
	ok("rune cannot be forged yet, and the smithy says why", not Rules.can_forge(m, rs) and Rules.forge_why(m, rs).contains("across the river"), Rules.forge_why(m, rs))
	m.mith = 3; m.steel = 20; m.wood = 0
	var mc := D.tier_item(19, "mithril")
	R.do_act(m, "forge", mc)
	ok("a mithril cap: three mithril and some steel, and it goes on", m.head == mc and m.mith == 0, [m.head, m.mith])
	# ---------- kits
	m.books[3] = 0
	var kc: int = D.kits()[1]                                   # the crude watchman's
	ok("six kits: a ranger and a watchman in crude, iron and steel", D.kits().size() == 6 and D.IT[kc].kit == "watch" and D.IT[kc].tier == "crude")
	ok("kits need Hammer and Tongs: crude rank 1, iron 3, steel 6", not Rules.can_forge(m, kc) and (func(): m.books[3] = 1; return Rules.can_forge(m, kc) and not Rules.can_forge(m, D.kits()[2])).call() and (func(): m.books[3] = 6; return Rules.can_forge(m, D.kits()[4])).call())
	var q: E.Peasant = null
	for o in R.peasants:
		if o.kind == 0 and o.state != "body" and q == null: q = o
	q.owner = m.id; q.state = "follow"; q.x = m.x + 1; q.z = m.z
	m.iron = 10; m.wood = 5; m.books[3] = 1
	ok("ten of the metal and five wood (less with the book)", D.IT[kc].cost == {"iron": 10, "wood": 5})
	R.do_act(m, "forge", kc)
	ok("a kit goes straight to one of your posse", q.kit == kc and m.inv.is_empty(), [q.kit, m.inv])
	var kg := Rules.kit_gear(kc, q.ni)
	ok("a watchman has a weapon, a helm and a shield of the kit's tier", kg[0] >= 0 and D.IT[kg[0]].tier == "crude" and D.IT[kg[0]].s == "w" and kg[1] == D.tier_item(19, "crude") and kg[2] == D.tier_item(25, "crude"), kg)
	var rg := Rules.kit_gear(D.kits()[0], q.ni)
	ok("a ranger, a bow and a cap", D.IT[rg[0]].pool == "bow" and rg[1] >= 0 and rg[2] == -1, rg)
	var weapons := {}
	for i in 10: weapons[Rules.kit_gear(D.kits()[3], i)[0]] = true
	ok("the watchman's weapon varies", weapons.size() >= 3, weapons.keys())
	# a ranger shoots from behind the others
	var r2: E.Peasant = null
	for o in R.peasants:
		if o.kind == 0 and o.state != "body" and o.owner == 0 and r2 == null: r2 = o
	r2.owner = m.id; r2.state = "follow"; r2.kit = D.kits()[2]
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()
	m.x = 0; m.z = 6; r2.x = 0; r2.z = 8; q.x = 40; q.z = 40
	var u := R.spawn_undead(0, 0, -2.5)
	u.state = "walk"; u.stun = 99; u.hp = 900; u.mhp = 900
	var shots := 0
	var t := 0.0
	var closest := 99.0
	while t < 5.0:
		R.step(STEP); t += STEP
		shots += R.ev.filter(func(e): return e[0] == "shot" and e[5] == 1).size()
		closest = minf(closest, sqrt(D.d2(r2.x, r2.z, u.x, u.z)))
		R.ev.clear()
	ok("a ranger shoots, and keeps their distance", shots >= 2 and u.hp < 900 and closest > 5.0, [shots, u.hp, closest])
	# and the armour keeps something off
	var plain := E.Peasant.new(); plain.hp = 100
	R.hurt_friend(plain, 20, false, null, false)
	q.hp = 100
	R.hurt_friend(q, 20, false, null, false)
	ok("a watchman's helm and shield keep some of it off", 100 - q.hp < 100 - plain.hp, [100 - q.hp, 100 - plain.hp])
	# it outlives them
	q.x = 2; q.z = 2
	var nd := R.drops.size()
	q.hp = 1; q.saved = true
	R.hurt_friend(q, 50, false, null, false)
	ok("when a kitted peasant falls, the kit lies where they fell", q.state == "body" and q.kit == 0 and R.drops.size() == nd + 1 and R.drops[-1].it == kc, [q.state, R.drops.size()])
	# crude kits come apart after two nights
	R.night.q = []; R.undead.clear()
	r2.kit = D.kits()[0]; r2.kw = 0
	R.end_night()
	ok("a crude kit lasts the first night", r2.kit == D.kits()[0] and r2.kw == 1)
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP); R.night.q = []; R.night.boss = -1; R.undead.clear()
	R.end_night()
	ok("and is gone after the second", r2.kit == 0 and R.dawn.lines.any(func(l): return l.contains("come apart")), R.dawn.lines)
	r2.kit = D.kits()[2]
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP); R.night.q = []; R.night.boss = -1; R.undead.clear(); R.end_night()
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP); R.night.q = []; R.night.boss = -1; R.undead.clear(); R.end_night()
	ok("an iron one does not wear", r2.kit == D.kits()[2])
	# from the backpack
	m.inv = [D.kits()[3]]
	var r3: E.Peasant = null
	for o in R.peasants:
		if o.kind == 0 and o.state != "body" and o.owner == 0 and r3 == null: r3 = o
	r3.owner = m.id; r3.state = "follow"; r3.kit = 0
	R.do_act(m, "kit", 0)
	ok("a kit in the backpack can be handed to one of your posse", r3.kit == D.kits()[3] and m.inv.is_empty())
	var sv := R.save_data()
	var R2 := Rules.new()
	R2.load_game(sv, [{"id": 1, "name": "Matt", "col": 0}])
	ok("kits are saved", R2.peasants.any(func(o): return o.kit == D.kits()[3]) and R2.peasants.any(func(o): return o.kit == D.kits()[2]))
	# ---------- blessed rune armour
	var pr := D.station("priest")
	m.x = pr.x; m.z = pr.z
	var rb := D.tier_item(22, "rune")
	m.body = rb; m.coin = 300; m.holy = 1
	ok("the priest offers to bless rune armour for good, but only after both classes", Notices.data(R, "priest", m, "").o.any(func(o): return o.get("a", "") == "rbless" and not o.ok))
	R.do_act(m, "rbless", "body")
	ok("and will not do it before", m.body == rb and m.coin == 300)
	m.holy = 2
	R.do_act(m, "rbless", "body")
	ok("after both: a gold piece, and it is blessed for good", D.IT[m.body].blessed and D.IT[m.body].base == 22 and m.coin == 300 - D.RUNE_BLESS, [m.body, m.coin])
	m.head = D.tier_item(19, "mithril"); m.coin = 300
	ok("nothing else can be: not mithril, not weapons", not Notices.data(R, "priest", m, "").o.any(func(o): return o.get("a", "") == "rbless") and D.blessed_of(m.head) == -1)
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP); R.night.q = []; R.night.boss = -1; R.undead.clear()
	m.x = 30; m.z = 30; m.hp = 100; m.hurtT = 99; m.state = "ok"; m.charge = 0; m.prot = 0; m.books[4] = 0; m.head = -1; m.off = -1
	var w := R.spawn_undead(D.U_WRAITH, 31, 30)
	var wp := E.Player.new(); wp.hp = 100; wp.state = "ok"; wp.body = D.tier_item(22, "rune"); wp.head = -1; wp.off = -1
	R.hurt_friend(wp, 20, true, w, false)
	m.hp = 100
	R.hurt_friend(m, 20, true, w, false)
	ok("wraiths do half their harm through blessed rune armour", absf((100 - m.hp) * 2 - (100 - wp.hp)) < 0.6, [100 - m.hp, 100 - wp.hp])
	ok("and whatever strikes it is scorched", w.hp < w.mhp, [w.hp, w.mhp])
	# ---------- an old save: its runes are mithril now
	var old := R.save_data()
	old.v = 3
	old.store.rune = 7; old.store.erase("mith")
	old.players[0].rune = 5; old.players[0].erase("mith")
	var R3 := Rules.new()
	R3.load_game(old, [{"id": 1, "name": "Matt", "col": 0}])
	ok("an old save's runes become mithril, the player's and the storehouse's", R3.players[0].mith == 5 and R3.players[0].rune == 0 and R3.store.mith == 7 and R3.store.rune == 0, [R3.players[0].mith, R3.store])
	var twice := []
	for tier_ in D.TIERS + ["kits"]:
		var args: Array = Notices.data(R, "smithy", m, tier_).o.filter(func(o): return o.get("a", "") == "forge").map(func(o): return o.arg)
		for x in args:
			if args.count(x) > 1 and not twice.has([tier_, x]): twice.append([tier_, x])
	ok("no page of the smithy lists the same thing twice (the iron bow and crossbow did)", twice.is_empty(), twice)
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
