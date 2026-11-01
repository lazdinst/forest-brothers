@tool
extends EditorScenePostImport
## Keep the authored vertex palette visible in both editor previews and runtime.
func _post_import(scene):
	_apply(scene)
	return scene
func _apply(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var material = node.mesh.surface_get_material(surface).duplicate()
			material.vertex_color_use_as_albedo = true
			node.set_surface_override_material(surface,material)
	for child in node.get_children():
		_apply(child)
