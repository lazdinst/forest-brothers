extends SceneTree
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame

func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)

func _run() -> void:
	var world = load("res://scenes/prototype/camp_test.tscn").instantiate()
	root.add_child(world)
	var player = world.get_node("Player")
	await _frames(10)
	player.position = Vector3(11, 0.02, -8)
	player.velocity = Vector3.ZERO
	await _frames(5)
	player.camera.look_at(world.get_node("Course/Target2").global_position)
	Input.action_press("aim")
	await _frames(30)
	_check(player.is_aiming and player.weapon.aim_fraction == 1.0, "RMB must reach the iron-sight view")
	_check(not world.get_node("HUD/Crosshair").visible, "Hide crosshair in ADS")
	_check(player.camera.fov == 60.0, "ADS must not substitute world zoom for sight alignment")
	for size in [Vector2i(1280, 720), Vector2i(1024, 768)]:
		root.size = size
		await _frames(3)
		_check(player.weapon.sight_screen_position().distance_to(root.get_visible_rect().size * 0.5) < 0.1, "Front sight must align with camera center at %s" % size)
	for action in ["lean_left", "lean_right"]:
		Input.action_press(action)
		await _frames(30)
		var sprite_up: Vector2 = player.weapon._hands.get_global_transform().basis_xform(Vector2.UP)
		_check(sprite_up.x * player.camera.position.x > 0.01, "ADS sprite top must lean toward the same side as the camera for %s" % action)
		_check(player.weapon.sight_screen_position().distance_to(root.get_visible_rect().size * 0.5) < 0.1, "Leaning must rotate around the sight instead of displacing it")
		Input.action_release(action)
		await _frames(20)
	await _frames(30)
	player.camera.look_at(world.get_node("Course/Target2").global_position)
	player.weapon.rng.seed = 12345
	player.weapon.command(&"fire")
	await _frames(18)
	_check(world.get_node("Course/Target2").hit_count == 1, "Shot must hit the target beneath the iron-sight aim point")
	player.weapon.command(&"reload")
	await _frames(12)
	_check(not player.is_aiming and player.weapon.aim_fraction < 0.05, "Reload interrupts ADS while RMB remains held")
	await _frames(100)
	_check(player.is_aiming and player.weapon.aim_fraction == 1.0, "Held RMB resumes ADS after reloading")
	Input.action_release("aim")
	await _frames(20)
	_check(player.weapon.aim_fraction == 0.0 and world.get_node("HUD/Crosshair").visible, "Release RMB returns to hip view and crosshair")
	for action in ["lean_left", "lean_right"]:
		Input.action_press(action)
		await _frames(30)
		var sprite_up: Vector2 = player.weapon._hands.get_global_transform().basis_xform(Vector2.UP)
		_check(sprite_up.x * player.camera.position.x > 0.01, "Hip sprite top must lean toward the same side as the camera for %s" % action)
		Input.action_release(action)
		await _frames(20)
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: ADS entry/release, sight alignment at two sizes, lean alignment, centered hit, reload interruption/resumption, fixed FOV")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
