extends SceneTree
## Regression: camera pitch must not rotate/reposition the artwork or change FOV.
## Exercise the actual playable standing distance instead of teleporting inside it.

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world = load("res://scenes/prototype/camp_test.tscn").instantiate()
	root.add_child(world)
	var civilian: Node3D = world.get_node("StartingCivilian")
	var player = world.get_node("Player")
	player.global_position = civilian.global_position + Vector3(0, 0.01, 3)
	player.camera.rotation = Vector3.ZERO
	Input.action_press("move_forward")
	for frame in range(120):
		await physics_frame
	Input.action_release("move_forward")
	await process_frame
	await process_frame
	var separation := Vector2(player.position.x - civilian.position.x, player.position.z - civilian.position.z).length()
	_check(separation >= 1.18 and separation <= 1.3, "Walking up to the civilian should stop at about 1.2 m, got %.3f" % separation)
	var sprite: Sprite3D = civilian.get_node("FacingVisual/IdleSprite")
	var fixed_visual := sprite.global_transform
	var original_fov: float = player.camera.fov
	for pitch in [-1.1, -0.6, 0.0, 0.6, 1.1]:
		player.camera.rotation.x = pitch
		await process_frame
		await process_frame
		_check(sprite.global_transform.is_equal_approx(fixed_visual), "Looking up/down must not move or tilt the sprite (pitch %.2f)" % pitch)
		_check(is_equal_approx(player.camera.fov, original_fov), "Looking up/down must not change FOV")
		_check(sprite.global_basis.y.normalized().dot(Vector3.UP) > 0.999, "Civilian visual must remain upright")
	# At the nearest physically reachable distance, perspective taper is bounded.
	player.camera.look_at(civilian.global_position + Vector3(0, 0.9, 0))
	await process_frame
	await process_frame
	var upper_width: float = player.camera.unproject_position(sprite.to_global(Vector3(0.2, 0.7, 0))).distance_to(player.camera.unproject_position(sprite.to_global(Vector3(-0.2, 0.7, 0))))
	var lower_width: float = player.camera.unproject_position(sprite.to_global(Vector3(0.2, -0.7, 0))).distance_to(player.camera.unproject_position(sprite.to_global(Vector3(-0.2, -0.7, 0))))
	_check(lower_width > 0.0 and upper_width / lower_width < 1.9, "Standing distance must prevent extreme head-to-feet perspective taper")
	_check(civilian.global_basis.is_equal_approx(Basis.IDENTITY), "Looking must not rotate the collider")
	if failures.is_empty():
		print("PASS: standing distance, pitch-independent sprite transform/FOV, upright body, bounded close-up perspective")
	else:
		for failure in failures:
			push_error(failure)
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
