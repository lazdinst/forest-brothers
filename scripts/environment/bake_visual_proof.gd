extends SceneTree
## Editor-time resource baker. Run explicitly; never used in ordinary play.
## Original source geometry, fixed seed 1946. Output is replaceable candidate art.

const BASE := "res://assets/environment/"
var rng := RandomNumberGenerator.new()
var bark: StandardMaterial3D
var needles: StandardMaterial3D
var fern_material: StandardMaterial3D
var stone: ShaderMaterial
var wood: StandardMaterial3D

func _initialize() -> void:
	call_deferred("_bake")

func _material(id: String, color: Color, texture_name: String = "", two_sided: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	mat.vertex_color_use_as_albedo = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	if two_sided:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if not texture_name.is_empty():
		mat.albedo_texture = load(BASE + "textures/" + texture_name + ".png")
	_save(mat, "materials/" + id + ".tres")
	return mat

func _save(resource: Resource, path: String) -> void:
	var full := BASE + path
	var error := ResourceSaver.save(resource, full)
	assert(error == OK, "Cannot save " + full)
	resource.take_over_path(full)

func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color = Color.WHITE) -> void:
	for p in [a, b, c]:
		st.set_color(color)
		st.set_uv(Vector2(p.x + p.z, p.y))
		st.add_vertex(p)

func _finish(st: SurfaceTool, material: Material, path: String) -> ArrayMesh:
	st.generate_normals()
	st.set_material(material)
	var mesh := st.commit()
	_save(mesh, "meshes/" + path + ".res")
	return mesh

func _visual(parent: Node3D, mesh: Mesh, id: String, at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = id
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)
	return instance

func _body(parent: Node3D, shape: Shape3D, at: Vector3, id: String = "Collision") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = id
	body.collision_layer = 1
	body.collision_mask = 2
	parent.add_child(body)
	var collider := CollisionShape3D.new()
	collider.name = "Shape"
	collider.shape = shape
	collider.position = at
	body.add_child(collider)
	return body

func _pack(node: Node3D, path: String) -> PackedScene:
	_set_owners(node, node)
	var packed := PackedScene.new()
	assert(packed.pack(node) == OK)
	_save(packed, "scenes/" + path + ".tscn")
	node.free()
	return packed

func _set_owners(parent: Node, scene_root: Node) -> void:
	for child in parent.get_children():
		child.owner = scene_root
		_set_owners(child, scene_root)

func _spruce() -> PackedScene:
	var tree := Node3D.new()
	tree.name = "SpruceV1"
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.055
	trunk.bottom_radius = 0.23
	trunk.height = 11.0
	trunk.radial_segments = 9
	trunk.rings = 3
	trunk.material = bark
	_save(trunk, "meshes/spruce_trunk_v1.tres")
	_visual(tree, trunk, "Trunk", Vector3(0, 5.5, 0))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Irregular whorls of drooping boughs with lateral branchlets. Opaque
	# leaf geometry avoids alpha cards and the solid stacked-cone silhouette.
	for tier in range(17):
		var y := 1.6 + tier * 0.53
		var radius := (1.0 - float(tier) / 19.0) * 2.8
		var offset := rng.randf() * TAU
		for branch in range(8):
			var angle := offset + branch * TAU / 8.0 + rng.randf_range(-0.12, 0.12)
			var direction := Vector3(cos(angle), 0, sin(angle))
			var side := Vector3(-sin(angle), 0, cos(angle))
			var length := radius * rng.randf_range(0.75, 1.08)
			for section in range(6):
				var t := float(section + 1) / 7.0
				var center := direction * length * t + Vector3.UP * (y - sin(t * PI) * 0.36)
				var width := (1.0 - t) * 0.54 + 0.07
				var color := Color(0.72, 0.83, 0.67).lerp(Color(1.07, 1.02, 0.81), rng.randf())
				for sign_value in [-1.0, 1.0]:
					# Four narrow needle sprays on each lateral twig. The gaps
					# retain a feathered outline instead of a single broad leaf.
					for twig in range(4):
						var q := float(twig + 1) / 4.0
						var tip: Vector3 = center + side * width * sign_value * q - direction * q * 0.22 - Vector3.UP * q * 0.18
						var spread := (0.08 + (1.0 - q) * 0.055) * rng.randf_range(0.75, 1.2)
						_triangle(st, tip - side * spread, tip + direction * 0.25 + Vector3.UP * 0.045, tip + side * spread, color)
						_triangle(st, tip - Vector3.UP * spread * 0.65, tip + direction * 0.23, tip + Vector3.UP * spread * 0.65, color.darkened(0.08))
	var foliage := _finish(st, needles, "spruce_boughs_v1")
	_visual(tree, foliage, "Boughs")
	var shape := CylinderShape3D.new()
	shape.radius = 0.23
	shape.height = 11.0
	_body(tree, shape, Vector3(0, 5.5, 0), "TrunkBody")
	return _pack(tree, "spruce_v1")

func _fern() -> PackedScene:
	var plant := Node3D.new()
	plant.name = "FernV1"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for frond in range(9):
		var angle := frond * TAU / 9.0
		var direction := Vector3(cos(angle), 0, sin(angle))
		var side := Vector3(-sin(angle), 0, cos(angle))
		var length := rng.randf_range(0.6, 0.9)
		for section in range(1, 13):
			var t := float(section) / 14.0
			var center := direction * length * t + Vector3.UP * (sin(t * PI * 0.85) * 0.48 + 0.04)
			var width := sin(t * PI) * 0.16
			var color := Color(0.78, 0.88, 0.65).lerp(Color(1.05, 1.05, 0.8), t)
			for sign_value in [-1.0, 1.0]:
				var tip: Vector3 = center + side * width * sign_value + direction * 0.06
				_triangle(st, center - direction * 0.028, tip, center + direction * 0.038, color)
			_triangle(st, center - side * 0.008, center + side * 0.008, center + direction * 0.075 + Vector3.UP * 0.025, color)
	_visual(plant, _finish(st, fern_material, "fern_v1"), "Fronds")
	return _pack(plant, "fern_v1")

func _rock() -> PackedScene:
	var rock := Node3D.new()
	rock.name = "BoulderV1"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = []
	for ring in range(8):
		var pitch := PI * (0.02 + 0.96 * ring / 7.0)
		for sector in range(12):
			var angle := sector * TAU / 12.0
			var r := rng.randf_range(0.87, 1.13)
			points.append(Vector3(cos(angle) * sin(pitch) * 1.25 * r, cos(pitch) * 0.8 * r + 0.64, sin(angle) * sin(pitch) * 0.93 * r))
	for ring in range(7):
		for sector in range(12):
			var a := points[ring * 12 + sector]
			var b := points[ring * 12 + (sector + 1) % 12]
			var c := points[(ring + 1) * 12 + sector]
			var d := points[(ring + 1) * 12 + (sector + 1) % 12]
			_triangle(st, a, c, b)
			_triangle(st, b, c, d)
	var mesh := _finish(st, stone, "boulder_v1")
	_visual(rock, mesh, "Visual")
	_body(rock, mesh.create_convex_shape(), Vector3.ZERO)
	return _pack(rock, "boulder_v1")

func _crate() -> PackedScene:
	var crate := Node3D.new()
	crate.name = "CrateV1"
	var planks := SurfaceTool.new()
	planks.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Merge plank boxes into one mesh, keeping narrow physical-looking joints.
	for row in range(4):
		for side in [-1, 1]:
			_box_geometry(planks, Vector3(0, 0.1 + row * 0.19, side * 0.36), Vector3(1.04, 0.18, 0.055))
			_box_geometry(planks, Vector3(side * 0.5, 0.1 + row * 0.19, 0), Vector3(0.055, 0.18, 0.7))
	for index in range(5):
		_box_geometry(planks, Vector3(-0.4 + index * 0.2, 0.79, 0), Vector3(0.19, 0.05, 0.76))
	for side in [-1, 1]:
		for x in [-0.39, 0.39]:
			_box_geometry(planks, Vector3(x, 0.4, side * 0.4), Vector3(0.095, 0.8, 0.045))
	_visual(crate, _finish(planks, wood, "crate_v1"), "Visual")
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.06, 0.82, 0.84)
	_body(crate, shape, Vector3(0, 0.41, 0)).add_to_group("vaultable", true)
	return _pack(crate, "crate_v1")

func _box_geometry(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var box := BoxMesh.new()
	box.size = size
	var vertices := box.get_faces()
	for i in range(0, vertices.size(), 3):
		_triangle(st, vertices[i] + at, vertices[i + 1] + at, vertices[i + 2] + at)

func _ground() -> PackedScene:
	var ground := Node3D.new()
	ground.name = "MossGroundV1"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-12, 12):
		for x in range(-12, 12):
			_triangle(st, Vector3(x, 0, z), Vector3(x + 1, 0, z), Vector3(x, 0, z + 1))
			_triangle(st, Vector3(x + 1, 0, z), Vector3(x + 1, 0, z + 1), Vector3(x, 0, z + 1))
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/environment/ground_v1.gdshader")
	mat.set_shader_parameter("ground_texture", load(BASE + "textures/moss_soil_v1.png"))
	_save(mat, "materials/moss_ground_v1.tres")
	var mesh := _finish(st, mat, "moss_ground_v1")
	_visual(ground, mesh, "Visual")
	_body(ground, mesh.create_trimesh_shape(), Vector3.ZERO)
	return _pack(ground, "moss_ground_v1")

func _bake() -> void:
	rng.seed = 1946
	for folder in ["materials", "meshes", "scenes"]:
		DirAccess.make_dir_recursive_absolute(BASE + folder)
	bark = _material("spruce_bark_v1", Color.WHITE, "spruce_bark_v1")
	needles = _material("spruce_needles_v1", Color(0.20, 0.29, 0.18), "", true)
	fern_material = _material("fern_v1", Color(0.32, 0.40, 0.19), "", true)
	stone = ShaderMaterial.new()
	stone.shader = load("res://scripts/environment/stone_v1.gdshader")
	stone.set_shader_parameter("stone_texture", load(BASE + "textures/granite_v1.png"))
	_save(stone, "materials/granite_v1.tres")
	wood = _material("weathered_wood_v1", Color.WHITE, "weathered_wood_v1")
	_spruce()
	_fern()
	_rock()
	_crate()
	_ground()
	print("ENVIRONMENT BAKE PASS: five reusable candidate scenes, original geometry, seed 1946.")
	quit()
