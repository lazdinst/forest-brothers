extends SceneTree
## Check view selection with an independent camera, including rotated actors.

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var civilian = load("res://scenes/characters/starting_civilian.tscn").instantiate()
	root.add_child(civilian)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.make_current()
	var cases := [
		[Vector3(0, 1.6, 3), "front", false],
		[Vector3(3, 1.6, 0), "side", false],
		[Vector3(0, 1.6, -3), "back", false],
		[Vector3(-3, 1.6, 0), "side", true],
		[Vector3(0.01, 1.6, -3), "back", false]
	]
	for yaw in [0.0, PI / 2.0]:
		civilian.rotation.y = yaw
		for entry in cases:
			camera.position = civilian.global_basis * entry[0]
			await process_frame
			await process_frame
			var sprite: Sprite3D = civilian.get_node("IdleSprite")
			_check(sprite.texture.resource_path.contains("_%s_" % entry[1]), "Wrong texture for view %s at yaw %.2f" % [entry[1], yaw])
			_check(sprite.flip_h == entry[2], "Wrong profile mirroring at yaw %.2f" % yaw)
	# Small movements across a sector boundary should not flicker between views.
	civilian.rotation.y = 0.0
	camera.position = Vector3(0, 1.6, 3)
	await process_frame
	await process_frame
	camera.position = Vector3(3.05, 1.6, 3)
	await process_frame
	await process_frame
	_check(civilian.get_node("IdleSprite").texture == civilian.front_texture, "Direction must remain stable near a boundary")
	if failures.is_empty():
		print("PASS: front/back/both profiles, rotated actor, angle wrapping, direction-boundary stability")
	else:
		for failure in failures:
			push_error(failure)
	civilian.queue_free()
	camera.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
