extends SceneTree
const Builder = preload("res://assets/characters/polygon_humanoid/source/humanoid_builder.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	for variant in [&"civilian",&"guard"]:
		var builder = Builder.new()
		var model = builder.build(variant)
		root.add_child(model)
		await process_frame
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var error := document.append_from_scene(model,state)
		if error==OK:
			error = document.write_to_filesystem(state,"res://assets/characters/polygon_humanoid/%s_v1.glb" % variant)
		if error != OK:
			push_error("glTF bake failed: %s / %d" % [variant,error])
			quit(1)
			return
		print("BAKED ",variant," triangles=",builder.triangles," bones=",builder.bones.size())
		model.queue_free()
		await process_frame
	quit(0)
