extends SceneTree
## Blood trails and temperaments: a bleeding player drips (heavier = denser, standing = pool), an
## enemy follows the player's blood around a wall to find them, a hurt timid enemy runs off and
## hides leaving a trail to follow, a hurt aggressive enemy pushes instead of taking cover.
const BloodTrail = preload("res://scripts/combat/blood_trail.gd")
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
func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
func _keep_alive(player) -> void:
	if not player.body.is_alive():
		player.restore_for_drill()
func _walk(player, from: Vector3, to: Vector3, steps: int) -> void:
	for i in range(steps + 1):
		player.global_position = from.lerp(to, float(i) / steps)
		await _frames(2)

func _run() -> void:
	var arena = load("res://scenes/combat/combat_arena.tscn").instantiate()
	arena.temperament_pool.assign([Enemy.STEADY])
	root.add_child(arena)
	await _frames(10)
	var player = arena.player
	for enemy in arena.enemies:
		enemy.active = false
	var trail = BloodTrail.find_or_create(player)
	# --- A bleeding player leaves drops; heavier bleeding is denser; standing still pools. ---
	await _walk(player, Vector3(-20, 0.02, 20), Vector3(-10, 0.02, 20), 40)
	_check(trail.drops_from(player).is_empty(), "A player who is not bleeding leaves no blood")
	player.body.light_bleeding[&"left_leg"] = true
	await _walk(player, Vector3(-20, 0.02, 22), Vector3(-10, 0.02, 22), 40)
	var light: int = trail.drops_from(player).size()
	player.body.heavy_bleeding[&"left_leg"] = true
	await _walk(player, Vector3(-20, 0.02, 24), Vector3(-10, 0.02, 24), 40)
	var heavy: int = trail.drops_from(player).size() - light
	_check(light >= 4 and heavy > light, "Bleeding leaves drops, denser when heavy (%d light, %d heavy over 10 m)" % [light, heavy])
	var before: int = trail.drops_from(player).size()
	await _frames(60 * 5)
	_check(trail.drops_from(player).size() > before, "Standing still while bleeding leaves a pool")
	var drop: Dictionary = trail.drops_from(player)[0]
	_check(absf(drop.position.y) < 0.05, "Drops lie on the ground")
	player.body.heavy_bleeding[&"left_leg"] = false
	player.body.light_bleeding[&"left_leg"] = false
	arena.reset_enemies()
	await _frames(10)
	_check(trail.drops.is_empty() and trail.get_child_count() == 0, "Arena reset clears the trail")
	for enemy in arena.enemies:
		enemy.active = false
	# --- An enemy follows the player's blood around the screening wall. ---
	var tracker = arena.enemies[0]
	tracker.global_position = Vector3(0, 0, 10)
	tracker.rotation.y = 0.0
	player.global_position = Vector3(0, 0.02, -2)
	tracker.active = true
	await _frames(60 * 3)
	_check(not tracker.can_see(player) and tracker.state == &"patrol", "Without blood the tracker stays on its post")
	var path := [Vector3(-3, 0, 10), Vector3(-6, 0, 10), Vector3(-9, 0, 10), Vector3(-12, 0, 9), Vector3(-15, 0, 8), Vector3(-17, 0, 6), Vector3(-17.5, 0, 4), Vector3(-17, 0, 2), Vector3(-15, 0, 0), Vector3(-12, 0, -1), Vector3(-9, 0, -2), Vector3(-6, 0, -2)]
	for point in path:
		trail.now += 1.0
		trail.add_drop(point, 1.0, player)
	var went_round := false
	var found := false
	for i in range(60 * 45):
		await _frames(1)
		_keep_alive(player)
		if tracker.global_position.x < -13.0: went_round = true
		if tracker.state == &"engage" or tracker.recognition > 0.5:
			found = true
			break
	_check(went_round and found, "The tracker follows the blood round the wall and finds the player (round %s, found %s, at %s)" % [went_round, found, tracker.global_position])
	tracker.active = false
	# --- Timid and hurt: run off, hide, and leave a trail to follow. ---
	var timid = arena.enemies[1]
	timid.temperament = Enemy.TIMID
	timid.global_position = Vector3(-8, 0, 16)
	player.global_position = Vector3(-8, 0.02, 26)
	timid.active = true
	await _frames(5)
	var shots := {"n": 0}
	timid.fired.connect(func(_e, _a, _h): shots.n += 1)
	var start: Vector3 = timid.global_position
	timid.receive_hit(35, timid.global_position + Vector3.UP, Vector3.FORWARD, player, &"arms")
	_check(timid.flee_phase == &"run" and _flat(timid.flee_point, player.global_position) >= _flat(start, player.global_position) + 8.0, "A hurt timid enemy runs for a spot well away from the threat")
	for i in range(60 * 20):
		await _frames(1)
		_keep_alive(player)
		if timid.flee_phase == &"hide": break
	_check(timid.flee_phase == &"hide" and shots.n == 0, "It reaches a hiding spot without firing on the way")
	_check(_flat(timid.global_position, player.global_position) > _flat(start, player.global_position) + 6.0, "It ends up far from the threat")
	var drops: Array = trail.drops_from(timid)
	_check(drops.size() >= 5 and _flat(drops[drops.size() - 1].position, timid.global_position) < 3.0, "Its wound leaves a trail that leads to where it hides (%d drops)" % drops.size())
	timid.receive_alert(player.global_position, null)
	_check(timid.flee_phase == &"hide" and timid.search_left <= 0.0, "A hiding enemy ignores alerts")
	# Blood loss: the untreated wound keeps draining the torso until the enemy collapses.
	var torso: float = timid.body.health[&"torso"]
	await _frames(60 * 10)
	_check(timid.body.health[&"torso"] < torso - 3.0, "A wound drains the hidden enemy's health (%.1f -> %.1f)" % [torso, timid.body.health[&"torso"]])
	timid.body.health[&"torso"] = 2.0
	await _frames(60 * 6)
	_check(timid.state == &"downed", "Blood loss eventually downs it where it hid")
	timid.active = false
	# --- Aggressive and hurt: no cover; it closes on the threat while firing. ---
	var brave = arena.enemies[0]
	brave.temperament = Enemy.AGGRESSIVE
	brave.global_position = Vector3(18, 0, 6)
	player.global_position = Vector3(18, 0.02, 24)
	brave.rotation.y = 0.0
	brave.active = true
	brave.recognition = 1.0
	await _frames(10)
	brave.fired.connect(func(_e, _a, _h): shots.n += 1)
	shots.n = 0
	var gap: float = _flat(brave.global_position, player.global_position)
	brave.receive_hit(35, brave.global_position + Vector3.UP, Vector3.FORWARD, player, &"arms")
	_check(brave.pushing and brave.cover_phase == &"", "A hurt aggressive enemy pushes instead of taking cover")
	for i in range(60 * 4):
		await _frames(1)
		_keep_alive(player)
	_check(_flat(brave.global_position, player.global_position) < gap - 3.0 and shots.n > 0, "It closes the distance while firing (gap %.1f -> %.1f, %d shots)" % [gap, _flat(brave.global_position, player.global_position), shots.n])
	# --- Steady and hurt: cover as before. ---
	arena.reset_enemies()
	await _frames(5)
	arena.enemies[0].active = false
	var steady = arena.enemies[1]
	steady.temperament = Enemy.STEADY
	steady.global_position = Vector3(18, 0, 3)
	steady.active = true
	await _frames(3)
	steady.receive_hit(35, steady.global_position + Vector3.UP, Vector3.FORWARD, player, &"arms")
	_check(steady.cover_phase == &"move" and not steady.pushing, "A hurt steady enemy still takes cover")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: player blood drops (light/heavy/pool), enemy tracks blood round a wall, timid flees and hides leaving a trail, aggressive pushes while firing, steady takes cover")
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
