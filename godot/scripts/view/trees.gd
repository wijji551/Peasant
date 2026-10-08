extends Node3D
## The trees, drawn from the rules' list: standing, a stump, or a sapling. A felled tree topples and shrinks
## away and leaves its stump; a tree being chopped shivers. Each kind of tree is one MultiMesh.

var fx: Node3D
var _pine: MultiMesh
var _round: MultiMesh
var _stump: MultiMesh
var _tv := -1
var _v := {}            # tree index -> [st, par, fall, shake] as last drawn
var _slot := {}         # tree index -> its place in the pine or round MultiMesh


func _ready() -> void:
	_pine = _multi("pine")
	_round = _multi("round")
	_stump = _multi("stump")


func _multi(mesh: String) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = Models.get_mesh(mesh)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)
	return mm


func shake_near(x: float, z: float) -> void:   # someone is chopping at the tree nearest here
	var best := -1
	var bd := 9.0
	for i in _slot:
		var t: E.Trunk = _trees[i]
		if t.alive:
			var d := D.d2(x, z, t.x, t.z)
			if d < bd:
				bd = d; best = i
	if best >= 0:
		_v[best][3] = 0.3


var _trees: Array = []


func _put_tree(t: E.Trunk, grow: float, tilt: float, stump: bool) -> void:   # grow 1 = standing, a third = a sapling, 0 = gone
	var s := t.s * grow
	var mm := _round if t.kind else _pine
	var xf := Transform3D(Basis(Vector3.UP, t.rot) * Basis(Vector3.BACK, tilt) * Basis.from_scale(Vector3(s, s, s)), Vector3(t.x, 0, t.z))
	mm.set_instance_transform(_slot[t.i], xf)
	var st := t.s if stump else 0.0
	_stump.set_instance_transform(t.i, Transform3D(Basis(Vector3.UP, t.rot) * Basis.from_scale(Vector3(st, st, st)), Vector3(t.x, 0, t.z)))


func _show(t: E.Trunk) -> void:
	if t.st == 0: _put_tree(t, 1, 0, false)
	elif t.st == 1: _put_tree(t, 0, 0, true)
	else: _put_tree(t, 0.34, 0, false)


func sync(R: Rules, delta: float) -> void:
	if _trees.is_empty():                              # the first time: give every tree its place
		_trees = R.trees
		var np := 0
		var nr := 0
		for t: E.Trunk in _trees:
			if t.kind:
				_slot[t.i] = nr
				nr += 1
			else:
				_slot[t.i] = np
				np += 1
		_pine.instance_count = np; _round.instance_count = nr; _stump.instance_count = _trees.size()
		for t: E.Trunk in _trees:
			(_round if t.kind else _pine).set_instance_color(_slot[t.i], t.tint)
			_v[t.i] = [t.st, t.par, 0.0, 0.0]
			_show(t)
	if R.tv != _tv:
		var first := _tv < 0
		_tv = R.tv
		for t: E.Trunk in _trees:
			var v: Array = _v[t.i]
			if v[0] == t.st and v[1] == t.par: continue
			if t.st == 1 and v[0] == 0 and not first:     # just felled: it topples
				v[2] = 0.35
				if fx: fx.puff(t.x, 1.5, t.z, 10, fx.C_LEAF, 3)
			else:
				v[2] = 0.0
				_show(t)
			v[0] = t.st; v[1] = t.par
	for i in _v:
		var v: Array = _v[i]
		if v[2] > 0:
			var t: E.Trunk = _trees[i]
			v[2] -= delta
			var g := maxf(0.0, v[2] / 0.35)
			if v[2] <= 0 or t.st != 1:
				v[2] = 0.0; _show(t)
			else:
				_put_tree(t, 0.5 + g * 0.5, (1 - g) * 0.9, true)
		elif v[3] > 0:
			var t: E.Trunk = _trees[i]
			v[3] -= delta
			if t.st == 0: _put_tree(t, 1, sin(v[3] * 60) * 0.06 if v[3] > 0 else 0.0, false)
