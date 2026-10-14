extends SceneTree
## Version 7.17: fish, apart from food, that heal you fully; and Field, Hook and Pot as the posse's cook.
## Run:  godot --headless --path godot -s res://tests/fish_test.gd

var lines := []
func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))

func _init() -> void:
	seed(717)
	var R := Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	var m: E.Player = R.players[0]
	var f: E.Player = R.players[1]
	m.food = 0; m.fish = 0; m.gk = 5; m.bite = 1.0
	R.do_fish(m)
	ok("a catch is fish, not food", m.fish == 5 and m.food == 0, [m.fish, m.food])
	m.hp = 10
	R.eat_fish(m)
	ok("one fish: back to full health at once", m.hp == Rules.max_hp(m) and m.fish == 4)
	m.hp = 10
	R.eat_fish(m)
	ok("and then a wait before the next", m.hp == 10 and m.fish == 4 and m.fishCd > 15)
	m.fishCd = 0; m.hp = Rules.max_hp(m)
	R.eat_fish(m)
	ok("not eaten when you are well", m.fish == 4)
	m.books[1] = 9; m.hp = 5
	R.eat_fish(m)
	ok("rank IX: the next sooner", m.fishCd <= D.FISH.wait9 + 0.01)
	m.books[1] = 10; m.fishCd = 0; m.hp = Rules.max_hp(m); f.x = m.x + 1; f.z = m.z; f.hp = 10; f.state = "ok"
	R.eat_fish(m)
	ok("rank X: everyone near you as well, even when you are well yourself", f.hp == Rules.max_hp(f))
	# the market
	m.books[1] = 0; m.x = 0; m.z = 19.7; m.fish = 5; m.coin = 0
	R.do_act(m, "sell", "fish")
	ok("fish sell for twice what food does", m.coin == 10, m.coin)
	m.books[1] = 5; m.fish = 5; m.coin = 0
	R.do_act(m, "sell", "fish")
	ok("twice again at rank V", m.coin == 20, m.coin)
	m.coin = 50
	R.do_act(m, "buy", "fish")
	ok("and the market sells none", m.coin == 50)
	# prize fish
	m.books[1] = 8
	var prizes := 0
	for i in 600:
		m.fish = 0; m.gk = 5; m.bite = 1.0; var c0 := m.coin
		R.do_fish(m)
		if m.coin >= c0 + D.FISH.prize_coin: prizes += 1
	ok("rank VIII: one catch in ten a prize", prizes > 35 and prizes < 95, prizes)
	# the posse's cook
	m.books[1] = 0; m.xp[1] = 0.0
	var q: E.Peasant = null
	for o in R.peasants:
		if o.kind == 0 and o.owner == 0 and q == null: q = o
	q.owner = m.id; q.state = "follow"; q.x = m.x; q.z = m.z + 1
	R.dusk_falls(); R.timeLeft = 0.01; R.step(1.0 / 30.0); R.night.q = []; R.night.boss = -1; R.undead.clear()
	var keeper := R.spawn_undead(0, 100, -55); keeper.state = "walk"; keeper.stun = 9999; keeper.hp = 90000; keeper.mhp = 90000
	m.food = 10; q.hp = 20
	R.step(1.0 / 30.0)
	ok("without the book, the posse does not cook", q.hp <= 20.5 and m.food == 10)
	m.books[1] = 1
	R.step(1.0 / 30.0)
	ok("from rank I: a peasant badly hurt eats one of your food, and mends", m.food == 9 and q.hp > 30, [m.food, q.hp])
	q.hp = 20
	R.step(1.0 / 30.0)
	ok("not again straight away", m.food == 9)
	q.ate = 0; q.hp = Rules.q_max(q) * 0.6
	R.step(1.0 / 30.0)
	ok("only when badly hurt", m.food == 9, [m.food, q.hp, Rules.q_max(q), R.peasants.filter(func(o): return o.owner == m.id).size()])
	m.books[1] = 6
	R.step(1.0 / 30.0)
	ok("rank VI: before it is badly hurt", m.food == 8)
	ok("fish are kept, and sent", Rules.P_SAVE.has("fish") and Net.PF.has("fish") and Net.PF.has("fishCd") and D.STORE_RES.has("fish"))
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
