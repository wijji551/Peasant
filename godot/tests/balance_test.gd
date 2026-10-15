extends SceneTree
## Version 7.24: the balance pass before the test groups. Checks the new limits stay put.
## Run:  godot --headless --path godot -s res://tests/balance_test.gd

var lines := []
func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))

func _init() -> void:
	seed(724)
	var R := Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}])
	var m: E.Player = R.players[0]
	m.head = D.blessed_of(D.tier_item(19, "rune")); m.body = D.blessed_of(D.tier_item(22, "rune")); m.off = D.blessed_of(D.tier_item(25, "rune"))
	m.books[3] = 10; m.books[D.B_SHIELD] = 10
	ok("full rune armour, every book: at most 65% off a blow", absf(Rules.gear_cut(m) - 0.35) < 0.001, Rules.gear_cut(m))
	m.head = -1; m.off = -1; m.body = 23; m.books[3] = 0; m.books[D.B_SHIELD] = 0
	ok("the Vicar's Breastplate takes 30% off", absf(Rules.gear_cut(m) - 0.7) < 0.001, Rules.gear_cut(m))
	m.body = -1
	ok("the Silvered Sword swings a little slower", D.IT[17].cd == 0.42)
	ok("warhammers hit harder: iron 52, and the tiers from it", D.IT[5].dmg == 52 and D.IT[D.tier_item(5, "rune")].dmg > 74, D.IT[D.tier_item(5, "rune")].dmg)
	var I: Dictionary = D.IT[0]
	var plain := Rules.dmg_of(m, I)
	m.charge = 10.0
	ok("a charge: a third harder", absf(Rules.dmg_of(m, I) / plain - 1.35) < 0.01)
	m.books[7] = 7
	ok("and at rank VII of the Ledger, 1.6, not double", absf(Rules.dmg_of(m, I) / plain - 1.6) < 0.01)
	m.charge = 0; m.books[7] = 0
	ok("holy: a third more, and 1.6 with the relic book", Rules.src_of(m, D.IT[15]).holy == 1.35 and (func(): m.books[8] = 5; return Rules.src_of(m, D.IT[15]).holy == 1.6).call())
	m.books[8] = 0
	# burning and held do not add up
	m.books[D.B_FIRE] = 9; m.books[D.B_DOG] = 6; m.x = 0; m.z = 10
	var u := R.spawn_undead(0, 1, 11); u.state = "walk"; u.stun = 99; u.hp = 900; u.mhp = 900; u.nt = 0xff
	u.burn = 5.0; u.burnby = m.id; u.held = 5.0; u.heldby = m.id
	R.hit_u(u, 10.0, {"p": m, "farm": false})
	ok("burning and held by the dog: a quarter more, not both", absf((900 - u.hp) - 12.5) < 0.1, 900 - u.hp)
	# a boss is never struck from the dark
	m.books[D.B_WATCH] = 10; m.x = 60; m.z = 30
	var b := R.spawn_undead(D.U_STEWARD if "U_STEWARD" in D else 3, 61, 31); b.state = "walk"; b.stun = 99; b.nt = 0
	var bh := b.hp
	R.hit_u(b, 10.0, {"p": m, "farm": false})
	ok("a boss is never struck from the dark", absf((bh - b.hp) - 10.0) < 0.5, bh - b.hp)
	var n := R.spawn_undead(0, 61, 30); n.state = "walk"; n.stun = 99; n.hp = 900; n.mhp = 900; n.nt = 0
	R.hit_u(n, 10.0, {"p": m, "farm": false})
	ok("an ordinary one, out in the dark, at rank X: three times", absf((900 - n.hp) - 30.0) < 0.5, 900 - n.hp)
	m.books[0] = 10
	ok("carrying stops at 50", Rules.cap(m) == 50)
	# (version 7.35) more mithril and runes for a big village: one more a vein and a seam for every two players above three
	var got := []
	for np in [4, 5, 7, 8]:
		var Rn := Rules.new()
		var inf := []
		for i in np: inf.append({"id": i + 1, "name": "P%d" % i, "col": i})
		Rn.new_game(inf)
		got.append([Rn.rune_left[0], Rn.runes2[0]])
	ok("mithril and runes: 2, 3, 4, 4 a vein and a seam for 4, 5, 7 and 8 players", got == [[2, 2], [3, 3], [4, 4], [4, 4]], got)
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
