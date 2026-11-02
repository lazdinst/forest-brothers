extends SceneTree
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
func _spawn(world: Node3D, at: Vector3) -> Node:
	var enemy = Enemy.new()
	enemy.position = at
	world.add_child(enemy)
	return enemy
func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var plane := BoxShape3D.new()
	plane.size = Vector3(40, 0.2, 40)
	floor_shape.shape = plane
	floor_shape.position.y = -0.1
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)
	var counts := {"defeats": 0, "calls": 0, "shots": 0}
	# Headshot: immediate death, once.
	var a = _spawn(world, Vector3(-6, 0, 0))
	a.defeated.connect(func(_e): counts.defeats += 1)
	await _frames(3)
	a.receive_hit(40, a.global_position + Vector3.UP * 1.6, Vector3.FORWARD, null, &"head")
	a.receive_hit(40, a.global_position + Vector3.UP * 1.6, Vector3.FORWARD, null, &"head")
	_check(a.state == &"dead" and counts.defeats == 1, "Headshot kills once")
	# Torso: downed, calls out, crawls away from the threat and never fires.
	var b = _spawn(world, Vector3(0, 0, 0))
	b.defeated.connect(func(_e): counts.defeats += 1)
	b.spotted.connect(func(_e, _at): counts.calls += 1)
	b.fired.connect(func(_e, _t, _h): counts.shots += 1)
	await _frames(3)
	b.active = true
	var shooter := Node3D.new()
	world.add_child(shooter)
	shooter.position = Vector3(0, 0, 6)
	b.receive_hit(40, b.global_position + Vector3.UP, Vector3.FORWARD, null, &"torso")
	_check(b.state != &"downed", "One torso hit does not down")
	b.receive_hit(40, b.global_position + Vector3.UP, Vector3.FORWARD, shooter, &"torso")
	_check(b.state == &"downed" and b.body.is_downed() and counts.defeats == 1, "Torso at zero downs without defeat")
	_check(counts.calls == 1, "Downed enemy calls out once through local alert")
	_check(b.hit_zones.layout == &"downed" and b.get_node("Body").shape is BoxShape3D, "Downed enemy lies flat for shots and movement")
	var start: Vector3 = b.global_position
	await _frames(60)
	_check(b.global_position.z < start.z - 0.1, "Downed enemy crawls away from the last known threat")
	b.hear_noise(Vector3(0, 0, 6))
	_check(b.state == &"downed" and counts.shots == 0, "Downed enemy ignores noise and does not fire")
	b.receive_hit(1, b.global_position, Vector3.FORWARD, null, &"legs")
	_check(b.state == &"dead" and counts.defeats == 2, "Any further hit finishes a downed enemy")
	b.receive_hit(1, b.global_position, Vector3.FORWARD, null, &"legs")
	_check(counts.defeats == 2, "Finished enemy is defeated only once")
	# Bleed-out.
	var c = _spawn(world, Vector3(6, 0, 0))
	c.bleed_out_seconds = 0.5
	c.defeated.connect(func(_e): counts.defeats += 1)
	await _frames(3)
	c.receive_hit(100, c.global_position + Vector3.UP, Vector3.FORWARD, null, &"torso")
	await _frames(20)
	_check(c.state == &"downed", "Bleed-out waits for its timer")
	await _frames(25)
	_check(c.state == &"dead" and counts.defeats == 3, "Bleed-out kills a downed enemy")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: headshot kill, torso down, call-out, flat downed body, crawl, no fire, finish once, bleed-out")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
