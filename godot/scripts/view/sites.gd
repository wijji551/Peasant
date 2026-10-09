extends Node3D
## The things that move every morning: the rocky outcrop (stone), the mine (iron), the jetty (fish), and the
## two outer ruins, which fall down differently every night, with their heaps of rubble to search. And the
## priest, who stands outside his chapel whatever the day.

var _key := ""
var _quarry: MeshInstance3D
var _mine: MeshInstance3D
var _jetty: MeshInstance3D
var _ruins: Node3D
var _spots: Array = []          # one heap of rubble per search spot, paler while something is left in it
var _spot_mats: Array = []


func _ready() -> void:
	_quarry = _mi("outcrop")
	_mine = _mi("mine")
	_jetty = _mi("jetty")
	_ruins = Node3D.new()
	add_child(_ruins)
	var pr := _mi("priest")                          # the priest, outside his chapel
	var st: Dictionary = D.STATIONS[6]
	pr.position = Vector3(st.x + 0.9, 0, st.z - 0.5)
	pr.rotation.y = -2.2
	pr.scale = Vector3.ONE * 1.08
	var halo := MeshInstance3D.new()                  # and, faintly, a halo. He has been very good this year
	var tm := TorusMesh.new(); tm.inner_radius = 0.2; tm.outer_radius = 0.26; tm.rings = 20; tm.ring_segments = 6
	halo.mesh = tm
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.albedo_color = Color(1.0, 0.86, 0.45, 0.85)
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo.material_override = hm
	halo.position = Vector3(0, 1.88, 0)
	pr.add_child(halo)
	var gl := OmniLight3D.new()
	gl.light_color = Color(1.0, 0.88, 0.6)
	gl.light_energy = 0.6
	gl.omni_range = 3.2
	gl.position = Vector3(0, 1.6, 0.3)
	pr.add_child(gl)


func _mi(mesh: String, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = Models.get_mesh(mesh)
	(parent if parent else self).add_child(mi)
	return mi


static func _tinted(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_color = c
	m.roughness = 1.0
	return m


func sync(R: Rules) -> void:
	var key := "%d:%d:%s" % [R.gseed, R.day, R.sites]
	if key != _key:
		_key = key
		_quarry.position = Vector3(R.QUARRY.x, 0, R.QUARRY.z)
		_mine.position = Vector3(R.MINEC.x, 0, R.MINEC.z)
		_mine.rotation.y = 0.0 if R.MINE.dir > 0 else PI    # the mouth faces back towards the village
		_jetty.position = Vector3(R.JETTY.x, 0, R.JETTY.z)
		for c in _ruins.get_children(): c.queue_free()
		var L := Map.ruin_layout(R.gseed, R.day)
		var light := _tinted(Color(0.65, 0.62, 0.56))
		var dark := _tinted(Color(0.54, 0.52, 0.47))
		for b in L.rub:
			var m := _mi("rub", _ruins)
			m.material_override = light if b.c else dark
			m.position = Vector3(b.x, 0, b.z)
			m.rotation.y = b.rot
			m.scale = Vector3(b.w, b.h, b.d)
		for p in L.pil:
			var m := _mi("pillar", _ruins)
			m.position = Vector3(p.x, 0, p.z)
			m.scale = Vector3(1, p.h, 1)
		_spots.clear(); _spot_mats.clear()
		for i in L.spots.size():
			var sp: Dictionary = L.spots[i]
			var m := _mi("spot", _ruins)
			m.position = Vector3(sp.x, 0, sp.z)
			m.rotation.y = i * 1.7
			var mat := _tinted(Color(0.9, 0.86, 0.74))
			m.material_override = mat
			_spots.append(m); _spot_mats.append(mat)
	for i in _spots.size():
		var full: bool = R.spots[i] > 0
		_spots[i].scale = Vector3(1, 1.0 if full else 0.55, 1)
		_spot_mats[i].albedo_color = Color(0.9, 0.86, 0.74) if full else Color(0.5, 0.48, 0.44)
