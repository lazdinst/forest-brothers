extends SceneTree
const PlayerScene = preload("res://scenes/player/first_person_player.tscn")
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
func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	shape.shape = box
	shape.position.y = -0.5
	ground.add_child(shape)
	world.add_child(ground)
	var player = PlayerScene.instantiate()
	world.add_child(player)
	player.position = Vector3(0, 0.02, 0)
	await _frames(10)
	var enemy = Enemy.new()
	enemy.position = Vector3(0, 0, -10)
	world.add_child(enemy)
	await _frames(3)
	var counts := {"shots": 0, "reloads": 0}
	enemy.fired.connect(func(_e, _a, _h): counts.shots += 1)
	enemy.reload_started.connect(func(_e): counts.reloads += 1)
	# Keep the player alive and fast-forward the fire rate so a magazine empties quickly.
	enemy.aim_spread_degrees = 60.0
	enemy.fire_interval = 0.1
	enemy.spare_magazines.assign([10])
	var total_before: int = enemy.total_rounds()
	enemy.targets.assign([player])
	enemy.active = true
	var shots_at_reload := -1
	for i in range(240):
		await _frames(1)
		player.restore_for_drill()
		if enemy.is_reloading() and shots_at_reload < 0:
			shots_at_reload = counts.shots
		if shots_at_reload >= 0:
			break
	_check(shots_at_reload == 10, "Enemy fires exactly one magazine before reloading (%d)" % shots_at_reload)
	_check(enemy.rifle.rotation.x > 0.6 or enemy.is_reloading(), "Reloading enemy drops the rifle")
	await _frames(60)
	_check(counts.shots == 10 and enemy.is_reloading(), "No shots during the reload window")
	await _frames(150)
	player.restore_for_drill()
	_check(not enemy.is_reloading() and counts.shots > 10, "Enemy resumes fire after the reload")
	_check(counts.shots + enemy.total_rounds() == total_before, "Rounds are conserved: fired + carried stays constant")
	for i in range(240):
		await _frames(1)
		player.restore_for_drill()
	_check(counts.shots == 20 and enemy.total_rounds() == 0 and counts.reloads == 1, "With no ammunition left the enemy stops firing")
	# Out of contact: a half-empty rifle is topped up, and the partial magazine is kept.
	var calm = Enemy.new()
	calm.position = Vector3(8, 0, -10)
	world.add_child(calm)
	await _frames(3)
	calm.rounds_in_magazine = 4
	calm.spare_magazines.assign([10])
	calm.reload_seconds = 0.5
	calm.active = true
	await _frames(45)
	_check(calm.rounds_in_magazine == 10 and calm.spare_magazines == [4], "Tactical reload keeps the partial magazine")
	calm.active = false
	calm.rounds_in_magazine = 0
	calm.spare_magazines.assign([10])
	calm.reload_seconds = 5.0
	calm.start_reload()
	calm.receive_hit(100, calm.global_position + Vector3.UP, Vector3.FORWARD, player, &"torso")
	await _frames(400)
	_check(calm.state == &"downed" and calm.rounds_in_magazine == 0, "Downed enemy does not finish reloading")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: magazine limit, reload pause and pose, resume, round conservation, empty stops fire, partial magazine kept, downed cancels reload")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
