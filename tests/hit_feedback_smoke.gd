extends SceneTree
const PlayerScene = preload("res://scenes/player/first_person_player.tscn")
const Enemy = preload("res://scripts/combat/enemy_actor.gd")
const HitSounds = preload("res://scripts/combat/hit_sounds.gd")
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
	var feedback = player.get_node("HitFeedback")
	var origin: Vector3 = player.global_position
	_check(absf(feedback.bearing_to(origin + Vector3(0, 0, -5))) < 0.01, "Source ahead points up")
	_check(absf(feedback.bearing_to(origin + Vector3(5, 0, 0)) - PI / 2) < 0.01, "Source on the right points right")
	_check(absf(feedback.bearing_to(origin + Vector3(-5, 0, 0)) + PI / 2) < 0.01, "Source on the left points left")
	_check(absf(absf(feedback.bearing_to(origin + Vector3(0, 0, 5))) - PI) < 0.01, "Source behind points down")
	player.rotation.y = PI / 2
	await _frames(1)
	_check(absf(feedback.bearing_to(player.global_position + Vector3(0, 0, -5)) - PI / 2) < 0.01, "Bearing follows the player's turn")
	player.rotation.y = 0
	var shooter := Node3D.new()
	world.add_child(shooter)
	shooter.global_position = origin + Vector3(6, 1, 0)
	player.receive_hit(10, origin, Vector3.FORWARD, shooter, &"arms")
	_check(feedback.indicators.size() == 1 and feedback.indicators[0].zone == &"arms", "A hit adds one indicator with its zone")
	_check(absf(feedback.indicators[0].bearing - PI / 2) < 0.05, "Indicator points toward the shooter")
	await _frames(100)
	_check(feedback.indicators.is_empty(), "Indicator fades after its display time")
	var enemy = Enemy.new()
	enemy.position = origin + Vector3(0, 0, 8)
	world.add_child(enemy)
	await _frames(3)
	enemy._shoot(player)
	_check(feedback.indicators.size() == 1 and absf(absf(feedback.indicators[0].bearing) - PI) < 0.1, "Real enemy shot from behind shows a rear indicator")
	var lengths := {}
	for zone in [&"head", &"torso", &"arms", &"legs"]:
		var wav: AudioStreamWAV = HitSounds.stream(zone)
		_check(wav.data.size() > 0, "Zone sound exists: %s" % zone)
		lengths[wav.data.size()] = true
	_check(lengths.size() == 4, "Each zone has a distinct sound")
	_check(HitSounds.stream(&"head") == HitSounds.stream(&"head"), "Zone sounds are generated once and reused")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: indicator bearings, turn tracking, zone tag, fade, enemy-shot direction, distinct cached zone sounds")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
