extends SceneTree
## Peeking: after holding cover an enemy sidesteps to a spot that sees the threat, fires after a
## short reaction, steps back into hidden cover, and after its peeks are spent leaves toward the threat.
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
## Advances until the enemy's cover phase matches, keeping the drill player standing.
func _until(enemy, player, phase: StringName, seconds: float) -> bool:
	for i in range(int(60 * seconds)):
		await _frames(1)
		if player.body.is_dead() or player.body.is_downed():
			player.restore_for_drill()
		if enemy.cover_phase == phase:
			return true
	return false
func _run() -> void:
	var arena = load("res://scenes/combat/combat_arena.tscn").instantiate()
	root.add_child(arena)
	await _frames(10)
	var player = arena.player
	var enemy = arena.enemies[0]
	arena.enemies[1].active = false
	# Same open ground as the cover check: east of the screening wall, player due south.
	enemy.global_position = Vector3(18, 0, 3)
	player.global_position = Vector3(18, 0.02, 20)
	await _frames(5)
	var space: PhysicsDirectSpaceState3D = enemy.get_world_3d().direct_space_state
	var eye: Vector3 = player.global_position + Vector3.UP * 1.5
	var shots := {"n": 0}
	enemy.fired.connect(func(_e, _a, _h): shots.n += 1)
	enemy.receive_hit(10, enemy.global_position + Vector3.UP, Vector3.FORWARD, player, &"arms")
	_check(await _until(enemy, player, &"hold", 6.0), "Hit enemy reaches cover")
	var cover: Vector3 = enemy.cover_point
	shots.n = 0
	_check(await _until(enemy, player, &"peek_out", 4.0), "After holding, the enemy steps out to peek")
	var peek: Vector3 = enemy.peek_point
	_check(peek != Vector3.INF and _flat(peek, cover) <= 2.1, "The peek point is a short sidestep from cover (%.2f m)" % _flat(peek, cover))
	var aim: Vector3 = player.global_position + Vector3.UP
	_check(space.intersect_ray(PhysicsRayQueryParameters3D.create(peek + Vector3.UP * 1.55, aim, 1, [enemy.get_rid()])).is_empty(), "The peek point sees the threat past the cover")
	_check(await _until(enemy, player, &"peek", 3.0), "The enemy reaches the peek")
	_check(enemy.can_see(player), "Peeking, the enemy sees the player")
	var frames_to_shot := 0
	# Stop waiting once the peek is over, so a late (or no) shot cannot hide the step back.
	while shots.n == 0 and frames_to_shot < 60 * 3 and enemy.cover_phase == &"peek":
		await _frames(1)
		frames_to_shot += 1
	_check(shots.n > 0, "The enemy fires while peeking")
	_check(frames_to_shot >= int(60 * enemy.peek_reaction) - 2, "It reacts before the first peek shot (%d frames)" % frames_to_shot)
	_check(enemy.cover_phase in [&"peek_back", &"hold"] or await _until(enemy, player, &"peek_back", 4.0), "The enemy steps back after the peek")
	_check(enemy.cover_phase == &"hold" or await _until(enemy, player, &"hold", 4.0), "The enemy is back in cover")
	_check(_flat(enemy.global_position, cover) < 0.8 and enemy.hidden_from(space, eye, enemy.global_position), "Back in cover, the enemy is hidden again")
	# A second peek, then the enemy gives up the position and moves on the threat.
	_check(await _until(enemy, player, &"peek", 6.0), "The enemy peeks a second time")
	# Leaving: it moves on the threat, or engages at once if it already sees the player.
	_check(await _until(enemy, player, &"", 12.0) and (enemy.search_phase == &"travel" or enemy.state == &"engage"), "With its peeks spent, the enemy leaves cover toward the threat")
	# Out of ammunition during a peek: reload, step back into cover. Fresh start from the open.
	enemy.cover_phase = &""
	enemy.begin_search(Vector3(18, 0, 3))
	enemy.search_left = 0.0
	enemy.global_position = Vector3(18, 0, 3)
	await _frames(3)
	enemy.receive_hit(1, enemy.global_position + Vector3.UP, Vector3.FORWARD, player, &"arms")
	_check(await _until(enemy, player, &"peek", 12.0), "A fresh hit leads to another peek")
	enemy.rounds_in_magazine = 0
	await _frames(2)
	_check(enemy.is_reloading() and enemy.cover_phase == &"peek_back", "An empty rifle while peeking: step back and reload")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: peek out from cover to a sidestep that sees the threat, react then fire, step back hidden, second peek, give up toward threat, reload from a peek")
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
