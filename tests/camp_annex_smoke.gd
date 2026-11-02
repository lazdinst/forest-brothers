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
	_check(annex.runtime.stock==world.stock,"Annex shares the original communal ledger")
	_check(not annex.stations.has(&"entry") and not annex.stations.has(&"return"),"Travel requires no portal tables")
	# Walk both directions using real player input, without interaction or jumping.
	player.global_position = Vector3(0,0.1,18.3)
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	await _frames(12)
	var rounds_before: int = player.weapon.state.loose_rounds
	Input.action_press("move_right")
	await _frames(750) # Slower strafe plus acceleration.
	Input.action_release("move_right")
	await _frames(5)
	_check(player.global_position.x > 35 and player.is_on_floor(),"Walk from main yard through the open camp entrance: %s" % player.global_position)
	Input.action_press("move_left")
	await _frames(750) # Slower strafe plus acceleration.
	Input.action_release("move_left")
	await _frames(5)
	_check(absf(player.global_position.x) < 1 and player.is_on_floor(),"Walk back to main yard without a transition: %s" % player.global_position)
	_check(player.weapon.state.loose_rounds == rounds_before and not annex._overlay.visible,"Travel preserves ammunition without opening UI")
	for id in [&"depot",&"well",&"cook",&"food",&"armourer",&"ammo",&"medical",&"shelter",&"trench",&"planning",&"hq",&"combat"]:
		var station = annex.stations[id]
		player.global_position = station.global_position+Vector3(0,0.02,1.6)
		player.velocity = Vector3.ZERO
		await _frames(5)
		player.camera.look_at(station.global_position+Vector3.UP*0.7)
		player.try_interact()
		await _frames(2)
		_check(annex._overlay.visible and annex._panel_station==id,"Real interaction ray opens %s" % id)
		annex.close_panel()
	annex.open_station(annex.stations[&"depot"],player)
	await _frames(3)
	var depot_button = annex._actions.get_child(0)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = depot_button.get_global_rect().get_center()
	root.push_input(press,true)
	press.pressed = false
	root.push_input(press,true)
	await _frames(3)
	_check(annex.runtime.cache_claimed and player.weapon.shots==0,"Station button receives click without firing the weapon")
	annex.close_panel()
	annex.open_resident(annex.resident_nodes[&"resident_01"],player)
	_check(annex._overlay.visible and annex._actions.get_child_count()==3,"Civilian exposes role assignment UI")
	annex.close_panel()
	# Use the actual primary cooking button without assigning the civilian.
	var kitchen = annex.stations[&"cook"]
	player.global_position = kitchen.global_position+Vector3(0,0.02,1.6)
	player.velocity = Vector3.ZERO
	await _frames(5)
	var meals_before: int = annex.runtime.stock.count(&"meals")
	annex.open_station(kitchen,player)
	_check(annex._actions.get_child(0).text.begins_with("Do it yourself:"),"Personal work is the primary station action")
	annex._actions.get_child(0).pressed.emit()
	await _frames(250)
	_check(annex.runtime.stock.count(&"meals")==meals_before+1 and annex.runtime.residents[&"resident_01"].role==&"unassigned","Real cooking UI lets an unassisted player produce a meal")
	annex._actions.get_child(0).pressed.emit()
	annex.close_panel()
	_check(not annex.runtime.jobs.has(&"cook"),"Closing the panel cancels personal work")
	annex.open_station(annex.stations[&"planning"],player)
	annex.start_planning()
	await _frames(3)
	_check(root.get_camera_3d()==annex._planner and not player.weapon.visible,"Build table selects overhead camera and hides first-person gun")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = annex._planner.unproject_position(annex.global_position+Vector3(-10,0,4))
	root.push_input(click,true) # Already in viewport coordinates; avoid OS/headless window stretch.
	await _frames(3)
	_check(annex.runtime.plans.size()==1,"Overhead click places a validated rack plan")
	click.pressed = false
	root.push_input(click,true)
	annex.stop_planning()
	_check(root.get_camera_3d()==player.camera and player.weapon.visible,"Leaving planning restores the first-person camera and gun")
	annex.runtime.assign_role(&"resident_01",&"builder")
	var plan_id = annex.runtime.plans.keys()[0]
	annex.runtime.start_job(&"rack",plan_id,"occupied_build")
	player.global_position = annex.global_position+Vector3(-10,0.02,4)
	player.velocity = Vector3.ZERO
	await _frames(375)
	_check(annex.runtime.jobs.has(plan_id) and annex.runtime.plans[plan_id].status==&"building","Construction waits instead of spawning a solid rack around the player")
	annex._teleport(Vector3(0,0.02,17))
	await _frames(25)
	_check(annex.runtime.plans[plan_id].status==&"complete","Construction completes when its footprint clears")
	annex._begin_exercise()
	var rescue = annex.resident_nodes[&"rescued_test_01"]
	player.global_position = rescue.global_position+Vector3(0,0.02,1.5)
	player.velocity = Vector3.ZERO
	await _frames(5)
	player.camera.look_at(rescue.global_position+Vector3.UP)
	player.try_interact()
	await _frames(3)
	_check(annex.runtime.pending_recruits.size()==1 and annex.runtime.residents.size()==1,"Civilian ray interaction creates only a pending recruit")
	await _frames(100)
	_check(not rescue.visible,"Rescued civilian departs visibly before arrival")
	annex.runtime.resolve_exercise(true)
	await _frames(3)
	_check(rescue.visible and not rescue.rescuable and not rescue.departing and annex.runtime.residents.size()==2,"Safe result arrives at camp and becomes an assignable resident")
	annex._begin_exercise()
	var quick_recruit = null
	for resident in annex.resident_nodes.values():
		if resident.rescuable and resident.visible:
			quick_recruit = resident
	quick_recruit.interact(player)
	annex.runtime.resolve_exercise(true)
	await _frames(105)
	_check(quick_recruit.visible and not quick_recruit.departing,"An early safe result cancels departure so the arrived civilian cannot disappear later")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: original-yard integration, all 12 station ray interactions, resident UI, overhead placement/restoration, shared ledger, two-way walking connection")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
