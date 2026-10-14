extends SceneTree
## Version 7.9: the four new books (fire, the night watchman, shield-work, the dog), boots, and relics for every player.
## Run:  godot --headless --path godot -s res://tests/newbooks_test.gd

var R: Rules
var m: E.Player
var f: E.Player
var lines := []
const STEP := 1.0 / 30.0


func ok(name: String, cond: bool, extra = null) -> void:
	lines.append(("PASS " if cond else "FAIL ") + name + ("" if extra == null else "  [" + str(extra) + "]"))


func fast(sec: float) -> void:
	var t := 0.0
	while t < sec:
		R.step(STEP); R.ev.clear(); t += STEP


func only(b: int, r: int) -> void:
	for i in m.books.size(): m.books[i] = 0
	m.books[b] = r
	m.pwCd = []; m.state = "ok"; m.frozen = 0; m.room = ""


func one(k: int, x: float, z: float) -> E.Undead:
	var u := R.spawn_undead(k, x, z)
	u.state = "walk"; u.stun = 99; u.hp = 900; u.mhp = 900
	return u


func night() -> void:
	R.dusk_falls(); R.timeLeft = 0.01; R.step(STEP)
	R.night.q = []; R.night.boss = -1; R.undead.clear()


func _init() -> void:
	seed(79)
	R = Rules.new()
	R.new_game([{"id": 1, "name": "Matt", "col": 0}, {"id": 2, "name": "Fred", "col": 1}])
	m = R.players[0]; f = R.players[1]
	R.weather = "clear"
	# ---------- the shelf
	ok("sixteen books, the new four after the Holy Book, ten ranks each", D.BOOKS.size() == 16 and D.BOOKS[11].name == "Fire and How to Start It" and D.BOOKS[14].name.begins_with("Dogs") and D.BOOKS.all(func(b): return b.ranks.size() == 10))
	ok("titles for them", D.TITLE_NOUN.size() == 16 and D.TITLE_ADJ.size() == 16)
	ok("the new things kept their numbers after everything else", D.IT[D.I_MATCH].n == "the Everlasting Match" and D.IT[D.I_HOTFOOT].n.begins_with("Brother Cinder") and D.IT[90].s == "k")
	ok("an old save's books are made up to the full shelf", (func():
		var sv := R.save_data(); for pr in sv.players: pr.books = pr.books.slice(0, 11); pr.xp = pr.xp.slice(0, 11)
		var R2 := Rules.new(); R2.load_game(sv, [{"id": 1, "name": "Matt", "col": 0}]); return R2.players[0].books.size() == D.BOOKS.size()).call())
	# ---------- fire
	night()
	only(D.B_FIRE, 1)
	m.x = 0; m.z = -40; m.r = PI
	var u := one(0, 0, -45)
	R.book_power(m, D.B_FIRE)
	ok("the fire stick: one of the dead ahead goes up", u.burn > 0 and m.fs == 0)
	R.book_power(m, D.B_FIRE)
	ok("one stick to hand, and it is gone until another is ready", m.fsT > 0)
	only(D.B_FIRE, 8)
	m.fs = 2
	R.book_power(m, D.B_FIRE)
	ok("rank 8: two sticks", m.fs == 1)
	only(D.B_FIRE, 4)
	m.fs = 1; R.undead.clear()
	var a := one(0, 0, -45)
	var b := one(0, 1.5, -45.5)
	R.book_power(m, D.B_FIRE)
	ok("rank 4: it bursts, and the one beside goes up too", a.burn > 0 and b.burn > 0)
	R.weather = "rain"
	only(D.B_FIRE, 1)
	var c := one(0, 3, -45); c.burn = 0
	R.ignite(c, m, 4.0)
	var rain1 := c.burn
	only(D.B_FIRE, 2); c.burn = 0
	R.ignite(c, m, 4.0)
	ok("rank 2: rain no longer halves your fires", c.burn > rain1 * 1.8, [rain1, c.burn])
	R.weather = "clear"
	only(D.B_FIRE, 7); c.burn = 0; c.fear = 0
	R.ignite(c, m, 4.0)
	ok("rank 7: what you set alight is afraid", c.fear > 0)
	only(D.B_FIRE, 9); c.burn = 3.0; c.burnby = m.id
	var h0 := c.hp
	R.hit_u(c, 10.0, {"farm": false})
	ok("rank 9: the burning take a quarter more", absf((h0 - c.hp) - 12.5) < 0.01, h0 - c.hp)
	# burning oil, from the wall
	R.undead.clear()
	only(D.B_FIRE, 6)
	var wall: E.Struct = R.structs[2]
	wall.built = true; wall.hp = wall.mhp
	m.x = wall.x; m.z = D.VN + 1.5
	var below := one(0, wall.x, D.VN - 2.8)
	R.oil_power(m)
	fast(0.6)
	ok("rank 6: burning oil, poured from the wall, and what is below it burns", R.fires.size() == 1 and below.burn > 0, [R.fires.size(), below.burn])
	m.x = 40; m.z = 30; m.oilCd = 0
	R.oil_power(m)
	ok("but not poured from anywhere else", R.fires.size() == 1)
	# the tar, and the pot
	only(D.B_FIRE, 3)
	m.x = 0; m.z = -10
	var tar := R.mk_struct("tar", 0, -12, 0, true, 100, 100, -1)
	R.structs.append(tar)
	R.light_tar(0, -12.5, m)
	ok("rank 3: a tar pit can be set alight", tar.fire > 0)
	var w2 := one(0, 0, -12)
	w2.burn = 0
	fast(0.2)
	ok("and sets alight what wades through it", w2.burn > 0)
	only(D.B_FIRE, 5)
	m.wood = 10; m.stone = 10; m.iron = 5; m.x = 10; m.z = 10
	ok("rank 5: the burning pot can be built", R.try_place(m, "firepot", 10, 12, 0))
	f.x = 10; f.z = 13; f.state = "ok"; f.room = ""; f.wpn = D.tier_item(13, "crude"); f.r = 0; f.books[5] = 0
	R.undead.clear()
	var tgt := one(0, 10, 20)
	R.shoot(f, D.IT[f.wpn], 1.0, {"stun": 0.0})
	ok("and anyone with a bow beside it shoots burning arrows (the crude bow wants no book)", tgt.burn > 0, tgt.burn)
	R.undead.clear()
	# ---------- the night watchman
	only(D.B_WATCH, 1)
	m.x = 60; m.z = 30; m.feet = -1
	var out1 := Rules.stride(m)
	m.x = 0; m.z = 10
	ok("rank 1: faster outside the wall", out1 > 1.0 and Rules.stride(m) == 1.0)
	only(D.B_WATCH, 3)
	m.x = 60; m.z = 30
	var n1 := one(0, 61.5, 30)
	n1.stun = 0
	R.book_power(m, D.B_WATCH)
	fast(0.2)
	ok("rank 3: the dark lantern, and the dead do not go for you", m.dark > 0 and n1.tg != m.id)
	only(D.B_WATCH, 5)
	m.dark = 0
	var n2 := one(0, 62, 32); n2.nt = 0
	var hh := n2.hp
	R.hit_u(n2, 10.0, {"p": m, "farm": false})
	var first := hh - n2.hp
	hh = n2.hp
	R.hit_u(n2, 10.0, {"p": m, "farm": false})
	ok("rank 5: the first blow on one that has not noticed you is three times as hard; the next is not", absf(first - 30) < 0.5 and absf((hh - n2.hp) - 10) < 0.5, [first, hh - n2.hp])
	R.undead.clear()
	# ---------- shield-work
	only(D.B_SHIELD, 0)
	m.off = 25; m.head = -1; m.body = -1; m.feet = -1
	var cut0 := Rules.gear_cut(m)
	only(D.B_SHIELD, 1)
	ok("rank 1: your shield stops more", Rules.gear_cut(m) < cut0)
	only(D.B_SHIELD, 3)
	m.x = 0; m.z = -40; m.r = PI; m.hp = 100
	var front := one(0, 0, -41.2)
	R.book_power(m, D.B_SHIELD)
	R.hurt_friend(m, 20, true, front, false)
	ok("rank 3: braced, nothing from the front harms you", m.hp == 100 and m.braced > 0)
	var back := one(0, 0, -38.8)
	R.hurt_friend(m, 20, true, back, false)
	ok("but from behind it does", m.hp < 100)
	only(D.B_SHIELD, 10)
	m.braced = 5.0
	var bx := m.x
	R.shove(m, 1, 0, 5)
	ok("rank 10: braced, nothing moves you", absf(m.x - bx) < 0.01)
	m.braced = 0
	only(D.B_SHIELD, 2)
	m.mist = 0; m.charge = 0; m.x = bx
	R.shove(m, 1, 0, 4)
	ok("rank 2: behind a shield, thrown half as far (or not at all, now and then, to the prayer)", absf(m.x - bx) < 2.2, m.x - bx)
	m.off = -1
	R.undead.clear()
	# ---------- the dog
	only(D.B_DOG, 1)
	m.x = 0; m.z = 5; m.room = ""
	fast(0.2)
	var dog := R.dog_of(m)
	ok("rank 1: a dog turns up", dog != null and dog.kind == 3)
	ok("and it is not one of the posse", m.posse == R.peasants.filter(func(q): return q.owner == m.id and q.kind == 0 and q.state != "body").size())
	m.x = 20; m.z = 5
	fast(4.0)
	ok("it follows you", D.d2(dog.x, dog.z, m.x, m.z) < 9.0, sqrt(D.d2(dog.x, dog.z, m.x, m.z)))
	night()
	m.x = 0; m.z = -40
	dog.x = 0.5; dog.z = -40
	var bitten := one(0, 0, -42)
	bitten.stun = 99
	fast(2.0)
	ok("and bites what is near you", bitten.hp < 900, bitten.hp)
	only(D.B_DOG, 3)
	m.r = PI; dog.dt = 0
	R.undead.clear()
	var held := one(0, 0, -48)
	R.book_power(m, D.B_DOG)
	fast(2.0)
	ok("rank 3: That One: the dog pulls it down and holds it", held.held > 0 and held.pin > 0, [held.held, held.pin])
	only(D.B_DOG, 1)
	dog.hp = 5
	R.hurt_friend(dog, 50, false, held, false)
	ok("knocked down, not killed", dog.state == "down" and R.peasants.has(dog))
	only(D.B_DOG, 5)
	dog.downT = 0.01
	fast(0.2)
	ok("rank 5: and up again in a minute (here, at once)", dog.state != "down")
	ok("dogs are not saved: they turn up again", not (R.save_data().peasants as Array).any(func(q): return int(q.get("kind", 0)) == 3))
	m.trk = D.I_LEAD
	fast(0.2)
	ok("Saint Wilbur's Dog Lead: a second dog", R.peasants.filter(func(q): return q.kind == 3 and q.owner == m.id).size() == 2)
	m.trk = -1
	fast(0.2)
	R.undead.clear()
	# ---------- boots
	only(0, 0)
	m.feet = -1; m.x = 0; m.z = 10
	var s0 := Rules.stride(m)
	m.feet = D.I_FLEET
	ok("boots go on the feet: Brother Fleet's are a quarter faster", absf(Rules.stride(m) - s0 - 0.25) < 0.001 and D.SLOTS.has("feet"))
	only(D.B_WATCH, 8)
	m.x = 0; m.z = 10
	ok("and half as good again with the night watchman's eighth rank", absf(Rules.stride(m) - 1.375) < 0.001)
	m.feet = D.I_SABATONS
	only(0, 0)
	ok("sabatons take a twentieth off", Rules.gear_cut(m) < 1.0)
	m.feet = D.I_HOTFOOT; m.hp = 100; m.state = "ok"
	night()
	var kick := one(0, 0, 9)
	kick.burn = 0
	R.hurt_friend(m, 5, true, kick, false)
	ok("the hot-foot boots: what touches you catches light", kick.burn > 0)
	m.feet = D.I_SANDALS; m.x = 0; m.z = 10
	var holy := one(0, 0, 10.3)
	holy.stun = 99
	for i in 60:
		R.step(STEP); R.ev.clear()
	ok("the sandals: where you walk is hallowed, and the dead on it scorched", holy.hp < 900, holy.hp)
	m.feet = -1
	ok("boots at the smithy, and turnshoes in the rubble", D.IT[D.I_HOBNAILS].cost.size() > 0 and D.IT[D.I_SABATONS].tier == "steel" and D.FOUND_A.has(D.I_TURNSHOES))
	# ---------- relics for every player
	R.relics = []
	for i in m.books.size(): m.books[i] = 0; f.books[i] = 0
	m.books[4] = 1; f.books[4] = 1
	ok("two players with a book: two of its relic to find", R.relic_wanted(17) == 2 and R.relics_left().has(17))
	R.relics = [17]
	ok("one found, one still out there", R.relics_left().has(17))
	R.relics = [17, 17]
	ok("both found, none", not R.relics_left().has(17))
	f.books[4] = 0
	ok("a book nobody holds: one, as ever", R.relic_wanted(55) == 1)
	ok("relic boots: one of each for every player, whatever they have read", R.relic_wanted(D.I_FLEET) == 2 and R.relics_left().has(D.I_FLEET))
	ok("the new books' relics are among them", [D.I_MATCH, D.I_LANTERN, D.I_POTLID, D.I_LEAD].all(func(i): return D.RELICS.has(i)))
	for l in lines: print(l)
	var bad := lines.filter(func(l): return l.begins_with("FAIL")).size()
	print("%d passed, %d failed" % [lines.size() - bad, bad])
	quit(1 if bad else 0)
