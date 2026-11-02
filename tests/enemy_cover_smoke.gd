extends SceneTree
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
func _run() -> void:
	var arena = load("res://scenes/combat/combat_arena.tscn").instantiate()
	root.add_child(arena)
	await _frames(10)
	var player = arena.player
	var enemy = arena.enemies[0]
	arena.enemies[1].active = false
	# Open ground east of the screening wall, between it and the farmhouse; player due south.
	enemy.global_position = Vector3(18, 0, 3)
	player.global_position = Vector3(18, 0.02, 20)
	await _frames(5)
	var space: PhysicsDirectSpaceState3D = enemy.get_world_3d().direct_space_state
	var eye: Vector3 = player.global_position + Vector3.UP * 1.5
	var point: Vector3 = enemy.find_cover(player.global_position)
	_check(point != Vector3.INF, "Enemy finds cover near it")
	_check(point == Vector3.INF or enemy.hidden_from(space, eye, point), "Chosen cover hides chest and head from the threat")
	_check(_flat(point, enemy.global_position) <= enemy.max_cover_path, "Cover is close by")
	# A hit from the player sends the enemy to cover instead of standing in the open.
	var shots := {"n": 0}
	enemy.fired.connect(func(_e, _a, _h): shots.n += 1)
	enemy.receive_hit(10, enemy.global_position + Vector3.UP, Vector3.FORWARD, player, &"arms")
	_check(enemy.cover_phase == &"move" and enemy.last_known.distance_to(player.global_position) < 0.1, "Being hit sends the enemy to cover from the shooter")
	var arrived := false
	for i in range(60 * 6):
		await _frames(1)
		if enemy.cover_phase == &"hold":
			arrived = true
			break
	_check(arrived and _flat(enemy.global_position, enemy.cover_point) < 0.8, "Enemy reaches its cover point")
	_check(shots.n == 0, "Enemy does not fire while running to cover")
	_check(enemy.hidden_from(space, eye, enemy.global_position), "Enemy is out of the shooter's sight in cover")
	for i in range(60 * 4):
		await _frames(1)
		if enemy.cover_phase == &"":
			break
	_check(enemy.cover_phase == &"" and enemy.search_phase == &"travel", "After holding, the enemy leaves cover toward the threat")
	# Reloading while engaged also seeks cover.
	enemy.global_position = Vector3(18, 0, 3)
	enemy.cover_phase = &""
	enemy.begin_search(enemy.global_position)
	enemy.search_left = 0.0
	enemy.rounds_in_magazine = 0
	enemy.aim_spread_degrees = 0.0
	await _frames(2)
	for i in range(60 * 3):
		await _frames(1)
		player.restore_for_drill()
		if enemy.is_reloading():
			break
	_check(enemy.is_reloading() and enemy.cover_phase == &"move", "Empty rifle while engaged: reload from cover")
	# No navigation map (camp annex style): cover is unavailable and behaviour is unchanged.
	var bare := Node3D.new()
	var world := SubViewport.new()
	world.own_world_3d = true
	root.add_child(world)
	world.add_child(bare)
	var loner = load("res://scripts/combat/enemy_actor.gd").new()
	bare.add_child(loner)
	await _frames(2)
	_check(loner.find_cover(Vector3(0, 0, 10)) == Vector3.INF and not loner.try_take_cover(Vector3(0, 0, 10)), "Without a navigation map no cover is taken")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: hidden reachable cover, hit sends to cover, no fire while moving, sheltered, leaves toward threat, reload from cover, no-nav fallback")
	world.queue_free()
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
