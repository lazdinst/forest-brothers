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
# Fires many shots from a fixed distance and counts how many reach the player.
func _hit_rate(enemy, player, shots: int) -> float:
	var hits := {"n": 0}
	var counter := func(_e, _a, hit): if hit: hits.n += 1
	enemy.fired.connect(counter)
	for i in range(shots):
		player.restore_for_drill()
		enemy._shoot(player)
	enemy.fired.disconnect(counter)
	return float(hits.n) / shots
func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	shape.shape = box
	shape.position.y = -0.5
	ground.add_child(shape)
	world.add_child(ground)
	var player = PlayerScene.instantiate()
	world.add_child(player)
	player.position = Vector3(0, 0.02, 0)
	await _frames(10)
	var enemy = Enemy.new()
	enemy.position = Vector3(0, 0, -20)
	world.add_child(enemy)
	await _frames(3)
	enemy.rng.seed = 2024
	# Spread rules.
	enemy.aim_time = 0.0
	var fresh: float = enemy.shot_spread_degrees(player)
	enemy.aim_time = 10.0
	var settled: float = enemy.shot_spread_degrees(player)
	_check(settled < fresh, "Spread tightens the longer an enemy aims")
	player.velocity = Vector3(5, 0, 0)
	_check(enemy.shot_spread_degrees(player) > settled, "A moving target widens spread")
	player.velocity = Vector3.ZERO
	# Hit rates: fresh aim is worse than settled aim, and distance makes it worse again.
	enemy.aim_time = 0.0
	var near_fresh := _hit_rate(enemy, player, 120)
	enemy.aim_time = 10.0
	var near_settled := _hit_rate(enemy, player, 120)
	enemy.global_position = Vector3(0, 0, -60)
	await _frames(2)
	var far_settled := _hit_rate(enemy, player, 120)
	_check(near_settled > near_fresh, "Settled aim hits more than first exposure (%.2f vs %.2f)" % [near_settled, near_fresh])
	_check(far_settled < near_settled, "Distant shots hit less (%.2f vs %.2f)" % [far_settled, near_settled])
	_check(near_fresh < 1.0 and far_settled > 0.0, "Enemies can miss, and can still hit at range")
	# Near misses are reported for presentation, never as damage.
	var feedback = player.get_node("HitFeedback")
	var before: int = feedback.near_misses
	enemy.aim_time = 0.0
	enemy.aim_spread_degrees = 8.0
	_hit_rate(enemy, player, 40)
	_check(feedback.near_misses > before, "Close misses produce a near-miss crack")
	print("hit rates: near fresh %.2f, near settled %.2f, far settled %.2f" % [near_fresh, near_settled, far_settled])
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: settling spread, moving-target spread, fresh/settled/distance hit rates, misses possible, near-miss cracks")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
