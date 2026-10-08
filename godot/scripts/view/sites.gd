extends Node3D
## The things that move every morning: the rocky outcrop (stone), the mine (iron), the jetty (fish),
## and the two outer ruins, which fall down differently every night. Rebuilt when the day changes.

const Build := preload("res://scripts/build.gd")
const C_STONE := Color("c3bcab")
const C_STONE2 := Color("a69f90")
const C_STONE3 := Color("8a8478")
const C_TIMBER := Color("5b4130")
const C_WOOD := Color("8b6b47")

var _key := ""
var _quarry: Node3D
var _mine: Node3D
var _jetty: Node3D
var _ruins: Node3D
var _marks: Array = []          # one small marker over each heap of rubble with something left in it


func _ready() -> void:
	_quarry = Node3D.new(); add_child(_quarry)
	for r in [[-1.1, -0.5, 2.1, 2.4, 1.8, 0.3, C_STONE], [0.9, 0.5, 1.9, 1.7, 1.6, 1.1, C_STONE2], [0.3, -1.1, 1.5, 1.1, 1.3, 2.0, C_STONE3], [-0.6, 1.1, 1.4, 0.9, 1.2, 0.7, C_STONE2], [1.9, -0.7, 1.0, 0.7, 0.9, 2.6, C_STONE]]:
		Build.box(_quarry, Vector3(r[2], r[3], r[4]), Vector3(r[0], 0, r[1]), r[6], r[5])
	_mine = Node3D.new(); add_child(_mine)            # a grassy mound with a dark mouth on one side
	Build.cyl(_mine, 1.9, 3.1, 2.3, Vector3.ZERO, Color("93a064"), 8)
	Build.box(_mine, Vector3(0.7, 1.9, 1.8), Vector3(-2.75, 0, 0), Color("2a2420"))
	for sz in [-1.0, 1.0]:
		Build.box(_mine, Vector3(0.3, 2.1, 0.3), Vector3(-3.05, 0, sz * 1.02), C_TIMBER)
	Build.box(_mine, Vector3(0.4, 0.3, 2.6), Vector3(-3.05, 2.1, 0), C_TIMBER)
	_jetty = Node3D.new(); add_child(_jetty)
	Build.box(_jetty, Vector3(1.8, 0.2, 7), Vector3(0, 0.25, 4.1), C_WOOD)
	for sx in [-1.0, 1.0]:
		for zz in [1.6, 4.6, 7.1]:
			Build.box(_jetty, Vector3(0.25, 1, 0.25), Vector3(sx * 0.8, -0.2, zz), C_TIMBER)
	_ruins = Node3D.new(); add_child(_ruins)


func sync(R: Rules) -> void:
	var key := "%d:%d:%s" % [R.seed, R.day, R.sites]
	if key != _key:
		_key = key
		_quarry.position = Vector3(R.QUARRY.x, 0, R.QUARRY.z)
		_mine.position = Vector3(R.MINEC.x, 0, R.MINEC.z)
		_mine.rotation.y = 0.0 if R.MINE.dir > 0 else PI    # the mouth faces back towards the village
		_jetty.position = Vector3(R.JETTY.x, 0, R.JETTY.z)
		for c in _ruins.get_children(): c.queue_free()
		var L := Map.ruin_layout(R.seed, R.day)
		for b in L.rub:
			Build.box(_ruins, Vector3(b.w, b.h, b.d), Vector3(b.x, 0, b.z), C_STONE2 if b.c else C_STONE3, b.rot)
		for p in L.pil:
			Build.cyl(_ruins, 0.36, 0.42, p.h, Vector3(p.x, 0, p.z), C_STONE2, 6)
		_marks.clear()
		for sp in L.spots:                               # a heap of rubble, and a small sign of something in it
			Build.box(_ruins, Vector3(1.3, 0.45, 1.0), Vector3(sp.x, 0, sp.z), C_STONE3, sp.x)
			var m := Build.box(_ruins, Vector3(0.22, 0.22, 0.22), Vector3(sp.x, 0.7, sp.z), Color("ffe08a"))
			m.material_override = Build.mat(Color("ffe08a"), 1.6)
			_marks.append(m)
	for i in _marks.size():
		_marks[i].visible = R.spots[i] > 0
		_marks[i].rotation.y += 0.02
