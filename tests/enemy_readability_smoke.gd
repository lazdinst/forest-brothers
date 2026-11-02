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
	var camera: Vector3 = player.camera.global_position
	# Facing: +z is the enemy's true forward, toward the player here.
	_check(enemy.facing_toward(camera) > 0.95, "Enemy facing the player reads as facing")
	await _frames(2)
	var lit_front: float = enemy.sprite.modulate.r
	enemy.rotation.y = PI
	await _frames(2)
	_check(enemy.facing_toward(camera) < -0.95, "Turned enemy reads as facing away")
	_check(enemy.sprite.modulate.r < lit_front - 0.3, "Sprite dims when the body faces away (%.2f vs %.2f)" % [enemy.sprite.modulate.r, lit_front])
	_check(enemy.muzzle_world_position().z < enemy.global_position.z, "Rifle points along the true facing, not at the camera")
	enemy.rotation.y = 0
	await _frames(2)
	_check(enemy.muzzle_world_position().z > enemy.global_position.z + 0.4, "Muzzle sits in front of a forward-facing enemy")
	# Tell: lowered while calm, raised once it engages.
	_check(enemy.rifle.rotation.x > 0.5, "Calm enemy holds the rifle lowered")
	enemy.targets.assign([player])
	enemy.active = true
	await _frames(70)
	_check(enemy.state == &"engage" and absf(enemy.rifle.rotation.x) < 0.2, "Engaging enemy raises the rifle toward the target")
	var muzzle: Vector3 = enemy.muzzle_world_position()
	enemy._shoot(player)
	_check(enemy.standing_views.pose == &"firing", "Actual shot selects the illuminated firing sprite")
	_check(enemy.muzzle_world_position().distance_to(muzzle) < 0.05, "Firing flash stays aligned with the aimed muzzle")
	enemy.active = false
	enemy.receive_hit(100, enemy.global_position + Vector3.UP, Vector3.FORWARD, player, &"torso")
	_check(not enemy.rifle.visible, "Downed enemy drops the rifle proxy")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: true facing, dimmed back view, rifle follows facing, lowered/raised tell, muzzle flash at barrel, rifle hidden when downed")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
