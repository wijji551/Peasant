extends Node3D
## The defences: the seven foundations of the north wall and what is built on them, and everything placed by hand.
## A new defence pops up, a struck one shudders, the gate swings open for friends when none of the dead are near,
## and anything damaged shows how much is left.

const SH := {"wall": 3.9, "gate": 5.6, "barricade": 2.1, "spikes": 1.6, "bodywall": 1.8, "decoy": 2.6}   # bar height
const SW := {"wall": 3.0, "gate": 3.0, "barricade": 1.8, "spikes": 1.8, "bodywall": 1.8, "decoy": 1.0}   # bar width
const IRONED := Color(0.72, 0.76, 0.86)

var fx: Node3D
var _nodes := {}        # struct id -> {node, sig, pop, shake, hc, open, doors, bar, fill, built}
var _started := 0.0


func _ready() -> void:
	_started = Time.get_ticks_msec() / 1000.0


static func _tinted(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_color = c
	m.roughness = 1.0
	return m


func _mi(parent: Node3D, mesh: String, mat: Material = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = Models.get_mesh(mesh)
	if mat: mi.material_override = mat
	parent.add_child(mi)
	return mi


func _make(s: E.Struct) -> Dictionary:
	var e := {"node": Node3D.new(), "doors": [], "pop": 0.0, "shake": 0.0, "hc": s.hc, "open": 0.0}
	var n: Node3D = e.node
	add_child(n)
	n.position = Vector3(s.x, 0, s.z)
	n.rotation.y = s.rot
	var body := Node3D.new()                             # what pops and shudders
	n.add_child(body)
	e.body = body
	if not s.built:
		_mi(body, "foundGate" if s.k == "gate" else "found")
	elif s.k == "gate":
		_mi(body, "gateFrame")
		if s.re: _mi(body, "gateRe")
		var dm := _tinted(Color(0.78, 0.78, 0.84) if s.re else Color.WHITE)
		for side in [-1, 1]:
			var d := Node3D.new()
			d.position = Vector3(side * 2.3, 0, 0)
			d.rotation.y = 0.0 if side < 0 else PI
			body.add_child(d)
			_mi(d, "door", dm)
			e.doors.append(d)
	else:
		_mi(body, s.k, _tinted(IRONED) if s.re and (s.k == "barricade" or s.k == "spikes") else null)
		if s.k == "wall" and s.re: _mi(body, "wallRe")
	# a small health bar, which faces the camera
	var bar := Node3D.new()
	bar.top_level = true
	n.add_child(bar)
	var bg := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(1, 0.26); bg.mesh = q
	var bm := StandardMaterial3D.new(); bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; bm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; bm.albedo_color = Color(0.14, 0.1, 0.1)
	bg.material_override = bm; bar.add_child(bg)
	var fill := MeshInstance3D.new(); var q2 := QuadMesh.new(); q2.size = Vector2(1, 0.14); fill.mesh = q2
	var fm := bm.duplicate(); fm.albedo_color = Color(0.88, 0.72, 0.36); fm.render_priority = 1
	fill.material_override = fm; bar.add_child(fill)
	e.bar = bar; e.fill = fill; e.bg = bg
	bar.visible = false
	return e


func sync(R: Rules, delta: float) -> void:
	var seen := {}
	var now := Time.get_ticks_msec() / 1000.0
	for s: E.Struct in R.structs:
		seen[s.id] = true
		var sig := "%s|%s|%s|%s" % [s.k, s.built, s.re, s.bl]
		var e = _nodes.get(s.id)
		if e == null or e.sig != sig:
			var was_built: bool = e.built if e else s.built
			var was_re: bool = e.re if e else s.re
			if e: e.node.queue_free()
			var fresh: bool = e == null
			e = _make(s)
			e.sig = sig; e.built = s.built; e.re = s.re
			_nodes[s.id] = e
			if s.built and (not was_built or (fresh and s.slot < 0 and now - _started > 1.5)) or (s.re and not was_re):
				e.pop = 1.0                              # just built, or just reinforced
				if fx: fx.puff(s.x, 0.4, s.z, 8, fx.C_WOOD, 3)
				Sound.play("build", 1.0, Vector2(s.x, s.z))
			if was_built and not s.built and fx:         # knocked down
				fx.puff(s.x, 0.6, s.z, 16, fx.C_WOOD, 4)
				Sound.play("thump", 0.9, Vector2(s.x, s.z))
		if s.hc != e.hc:
			e.hc = s.hc; e.shake = 0.18
			Sound.play("chop", 0.45, Vector2(s.x, s.z))
		e.pop = maxf(0, e.pop - delta * 3.5)
		e.shake = maxf(0, e.shake - delta)
		var pp: float = 1 + sin(e.pop * PI) * 0.22 - ((e.pop - 0.7) * 1.5 if e.pop > 0.7 else 0.0)
		var tilt: float = sin(e.shake * 70) * 0.04 if e.shake > 0 else 0.0
		e.body.scale = Vector3(pp, pp, pp)
		e.body.rotation.x = tilt
		if e.doors.size():                               # the gate opens for friends when none of the dead are near
			var near := false
			var danger := false
			for p in R.players:
				if p.state == "ok" and D.d2(p.x, p.z, s.x, s.z) < 16: near = true
			for q in R.peasants:
				if q.state != "body" and q.state != "idle" and D.d2(q.x, q.z, s.x, s.z) < 12: near = true
			for u in R.undead:
				if D.d2(u.x, u.z, s.x, s.z) < 30:
					danger = true
					break
			e.open = lerpf(e.open, 1.0 if near and not danger else 0.0, minf(1.0, delta * 7))
			e.doors[0].rotation.y = -1.35 * e.open
			e.doors[1].rotation.y = PI + 1.35 * e.open
		var hurt := s.built and s.hp < s.mhp
		e.bar.visible = hurt
		if hurt:
			var w: float = SW[s.k]
			var f := clampf(s.hp / s.mhp, 0, 1)
			e.bar.global_position = Vector3(s.x, SH[s.k], s.z)
			e.bg.scale = Vector3(w + 0.12, 1, 1)
			e.fill.scale = Vector3(maxf(0.02, w * f), 1, 1)
			e.fill.position = Vector3(-(w - w * f) / 2.0, 0, 0.01)
		if s.bl and fx and randf() < delta * 2:
			fx.puff(s.x + (randf() - 0.5) * 3, 1.2, s.z, 1, fx.C_HOLY, 0.6)
	for id in _nodes.keys():
		if not seen.has(id):
			var e = _nodes[id]
			if fx: fx.puff(e.node.position.x, 0.6, e.node.position.z, 16, fx.C_WOOD, 4)
			e.node.queue_free()
			_nodes.erase(id)
