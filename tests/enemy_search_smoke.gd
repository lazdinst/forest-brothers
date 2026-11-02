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
	var searcher = arena.enemies[0]
	arena.enemies[1].active = false
	# Hide the player far from everything so only the noise matters.
	player.global_position = Vector3(30, 0.02, 30)
	await _frames(5)
	var home: Vector3 = searcher.global_position
	searcher.hear_noise(Vector3(-6, 0, 8))
	var goal: Vector3 = searcher.last_known
	_check(searcher.state == &"search" and searcher.search_phase == &"travel", "Noise starts a search walk")
	var reached := false
	var looked := false
	var yaw_min := INF
	var yaw_max := -INF
	var frames_used := 0
	for i in range(60 * 60):
		await _frames(1)
		frames_used = i
		if _flat(searcher.global_position, goal) < 1.6:
			reached = true
		if searcher.search_phase == &"look":
			looked = true
			yaw_min = minf(yaw_min, searcher.rotation.y)
			yaw_max = maxf(yaw_max, searcher.rotation.y)
		if looked and searcher.state == &"patrol":
			break
	_check(reached, "Searcher walks around the wall to the noise")
	_check(looked and yaw_max - yaw_min > 1.5, "Searcher looks around at the spot (sweep %.2f rad)" % (yaw_max - yaw_min))
	_check(searcher.state == &"patrol" and searcher.last_known == goal, "Hidden player is lost; search ends without tracking them")
	_check(frames_used < 60 * 45, "Search is bounded in time (%d s)" % (frames_used / 60))
	for i in range(60 * 40):
		await _frames(1)
		if not searcher._returning:
			break
	_check(_flat(searcher.global_position, home) < 1.0, "Searcher walks back to its post")
	# Losing sight of a seen player starts a search from where they were last seen.
	var watcher = arena.enemies[1]
	watcher.active = true
	watcher.aim_spread_degrees = 0.0
	searcher.active = false
	player.restore_for_drill()
	player.global_position = watcher.global_position + Vector3(0, 0.02, 8)
	await _frames(40)
	_check(watcher.recognition > 0.0, "Watcher notices the exposed player")
	var seen_at: Vector3 = watcher.last_known
	player.global_position = Vector3(30, 0.02, 30)
	await _frames(3)
	_check(watcher.state == &"search" and watcher.search_phase == &"travel" and watcher.last_known == seen_at, "Losing sight searches from the last seen position")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: noise search around cover, look-around sweep, hidden player lost, bounded search, return to post, search from last seen")
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
