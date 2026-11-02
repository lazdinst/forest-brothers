extends SceneTree
var world
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if not args.is_empty() else "idle"
	world = load("res://scenes/prototype/camp_test.tscn").instantiate()
	root.add_child(world)
	for i in range(12):
		await physics_frame
	var annex = world.get_node("SystemsAnnex")
	annex.use_mpfb_enemy = mode != "sprite"
	annex.reset_enemies()
	var target = annex.enemies[0]
	var player = world.get_node("Player")
	player.global_position = target.global_position + Vector3(0,0.03,2.7)
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	player.weapon.hide()
	world.get_node("HUD").hide()
	annex._layer.hide()
	if mode == "death":
		player.global_position = target.global_position + Vector3(2.6,1,3.4)
	if mode == "walk":
		player.global_position = target.global_position + Vector3(2.6,0.03,1.4)
	# Let the physics server receive the teleported player before enabling sight.
	for i in range(4):
		await physics_frame
	if mode == "walk":
		target.targets.clear()
		target.active = true
	if mode == "aim":
		print("AIM FIXTURE visible before activation: ",target.can_see(player))
		target.active = true
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var label := Label.new()
	label.position = Vector2(24,24)
	label.add_theme_font_size_override("font_size",24)
	label.add_theme_constant_override("outline_size",6)
	layer.add_child(label)
	for i in range(110):
		if i == 20 and mode == "damage":
			target.receive_hit(40,target.global_position+Vector3(0,1.3,0),Vector3.FORWARD,player)
		if i == 20 and mode == "death":
			target.receive_hit(100,target.global_position+Vector3.UP,Vector3.FORWARD,player)
		player.camera.look_at(target.global_position + (Vector3(0,0.35,0.65) if mode=="death" else Vector3(0,0.93,0)))
		label.text = "FROZEN CHARACTER REVIEW / %s / health %.0f / %s" % [mode,target.health,target.state]
		await process_frame
	world.queue_free()
	layer.queue_free()
	for i in range(3):
		await process_frame
	quit()
