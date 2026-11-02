extends Node3D
## Rigged imported presentation only. Health, perception and rewards stay in Enemy.
@export var model_scene: PackedScene
var model: Node3D
var rig: Skeleton3D
var animator: AnimationPlayer
var current_state: StringName = &""
var _materials: Array[BaseMaterial3D] = []
var _hit_active: bool = false

func _ready() -> void:
	assert(model_scene != null,"Imported character needs a model scene")
	model = model_scene.instantiate()
	add_child(model)
	_find_parts(model)
	assert(rig != null and animator != null,"Imported character needs a rig and clips")
	play(&"idle")

func _find_parts(node: Node) -> void:
	if node is Skeleton3D:
		rig = node
	if node is AnimationPlayer:
		animator = node
	if node is MeshInstance3D:
		node.extra_cull_margin = 2.0
		for surface in range(node.mesh.get_surface_count()):
			var source = node.get_active_material(surface)
			if source is BaseMaterial3D:
				var material: BaseMaterial3D = source.duplicate()
				node.set_surface_override_material(surface,material)
				_materials.append(material)
	for child in node.get_children():
		_find_parts(child)

func play(state: StringName) -> void:
	if state == current_state:
		return
	assert(animator.has_animation(state),"Missing character clip: "+String(state))
	current_state = state
	var clip := animator.get_animation(state)
	clip.loop_mode = Animation.LOOP_NONE if state == &"die" else Animation.LOOP_LINEAR
	animator.play(state,0.12)

func set_hit_flash(active: bool) -> void:
	if active == _hit_active:
		return
	_hit_active = active
	for material in _materials:
		material.albedo_color = Color(1,0.5,0.5) if active else Color.WHITE
