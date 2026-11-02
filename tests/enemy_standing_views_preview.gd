extends SceneTree
## Isolated art-review contact sheet, using the actual enemy presentation.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var pose := StringName(args[0]) if not args.is_empty() else &"unarmed"
	root.size = Vector2i(1400, 900)
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.16, 0.18, 0.20)
	world.add_child(environment)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.0
	camera.position = Vector3(0, -0.3, 12)
	world.add_child(camera)
	camera.make_current()
	var enemies: Array = []
	for index in range(8):
		var enemy = load("res://scripts/combat/enemy_actor.gd").new()
		world.add_child(enemy)
		enemies.append(enemy)
		enemy.set_physics_process(false)
		enemy.position = Vector3((index % 4 - 1.5) * 1.8, -floori(index / 4.0) * 2.4, 0)
		enemy.rotation.y = index * TAU / 8.0
		enemy.state = &"engage" if pose == &"aiming" else &"idle"
		enemy._physics_process(0.0)
		enemy.standing_views.update(enemy, camera, enemy.sprite, enemy.FIGURE_HEIGHT, pose)
		enemy.rifle.hide()
		var label := Label3D.new()
		label.text = "%d degrees" % (index * 45)
		label.font_size = 40
		label.pixel_size = 0.004
		world.add_child(label)
		label.position = enemy.position + Vector3(0, -0.15, 0)
	for frame in range(8):
		await process_frame
	if pose == &"walking":
		for phase in range(4):
			for enemy in enemies:
				enemy.standing_views.advance_walk(Vector3.ZERO)
				enemy.standing_views.advance_walk(Vector3(phase * 0.35 + 0.01, 0, 0))
				enemy.standing_views.update(enemy, camera, enemy.sprite, enemy.FIGURE_HEIGHT, &"walking")
			await process_frame
			await RenderingServer.frame_post_draw
			var output := "res://docs/reviews/enemy_standing_2026-11-02/walk_frame_%d.png" % phase
			var error := root.get_texture().get_image().save_png(output)
			if error != OK:
				quit(error)
				return
		print("Walking review captures: four phases, eight directions")
		quit(0)
		return
	await RenderingServer.frame_post_draw
	var path := "res://docs/reviews/enemy_standing_2026-11-02/standing_in_engine.png"
	if pose != &"unarmed":
		path = "res://docs/reviews/enemy_standing_2026-11-02/%s_in_engine.png" % pose
	var result := root.get_texture().get_image().save_png(path)
	print("Standing review capture: ", result)
	quit(result)
