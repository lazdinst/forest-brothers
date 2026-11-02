extends Control
## Can display the supplied current visual without loading unapproved character art.
var has_character := false
var viewport: SubViewport
var pivot: Node3D

func bind_visual(visual: Node3D) -> void:
	if viewport != null:
		viewport.get_parent().queue_free()
		viewport = null
	has_character = is_instance_valid(visual)
	if not has_character:
		queue_redraw()
		return
	var container := SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	viewport = SubViewport.new()
	viewport.size = Vector2i(300,500)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	container.add_child(viewport)
	pivot = Node3D.new()
	viewport.add_child(pivot)
	var copy := visual.duplicate(0) as Node3D
	copy.transform = Transform3D.IDENTITY
	copy.process_mode = Node.PROCESS_MODE_DISABLED
	pivot.add_child(copy)
	for mesh in copy.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var camera := Camera3D.new()
	camera.position = Vector3(0,0.95,3.4)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.3
	camera.current = true
	viewport.add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30,-35,0)
	light.light_energy = 1.4
	viewport.add_child(light)
	queue_redraw()

func rotate_character(delta: float) -> void:
	if pivot != null: pivot.rotation.y += delta

func _draw() -> void:
	if has_character: return
	# Neutral ink mannequin, not a proposed outfit or an approved character model.
	var scale_factor := minf(size.x / 180, size.y / 450)
	draw_set_transform(Vector2(size.x/2,12),0,Vector2.ONE*scale_factor)
	var ink := Color("4b453a80")
	draw_circle(Vector2(0,31),25,ink)
	draw_colored_polygon(PackedVector2Array([Vector2(-13,52),Vector2(13,52),Vector2(45,74),Vector2(35,190),Vector2(32,230),Vector2(-32,230),Vector2(-35,190),Vector2(-45,74)]),ink)
	for signum in [-1,1]:
		draw_polyline(PackedVector2Array([Vector2(signum*40,83),Vector2(signum*61,158),Vector2(signum*66,236)]),ink,22,true)
		draw_polyline(PackedVector2Array([Vector2(signum*18,224),Vector2(signum*26,308),Vector2(signum*29,393)]),ink,27,true)
		draw_line(Vector2(signum*29,394),Vector2(signum*45,404),ink,18,true)
