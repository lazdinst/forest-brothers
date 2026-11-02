extends SceneTree
## Check the actual F5 scene, including new prop collisions and crate traversal.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	var world = load("res://scenes/prototype/camp_test.tscn").instantiate()
	root.add_child(world)
	var player = world.get_node("Player")
	await _frames(12)
	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	for entry in [[Vector3(7, 1, 5), Vector3(7, 1, -1), "TrunkBody"], [Vector3(13, 0.6, 6), Vector3(13, 0.6, 0), "Collision"]]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(entry[0], entry[1], 1, [player.get_rid()]))
		_check(not hit.is_empty() and hit.collider.name == entry[2], "Woodland cover blocks world rays at " + str(entry[0]))
	var fern_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(8.8, 0.3, 4.4), Vector3(8.8, 0.3, 3.1), 1, [player.get_rid()]))
	_check(fern_hit.is_empty(), "Decorative fern does not block world rays")
	player.position = Vector3(8, 0.02, 8.05)
	player.velocity = Vector3.ZERO
	await _frames(12)
	_check(player.try_vault(), "Training-yard crate supports vaulting")
	await _frames(50)
	_check(not player.is_vaulting and player.position.z < 7, "Crate vault has a clear landing in the actual training yard")
	if DisplayServer.get_name() != "headless":
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--capture="):
				player.position = Vector3(1, 0.02, 11)
				player.velocity = Vector3.ZERO
				player.camera.look_at(Vector3(9, 1.5, 3))
				await _frames(15)
				await RenderingServer.frame_post_draw
				_check(root.get_texture().get_image().save_png(arg.trim_prefix("--capture=")) == OK, "Save integrated training view")
	for failure in failures:
		push_error(failure)
	print("TRAINING ENVIRONMENT CHECK: ", "PASS" if failures.is_empty() else "FAIL")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
