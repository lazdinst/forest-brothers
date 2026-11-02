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
	await _frames(6)
	var weapon = player.weapon
	var target = world.get_node("Course/Target2")
	player.camera.look_at(target.global_position)
	await _frames(3)
	weapon.rng.seed = 12345
	weapon.state.inventory.chamber()
	var muzzle: Vector3 = weapon.muzzle_world_position()
	weapon.command(&"fire")
	await _frames(2)
	_check(weapon.last_shot_origin.distance_to(muzzle) < 0.02, "Shot begins at the projected barrel")
	_check(weapon.last_shot_origin.distance_to(player.camera.global_position) > 0.8, "Shot origin must be ahead of the player's eye")
	_check(weapon._flash.visible and weapon._flash.texture is AtlasTexture, "A successful shot starts sprite flash animation")
	_check(weapon._gun_material.get_shader_parameter("flash_strength") > 0.0 and weapon._world_light.light_energy > 0.0, "Flash lights the gun sprite and nearby world")
	_check((weapon._flash.position + weapon._flash.size * 0.5).distance_to(weapon.muzzle_screen_position()) < 0.1, "Flash follows the actual on-screen muzzle")
	_check(target.hit_count == 1, "Unobstructed hip shot reaches the target")
	await _frames(20)
	_check(not weapon._flash.visible and weapon._world_light.light_energy == 0.0 and weapon._gun_material.get_shader_parameter("flash_strength") == 0.0, "Flash and both lights expire")
	# Narrow cover blocks the barrel path but leaves the camera's sight line clear.
	var blocker := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.007, 0.007, 0.06)
	shape.shape = box
	blocker.add_child(shape)
	world.add_child(blocker)
	blocker.global_position = player.camera.global_position.lerp(weapon.muzzle_world_position(), 0.65)
	await _frames(3)
	var eye: Vector3 = player.camera.global_position
	var aim_hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye, eye - player.camera.global_basis.z * 150.0, 1, [player.get_rid()]))
	_check(not aim_hit.is_empty() and aim_hit.collider == target, "Fixture must leave the camera's target visible")
	weapon.command(&"fire")
	await _frames(2)
	_check(weapon.last_shot_blocked and target.hit_count == 1, "Barrel behind nearby cover cannot shoot through it")
	_check(weapon.last_shot_end.distance_to(blocker.global_position) < 0.06, "Blocked shot terminates on near cover")
	blocker.queue_free()
	await _frames(20)
	weapon.state.jammed = true
	weapon.command(&"fire")
	await _frames(2)
	_check(not weapon._flash.visible and weapon.shots == 2, "A jam produces no muzzle flash or shot")
	weapon.state.jammed = false
	Input.action_press("aim")
	await _frames(25)
	weapon.command(&"fire")
	await _frames(2)
	_check(weapon._flash.visible and (weapon._flash.position + weapon._flash.size * 0.5).distance_to(weapon.muzzle_screen_position()) < 0.1, "ADS uses its own muzzle attachment")
	await _frames(10)
	_check(target.hit_count == 2, "ADS barrel ray still reaches the aimed target")
	Input.action_release("aim")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: hip/ADS muzzle attachment, barrel ray origin, cover obstruction, aimed hits, flash atlas, gun/world illumination, expiry, no flash on jam")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
