class_name Map
extends RefCounted
## The fixed shape of Thornhallow as the rules see it: what you bump into, where the trees grow,
## and how the ruins have fallen down tonight. The view builds its models in the same places.


# a building, as the rules see it: a box to walk round. Sideways buildings swap width and depth.
static func house_box(x: float, z: float, ry: float, w: float, d: float) -> E.Box:
	var sw := absf(sin(ry)) > 0.5
	return E.Box.new(x, z, (d if sw else w) / 2.0 + 0.25, (w if sw else d) / 2.0 + 0.25)


# every fixed thing in the village you cannot walk through (the moving outcrop and mine are added by the rules)
static func colliders() -> Array:
	var out := []
	var wall := func(x0: float, z0: float, x1: float, z1: float) -> void:
		out.append(E.Box.new((x0 + x1) / 2.0, (z0 + z1) / 2.0, absf(x1 - x0) / 2.0 + 0.42, absf(z1 - z0) / 2.0 + 0.42))
	var VW := D.VW
	var VN := D.VN
	var VS := D.VS
	var G := D.GATE_Z
	wall.call(-VW, VN, -21.0, VN); wall.call(21.0, VN, VW, VN)
	wall.call(-VW, VN, -VW, G - 3); wall.call(-VW, G + 3, -VW, VS)
	wall.call(VW, VN, VW, G - 3); wall.call(VW, G + 3, VW, VS)
	wall.call(-VW, VS, VW, VS)
	out.append(E.Box.new(0, 0, D.KEEP_H, D.KEEP_H))
	out.append(house_box(-14.5, -12.6, 0, 9, 6.4))           # Robert Bailiff's
	out.append(house_box(17, -14.8, 0, 4.6, 7.8))            # the chapel, with its rounded north end
	out.append(house_box(-17.5, -4.7, PI / 2, 8, 6))         # the Thorny Rose Inn
	out.append(house_box(17.5, -4.7, -PI / 2, 6.5, 5.6))     # the smithy
	out.append(house_box(17.5, 10.6, -PI / 2, 7, 5.6))       # the storehouse
	out.append(house_box(-21.5, 19.2, 0.12, 3, 2.8))         # the slum
	out.append(house_box(-17.6, 21.6, -0.2, 3.3, 2.7))
	out.append(house_box(-13.8, 19.4, 0.25, 2.8, 2.8))
	for x in [-5.0, 0.0, 5.0]:                                # market stalls
		out.append(E.Box.new(x, 21.6, 1.4, 0.8))
	out.append(house_box(17.5, 20.4, -PI / 2, 6.6, 6))       # the library
	for i in 8:                                               # cottages
		var c := D.cottage(i)
		out.append(house_box(c.x, c.z, 0.0 if c.dir > 0 else PI, 3.7, 3.3))
	out.append(house_box(-47, 24, PI / 2, 5, 7))             # the farmhouse
	return out


static func tree_ok(x: float, z: float) -> bool:
	if x > -D.VW - 4 and x < D.VW + 4 and z > D.VN - 6 and z < D.VS + 4: return false   # the village
	if absf(x) < 34 and z < D.VN: return false                                           # the north field and the graveyard
	if absf(z - D.GATE_Z) < 4.5 and absf(x) < 50: return false                           # the gate paths
	if Vector2(x, z).distance_to(D.HILL) < 47: return false                              # castle hill
	if x > -74 and x < -42 and z > 17 and z < 44: return false                           # farms
	for c in D.RUIN_SITES:
		if absf(x - c.x) < 10 and absf(z - c.z) < 6.5: return false                       # the clearings the outer ruins wander between
	if absf(x) > 90.5 and absf(x) < 98: return false                                     # the thorn hedge
	if absf(z + 62.8) < 1.6 and absf(x) < 93: return false                               # the line of stakes
	for k in 2:
		for c in D.SITES[k]:
			if Vector2(x - c.x, z - c.z).length() < 6.5: return false                     # every place the stone or the iron can turn up
	for c in D.SITES[2]:
		if absf(x - c.x) < 3.5 and z > 46: return false                                   # and the paths to the jetties
	if z > 53.5: return false                                                            # river
	return true


# Hallowshire Forest to the west, and a scatter elsewhere. The same on every computer.
static func trees() -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var place := func(x0: float, x1: float, z0: float, z1: float, tries: int, gap: float) -> void:
		for i in tries:
			var x := rng.randf_range(x0, x1)
			var z := rng.randf_range(z0, z1)
			if not tree_ok(x, z):
				continue
			var ok := true
			for t in out:
				if D.d2(x, z, t.x, t.z) < gap * gap:
					ok = false
					break
			if not ok:
				continue
			var a := rng.randf_range(0, TAU)
			var dx := cos(a) * 1.4
			var dz := sin(a) * 1.4
			if not tree_ok(x + dx, z + dz):
				dx = -dx; dz = -dz
				if not tree_ok(x + dx, z + dz):
					dx = 0; dz = 0
			var t := E.Trunk.new()
			t.i = out.size(); t.x = x; t.z = z; t.ox = x; t.oz = z; t.dx = dx; t.dz = dz
			t.s = rng.randf_range(0.85, 1.35); t.rot = rng.randf_range(0, TAU); t.kind = 0 if rng.randf() < 0.72 else 1
			t.tint = Color(rng.randf_range(0.88, 1.08), rng.randf_range(0.92, 1.1), rng.randf_range(0.82, 1.02))
			t.wood = D.TREE_WOOD
			out.append(t)
	place.call(-90.0, -34.0, -48.0, 17.0, 420, 2.5)
	place.call(-125.0, 125.0, -95.0, 53.0, 520, 3.4)
	return out


# --- the ruins. The old ruins by the chapel never change; the two outer ruins move to new clearings every night,
# and fall down differently when they get there.
static var _ruin_key := ""
static var _ruin_now := {}

static func ruin_layout(game_seed: int, day: int) -> Dictionary:   # the same on every computer, from the game's seed and the day
	var key := str(game_seed) + ":" + str(day)
	if key == _ruin_key:
		return _ruin_now
	var rub := []
	var pil := []
	var spots := [{"x": 9.8, "z": -14.3, "ruin": 0}, {"x": 12.3, "z": -16.6, "ruin": 0}]
	var pick := RandomNumberGenerator.new()
	pick.seed = game_seed * 17 + day * 733 + 5
	var a := pick.randi_range(0, D.RUIN_SITES.size() - 1)
	var b := (a + 1 + pick.randi_range(0, D.RUIN_SITES.size() - 2)) % D.RUIN_SITES.size()
	var centres := [{"x": D.RUINS[0].x, "z": D.RUINS[0].z}, D.RUIN_SITES[a], D.RUIN_SITES[b]]
	for side in [1, 2]:
		var R: Dictionary = centres[side]
		var rng := RandomNumberGenerator.new()
		rng.seed = game_seed * 31 + day * 977 + side * 131
		var n := 8 + rng.randi_range(0, 4)
		for i in n:
			var tall := rng.randf() < 0.25
			rub.append({"x": R.x + rng.randf_range(-7, 7), "z": R.z + rng.randf_range(-4.4, 4.4), "w": rng.randf_range(1.2, 3.6),
				"h": rng.randf_range(2.6, 4.2) if tall else rng.randf_range(0.5, 2.2), "d": rng.randf_range(0.5, 0.8),
				"rot": rng.randi_range(0, 3) * PI / 4 + rng.randf_range(-0.15, 0.15), "c": i % 2})
		for i in 2 + rng.randi_range(0, 2):
			pil.append({"x": R.x + rng.randf_range(-6, 6), "z": R.z + rng.randf_range(-4, 4), "h": rng.randf_range(1.4, 3.6)})
		for i in 3:
			var x := 0.0
			var z := 0.0
			for t in 12:
				x = R.x + rng.randf_range(-6.5, 6.5)
				z = R.z + rng.randf_range(-3.9, 3.9)
				var ok := true
				for s in spots:
					if D.d2(s.x, s.z, x, z) <= 9:
						ok = false
				if ok:
					break
			spots.append({"x": x, "z": z, "ruin": side})
	_ruin_key = key
	_ruin_now = {"rub": rub, "pil": pil, "spots": spots, "centres": centres}
	return _ruin_now
