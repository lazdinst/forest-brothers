extends Node3D
## Authored training fixtures; geometry is generated from explicit named sizes.

const RangeTarget = preload("res://scripts/prototype/range_target.gd")
const Civilian = preload("res://scenes/characters/starting_civilian.tscn")


func _ready() -> void:
	call_deferred("_install_systems_annex")
	_box("JumpHurdle", Vector3(-11, 0.2, 7), Vector3(3, 0.4, 0.4), Color(0.46, 0.35, 0.2))
	_box("VaultBarrier", Vector3(-11, 0.425, 3.5), Vector3(3, 0.85, 0.55), Color(0.45, 0.37, 0.24), true)
	_box("MantlePlatform", Vector3(-11, 0.55, -1), Vector3(3, 1.1, 2), Color(0.38, 0.4, 0.35), true)
	_box("CrouchRoof", Vector3(-11, 1.35, -6), Vector3(3.4, 0.3, 3), Color(0.3, 0.35, 0.32))
	_box("TunnelLeft", Vector3(-12.6, 0.65, -6), Vector3(0.3, 1.3, 3), Color(0.3, 0.35, 0.32))
	_box("TunnelRight", Vector3(-9.4, 0.65, -6), Vector3(0.3, 1.3, 3), Color(0.3, 0.35, 0.32))
	_box("LeanWall", Vector3(-4.5, 1.4, 5), Vector3(0.3, 2.8, 4), Color(0.32, 0.37, 0.4))
	_box("CornerWall", Vector3(-3.1, 1.4, 3), Vector3(3, 2.8, 0.3), Color(0.32, 0.37, 0.4))
	_box("TooHigh", Vector3(-16, 1.1, 2), Vector3(2, 2.2, 0.5), Color(0.4, 0.3, 0.25), true)
	_label("Obstacle course\nSPACE jump / V vault & climb", Vector3(-11, 2.5, 10))
	_label("CTRL crouch\nLow passage", Vector3(-11, 2.5, -4))
	_label("Q / E lean\nF interact", Vector3(-5, 3.2, 7))
	_label("Too high\nFind another route", Vector3(-16, 2.8, 2))
	_label("Firing lane\nLMB fire / RMB aim", Vector3(11, 2.4, -6))
	for index in range(3):
		var target = RangeTarget.new()
		target.name = "Target%d" % (index + 1)
		target.position = Vector3(8 + index * 3, 1.4, -19)
		add_child(target)
		_add_box_parts(target, Vector3(1.0, 1.4, 0.16), Color(0.64, 0.55, 0.32))
		var bullseye := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.22
		disc.bottom_radius = 0.22
		disc.height = 0.02
		bullseye.mesh = disc
		bullseye.rotation.x = PI / 2.0
		bullseye.position.z = 0.1
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.35, 0.16, 0.12)
		bullseye.material_override = material
		target.add_child(bullseye)
		_label("%d" % (index + 1), target.position + Vector3(0, 1, 0))
	var walker = Civilian.instantiate()
	walker.name = "WalkingCivilian"
	walker.position = Vector3(-13, 0, -15)
	walker.patrol_enabled = true
	add_child(walker)
	_label("Walking animation test", Vector3(-13, 2.7, -11))


func _box(node_name: String, at: Vector3, size: Vector3, color: Color, vaultable: bool = false) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	if vaultable:
		body.add_to_group("vaultable")
	add_child(body)
	_add_box_parts(body, size, color)
	return body


func _add_box_parts(body: StaticBody3D, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.name = "Mesh"
	instance.mesh = mesh
	body.add_child(instance)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)


func _label(text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 40
	label.pixel_size = 0.0025
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)


func _install_systems_annex() -> void:
	var annex = load("res://scripts/camp/training_annex.gd").new()
	annex.name = "SystemsAnnex"
	get_parent().add_child(annex)
	var showcase = load("res://scripts/characters/polygon_showcase.gd").new()
	showcase.name = "PolygonShowcase"
	showcase.position = Vector3(-6,0,11)
	get_parent().add_child(showcase)
