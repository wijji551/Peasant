class_name Mesher
extends RefCounted
## Builds one mesh out of many boxes, cylinders, cones and lumps, each in its own colour, flat-shaded the way
## the web version is. The calls take the same arguments in the same order as the web version's Builder
## (width, height, depth, x, y, z, colour, then turns about y, x and z), so its models copy across line for line.
## A model made this way is one draw instead of dozens, which matters with two hundred of the dead about.

var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _xf := Transform3D.IDENTITY      # a frame to build in: at() moves and turns it

static var _shapes := {}             # cached unit shapes: key -> [vertices] (unindexed triangles)
static var _mat: Material


## Build everything that follows at (x, z), turned by ry, as the web version's at() does. at() with nothing resets.
func at(x: float = 0, z: float = 0, ry: float = 0) -> Mesher:
	_xf = Transform3D(Basis(Vector3.UP, ry), Vector3(x, 0, z))
	return self


static func _col(c) -> Color:
	if c is Color: return c
	if c is int: return Color.hex((c << 8) | 0xff)
	return Color(c)


static func _tris(key: String, mesh: PrimitiveMesh) -> PackedVector3Array:
	if _shapes.has(key):
		return _shapes[key]
	var a := mesh.get_mesh_arrays()
	var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var out := PackedVector3Array()
	if idx.size():
		for i in idx: out.append(verts[i])
	else:
		out = verts
	_shapes[key] = out
	return out


func _put(tris: PackedVector3Array, xf: Transform3D, color) -> void:
	var c := _col(color)
	var full := _xf * xf
	for i in range(0, tris.size(), 3):
		var a := full * tris[i]
		var b := full * tris[i + 1]
		var d := full * tris[i + 2]
		var n := (b - a).cross(d - a).normalized()
		# Godot's primitive meshes wind clockwise seen from outside, so the outward normal is the other way round
		_v.append(a); _v.append(b); _v.append(d)
		_n.append(-n); _n.append(-n); _n.append(-n)
		_c.append(c); _c.append(c); _c.append(c)


# (x, y, z) is the centre of the base, as in the web version; the turn is about that point
func _frame(x: float, y: float, z: float, ry: float, rx: float, rz: float, sx: float, sy: float, sz: float, lift: float) -> Transform3D:
	var b := Basis.from_euler(Vector3(rx, ry, rz))
	return Transform3D(b * Basis.from_scale(Vector3(sx, sy, sz)), Vector3(x, y, z) + b * Vector3(0, lift * sy, 0))


func box(w: float, h: float, d: float, x: float, y: float, z: float, c, ry: float = 0, rx: float = 0, rz: float = 0, _outline = true) -> Mesher:
	var m := BoxMesh.new()
	_put(_tris("box", m), _frame(x, y, z, ry, rx, rz, w, h, d, 0.5), c)
	return self


func cyl(rt: float, rb: float, h: float, sides: int, x: float, y: float, z: float, c, ry: float = 0, rx: float = 0, rz: float = 0, _outline = true) -> Mesher:
	var key := "cyl%d|%.3f" % [sides, rt / maxf(rb, 1e-4) if rb > 0 else -1.0]
	var tris: PackedVector3Array
	var r := maxf(rt, rb)
	if _shapes.has(key):
		tris = _shapes[key]
	else:
		var m := CylinderMesh.new()
		m.top_radius = rt / r; m.bottom_radius = rb / r; m.height = 1.0; m.radial_segments = sides; m.rings = 1
		tris = _tris(key, m)
	_put(tris, _frame(x, y, z, ry, rx, rz, r, h, r, 0.5), c)
	return self


func cone(r: float, h: float, sides: int, x: float, y: float, z: float, c, ry: float = 0, rx: float = 0, rz: float = 0) -> Mesher:
	return cyl(0.0, r, h, sides, x, y, z, c, ry, rx, rz)


## a lumpy ball, centred on (x, y, z) (unlike the others), squashed to s of its height
func ico(r: float, x: float, y: float, z: float, c, s: float = 1.0) -> Mesher:
	var key := "ico"
	var tris: PackedVector3Array
	if _shapes.has(key):
		tris = _shapes[key]
	else:
		var m := SphereMesh.new()
		m.radius = 1.0; m.height = 2.0; m.radial_segments = 7; m.rings = 4
		tris = _tris(key, m)
	_put(tris, Transform3D(Basis.from_scale(Vector3(r, r * s, r)), Vector3(x, y, z)), c)
	return self


## a pitched roof: span across the slope, length along the ridge
func roof(span: float, h: float, length: float, x: float, y: float, z: float, c, ry: float = 0) -> Mesher:
	var m := PrismMesh.new()
	_put(_tris("prism", m), _frame(x, y, z, ry, 0, 0, span, h, length, 0.5), c)
	return self


func is_empty() -> bool:
	return _v.is_empty()


func commit() -> ArrayMesh:
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = _v
	a[Mesh.ARRAY_NORMAL] = _n
	a[Mesh.ARRAY_COLOR] = _c
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	mesh.surface_set_material(0, material())
	return mesh


## The one material everything built here shares: vertex colours, times a tint per copy (for MultiMesh copies).
static func material() -> Material:
	if _mat == null:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 1.0
		m.metallic_specular = 0.15
		_mat = m
	return _mat


## A node showing the mesh, ready to add to the scene.
func node() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = commit()
	return mi
