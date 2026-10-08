extends Node3D
## The defences: the seven foundations of the north wall (and what is built on them), and everything placed
## by hand (barricades, spike rows, body walls, decoys). Drawn from the rules' list of structures.

const Build := preload("res://scripts/build.gd")
const C_WOOD := [Color("8b6b47"), Color("7d5f3f"), Color("98784f")]
const C_TIMBER := Color("5b4130")
const C_STONE := Color("a69f90")
const C_STONE3 := Color("8a8478")
const C_IRON := Color("70757f")
const C_BODY := Color("b8b09a")
const C_HOLY := Color("ffe9a0")

var _nodes := {}        # struct id -> {node, sig, bar}


func sync(R: Rules) -> void:
	var seen := {}
	for s: E.Struct in R.structs:
		seen[s.id] = true
		var sig := "%s|%s|%s|%s" % [s.k, s.built, s.re, s.bl]
		var e = _nodes.get(s.id)
		if e == null or e.sig != sig:
			if e: e.node.queue_free()
			e = {"node": _make(s), "sig": sig}
			e.bar = _bar(e.node, s)
			_nodes[s.id] = e
		var hurt := s.built and s.hp < s.mhp - 0.5
		e.bar.visible = hurt
		if hurt:
			var f := clampf(s.hp / s.mhp, 0, 1)
			e.bar.get_child(0).scale.x = maxf(0.001, f)
			e.bar.get_child(0).position.x = -(1 - f) * 0.9
	for id in _nodes.keys():
		if not seen.has(id):
			_nodes[id].node.queue_free()
			_nodes.erase(id)


func _bar(n: Node3D, s: E.Struct) -> Node3D:   # a small health bar over a damaged defence
	var b := Node3D.new()
	b.position = Vector3(0, 3.6 if s.k == "wall" or s.k == "gate" else 2.2, 0)
	n.add_child(b)
	var fill := Build.box(b, Vector3(1.8, 0.16, 0.16), Vector3.ZERO, Color("7cc35a"))
	fill.material_override = Build.mat(Color("7cc35a"), 0.6)
	Build.box(b, Vector3(1.9, 0.12, 0.12), Vector3(0, 0.02, -0.03), Color("2b2018"))
	return b


func _make(s: E.Struct) -> Node3D:
	var n := Node3D.new()
	n.position = Vector3(s.x, 0, s.z)
	n.rotation.y = s.rot
	add_child(n)
	if not s.built:
		if s.slot >= 0:                                  # an empty foundation: a line of stones
			for i in 7:
				Build.box(n, Vector3(0.7, 0.22, 0.6), Vector3(-2.7 + i * 0.9, 0, 0), C_STONE3, i * 0.7)
		return n
	match s.k:
		"wall":
			for i in 8:
				var h := 2.55 + ((i * 7) % 5) * 0.08
				var x := -2.62 + i * 0.75
				Build.cyl(n, 0.36, 0.4, h, Vector3(x, 0, 0), C_WOOD[i % 3], 5, i * 1.3)
				Build.cone(n, 0.38, 0.6, Vector3(x, h, 0), C_WOOD[i % 3], 5, i * 1.3)
			if s.re:                                     # faced with stone, on the outside
				Build.box(n, Vector3(6.1, 2.0, 0.35), Vector3(0, 0, -0.45), C_STONE)
				for i in 6: Build.box(n, Vector3(0.9, 0.3, 0.38), Vector3(-2.5 + i, 2.0, -0.45), C_STONE3)
		"gate":
			for e in [-1.0, 1.0]:
				Build.box(n, Vector3(0.8, 3.8, 1), Vector3(e * 3, 0, 0), C_TIMBER)
			Build.box(n, Vector3(7, 0.55, 1.1), Vector3(0, 3.8, 0), C_TIMBER)
			for i in 7:
				Build.box(n, Vector3(0.7, 3.0, 0.22), Vector3(-2.2 + i * 0.73, 0, 0), C_WOOD[i % 3])
			if s.re:
				for y in [0.6, 2.3]: Build.box(n, Vector3(5.2, 0.22, 0.3), Vector3(0, y, 0), C_IRON)
		"barricade":
			for i in 2:
				Build.box(n, Vector3(3.4, 0.28, 0.2), Vector3(0, 0.25 + i * 0.5, 0), C_WOOD[i], 0, 0, 0.08 * (1 - 2 * i))
			for x in [-1.3, 0.0, 1.3]:
				Build.box(n, Vector3(0.22, 1.25, 0.22), Vector3(x, 0, 0), C_TIMBER, 0, 0.25)
			if s.re:
				for x in [-1.3, 1.3]: Build.box(n, Vector3(0.3, 0.3, 0.3), Vector3(x, 0.8, 0), C_IRON)
		"spikes":
			for i in 6:
				var stake := Build.cyl(n, 0.0, 0.12, 1.3, Vector3(-1.45 + i * 0.58, 0, (i % 2) * 0.5 - 0.25), C_IRON if s.re else C_WOOD[i % 3], 4, 0, -0.5)
		"bodywall":
			for i in 5:
				Build.box(n, Vector3(0.8, 0.5, 0.55), Vector3(-1.3 + i * 0.65, (i % 2) * 0.4, 0), C_BODY, i * 0.6)
			Build.box(n, Vector3(3.2, 0.4, 0.6), Vector3(0, 0, 0), C_TIMBER)
		"decoy":                                         # one of the fallen, propped up on a stake to draw them off
			Build.box(n, Vector3(0.12, 1.8, 0.12), Vector3.ZERO, C_TIMBER)
			Build.box(n, Vector3(0.6, 0.65, 0.4), Vector3(0, 0.75, 0), C_BODY, 0, 0, 0.2)
			Build.box(n, Vector3(0.38, 0.36, 0.36), Vector3(0.05, 1.42, 0), Color("d8c7a0"), 0, 0, 0.3)
	if s.bl:                                             # a blessed body built in: a small shining cross
		var c := Build.box(n, Vector3(0.14, 0.7, 0.08), Vector3(0, 1.4, 0.4), C_HOLY)
		c.material_override = Build.mat(C_HOLY, 1.4)
		var c2 := Build.box(n, Vector3(0.45, 0.12, 0.08), Vector3(0, 1.82, 0.4), C_HOLY)
		c2.material_override = Build.mat(C_HOLY, 1.4)
	return n
