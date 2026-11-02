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
func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z)
func _run() -> void:
	var arena = load("res://scenes/combat/combat_arena.tscn").instantiate()
	root.add_child(arena)
	await _frames(10)
	var player = arena.player
	var engager = arena.enemies[0]
	var flanker = arena.enemies[1]
	engager.active = false
	# Player south of the screening wall; the engager faces them head-on from the north side of the open ground.
	player.global_position = Vector3(0, 0.02, 20)
	engager.global_position = Vector3(0, 0, 10)
	flanker.global_position = Vector3(20, 0, 8)
	await _frames(5)
	var target: Vector3 = player.global_position
	var space: PhysicsDirectSpaceState3D = flanker.get_world_3d().direct_space_state
	var point: Vector3 = flanker.find_flank_point(target, engager.global_position)
	_check(point != Vector3.INF, "Flanker finds a side position")
	var ally_line: Vector3 = _flat(engager.global_position - target).normalized()
	var side: Vector3 = _flat(point - target).normalized()
	_check(absf(side.dot(ally_line)) <= 0.5, "Flank position is off to the side of the ally's line (dot %.2f)" % side.dot(ally_line))
	var view := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.55, target + Vector3.UP, 1, [flanker.get_rid()])
	_check(space.intersect_ray(view).is_empty(), "Flank position has a clear view of the target")
	# The alert from an engaging ally sends this enemy to the flank instead of straight at the report.
	flanker.targets.clear()
	flanker.receive_alert(target, engager)
	_check(flanker.state == &"search" and flanker.flank_point != Vector3.INF, "Alert from an ally starts a flank")
	var arrived := false
	for i in range(60 * 25):
		await _frames(1)
		if flanker.search_phase == &"look":
			arrived = true
			break
	_check(arrived and _flat(flanker.global_position - point).length() < 1.0, "Flanker reaches the side position")
	var facing: Vector3 = _flat(target - flanker.global_position).normalized()
	_check(flanker.facing_toward(target) > 0.9, "Flanker turns to face the target on arrival")
	var approach: Vector3 = _flat(flanker.global_position - target).normalized()
	_check(approach.dot(ally_line) < 0.71, "Flanker covers a different angle than the engaging ally")
	flanker.targets.assign([player])
	await _frames(60)
	_check(flanker.state == &"engage" or flanker.recognition > 0.0, "Flanker picks up the exposed target from the side")
	# Without a reporting ally (plain noise alerts, camp annex) the old straight search is unchanged.
	flanker.global_position = Vector3(20, 0, 8)
	flanker.state = &"patrol"
	flanker.targets.clear()
	await _frames(2)
	flanker.receive_alert(target)
	_check(flanker.flank_point == Vector3.INF and flanker.search_phase == &"travel", "Alert without a reporter walks straight to the report")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: side flank point with view, alert starts flank, reaches flank, faces target, distinct angle, engages from side, plain alert unchanged")
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
