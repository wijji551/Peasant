extends RefCounted
## Helpers for building things out of boxes, cylinders and cones, the way the web version does.
## Every "pos" is the centre of the thing's base (it sits on that point), not its middle.

static var _mats: Dictionary = {}


static func mat(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var key := "%s|%.2f" % [color.to_html(), emission]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	m.metallic_specular = 0.15
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	_mats[key] = m
	return m


static func _place(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3, half_h: float, rot: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	# rotate about the base point, then lift by half the height
	var b := Basis.from_euler(rot)
	mi.transform = Transform3D(b, pos + b * Vector3(0, half_h, 0))
	parent.add_child(mi)
	return mi


static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rot_y: float = 0.0, rot_x: float = 0.0, rot_z: float = 0.0) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _place(parent, m, mat(color), pos, size.y * 0.5, Vector3(rot_x, rot_y, rot_z))


static func cyl(parent: Node3D, r_top: float, r_bottom: float, h: float, pos: Vector3, color: Color, sides: int = 8, rot_y: float = 0.0, rot_x: float = 0.0, rot_z: float = 0.0) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bottom
	m.height = h
	m.radial_segments = sides
	m.rings = 1
	return _place(parent, m, mat(color), pos, h * 0.5, Vector3(rot_x, rot_y, rot_z))


static func cone(parent: Node3D, r: float, h: float, pos: Vector3, color: Color, sides: int = 8, rot_y: float = 0.0) -> MeshInstance3D:
	return cyl(parent, 0.0, r, h, pos, color, sides, rot_y)


## A pitched roof: "span" across the slope, "length" along the ridge. rot_y 0 runs the ridge north to south.
static func roof(parent: Node3D, span: float, h: float, length: float, pos: Vector3, color: Color, rot_y: float = 0.0) -> MeshInstance3D:
	var m := PrismMesh.new()
	m.size = Vector3(span, h, length)
	return _place(parent, m, mat(color), pos, h * 0.5, Vector3(0, rot_y, 0))


static func glow_box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, rot_y: float = 0.0) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _place(parent, m, material, pos, size.y * 0.5, Vector3(0, rot_y, 0))


## An invisible wall: something villagers and the dead cannot walk through.
## (Not used for play any more: the rules keep their own map of what is solid, in rules/map.gd. Kept as a no-op so the
## building code reads the same as the web version's.)
static func solid(body: StaticBody3D, centre: Vector3, half_w: float, half_d: float, height: float = 4.0, rot_y: float = 0.0) -> void:
	return
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(half_w * 2.0, height, half_d * 2.0)
	cs.shape = shape
	cs.position = centre + Vector3(0, height * 0.5, 0)
	cs.rotation.y = rot_y
	body.add_child(cs)
