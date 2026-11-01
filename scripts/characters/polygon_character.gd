extends Node3D
## Presentation adapter shared by player, civilians and opponents. No gameplay effects.
@export_enum("civilian","guard","player") var variant: String = "civilian"
var model: Node3D
var rig: Skeleton3D
var animator: AnimationPlayer
var current_state: StringName = &""
var lean: float = 0.0
var _manual: bool = false
var _materials: Array[StandardMaterial3D] = []
var _hit_active: bool = false
var _pivot: Node3D
var _upper_meshes: Array[MeshInstance3D] = []

func _ready() -> void:
	_pivot = Node3D.new()
	_pivot.name = "LeanPivot"
	_pivot.position.y = 0.93
	add_child(_pivot)
	var asset_variant := "guard" if variant=="player" else variant
	model = load("res://assets/characters/polygon_humanoid/%s_v1.glb" % asset_variant).instantiate()
	model.position.y = -0.93
	_pivot.add_child(model)
	_find_parts(model)
	assert(rig != null and animator != null,"GLB must contain a skeleton and animation player")
	animator.process_priority = -10
	play(&"idle")

func _find_parts(node: Node) -> void:
	if node is Skeleton3D:
		rig = node
	if node is AnimationPlayer:
		animator = node
	if node is MeshInstance3D:
		node.extra_cull_margin = 2.0
		for surface in range(node.mesh.get_surface_count()):
			var material = node.mesh.surface_get_material(surface).duplicate()
			material.vertex_color_use_as_albedo = true
			node.set_surface_override_material(surface,material)
			_materials.append(material)
	if node is MeshInstance3D and ("UpperMesh" in String(node.name) or "TorsoMesh" in String(node.name)):
		_upper_meshes.append(node)
	for child in node.get_children():
		_find_parts(child)

func play(state: StringName) -> void:
	if animator == null:
		return
	if current_state == state and not _manual:
		return
	if not animator.has_animation(state):
		state = &"idle"
	current_state = state
	_manual = false
	animator.play(state,0.12)

func sample_action(state: StringName, progress: float) -> void:
	if animator == null or not animator.has_animation(state):
		return
	if current_state != state or not _manual:
		animator.play(state)
	current_state = state
	_manual = true
	animator.pause()
	animator.seek(clampf(progress,0,1)*animator.get_animation(state).length,true)

func set_first_person(enabled: bool) -> void:
	for mesh in _upper_meshes:
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func _process(_delta: float) -> void:
	_pivot.rotation.z = lean


func set_hit_flash(active: bool) -> void:
	if _hit_active == active:
		return
	_hit_active = active
	for material in _materials:
		material.albedo_color = Color(1,0.5,0.5) if active else Color.WHITE
