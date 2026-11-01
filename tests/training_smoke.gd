extends SceneTree
## Real physics checks for the local movement course and firing lane.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)

func _place(player, at: Vector3) -> void:
	player.position = at
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	await _frames(8)

func _run() -> void:
	var world = load("res://scenes/prototype/camp_test.tscn").instantiate()
	root.add_child(world)
	var player = world.get_node("Player")
	await _frames(10)
	await _place(player, Vector3(-11, 0.02, 8.3))
	Input.action_press("move_forward")
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	await _frames(35)
	Input.action_release("move_forward")
	_check(player.position.z < 6.6, "Jump must clear the low hurdle")
	await _place(player, Vector3(-11, 0.02, -3.8))
	Input.action_press("crouch")
	Input.action_press("move_forward")
	await _frames(60)
	Input.action_release("move_forward")
	Input.action_release("crouch")
	await _frames(12)
	_check(player.position.z < -5.0 and player.is_crouching, "Enter low tunnel and prevent standing through its roof")
	Input.action_press("move_back")
	await _frames(100)
	Input.action_release("move_back")
	await _frames(12)
	_check(not player.is_crouching, "Stand after leaving the low roof")
	await _place(player, Vector3(-5, 0.02, 5))
	Input.action_press("lean_right")
	await _frames(20)
	_check(player.camera.position.x > 0.01 and player.camera.position.x < 0.25, "Lean must stop the head at the wall")
	_check(absf(player.position.x + 5.0) < 0.01, "Leaning must not move the body")
	Input.action_release("lean_right")
	Input.action_press("lean_left")
	await _frames(30)
	_check(player.camera.position.x < -0.30, "Lean freely away from the wall")
	Input.action_release("lean_left")
	await _place(player, Vector3(-11, 0.02, 4.7))
	_check(player.try_vault(), "Start vault at the low barrier")
	await _frames(55)
	_check(player.position.z < 3.0 and not player.is_vaulting, "Complete vault across the barrier")
	await _place(player, Vector3(-11, 0.02, 0.9))
	_check(player.try_vault(), "Start climbing the marked platform")
	await _frames(55)
	_check(player.position.z < -1.0 and player.position.y > 1.0, "Finish on top of the platform")
	await _place(player, Vector3(-16, 0.02, 3.2))
	_check(not player.try_vault(), "Reject an obstacle too high to climb")
	# A blocked destination must reject traversal rather than teleporting into it.
	var blocker := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2, 2, 0.4)
	collision.shape = box
	blocker.add_child(collision)
	world.add_child(blocker)
	blocker.position = Vector3(-11, 1.0, 2.475)
	await _place(player, Vector3(-11, 0.02, 4.7))
	_check(not player.try_vault(), "Reject blocked landing")
	blocker.queue_free()
	await _place(player, Vector3(11, 0.02, -8))
	var target = world.get_node("Course/Target2")
	player.camera.look_at(target.global_position)
	player.weapon.rng.seed = 12345
	player.weapon.command(&"fire")
	await _frames(3)
	_check(target.hit_count == 1 and player.weapon.hits == 1, "Camera-directed shot must hit the aimed target")
	_check(player.weapon.state.total_rounds() == 39, "Successful shot consumes one physical round")
	var walker = world.get_node("Course/WalkingCivilian")
	var before: Vector3 = walker.position
	var first_frame = walker.get_node("FacingVisual/IdleSprite").texture
	await _frames(13)
	_check(walker.position.distance_to(before) > 0.05, "Walking civilian must physically move")
	_check(walker.get_node("FacingVisual/IdleSprite").texture is AtlasTexture, "Walking character must use atlas frames")
	_check(walker.get_node("FacingVisual/IdleSprite").texture != first_frame, "Walking atlas frame must advance")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: jump, low tunnel, blocked standing, collision-limited lean, vault, mantle, high/blocked rejection, aimed shot, walking frames")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
