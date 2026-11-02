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
func _run() -> void:
	var arena = load("res://scenes/combat/combat_arena.tscn").instantiate()
	root.add_child(arena)
	await _frames(10)
	_check(arena.navigation.navigation_mesh.get_polygon_count() > 0, "Arena bakes a navigation map")
	_check(arena.player != null and arena.enemies.size() == 2, "Arena spawns a player and two enemies")
	_check(arena.enemies.all(func(e): return e.active), "Arena enemies are active by default")
	# Pathing: send one enemy to a point straight behind the screening wall.
	var walker = arena.enemies[0]
	arena.enemies[1].active = false
	walker.targets.clear()
	var goal := Vector3(-6, 0, 12)
	var first_leg: Vector3 = walker.route_toward(goal, 0.0)
	var straight: Vector3 = goal - walker.global_position
	straight.y = 0
	_check(first_leg.length() > 0.1 and first_leg.normalized().dot(straight.normalized()) < 0.95, "Route bends away from the straight line through the wall")
	walker.last_known = goal
	walker.search_left = 60.0
	walker.search_speed = 3.0
	walker.state = &"search"
	var crossed_wall := false
	var previous_z: float = walker.global_position.z
	for i in range(1200):
		await _frames(1)
		var position: Vector3 = walker.global_position
		if previous_z < 4.0 and position.z >= 4.0 and absf(position.x) < 15.0:
			crossed_wall = true
		previous_z = position.z
		if Vector2(position.x - goal.x, position.z - goal.z).length() < 1.5:
			break
	var final: Vector3 = walker.global_position
	_check(Vector2(final.x - goal.x, final.z - goal.z).length() < 1.5, "Searching enemy reaches a point behind the wall (ended at %s)" % final)
	_check(not crossed_wall, "Enemy walks around the wall, not through it")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: arena navigation bake, spawns, active enemies, bent route, reaches goal around the wall")
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
