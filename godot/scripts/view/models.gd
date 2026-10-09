class_name Models
extends RefCounted
## The models drawn many times: peasants' bodies and tunics, everything they can hold or wear, the dead,
## the defences, and the places that move. Copied from the web version's 04-models.js, shape for shape.
## Each is built once and shared.

const P := {
	"grass": 0x9dbf68, "path2": 0xcfb97f, "cream": 0xf0e3c3, "roof2": 0x934834, "timber": 0x5b4130,
	"wood": 0x8b6b47, "wood2": 0x7d5f3f, "wood3": 0x98784f, "stone": 0xc3bcab, "stone2": 0xa69f90, "stone3": 0x8a8478,
	"skin": 0xe8b98f, "straw": 0xdcbc62, "iron": 0x70757f, "trunk": 0x6b4a2f, "leaf": 0x5d9349, "leaf2": 0x6aa04e,
}

static var _cache := {}


static func get_mesh(name: String) -> ArrayMesh:
	if not _cache.has(name):
		var b := Mesher.new()
		_build(name, b)
		_cache[name] = b.commit()
	return _cache[name]


static func logs(b: Mesher, x0: float, z0: float, x1: float, z1: float) -> void:   # a run of sharpened palisade logs
	var n := maxi(1, roundi(Vector2(x1 - x0, z1 - z0).length() / 0.78))
	var cs := [P.wood, P.wood2, P.wood3]
	for i in n:
		var f := (i + 0.5) / n
		var x := lerpf(x0, x1, f)
		var z := lerpf(z0, z1, f)
		var h := 2.55 + ((i * 7) % 5) * 0.08
		b.cyl(0.36, 0.4, h, 5, x, 0, z, cs[i % 3], i * 1.3)
		b.cone(0.38, 0.6, 5, x, h, z, cs[i % 3], i * 1.3)


static func _build(name: String, b: Mesher) -> void:
	match name:
		# --- peasants. The tunic and banner are white here and tinted per copy.
		"body":
			b.box(0.2, 0.46, 0.22, -0.14, 0, 0, 0x4a3a2c).box(0.2, 0.46, 0.22, 0.14, 0, 0, 0x4a3a2c)
			b.box(0.42, 0.4, 0.4, 0, 1.03, 0.02, P.skin).box(0.1, 0.1, 0.06, 0, 1.15, 0.24, 0xd9a279)
			b.cyl(0.34, 0.34, 0.07, 7, 0, 1.42, 0, P.straw).cyl(0.17, 0.2, 0.2, 7, 0, 1.56, 0, P.straw)
		"torso":                                             # a body without the legs, which swing on their own
			b.box(0.42, 0.4, 0.4, 0, 1.03, 0.02, P.skin).box(0.1, 0.1, 0.06, 0, 1.15, 0.24, 0xd9a279)
			b.cyl(0.34, 0.34, 0.07, 7, 0, 1.42, 0, P.straw).cyl(0.17, 0.2, 0.2, 7, 0, 1.56, 0, P.straw)
		"leg":
			b.box(0.2, 0.46, 0.22, 0, -0.46, 0, 0x4a3a2c)
		"tunic":
			b.box(0.66, 0.6, 0.42, 0, 0.44, 0, 0xffffff).box(0.17, 0.5, 0.2, -0.42, 0.52, 0, 0xffffff).box(0.17, 0.5, 0.2, 0.42, 0.52, 0, 0xffffff)
			b.box(0.64, 0.09, 0.42, 0, 0.5, 0, 0x9a8a78).cyl(0.23, 0.25, 0.1, 7, 0, 1.48, 0, 0xffffff)
		"banner":                                            # a tall flag in the player's colour: how you tell who is who
			b.box(0.06, 2.3, 0.06, -0.3, 0.55, -0.27, 0xffffff).box(0.86, 0.56, 0.06, 0.14, 2.28, -0.27, 0xffffff).box(0.3, 0.2, 0.06, 0.72, 2.28, -0.27, 0xffffff)
		"axe":
			b.box(0.07, 1.05, 0.07, 0, -0.25, 0, P.wood).box(0.1, 0.26, 0.34, 0, 0.5, 0.16, P.iron)
		"rod":
			b.box(0.05, 2.2, 0.05, 0, -0.4, 0, 0xa08562)
		# --- held: the hand is at the origin and the business end points up
		"fork":
			b.box(0.07, 1.75, 0.07, 0, -0.55, 0, P.wood).box(0.36, 0.06, 0.06, 0, 1.2, 0, P.iron)
			for x in [-0.15, 0.0, 0.15]: b.box(0.05, 0.32, 0.05, x, 1.22, 0, P.iron)
		"sword":
			b.box(0.07, 0.26, 0.07, 0, -0.08, 0, P.wood).box(0.32, 0.06, 0.09, 0, 0.18, 0, P.iron).box(0.1, 0.95, 0.035, 0, 0.24, 0, 0xcfd4dc)
		"spear":
			b.box(0.06, 2.2, 0.06, 0, -0.65, 0, P.wood).cyl(0, 0.1, 0.42, 4, 0, 1.55, 0, 0xcfd4dc)
		"mace":
			b.box(0.07, 0.95, 0.07, 0, -0.15, 0, P.wood).ico(0.2, 0, 0.9, 0, P.iron).box(0.46, 0.07, 0.07, 0, 0.865, 0, 0x8f949e).box(0.07, 0.07, 0.46, 0, 0.865, 0, 0x8f949e)
		"bill":
			b.box(0.06, 2.0, 0.06, 0, -0.6, 0, P.wood).box(0.05, 0.55, 0.3, 0, 1.0, 0.16, 0xcfd4dc).box(0.05, 0.14, 0.3, 0, 1.5, 0.3, 0xcfd4dc)
		"hammer":
			b.box(0.08, 1.3, 0.08, 0, -0.3, 0, P.wood).box(0.3, 0.28, 0.56, 0, 0.92, 0, P.iron)
		"helm":                                              # armour is pale, and tinted per item
			b.cyl(0.25, 0.28, 0.26, 7, 0, 1.43, 0, 0xffffff).box(0.07, 0.22, 0.06, 0, 1.22, 0.24, 0xffffff)
		"mail":
			b.box(0.71, 0.46, 0.47, 0, 0.52, 0, 0xffffff).box(0.19, 0.2, 0.22, -0.42, 0.82, 0, 0xffffff).box(0.19, 0.2, 0.22, 0.42, 0.82, 0, 0xffffff)
		"shield":
			b.box(0.09, 0.66, 0.54, -0.56, 0.36, 0.12, P.wood3).box(0.11, 0.7, 0.07, -0.56, 0.34, 0.12, P.iron).box(0.14, 0.16, 0.16, -0.58, 0.61, 0.12, P.iron)
		"club":
			b.box(0.09, 0.5, 0.09, 0, -0.1, 0, P.wood).cyl(0.17, 0.11, 0.72, 6, 0, 0.35, 0, P.wood2)
		"spade":
			b.box(0.07, 1.5, 0.07, 0, -0.45, 0, P.wood).box(0.34, 0.44, 0.05, 0, 1.05, 0, 0xb9bec8)
		"rake":
			b.box(0.06, 2, 0.06, 0, -0.6, 0, P.wood).box(0.62, 0.07, 0.07, 0, 1.4, 0, P.wood2)
			for i in range(-2, 3): b.box(0.04, 0.04, 0.22, i * 0.14, 1.41, 0.12, P.iron)
		"scythe":
			b.box(0.07, 2, 0.07, 0, -0.6, 0, P.wood).box(0.05, 0.13, 0.95, 0, 1.3, 0.45, 0xcfd4dc, 0, -0.25, 0)
		"dagger":
			b.box(0.06, 0.2, 0.06, 0, -0.06, 0, P.wood).box(0.07, 0.44, 0.03, 0, 0.14, 0, 0xcfd4dc)
		"pan":
			b.box(0.06, 0.5, 0.06, 0, -0.1, 0, P.iron).box(0.56, 0.56, 0.07, 0, 0.4, 0, 0x34343b)
		"sling":
			b.box(0.05, 0.5, 0.05, 0, 0, 0, 0x6b4a2f).box(0.05, 0.3, 0.05, 0, 0.5, 0.1, 0x6b4a2f, 0, 0.7, 0).ico(0.11, 0, 0.72, 0.26, P.stone2)
		"bow":
			b.box(0.06, 0.8, 0.06, 0, -0.1, 0.16, P.wood2).box(0.06, 0.5, 0.06, 0, 0.66, 0.16, P.wood2, 0, -0.5, 0).box(0.06, 0.5, 0.06, 0, -0.56, -0.08, P.wood2, 0, 0.5, 0).box(0.02, 1.56, 0.02, 0, -0.5, -0.1, 0xe9e4cf)
		"xbow":
			b.box(0.09, 0.1, 0.85, 0, 0.2, 0.3, P.wood2).box(0.85, 0.06, 0.07, 0, 0.23, 0.68, P.iron).box(0.03, 0.03, 0.5, 0, 0.3, 0.4, 0xcfd4dc)
		"bucket":
			b.cyl(0.2, 0.16, 0.3, 7, -0.48, 0.44, -0.16, 0xffffff).box(0.03, 0.16, 0.34, -0.48, 0.72, -0.16, 0xdddddd)
		# --- the dead
		"shamb":
			b.box(0.24, 0.5, 0.26, -0.17, 0, 0, 0x3d4138).box(0.24, 0.5, 0.26, 0.17, 0, 0, 0x3d4138)
			b.box(0.72, 0.74, 0.46, 0, 0.48, 0.04, 0x5e6455, 0, 0.22, 0)
			b.box(0.46, 0.42, 0.44, 0.04, 1.14, 0.22, 0x8bab86, 0, 0.15, 0.12)
			b.box(0.16, 0.16, 0.72, -0.43, 0.92, 0.44, 0x8bab86, 0, -0.12, 0).box(0.16, 0.16, 0.72, 0.43, 0.86, 0.44, 0x8bab86, 0, 0.1, 0)
		"skel":
			b.box(0.1, 0.56, 0.1, -0.13, 0, 0, 0xe9e4cf).box(0.1, 0.56, 0.1, 0.13, 0, 0, 0xe9e4cf)
			b.box(0.34, 0.12, 0.2, 0, 0.55, 0, 0xddd7bf).box(0.08, 0.3, 0.08, 0, 0.6, 0, 0xddd7bf).box(0.44, 0.3, 0.24, 0, 0.8, 0, 0xe9e4cf)
			b.box(0.36, 0.34, 0.34, 0, 1.16, 0.02, 0xf1edda).box(0.26, 0.08, 0.26, 0, 1.1, 0.05, 0xddd7bf)
			b.box(0.09, 0.09, 0.04, -0.09, 1.31, 0.19, 0x2b2433).box(0.09, 0.09, 0.04, 0.09, 1.31, 0.19, 0x2b2433)
			b.box(0.08, 0.5, 0.08, -0.3, 0.58, 0, 0xe9e4cf).box(0.08, 0.5, 0.08, 0.3, 0.58, 0.06, 0xe9e4cf, 0, -0.4, 0)
			b.box(0.06, 0.8, 0.04, 0.3, 0.5, 0.42, 0x8d8f96, 0, 1.1, 0)
		"archer":                                            # a hood, and a bow held out in front
			b.box(0.1, 0.56, 0.1, -0.13, 0, 0, 0xddd8c2).box(0.1, 0.56, 0.1, 0.13, 0, 0, 0xddd8c2)
			b.box(0.34, 0.12, 0.2, 0, 0.55, 0, 0xd1cbb3).box(0.44, 0.3, 0.24, 0, 0.8, 0, 0xddd8c2)
			b.box(0.36, 0.34, 0.34, 0, 1.16, 0.02, 0xece8d5).box(0.42, 0.2, 0.4, 0, 1.36, -0.02, 0x4a3f55)
			b.box(0.09, 0.09, 0.04, -0.09, 1.25, 0.19, 0x2b2433).box(0.09, 0.09, 0.04, 0.09, 1.25, 0.19, 0x2b2433)
			b.box(0.08, 0.08, 0.5, -0.3, 0.9, 0.24, 0xddd8c2).box(0.08, 0.08, 0.36, 0.3, 0.9, 0.12, 0xddd8c2)
			b.box(0.06, 0.5, 0.06, -0.3, 0.98, 0.5, 0x6b4a2f, 0, -0.35, 0).box(0.06, 0.5, 0.06, -0.3, 0.5, 0.5, 0x6b4a2f, 0, 0.35, 0)
		"steward":                                           # the Lord's butler, in a tailcoat, carrying a candle on a tray
			b.box(0.2, 0.7, 0.22, -0.14, 0, 0, 0x1d1a24).box(0.2, 0.7, 0.22, 0.14, 0, 0, 0x1d1a24)
			b.box(0.62, 0.8, 0.38, 0, 0.68, 0, 0x26222e).box(0.2, 0.62, 0.05, 0, 0.8, 0.2, 0xe9e6dc).box(0.1, 0.1, 0.06, 0, 1.36, 0.21, 0x7d1f27)
			b.box(0.5, 0.5, 0.1, 0, 0.3, -0.22, 0x26222e, 0, -0.25, 0)
			b.box(0.36, 0.42, 0.36, 0, 1.5, 0, 0xcfd6c8).box(0.38, 0.1, 0.38, 0, 1.9, -0.02, 0x15131a)
			b.box(0.15, 0.6, 0.17, -0.4, 0.82, 0, 0x26222e).box(0.15, 0.17, 0.5, 0.4, 1.1, 0.2, 0x26222e)
			b.cyl(0.26, 0.26, 0.04, 8, 0.4, 1.2, 0.5, 0xb9bcc4).box(0.07, 0.3, 0.07, 0.4, 1.24, 0.5, 0xf2ecd8)
		"ghoul":                                             # hunched and grey-green, all arms and teeth
			b.box(0.16, 0.42, 0.2, -0.15, 0, 0.02, 0x3f463a, 0, 0.25, 0).box(0.16, 0.42, 0.2, 0.15, 0, 0.02, 0x3f463a, 0, -0.2, 0)
			b.box(0.5, 0.56, 0.34, 0, 0.38, 0.08, 0x6f7c63, 0, 0.55, 0)
			b.box(0.42, 0.12, 0.3, 0, 0.42, 0.02, 0x4a3a2c, 0, 0.55, 0)                 # rags
			b.box(0.34, 0.3, 0.36, 0, 0.78, 0.42, 0x93a285).box(0.28, 0.08, 0.2, 0, 0.7, 0.56, 0x3b2b2b)
			for sx in [-1, 1]:
				b.box(0.1, 0.1, 0.78, sx * 0.31, 0.6, 0.42, 0x93a285, sx * -0.15, -0.45, 0)
				for c in [-0.05, 0.05]: b.box(0.03, 0.03, 0.16, sx * 0.31 + c, 0.27, 0.8, 0xe9e4cf, 0, -0.9, 0)
		"ghoul_eyes":
			b.box(0.08, 0.06, 0.04, -0.08, 0.86, 0.6, 0xfff07a).box(0.08, 0.06, 0.04, 0.08, 0.86, 0.6, 0xfff07a)
		"digger":                                            # a gravedigger: muddy coat, a wide hat, his spade over his shoulder
			b.box(0.22, 0.5, 0.24, -0.15, 0, 0, 0x3a3029).box(0.22, 0.5, 0.24, 0.15, 0, 0, 0x3a3029)
			b.box(0.68, 0.76, 0.44, 0, 0.48, 0, 0x5a4a38, 0, 0.18, 0)
			b.box(0.7, 0.18, 0.46, 0, 0.5, 0.02, 0x7a5a3a, 0, 0.18, 0)                   # mud
			b.box(0.42, 0.4, 0.4, 0, 1.12, 0.16, 0x9fae8e, 0, 0.12, 0)
			b.cyl(0.42, 0.42, 0.05, 8, 0, 1.44, 0.16, 0x2a241f).cyl(0.2, 0.24, 0.24, 8, 0, 1.47, 0.16, 0x2a241f)
			b.box(0.15, 0.6, 0.17, -0.42, 0.75, 0.05, 0x5a4a38).box(0.15, 0.6, 0.17, 0.42, 0.75, 0.05, 0x5a4a38)
			b.box(0.07, 1.6, 0.07, 0.28, 0.6, -0.3, P.wood, 0, 0.35, 0).box(0.32, 0.42, 0.05, 0.28, 2.0, -0.82, 0xa8a49a, 0, 0.35, 0)
		"digger_eyes":
			b.box(0.08, 0.06, 0.04, -0.08, 1.27, 0.37, 0xe4ffb0).box(0.08, 0.06, 0.04, 0.1, 1.29, 0.37, 0xe4ffb0)
		"bats":                                              # a swarm: a handful of bats, drawn as one
			for q in [[0, 0, 0, 1.0], [-0.7, 0.35, 0.3, 0.8], [0.65, 0.2, -0.25, 0.85], [0.1, 0.6, -0.55, 0.7], [-0.3, -0.3, -0.45, 0.75], [0.45, -0.25, 0.5, 0.7]]:
				var s: float = q[3]
				b.box(0.16 * s, 0.14 * s, 0.26 * s, q[0], q[1], q[2], 0x231d26)
				b.box(0.5 * s, 0.03, 0.22 * s, q[0] - 0.3 * s, q[1] + 0.08, q[2], 0x3a2f3d, 0, 0, 0.35).box(0.5 * s, 0.03, 0.22 * s, q[0] + 0.3 * s, q[1] + 0.08, q[2], 0x3a2f3d, 0, 0, -0.35)
				b.box(0.05, 0.08, 0.03, q[0] - 0.05 * s, q[1] + 0.12 * s, q[2] + 0.06, 0x231d26).box(0.05, 0.08, 0.03, q[0] + 0.05 * s, q[1] + 0.12 * s, q[2] + 0.06, 0x231d26)
		"bats_eyes":
			for q in [[0, 0, 0, 1.0], [-0.7, 0.35, 0.3, 0.8], [0.65, 0.2, -0.25, 0.85], [0.1, 0.6, -0.55, 0.7], [-0.3, -0.3, -0.45, 0.75], [0.45, -0.25, 0.5, 0.7]]:
				var s: float = q[3]
				b.box(0.04, 0.04, 0.02, q[0] - 0.04 * s, q[1] + 0.07 * s, q[2] + 0.13 * s, 0xff4a4a).box(0.04, 0.04, 0.02, q[0] + 0.04 * s, q[1] + 0.07 * s, q[2] + 0.13 * s, 0xff4a4a)
		"guard":                                             # the Lord's guard: blackened plate, a red tabard, a halberd
			b.box(0.22, 0.56, 0.24, -0.15, 0, 0, 0x34363d).box(0.22, 0.56, 0.24, 0.15, 0, 0, 0x34363d)
			b.box(0.74, 0.8, 0.48, 0, 0.55, 0, 0x4b4f58).box(0.5, 0.86, 0.06, 0, 0.32, 0.25, 0x6e1f27)
			b.box(0.86, 0.2, 0.5, 0, 1.22, 0, 0x5c616b)                                     # pauldrons
			b.box(0.44, 0.46, 0.42, 0, 1.38, 0.02, 0x5c616b).box(0.3, 0.06, 0.06, 0, 1.56, 0.23, 0x14121a)
			b.box(0.06, 0.34, 0.26, 0, 1.84, -0.02, 0x6e1f27)                              # a plume
			b.box(0.16, 0.6, 0.18, -0.46, 0.68, 0.05, 0x4b4f58).box(0.16, 0.6, 0.18, 0.46, 0.68, 0.05, 0x4b4f58)
			b.box(0.07, 2.5, 0.07, 0.5, -0.1, 0.32, P.timber).box(0.05, 0.5, 0.36, 0.5, 2.0, 0.42, 0xb9bec8).box(0.05, 0.3, 0.12, 0.5, 2.5, 0.32, 0xb9bec8)
		"guard_eyes":
			b.box(0.08, 0.04, 0.03, -0.08, 1.58, 0.245, 0xff6040).box(0.08, 0.04, 0.03, 0.08, 1.58, 0.245, 0xff6040)
		"wraith":                                            # a hooded shape with no feet, in rags that trail off into nothing
			b.cyl(0.36, 0.2, 0.9, 7, 0, 0.0, 0, 0x8c9cb0)
			b.cyl(0.3, 0.36, 0.55, 7, 0, 0.9, 0, 0xa8b8c8)
			b.cyl(0.0, 0.3, 0.5, 7, 0, 1.45, -0.02, 0x7c8ca0)                              # the hood
			b.box(0.22, 0.24, 0.1, 0, 1.45, 0.2, 0x14121a)                                  # the dark inside it
			for sx in [-1, 1]:
				b.box(0.12, 0.12, 0.7, sx * 0.34, 1.05, 0.35, 0xa8b8c8, sx * -0.2, -0.3, 0)
				b.box(0.2, 0.3, 0.05, sx * 0.22, -0.1, 0.1, 0x8c9cb0, 0, 0, sx * 0.3)
		"wraith_eyes":
			b.box(0.06, 0.06, 0.03, -0.06, 1.52, 0.26, 0x9fe8ff).box(0.06, 0.06, 0.03, 0.06, 1.52, 0.26, 0x9fe8ff)
		"ram":                                               # a coffin carried head-first at the gate by a row of skeletons
			b.box(0.78, 0.5, 2.7, 0, 0.95, 0, 0x2e231c).box(0.82, 0.08, 2.74, 0, 1.43, 0, 0x3d2e24)
			b.box(0.1, 0.06, 1.0, 0, 1.49, 0.1, 0xc9b26a).box(0.5, 0.06, 0.1, 0, 1.49, 0.35, 0xc9b26a)   # a brass cross on the lid
			b.box(0.86, 0.56, 0.1, 0, 0.92, 1.36, 0x6d5a42)                                 # an iron-shod end, for knocking
			for i in 3:
				for sx in [-1, 1]:
					var z := -0.9 + i * 0.9
					var x: float = sx * 0.62
					b.box(0.07, 0.5, 0.07, x - 0.07, 0, z, 0xe9e4cf).box(0.07, 0.5, 0.07, x + 0.07, 0, z, 0xe9e4cf)
					b.box(0.26, 0.3, 0.18, x, 0.5, z, 0xe9e4cf).box(0.24, 0.24, 0.24, x, 0.84, z + 0.04, 0xf1edda)
					b.box(0.06, 0.4, 0.06, x - sx * 0.14, 0.78, z, 0xe9e4cf, 0, 0, sx * 0.6)
		"ram_eyes":
			for i in 3:
				for sx in [-1, 1]:
					var z := -0.9 + i * 0.9
					b.box(0.05, 0.05, 0.02, sx * 0.62 - 0.05, 0.98, z + 0.17, 0xff8a4a).box(0.05, 0.05, 0.02, sx * 0.62 + 0.05, 0.98, z + 0.17, 0xff8a4a)
		"hearse":                                            # the Coachman's hearse: two black horses, a glass-sided carriage, and him on the box, headless
			b.box(1.5, 1.3, 2.6, 0, 0.75, -0.6, 0x15131a).box(1.6, 0.12, 2.7, 0, 2.05, -0.6, 0x26222e)
			b.box(1.3, 0.8, 0.04, 0, 1.0, 0.71, 0x3a4250).box(0.04, 0.8, 2.2, 0.76, 1.0, -0.6, 0x3a4250).box(0.04, 0.8, 2.2, -0.76, 1.0, -0.6, 0x3a4250)
			b.box(0.9, 0.35, 1.8, 0, 0.82, -0.6, 0x5a4636)                                    # a coffin inside
			for c in [[-0.85, -1.6], [0.85, -1.6], [-0.85, 0.35], [0.85, 0.35]]:
				b.cyl(0.55, 0.55, 0.12, 10, c[0], 0.55, c[1], 0x2a241f, 0, 0, PI / 2).cyl(0.12, 0.12, 0.16, 6, c[0], 0.55, c[1], 0xb9a060, 0, 0, PI / 2)
			b.box(0.7, 0.4, 0.5, 0, 2.15, 0.65, 0x26222e)                                     # the box he sits on
			b.box(0.5, 0.65, 0.36, 0, 2.55, 0.65, 0x1d1a24).box(0.56, 0.1, 0.4, 0, 3.2, 0.65, 0x7d1f27)   # him, a red collar, no head
			b.box(0.12, 0.5, 0.12, -0.32, 2.7, 0.9, 0x1d1a24, 0, -0.9, 0).box(0.03, 1.4, 0.03, 0.34, 2.9, 1.2, 0x6b4a2f, 0, -0.5, 0)   # the whip
			for sx in [-0.42, 0.42]:                         # the horses
				b.box(0.42, 0.62, 1.5, sx, 1.0, 2.2, 0x0f0d12)
				for lz in [1.7, 2.7]:
					b.box(0.12, 1.0, 0.14, sx - 0.12, 0, lz, 0x0f0d12).box(0.12, 1.0, 0.14, sx + 0.12, 0, lz, 0x0f0d12)
				b.box(0.26, 0.7, 0.34, sx, 1.45, 3.0, 0x0f0d12, 0, -0.45, 0).box(0.24, 0.26, 0.56, sx, 2.0, 3.25, 0x0f0d12)
				b.box(0.06, 0.4, 0.5, sx, 1.75, 2.85, 0x2e2a36, 0, -0.45, 0)                   # mane
				b.box(0.05, 0.36, 0.3, sx, 2.16, 2.98, 0x3d2a46)                                # a black plume
			b.box(0.06, 0.06, 1.4, -0.21, 1.15, 1.0, 0x3a2f2a).box(0.06, 0.06, 1.4, 0.21, 1.15, 1.0, 0x3a2f2a)   # the shafts
		"hearse_eyes":
			for sx in [-0.42, 0.42]:
				b.box(0.05, 0.06, 0.04, sx - 0.13, 2.04, 3.5, 0xff5030).box(0.05, 0.06, 0.04, sx + 0.13, 2.04, 3.5, 0xff5030)
			b.box(0.3, 0.12, 0.3, 0, 3.28, 0.65, 0x8fff9a)                                      # a green glow where his head was
		"captain":                                           # the Captain of the Guard: heavier plate, a crested helm, a red cloak, a long sword
			b.box(0.24, 0.6, 0.26, -0.16, 0, 0, 0x2c2e34).box(0.24, 0.6, 0.26, 0.16, 0, 0, 0x2c2e34)
			b.box(0.8, 0.86, 0.52, 0, 0.6, 0, 0x5c616b).box(0.56, 0.9, 0.06, 0, 0.34, 0.27, 0x6e1f27)
			b.box(0.84, 1.6, 0.08, 0, 0.12, -0.3, 0x6e1f27, 0, 0.08, 0)                     # the cloak
			b.box(0.98, 0.24, 0.56, 0, 1.3, 0, 0x7a808c)
			b.box(0.48, 0.52, 0.46, 0, 1.5, 0.02, 0x7a808c).box(0.34, 0.06, 0.06, 0, 1.7, 0.25, 0x14121a)
			b.box(0.08, 0.3, 0.6, 0, 2.0, 0.0, 0xd8b040)                                     # a gilt crest
			b.box(0.17, 0.66, 0.2, -0.5, 0.72, 0.05, 0x5c616b).box(0.17, 0.66, 0.2, 0.5, 0.72, 0.05, 0x5c616b)
			b.box(0.1, 0.3, 0.1, 0.5, 0.5, 0.3, 0x3a2f2a).box(0.4, 0.06, 0.1, 0.5, 0.78, 0.3, 0xd8b040).box(0.1, 1.5, 0.04, 0.5, 0.82, 0.3, 0xcfd4dc)
			b.box(0.08, 0.8, 0.6, -0.64, 0.5, 0.15, 0x4b4f58).box(0.1, 0.2, 0.2, -0.68, 0.8, 0.15, 0x6e1f27)   # a shield
		"captain_eyes":
			b.box(0.09, 0.04, 0.03, -0.09, 1.72, 0.25, 0xff6040).box(0.09, 0.04, 0.03, 0.09, 1.72, 0.25, 0xff6040)
		"lord":                                              # the Lord of Ashhollow: tall, black, a high red-lined collar, a cloak to the ground
			b.box(0.2, 0.8, 0.22, -0.14, 0, 0, 0x121016).box(0.2, 0.8, 0.22, 0.14, 0, 0, 0x121016)
			b.box(0.62, 0.95, 0.4, 0, 0.78, 0, 0x1d1a24).box(0.18, 0.7, 0.05, 0, 0.95, 0.2, 0x7d1f27)
			b.box(1.2, 1.9, 0.1, 0, 0.0, -0.3, 0x121016, 0, 0.1, 0).box(1.1, 1.8, 0.04, 0, 0.05, -0.24, 0x5a1520, 0, 0.1, 0)   # the cloak, red inside
			b.box(0.15, 0.7, 0.17, -0.4, 1.0, 0, 0x1d1a24).box(0.15, 0.7, 0.17, 0.4, 1.0, 0.05, 0x1d1a24)
			b.box(0.36, 0.44, 0.36, 0, 1.75, 0, 0xd8dccf).box(0.38, 0.12, 0.38, 0, 2.18, -0.02, 0x0c0a0e)   # pale face, black hair
			b.box(0.08, 0.06, 0.04, -0.12, 2.1, 0.19, 0x0c0a0e, 0, 0, -0.3).box(0.08, 0.06, 0.04, 0.12, 2.1, 0.19, 0x0c0a0e, 0, 0, 0.3)
			b.box(0.9, 0.7, 0.08, -0.4, 1.55, -0.12, 0x5a1520, 0.6, 0, 0).box(0.9, 0.7, 0.08, 0.4, 1.55, -0.12, 0x5a1520, -0.6, 0, 0)   # the collar
			b.box(0.04, 0.12, 0.02, -0.05, 1.6, 0.19, 0xffffff).box(0.04, 0.12, 0.02, 0.05, 1.6, 0.19, 0xffffff)   # fangs
			b.box(0.36, 0.08, 0.36, 0, 2.27, 0, 0x8f7a2e)                                    # a thin gold circlet
		"lord_eyes":
			b.box(0.08, 0.05, 0.03, -0.08, 1.88, 0.19, 0xff2a2a).box(0.08, 0.05, 0.03, 0.08, 1.88, 0.19, 0xff2a2a)
		"cart":                                              # a merchant's cart: two wheels, an awning (white: tinted per merchant), crates and sacks
			b.box(2.6, 0.18, 1.5, 0, 0.75, 0, P.wood2).box(2.6, 0.5, 0.08, 0, 0.93, 0.72, P.wood).box(2.6, 0.5, 0.08, 0, 0.93, -0.72, P.wood)
			for sz in [-0.82, 0.82]:
				b.cyl(0.55, 0.55, 0.1, 10, 0.2, 0.55, sz, P.timber, 0, PI / 2, 0).cyl(0.1, 0.1, 0.14, 6, 0.2, 0.55, sz, P.iron, 0, PI / 2, 0)
			b.box(0.08, 0.08, 1.6, 1.6, 0.85, 0.3, P.wood3, 0.2).box(0.08, 0.08, 1.6, 1.6, 0.85, -0.3, P.wood3, -0.2)   # the shafts
			for c in [[-1.2, -0.7], [1.2, -0.7], [-1.2, 0.7], [1.2, 0.7]]: b.box(0.08, 1.5, 0.08, c[0], 0.85, c[1], P.timber)
			b.box(0.6, 0.5, 0.5, -0.7, 0.93, 0.2, 0x9a7a4a).box(0.5, 0.42, 0.42, -0.6, 1.43, 0.15, 0xa8885a).box(0.55, 0.6, 0.45, 0.6, 0.93, -0.2, 0xd8c8a0)
			b.cyl(0.25, 0.28, 0.6, 8, 0.2, 0.93, 0.3, 0x7a4a2a)
		"awning":                                            # white, tinted per merchant
			b.box(2.9, 0.08, 1.9, 0, 2.38, 0, 0xffffff, 0, 0.08, 0)
			for i in 6: b.box(0.44, 0.22, 0.04, -1.2 + i * 0.48, 2.18, 0.96, 0xffffff if i % 2 else 0xe8e0d0)
		"merchant":                                          # a travelling merchant: a big hat, a long coat, a purse
			b.box(0.2, 0.5, 0.22, -0.14, 0, 0, 0x3a2f28).box(0.2, 0.5, 0.22, 0.14, 0, 0, 0x3a2f28)
			b.box(0.66, 0.8, 0.44, 0, 0.45, 0, 0x6a4a7a).box(0.68, 0.08, 0.46, 0, 0.75, 0, 0x5a3a20)
			b.box(0.17, 0.55, 0.2, -0.42, 0.7, 0, 0x6a4a7a).box(0.17, 0.55, 0.2, 0.42, 0.7, 0.05, 0x6a4a7a)
			b.box(0.42, 0.42, 0.4, 0, 1.25, 0.02, P.skin).box(0.1, 0.1, 0.06, 0, 1.37, 0.24, 0xd9a279)
			b.cyl(0.46, 0.46, 0.05, 10, 0, 1.6, 0, 0x3a2a1a).cyl(0.2, 0.26, 0.3, 8, 0, 1.64, 0, 0x3a2a1a).box(0.06, 0.3, 0.2, 0.18, 1.8, 0, 0xd8b040)
			b.box(0.2, 0.24, 0.12, 0.3, 0.6, 0.24, 0xc9a040)
		# the glowing bits (eyes, the candle), drawn with their own bright material
		"shamb_eyes":
			b.box(0.09, 0.07, 0.05, -0.07, 1.3, 0.47, 0xe4ffb0).box(0.09, 0.07, 0.05, 0.15, 1.33, 0.46, 0xe4ffb0)
		"skel_eyes":
			b.box(0.07, 0.07, 0.03, -0.09, 1.32, 0.205, 0xff8a4a).box(0.07, 0.07, 0.03, 0.09, 1.32, 0.205, 0xff8a4a)
		"archer_eyes":
			b.box(0.07, 0.07, 0.03, -0.09, 1.26, 0.205, 0xff8a4a).box(0.07, 0.07, 0.03, 0.09, 1.26, 0.205, 0xff8a4a)
		"steward_eyes":
			b.box(0.07, 0.05, 0.03, -0.08, 1.72, 0.19, 0xe9ffb5).box(0.07, 0.05, 0.03, 0.08, 1.72, 0.19, 0xe9ffb5).box(0.06, 0.1, 0.06, 0.4, 1.54, 0.5, 0xffd27a)
		# --- defences
		"wall":
			logs(b, -3, 0, 3, 0)
			b.box(5.8, 0.2, 0.16, 0, 1.5, 0.44, P.timber)
		"found":
			b.box(5.7, 0.16, 1, 0, 0, 0, P.stone2)
			for s in [-1, 1]: b.box(0.34, 0.5, 0.34, s * 2.75, 0, 0, P.stone3)
			for i in 4: b.box(0.7, 0.05, 0.16, -1.8 + i * 1.2, 0.16, 0, P.wood3)
		"foundGate":
			b.box(5.7, 0.16, 1.3, 0, 0, 0, P.stone)
			for s in [-1, 1]: b.box(0.7, 0.8, 1, s * 2.65, 0, 0, P.stone3)
		"gateFrame":
			for s in [-1, 1]: b.box(0.8, 3.8, 1, s * 2.7, 0, 0, P.timber)
			b.box(6.6, 0.55, 1.1, 0, 3.8, 0, P.timber).roof(1.9, 0.8, 7, 0, 4.35, 0, P.roof2, PI / 2)
		"door":
			b.box(2.25, 3.35, 0.2, 1.125, 0.12, 0, P.wood2)
			for y in [0.8, 2.6]: b.box(2.25, 0.16, 0.26, 1.125, y, 0, P.iron)
		"barricade":
			b.box(3.4, 0.22, 0.22, 0, 0.72, 0, P.wood).box(3.2, 0.3, 0.1, 0, 0.22, 0.3, P.wood3)
			for x in [-1.3, -0.43, 0.43, 1.3]:
				b.box(0.2, 1.55, 0.2, x, 0, 0, P.wood2, 0, 0.62, 0); b.box(0.2, 1.55, 0.2, x + 0.22, 0, 0, P.wood3, 0, -0.62, 0)
		"spikes":
			b.box(3.4, 0.08, 1.5, 0, 0, 0, 0x7d6c4b)
			for i in 9: b.cyl(0, 0.12, 1.15, 4, -1.5 + i * 0.375, 0, 0.3 if i % 2 else -0.3, P.wood2 if i % 2 else P.wood3, 0, 0.55 if i % 2 else -0.55, 0)
		"wallRe":                                            # stone facing for a wall
			for i in 5: b.box(1.14, 1.25, 0.42, -2.36 + i * 1.18, 0, -0.58, P.stone if i % 2 else P.stone2)
			for i in 4: b.box(1.14, 0.55, 0.38, -1.77 + i * 1.18, 1.25, -0.56, P.stone2 if i % 2 else P.stone3)
		"gateRe":                                            # iron bands for a gate
			for sx in [-1, 1]:
				for y in [0.7, 2.0, 3.2]: b.box(0.9, 0.16, 1.1, sx * 2.7, y, 0, P.iron)
			b.box(6.7, 0.14, 1.16, 0, 4.0, 0, P.iron)
		"bodywall":                                          # what a peasant community does with its fallen
			for q in [[-0.75, 0, 0.1, 0x8f7f63], [0.8, 0, -0.12, 0x7f7460], [0, 0.42, 0.05, 0x9a8a6c]]:
				b.box(1.45, 0.42, 0.56, q[0], q[1], 0, q[3], q[2]); b.box(0.36, 0.34, 0.36, q[0] + 0.86, q[1] + 0.04, 0.02, 0xc9b79a, q[2]); b.box(0.2, 0.2, 0.6, q[0] - 0.8, q[1] + 0.05, 0, 0x4a3a2c, q[2])
			for x in [-1.5, 0.0, 1.5]: b.box(0.12, 1.25, 0.12, x, 0, 0.36, P.wood2, 0, -0.25, 0)
			b.box(3.3, 0.12, 0.1, 0, 0.82, 0.5, P.wood3)
		"decoy":
			b.box(0.12, 2.0, 0.12, 0, 0, -0.22, P.wood2).box(1.3, 0.1, 0.1, 0, 1.25, -0.22, P.wood2)
			b.box(0.6, 0.62, 0.38, 0, 0.72, 0, 0x8f7f63, 0, 0.1, 0).box(0.2, 0.5, 0.22, -0.14, 0.2, 0.04, 0x4a3a2c).box(0.2, 0.5, 0.22, 0.14, 0.2, 0.04, 0x4a3a2c, 0, 0, 0.2)
			b.box(0.4, 0.38, 0.38, 0, 1.36, 0.06, 0xc9b79a, 0, 0.3, 0.2).cyl(0.36, 0.36, 0.07, 7, 0, 1.74, 0.02, P.straw, 0, 0.2, 0.2)
			b.box(0.16, 0.5, 0.16, -0.52, 0.86, -0.1, 0x8f7f63, 0, 0, 0.5).box(0.16, 0.5, 0.16, 0.52, 0.86, -0.1, 0x8f7f63, 0, 0, -0.5)
		"bailiff":                                           # Robert Bailiff, head and shoulders, in his nightcap
			b.box(0.9, 0.5, 0.5, 0, 0, 0, 0x5a2a3a).box(0.3, 0.1, 0.52, 0, 0.42, 0, 0xd8b040)
			b.box(0.46, 0.46, 0.44, 0, 0.5, 0.02, P.skin).box(0.12, 0.12, 0.08, 0, 0.62, 0.26, 0xd9a279)
			b.box(0.5, 0.1, 0.46, 0, 0.5, 0.02, 0x8a6a4a)                                  # whiskers
			b.cone(0.26, 0.6, 7, 0, 0.94, 0, 0xe8e0d0, 0, 0.5, 0).ico(0.08, 0.2, 1.3, -0.12, 0xe8e0d0)
		# --- contraptions
		"chicken":                                           # a chicken in a wicker cage on a post
			b.box(0.12, 0.9, 0.12, 0, 0, 0, P.wood2)
			b.box(0.8, 0.06, 0.8, 0, 0.9, 0, P.wood3)
			for c in [[-0.38, -0.38], [0.38, -0.38], [-0.38, 0.38], [0.38, 0.38], [0, -0.38], [0, 0.38], [-0.38, 0], [0.38, 0]]: b.box(0.04, 0.7, 0.04, c[0], 0.96, c[1], 0xb08850)
			b.box(0.8, 0.06, 0.8, 0, 1.66, 0, P.wood3)
			b.box(0.34, 0.3, 0.42, 0, 1.0, 0, 0xf4f0e6).box(0.18, 0.22, 0.18, 0, 1.28, 0.2, 0xf4f0e6).box(0.06, 0.1, 0.12, 0, 1.44, 0.24, 0xd8302a).box(0.08, 0.05, 0.1, 0, 1.3, 0.34, 0xe0a020)
			b.box(0.2, 0.22, 0.12, 0, 1.08, -0.24, 0xe8e2d4, 0.5)
		"pitfall":                                           # a hole, badly hidden under sticks and leaves
			b.box(2.4, 0.04, 2.4, 0, 0, 0, 0x2a2018)
			for i in 7: b.box(0.1, 0.08, 2.5, -1.05 + i * 0.35, 0.04, 0, P.wood2 if i % 2 else P.wood3, 0.08 * (i % 3 - 1))
			for i in 9: b.box(0.3, 0.05, 0.3, -0.9 + (i * 0.73) - floorf(i / 3.0) * 2.1, 0.1, -0.7 + floorf(i / 3.0) * 0.7, P.leaf if i % 2 else 0x8a7a40, i * 0.7)
		"tar":                                               # a shallow pit of black tar in a ring of stones
			b.box(3.4, 0.05, 2.2, 0, 0, 0, 0x14110e)
			b.box(2.6, 0.03, 1.4, 0.1, 0.05, 0.05, 0x2a2420, 0.2)
			for i in 10:
				var a := TAU * i / 10.0
				b.box(0.4, 0.22, 0.34, cos(a) * 1.75, 0, sin(a) * 1.15, P.stone2 if i % 2 else P.stone3, a)
		"trough":                                            # a long stone trough of holy water, with a little cross
			b.box(3.2, 0.5, 0.9, 0, 0, 0, P.stone).box(2.9, 0.06, 0.6, 0, 0.44, 0, 0x8fd0e8)
			b.box(0.08, 0.7, 0.08, 1.5, 0.5, 0, 0xe2b54a).box(0.34, 0.08, 0.08, 1.5, 0.95, 0, 0xe2b54a)
		"logs":                                              # a stack of logs held back by two stakes, up the road
			for i in 5: b.cyl(0.32, 0.32, 3.0, 7, -1.5, 0.32 + (0.55 if i >= 3 else 0.0), -0.66 + (i % 3) * 0.6 + (0.3 if i >= 3 else 0.0), P.trunk if i % 2 else P.wood, 0, 0, PI / 2)
			for sx in [-1.7, 1.7]: b.box(0.16, 1.5, 0.16, sx, 0, 0.95, P.timber, 0, -0.2, 0)
			b.box(3.6, 0.12, 0.12, 0, 1.1, 1.0, P.timber)
		"thresher":                                          # a post, a crank, and a spinning arm of flails
			b.box(1.4, 0.14, 1.4, 0, 0, 0, P.wood2).box(0.24, 1.3, 0.24, 0, 0.1, 0, P.timber)
			b.box(0.08, 0.45, 0.08, 0.35, 0.6, 0, P.iron).box(0.3, 0.06, 0.06, 0.5, 0.82, 0, P.iron)
		"thresher_arm":
			b.box(2.8, 0.12, 0.12, 0, 1.3, 0, P.wood).box(0.12, 0.12, 2.8, 0, 1.3, 0, P.wood)
			for c in [[1.4, 0], [-1.4, 0], [0, 1.4], [0, -1.4]]:
				b.box(0.05, 0.5, 0.05, c[0], 0.85, c[1], 0x8a8a8a).ico(0.16, c[0], 0.8, c[1], P.iron)
		# --- places that move
		"outcrop":
			b.box(6.4, 0.06, 5.4, 0, 0, 0, 0xcfc9bb, 0.2)
			for r in [[-1.1, -0.5, 2.1, 2.4, 1.8, 0.3, P.stone], [0.9, 0.5, 1.9, 1.7, 1.6, 1.1, P.stone2], [0.3, -1.1, 1.5, 1.1, 1.3, 2.0, P.stone3], [-0.6, 1.1, 1.4, 0.9, 1.2, 0.7, P.stone2], [1.9, -0.7, 1.0, 0.7, 0.9, 2.6, P.stone], [-2.4, 0.9, 0.8, 0.5, 0.7, 1.5, P.stone3], [2.5, 1.4, 0.6, 0.4, 0.6, 0.4, P.stone2]]:
				b.box(r[2], r[3], r[4], r[0], 0, r[1], r[6], r[5])
		"mine":
			b.cyl(1.9, 3.1, 2.3, 8, 0, 0, 0, 0x93a064).box(0.7, 1.9, 1.8, -2.75, 0, 0, 0x2a2420)
			for sz in [-1, 1]: b.box(0.3, 2.1, 0.3, -3.05, 0, sz * 1.02, P.timber)
			b.box(0.4, 0.3, 2.6, -3.05, 2.1, 0, P.timber)
			for q in [[-3.7, 1.9, 0.5], [-3.3, 2.3, 0.4], [-4.0, 2.4, 0.34]]: b.box(q[2], q[2] * 0.8, q[2], q[0], 0, q[1], 0x6d5a50, q[0])
			b.box(4.4, 0.05, 3.6, -3.9, 0, 0, 0xb9a988)
		"jetty":
			b.box(1.8, 0.2, 7, 0, 0.25, 4.1, P.wood)
			for sx in [-1, 1]:
				for zz in [1.6, 4.6, 7.1]: b.box(0.25, 1, 0.25, sx * 0.8, -0.2, zz, P.timber)
			b.box(0.16, 1.5, 0.16, 1.5, 0, 0.4, P.timber).box(0.8, 0.45, 0.08, 1.5, 1.05, 0.46, 0x8fcbd8).box(2.6, 0.05, 3.4, 0, 0, -1.2, P.path2)
		"rub":
			b.box(1, 1, 1, 0, 0, 0, 0xffffff)
		"pillar":
			b.cyl(0.4, 0.48, 1, 6, 0, 0, 0, P.stone)
		"spot":
			b.box(0.9, 0.3, 0.7, 0, 0, 0, 0xffffff, 0.3).box(0.6, 0.26, 0.5, 0.3, 0.3, 0.1, 0xe6e6e6, 1.1).box(0.4, 0.2, 0.4, -0.5, 0, 0.5, 0xdcdcdc, 0.8).box(1.5, 0.1, 0.16, 0, 0.36, -0.3, 0xa58560, 0.5, 0, 0.2)
		"arrow":
			b.box(0.05, 0.05, 0.95, 0, 0, 0, 0x6b4a2f).box(0.1, 0.1, 0.16, 0, -0.025, 0.5, 0xcfd4dc).box(0.14, 0.02, 0.2, 0, 0.015, -0.42, 0xe9e4cf)
		"bit":
			b.box(0.16, 0.16, 0.16, 0, -0.08, 0, 0xffffff)
		# --- trees and stumps
		"pine":
			b.cyl(0.2, 0.28, 1.1, 5, 0, 0, 0, P.trunk).cone(1.25, 2.0, 6, 0, 0.8, 0, P.leaf).cone(0.98, 1.8, 6, 0, 1.95, 0, P.leaf, 0.5).cone(0.62, 1.4, 6, 0, 3.0, 0, P.leaf, 1)
		"round":
			b.cyl(0.22, 0.3, 1.5, 5, 0, 0, 0, P.trunk).ico(1.35, 0, 2.4, 0, P.leaf2, 0.85).ico(0.85, 0.7, 3.2, 0.25, P.leaf2, 0.9)
		"stump":
			b.cyl(0.24, 0.32, 0.34, 6, 0, 0, 0, P.trunk).cyl(0.2, 0.2, 0.03, 6, 0, 0.34, 0, 0xcaa972)
		"priest":                                            # the priest: white robes, a gold-edged vestment, a cross, a book
			b.cyl(0.34, 0.48, 1.0, 8, 0, 0, 0, 0xf4f0e4)                                   # the long white alb, to the ground
			b.box(0.74, 0.7, 0.46, 0, 0.5, 0, 0xfbf6e8)                                     # the vestment over it
			b.box(0.76, 0.06, 0.48, 0, 0.5, 0, 0xd8b040).box(0.76, 0.06, 0.48, 0, 1.14, 0, 0xd8b040)   # gold hems
			b.box(0.1, 0.62, 0.04, 0, 0.52, 0.245, 0xd8b040).box(0.36, 0.1, 0.04, 0, 0.86, 0.245, 0xd8b040)  # the cross on his front
			b.box(0.07, 0.95, 0.03, -0.24, 0.2, 0.235, 0x7a2a8c).box(0.07, 0.95, 0.03, 0.24, 0.2, 0.235, 0x7a2a8c)  # the purple stole
			b.box(0.17, 0.52, 0.2, -0.43, 0.66, 0, 0xfbf6e8).box(0.17, 0.52, 0.2, 0.43, 0.66, 0, 0xfbf6e8)  # sleeves
			b.box(0.16, 0.12, 0.18, -0.43, 0.6, 0.04, P.skin).box(0.16, 0.12, 0.18, 0.43, 0.6, 0.04, P.skin)  # hands
			b.box(0.3, 0.1, 0.46, 0, 1.18, 0, 0x7a2a8c)                                       # the collar
			b.box(0.42, 0.42, 0.4, 0, 1.22, 0.02, P.skin).box(0.1, 0.1, 0.06, 0, 1.34, 0.24, 0xd9a279)
			b.box(0.46, 0.14, 0.44, 0, 1.46, 0.0, 0xc9c4ba)                                   # a grey fringe round a bald crown
			b.box(0.3, 0.05, 0.24, 0, 1.6, 0.0, P.skin)
			b.box(0.06, 2.3, 0.06, 0.5, 0, 0.16, 0x6b4a2f)                                     # the processional cross
			b.box(0.08, 0.5, 0.08, 0.5, 2.2, 0.16, 0xe2b54a).box(0.34, 0.08, 0.08, 0.5, 2.48, 0.16, 0xe2b54a)
			b.box(0.34, 0.06, 0.26, -0.45, 0.7, 0.22, 0x7a1e18).box(0.3, 0.04, 0.22, -0.45, 0.76, 0.22, 0xf3e8c8)  # his book


## Where an item hangs on a peasant: the slot it is worn in decides.
static func gear_pool(id: int) -> String:
	if id == 26: return "bucket"     # the handbell and the censer are carried like a bucket
	return D.IT[id].pool


## A bright material for eyes and candles: their own colour, unlit, bright enough to glow at night.
static var _glow: Material
static func glow() -> Material:
	if _glow == null:
		var sh := Shader.new()
		sh.code = "shader_type spatial;\nrender_mode unshaded;\nvoid fragment() { ALBEDO = COLOR.rgb * 1.7; }\n"
		var m := ShaderMaterial.new()
		m.shader = sh
		_glow = m
	return _glow
