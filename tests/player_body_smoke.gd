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
	var events: Array[StringName] = []
	player.casualty.connect(func(_p, outcome): events.append(outcome))
	await _frames(10)
	_check(player.hit_zones.zones().size() == 5, "Player carries the standing hit zones")
	# Solo: torso at zero is mission death, never a downed state.
	player.receive_hit(80, player.global_position, Vector3.FORWARD, null, &"torso")
	_check(player.body.is_dead() and events == [&"killed"], "Solo torso incapacitation resolves as death")
	_check(not player.controls_active(), "Dead player cannot act")
	player.restore_for_drill()
	events.clear()
	player.receive_hit(40, player.global_position, Vector3.FORWARD, null, &"head")
	_check(player.body.is_dead() and events == [&"killed"], "Head at zero kills even with no other damage")
	# Simulated co-op: torso at zero downs; downed is helpless; any hit kills once.
	player.restore_for_drill()
	player.has_teammate_nearby = true
	events.clear()
	player.receive_hit(80, player.global_position, Vector3.FORWARD, null, &"torso")
	_check(player.body.is_downed() and events == [&"downed"], "With a teammate nearby, torso at zero downs")
	_check(not player.controls_active() and player.hit_zones.layout == &"downed", "Downed player cannot act and lies flat for shots")
	await _frames(90)
	_check(player.body_shape.shape.height < 0.7 and player.camera.position.y < 0.6, "Downed player's body and camera drop to the ground")
	player.receive_hit(1, player.global_position, Vector3.FORWARD, null, &"legs")
	player.receive_hit(1, player.global_position, Vector3.FORWARD, null, &"legs")
	_check(player.body.is_dead() and events == [&"downed", &"killed"], "Any further hit kills a downed player once")
	# Bleed-out.
	player.restore_for_drill()
	player.bleed_out_seconds = 0.5
	events.clear()
	player.receive_hit(80, player.global_position, Vector3.FORWARD, null, &"torso")
	await _frames(45)
	_check(player.body.is_dead() and events == [&"downed", &"killed"], "Bleed-out kills a downed player")
	# A real enemy ray resolves a player zone.
	player.restore_for_drill()
	player.has_teammate_nearby = false
	events.clear()
	await _frames(90)
	_check(player.hit_zones.height > 1.5, "Player zones grow back with standing height")
	var enemy = Enemy.new()
	enemy.position = Vector3(0, 0, -8)
	world.add_child(enemy)
	await _frames(3)
	enemy.aim_spread_degrees = 0.0
	enemy._shoot(player)
	_check(player.last_hit_zone == &"torso" and player.body.health[&"torso"] < 80, "Enemy shot at centre mass hits the player's torso zone")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: player zones, solo down = death, head kill, simulated co-op down, helpless/flat, finish once, bleed-out, enemy ray zone")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
