extends SceneTree
const Character = preload("res://scripts/characters/polygon_character.gd")
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func _run() -> void:
	var raw = load("res://assets/characters/polygon_humanoid/civilian_v1.glb").instantiate()
	for mesh in raw.find_children("*","MeshInstance3D",true,false):
		_check(mesh.get_active_material(0).vertex_color_use_as_albedo,"Post-import preserves palette without the runtime adapter")
	raw.free()
	var model = Character.new()
	root.add_child(model)
	await _frames(3)
	_check(model.rig.get_bone_count()==32,"GLB round-trip preserves 32-bone rig")
	_check(model._upper_meshes.size()>0,"Imported mesh keeps first-person visibility group")
	for socket in ["HandSocket_L","HandSocket_R"]:
		_check(model.model.find_child(socket,true,false)!=null,"GLB preserves attachment: %s" % socket)
	for mesh in model.model.find_children("*","MeshInstance3D",true,false):
		_check(mesh.skin!=null and mesh.skin.get_bind_count()==32,"Imported mesh has the complete skin binding")
		_check(mesh.get_node(mesh.skeleton)==model.rig,"Imported mesh is bound to the animated skeleton")
	for name in [&"idle",&"walk",&"run",&"crouch",&"aim",&"reload",&"interact",&"die"]:
		_check(model.animator.has_animation(name),"Imported animation exists: %s" % name)
	model.sample_action(&"walk",0.0)
	model.rig.force_update_all_bone_transforms()
	var foot: int = model.rig.find_bone("Foot_L")
	var start: Vector3 = model.rig.get_bone_global_pose(foot).origin
	model.sample_action(&"walk",0.25)
	model.rig.force_update_all_bone_transforms()
	_check(model.rig.get_bone_global_pose(foot).origin.distance_to(start)>0.08,"Walking changes actual skeletal foot position")
	model.sample_action(&"crouch",0.5)
	model.rig.force_update_all_bone_transforms()
	var head: int = model.rig.find_bone("Head")
	_check(model.rig.get_bone_global_pose(head).origin.y < 1.2,"Crouch lowers skeletal head to crouching height")
	model.sample_action(&"idle",0.0)
	model.rig.force_update_all_bone_transforms()
	_check(model.rig.get_bone_global_pose(head).origin.y > 1.55,"Idle restores standing pose after crouch")
	model.sample_action(&"die",1.0)
	model.rig.force_update_all_bone_transforms()
	_check(model.rig.get_bone_global_pose(head).origin.y < 0.3,"Death animation brings the body down without billboarding")
	model.queue_free()
	await process_frame
	var world = load("res://scenes/prototype/camp_test.tscn").instantiate()
	root.add_child(world)
	await _frames(12)
	var default_player = world.get_node("Player")
	var default_annex = world.get_node("SystemsAnnex")
	_check(default_player.body_visual == null,"Rejected blockout body is absent by default")
	_check(default_annex.resident_nodes[&"resident_01"].sprite.visible,"Default residents retain painted sprites")
	_check(default_annex.resident_nodes[&"resident_01"].polygon_model == null,"Default residents do not allocate rejected models")
	_check(default_annex.resident_nodes[&"resident_01"].get_node("PlayerClearance").collision_layer == 4,"Restored sprite keeps its near-camera clearance")
	_check(default_annex.stations[&"medical"].get_node_or_null("SpritePatient") != null,"Default medical patient retains sprite presentation")
	for enemy in default_annex.enemies:
		_check(enemy.polygon_model == null and enemy.sprite.visible,"Default enemies retain sprites")
	default_annex.start_planning()
	default_annex.stop_planning()
	_check(default_player.camera.current,"Planning restores camera without optional body")
	# Swap in explicit opt-in fixtures without altering normal scene defaults.
	default_annex.use_polygon_characters = true
	default_annex.reset_enemies()
	var old_resident = default_annex.resident_nodes[&"resident_01"]
	default_annex.remove_child(old_resident)
	old_resident.queue_free()
	default_annex._spawn_resident(&"resident_01",Vector3(0,0,8),false)
	var player = world.get_node("Player")
	player.use_polygon_body = true
	# Re-enter readiness once to construct the optional presentation in this fixture.
	world.remove_child(player)
	player.request_ready()
	world.add_child(player)
	await _frames(3)
	_check(player.body_visual != null and player.body_visual.rig.get_bone_count()==32,"Player owns a rigged polygon body")
	for mesh in player.body_visual._upper_meshes:
		_check(mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY,"Local head/arms do not occlude first-person camera")
	Input.action_press("move_forward")
	await _frames(10)
	Input.action_release("move_forward")
	_check(player.body_visual.current_state==&"walk","Player input drives body locomotion")
	for action in ["lean_left","lean_right"]:
		Input.action_press(action)
		await _frames(25)
		var upper_direction: Vector3 = player.global_basis.inverse()*player.body_visual._pivot.global_basis.y
		_check(upper_direction.x*player.camera.position.x>0.01,"Polygon body leans in the same direction as the view")
		Input.action_release(action)
		await _frames(20)
	var annex = world.get_node("SystemsAnnex")
	var civilian = annex.resident_nodes[&"resident_01"]
	_check(civilian.polygon_model != null and not civilian.sprite.visible,"Camp civilian uses 3D mesh instead of billboard")
	var before: Basis = civilian.polygon_model.global_basis
	player.global_position = civilian.global_position+Vector3(2,0,0)
	await _frames(3)
	_check(civilian.polygon_model.global_basis.is_equal_approx(before),"3D civilian does not turn to face the camera")
	var opponent = annex.enemies[0]
	_check(opponent.polygon_model != null and not opponent.sprite.visible,"First enemy uses polygon rig; second remains a comparison sprite")
	opponent.receive_hit(100,opponent.global_position+Vector3.UP,Vector3.FORWARD,player)
	await _frames(75)
	_check(opponent.state==&"dead" and opponent.polygon_model.current_state==&"die","Combat death selects the rig's death animation")
	annex.open_station(annex.stations[&"planning"],player)
	annex.start_planning()
	_check(player.body_visual._upper_meshes[0].cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON,"Overhead view shows the full player body")
	annex.stop_planning()
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: sprite defaults, optional-body planning, opt-in GLB skeleton/animations, actual bone locomotion/crouch/reset/death, player body/visibility, nonbillboard NPC, enemy death, planning view")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
