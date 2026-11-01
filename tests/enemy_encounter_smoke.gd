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
func _run() -> void:
	var world = load("res://scenes/prototype/camp_test.tscn").instantiate()
	root.add_child(world)
	await _frames(12)
	var annex = world.get_node("SystemsAnnex")
	var player = world.get_node("Player")
	var target = annex.enemies[1]
	player.global_position = annex.global_position+Vector3(5,0.02,-9)
	player.velocity = Vector3.ZERO
	await _frames(10)
	player.weapon.rng.seed = 12345
	for i in range(3):
		player.camera.look_at(target.global_position+Vector3.UP)
		await _frames(3)
		player.weapon.command(&"fire")
		await _frames(18)
	_check(target.health==0 and target.state==&"dead","Three actual rifle rays defeat the test enemy")
	await _frames(40)
	_check(target.get_node("Body").disabled and target.collision_layer==0,"Corpse cannot block movement or continue fighting")
	_check(target.visual.position.y < 0.05 and absf(target.visual.rotation.x)>1.5,"Death animation completes on the ground")
	_check(get_nodes_in_group("training_blood").size()>0,"Lethal hit leaves bounded non-graphic blood feedback")
	var observer = annex.enemies[0]
	player.global_position = annex.global_position+Vector3(-4,0.02,-2)
	player.velocity = Vector3.ZERO
	observer.active = true
	var counts := {"shots":0}
	observer.fired.connect(func(_enemy,_actor,_hit): counts.shots += 1)
	await _frames(90)
	_check(not observer.can_see(player) and counts.shots==0,"Solid cover blocks recognition and shots")
	observer.hear_noise(player.global_position)
	var last: Vector3 = observer.last_known
	await _frames(420)
	_check(observer.last_known==last and observer.state==&"patrol","Unseen player is not tracked; sound search decays")
	player.global_position = annex.global_position+Vector3(-4,0.02,-8)
	player.velocity = Vector3.ZERO
	await _frames(3)
	_check(counts.shots==0,"Recognition/reaction prevents instant fire on first exposure")
	await _frames(170)
	_check(counts.shots>0,"Visible exposure eventually permits enemy firing")
	annex.reset_enemies()
	await _frames(3)
	_check(annex.enemies[0].health==100 and get_nodes_in_group("training_blood").is_empty(),"Reset restores opponents and cleans blood effects")
	# One witness sees the player while a nearby observer's own LOS is blocked.
	player.global_position = annex.global_position+Vector3(-4,0.02,-8)
	player.velocity = Vector3.ZERO
	var screen_wall = annex._box(annex,"AlertTestCover",Vector3(0.5,1.3,-11.5),Vector3(1.5,2.6,1.5),Color.GRAY,true)
	await _frames(4)
	var witness = annex.enemies[0]
	var hidden_observer = annex.enemies[1]
	_check(witness.can_see(player) and not hidden_observer.can_see(player),"Alert fixture separates witness visibility from observer visibility")
	witness.active = true
	hidden_observer.active = true
	await _frames(55)
	_check(hidden_observer.recognition==0 and hidden_observer.search_left>0,"Local witness alert starts investigation without granting direct sight")
	screen_wall.queue_free()
	annex.reset_enemies()
	await _frames(3)
	var carried_before: int = player.weapon.state.total_rounds()
	annex.arm_bout()
	await _frames(240)
	_check(annex.vitality < 100,"Armed enemy rays reduce training vitality")
	await _frames(360)
	_check(annex.vitality==0 and not annex._bout_active and player.global_position.z > 10,"Zero training vitality stops enemies and returns only the test player to camp")
	_check(player.weapon.state.total_rounds()==carried_before,"Bout reset does not silently refill or consume carried ammunition")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: rifle damage, death/corpse animation, blood/reset, cover LOS, finite sound search, recognition/reaction delay, local alert, enemy firing/vitality/bout return")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
