extends SceneTree
## Focused collision/traversal integration plus optional real-renderer captures.
## -- --capture-dir=<absolute path> enables a stationary GPU sample and images.

var failures: Array[String] = []
var world: Node3D
var player

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	return world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1, [player.get_rid()]))

func _capture(directory: String, name: String) -> void:
	await _frames(12)
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(directory.path_join(name + ".png"))
	_check(error == OK, "Save rendered proof " + name)

func _run() -> void:
	world = load("res://scenes/environment/environment_visual_proof.tscn").instantiate()
	if world == null:
		push_error("Proof cannot load; import and bake environment resources first.")
		quit(1)
		return
	root.add_child(world)
	player = world.get_node("Player")
	await _frames(15)
	_check(player.is_on_floor(), "Player lands on proof ground")
	_check(not _ray(Vector3(-3.8, 1, 2), Vector3(-3.8, 1, -3)).is_empty(), "Spruce trunk blocks world/weapon rays")
	_check(_ray(Vector3(-3.0, 1, -1), Vector3(-3.0, 1, -3)).is_empty(), "Foliage does not create a solid collision curtain")
	_check(_ray(Vector3(-1.9, 0.3, 3), Vector3(-1.9, 0.3, 1.5)).is_empty(), "Fern decoration does not block projectiles")
	_check(not _ray(Vector3(3.6, 0.6, 0), Vector3(3.6, 0.6, -5)).is_empty(), "Boulder blocks world/weapon rays")
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await _frames(25)
	Input.action_release("move_forward")
	Input.action_release("sprint")
	_check(player.position.z < 6, "Existing controller runs along clear trail")
	Input.action_press("crouch")
	await _frames(15)
	_check(player.is_crouching, "Crouch works on ground")
	Input.action_release("crouch")
	Input.action_press("lean_left")
	await _frames(20)
	_check(player.camera.position.x < -0.1, "Leaning remains active")
	Input.action_release("lean_left")
	Input.action_press("aim")
	await _frames(25)
	_check(player.weapon.aim_fraction > 0.9, "Existing ADS remains active")
	Input.action_release("aim")
	player.position = Vector3(1.8, 0.03, 1.05)
	player.velocity = Vector3.ZERO
	await _frames(15)
	_check(player.try_vault(), "Crate collision supports existing low-vault detection")
	await _frames(50)
	_check(not player.is_vaulting and player.position.z < 0, "Crate vault completes with clear landing")
	var capture_dir := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	if not capture_dir.is_empty() and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(capture_dir)
		player.position = Vector3(0, 0.03, 7)
		player.velocity = Vector3.ZERO
		player.camera.rotation = Vector3(-0.04, 0, 0)
		await _frames(60)
		var times: Array[float] = []
		var draws: Array[float] = []
		var primitives: Array[float] = []
		var previous := Time.get_ticks_usec()
		for frame in range(240):
			await process_frame
			var now := Time.get_ticks_usec()
			times.append((now - previous) / 1000.0)
			previous = now
			draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		times.sort()
		var report := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(), "viewport": str(root.size), "samples": times.size(), "median_frame_ms": times[120], "p95_frame_ms": times[228], "draw_calls_max": draws.max(), "primitives_max": primitives.max(), "texture_bytes_process": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED), "video_bytes_process": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), "conditions": "Stationary proof spawn, six repeated spruce, five ferns, boulder, crate, civilian reference, existing weapon HUD, one shadowed sun, depth fog; uncapped, no movie writer. Whole process memory includes reused art. Not a 100m biome benchmark."}
		var file := FileAccess.open(capture_dir.path_join("performance.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
		print("PROOF_GPU_MEASUREMENTS ", JSON.stringify(report))
		await _capture(capture_dir, "proof_eye")
		player.position = Vector3(-0.1, 0.03, 3.2)
		player.camera.look_at(Vector3(-2.8, 1.8, -1))
		await _capture(capture_dir, "proof_spruce")
		player.position = Vector3(-0.7, 0.03, 3.7)
		player.camera.look_at(Vector3(-1.9, 0.25, 2.3))
		await _capture(capture_dir, "proof_fern_ground")
		player.position = Vector3(3.1, 0.03, 2.4)
		player.camera.look_at(Vector3(1.8, 0.4, 0))
		await _capture(capture_dir, "proof_crate")
		player.position = Vector3(5.1, 0.03, -0.4)
		player.camera.look_at(Vector3(3.6, 0.6, -2.8))
		await _capture(capture_dir, "proof_boulder")
	for failure in failures:
		push_error(failure)
	print("ENVIRONMENT PROOF CHECK: ", "PASS" if failures.is_empty() else "FAIL")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
