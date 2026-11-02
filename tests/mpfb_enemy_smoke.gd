extends SceneTree
const Model = preload("res://scripts/characters/imported_character.gd")
const Asset = preload("res://assets/characters/mpfb_enemy/enemy_v1.glb")
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
func frames(n: int) -> void:
	for i in range(n):
		await physics_frame
		await process_frame
func sample(model, clip: StringName, t: float) -> void:
	model.play(clip)
	model.animator.play(clip,0.0)
	model.animator.pause()
	model.animator.seek(t,true)
	model.rig.force_update_all_bone_transforms()
func _run() -> void:
	var model = Model.new()
	model.model_scene = Asset
	root.add_child(model)
	await frames(3)
	check(model.rig.get_bone_count()==53,"MPFB 53-bone rig survives GLB import")
	for part in ["Body","Shirt","Trousers","Boots","Eyes","Hair"]:
		var mesh = model.model.find_child(part,true,false)
		check(mesh is MeshInstance3D,"Separate character part: "+part)
		if mesh is MeshInstance3D:
			check(mesh.skin != null and mesh.get_node(mesh.skeleton)==model.rig,"Part shares the animated rig: "+part)
	for clip in [&"idle",&"walk",&"aim",&"die"]:
		check(model.animator.has_animation(clip),"Imported action: "+String(clip))
	var foot: int = model.rig.find_bone("foot_l")
	var head: int = model.rig.find_bone("head")
	sample(model,&"walk",0)
	var before: Vector3 = model.rig.get_bone_global_pose(foot).origin
	sample(model,&"walk",0.25)
	check(model.rig.get_bone_global_pose(foot).origin.distance_to(before)>0.05,"Walking moves a real foot bone")
	sample(model,&"die",model.animator.get_animation(&"die").length)
	check(model.rig.get_bone_global_pose(head).origin.y<0.55,"Death clip puts the head near the ground")
	sample(model,&"idle",0)
	check(model.rig.get_bone_global_pose(head).origin.y>1.35,"Idle resets the death pose")
	model.queue_free()
	await frames(2)
	var world = load("res://scenes/prototype/camp_test.tscn").instantiate()
	root.add_child(world)
	await frames(12)
	var annex = world.get_node("SystemsAnnex")
	var player = world.get_node("Player")
	check(not annex.use_mpfb_enemy and annex.enemies[0].polygon_model == null,"Sprite is the default after the art freeze")
	annex.use_mpfb_enemy = true
	annex.reset_enemies()
	await frames(3)
	var enemy = annex.enemies[0]
	check(enemy.character_scene==Asset and enemy.polygon_model != null and not enemy.sprite.visible,"First enemy uses the selected MPFB mesh")
	check(annex.enemies[1].polygon_model==null and annex.enemies[1].sprite.visible,"Second enemy remains the sprite comparison")
	var facing: Basis = enemy.visual.global_basis
	player.global_position = enemy.global_position+Vector3(2,0,0)
	await frames(3)
	check(enemy.visual.global_basis.is_equal_approx(facing),"Imported body does not billboard toward the camera")
	player.global_position = annex.global_position+Vector3(-4,0.02,-9)
	player.velocity = Vector3.ZERO
	await frames(8)
	if player.weapon.state.inventory.weapon().chambered_round == null:
		player.weapon.command(&"chamber")
		await frames(60)
	player.weapon.rng.seed = 12345
	for i in range(3):
		player.camera.look_at(enemy.global_position+Vector3.UP*(0.12 if enemy.state==&"downed" else 1.0))
		await frames(3)
		player.weapon.command(&"fire")
		await frames(18)
	check(enemy.body.is_dead() and enemy.state==&"dead","Two torso rays down the MPFB enemy and a third finishes it")
	await frames(75)
	check(enemy.get_node("Body").disabled and enemy.collision_layer==0,"MPFB corpse no longer blocks or fights")
	check(enemy.polygon_model.current_state==&"die","Lethal hit selects skeletal death")
	check(get_nodes_in_group("training_blood").size()>0,"MPFB hits retain blood feedback")
	annex.reset_enemies()
	await frames(4)
	check(annex.enemies[0].body.is_alive() and annex.enemies[0].polygon_model.current_state==&"idle","Reset recreates living MPFB opponent")
	world.queue_free()
	await frames(3)
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: MPFB rig, separate clothing, actual walk/death/reset poses, fixed world orientation, rifle hits, blood, nonblocking corpse and reset")
	quit(0 if failures.is_empty() else 1)
