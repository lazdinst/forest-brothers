extends SceneTree
## Crouching: with only a crate nearby, a hit enemy takes low cover and crouches behind it, hidden
## from the shooter; it peeks by standing up in place to fire over the crate, then crouches again.
## Full-height wall cover is still measured at standing chest and head height.
const Enemy = preload("res://scripts/combat/enemy_actor.gd")
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)
func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
func _until(enemy, player, phase: StringName, seconds: float) -> bool:
	for i in range(int(60 * seconds)):
		await _frames(1)
		if not player.body.is_alive():
			player.restore_for_drill()
		if enemy.cover_phase == phase:
			return true
	return false
func _sees(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, exclude: Array[RID]) -> bool:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1, exclude)).is_empty()

func _run() -> void:
	var arena = load("res://scenes/combat/combat_arena.tscn").instantiate()
	arena.temperament_pool.assign([Enemy.STEADY])
	root.add_child(arena)
	await _frames(10)
	var player = arena.player
	for other in arena.enemies:
		other.active = false
	var enemy = arena.enemies[0]
	# The crate at (-12, 0.5, 14) is the only cover in reach; the player stands well south of it.
	enemy.global_position = Vector3(-12, 0, 11.5)
	enemy.rotation.y = 0.0
	player.global_position = Vector3(-12, 0.02, 26)
	enemy.active = true
	await _frames(5)
	var space: PhysicsDirectSpaceState3D = enemy.get_world_3d().direct_space_state
	var eye: Vector3 = player.global_position + Vector3.UP * 1.5
	var point: Vector3 = enemy.find_cover(player.global_position)
	_check(point != Vector3.INF and _flat(point, Vector3(-12, 0, 14)) < 2.0, "With only a crate nearby, the enemy picks low cover behind it (%s)" % point)
	_check(enemy._found_cover_crouch and not enemy.hidden_from(space, eye, point) and enemy.hidden_from(space, eye, point, Enemy.CROUCHED_COVER_HEIGHTS), "The crate hides a crouched body but not a standing one")
	enemy.receive_hit(10, enemy.global_position + Vector3.UP, Vector3.FORWARD, player, &"arms")
	_check(enemy.cover_crouch and enemy.cover_phase == &"move", "Hit, it runs for the crate")
	_check(not enemy.crouched, "It runs upright")
	_check(await _until(enemy, player, &"hold", 6.0), "It reaches the crate")
	await _frames(2)
	_check(enemy.crouched and absf(enemy.get_node("Body").shape.height - Enemy.CROUCH_HEIGHT) < 0.01 and enemy.hit_zones.height < 1.0, "Behind the crate it crouches: body and hit zones lower")
	var head: Vector3 = enemy.global_position + Vector3.UP * (Enemy.CROUCH_HEIGHT - 0.03)
	_check(not _sees(space, eye, head, [player.get_rid()]) and not enemy.can_see(player), "Crouched, it is hidden from the player and cannot see them")
	var shots := {"n": 0}
	enemy.fired.connect(func(_e, _a, _h): shots.n += 1)
	_check(await _until(enemy, player, &"peek", 6.0), "It peeks")
	_check(not enemy.crouched and _flat(enemy.global_position, enemy.cover_point) < 0.5, "It peeks by standing up in place")
	var waited := 0
	while shots.n == 0 and waited < 60 * 3:
		await _frames(1)
		waited += 1
		if not player.body.is_alive():
			player.restore_for_drill()
	_check(shots.n > 0, "It fires over the crate")
	_check(await _until(enemy, player, &"hold", 6.0), "It drops back behind the crate")
	await _frames(2)
	_check(enemy.crouched, "And crouches again")
	# Down while crouched: the downed body takes over.
	enemy.receive_hit(90, enemy.global_position + Vector3.UP * 0.5, Vector3.FORWARD, player, &"torso")
	_check(enemy.state == &"downed" and not enemy.crouched and enemy.hit_zones.layout == &"downed", "Going down clears the crouch")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: low cover chosen behind a crate, runs upright, crouches hidden, peeks by standing, fires over, crouches again, down clears crouch")
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
