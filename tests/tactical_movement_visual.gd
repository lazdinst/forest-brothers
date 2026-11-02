extends SceneTree
## Real Compatibility captures of the requested HUD states at all three resolutions.
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func _run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Requires actual Compatibility rendering")
		quit(1)
		return
	var world = load("res://scenes/prototype/camp_test.tscn").instantiate()
	root.add_child(world)
	var player = world.player
	await frames(20)
	player.set_physics_process(false)
	var output := "res://.godot/minimal_hud_review"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var states := [
		["standing_max",7,10,100.0,100.0,false,false],
		["partial_medium",4,5,100.0,100.0,false,false],
		["crouch_min",1,1,100.0,100.0,false,false],
		["low_legs",7,10,4.0,100.0,false,false],
		["ads_empty_arms",4,5,70.0,0.0,true,false],
		["normal",7,10,100.0,100.0,false,false],
		["developer",7,10,100.0,100.0,false,true],
		["prone",0,3,80.0,75.0,false,false]
	]
	var sheet := Image.create(720, 8*200,false,Image.FORMAT_RGB8)
	for r in range(3):
		var resolution: Vector2i = [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)][r]
		root.size = resolution
		await frames(4)
		for index in range(states.size()):
			var state: Array = states[index]
			player.is_prone = state[1]==0
			player.body_shape.shape.height = player.movement_tuning.prone_height if player.is_prone else player.movement_tuning.stance_heights[state[1]-1]
			player.camera.position.y = player.body_shape.shape.height-0.2
			player.locomotion.speed_setting = state[2]
			player.locomotion.legs = state[3]
			player.locomotion.arms = state[4]
			player.locomotion.exhausted = state[3]<25
			player.is_aiming = state[5]
			world.debug_overlay.set_enabled(state[6])
			world.get_node("HUD/TacticalMovement")._refresh(1.0)
			await frames(12)
			await RenderingServer.frame_post_draw
			var capture := root.get_texture().get_image()
			var path := output.path_join("%dx%d_%s.png" % [resolution.x,resolution.y,state[0]])
			if capture.save_png(path)!=OK: failures.append(path)
			# Pixel-for-pixel crops, arranged by resolution then state, for visual QA.
			var region := Rect2i(0,resolution.y-200,240,200)
			var crop := capture.get_region(region)
			crop.convert(Image.FORMAT_RGB8)
			sheet.blit_rect(crop,Rect2i(0,0,240,200),Vector2i(r*240,index*200))
			print(path)
	sheet.save_png(output.path_join("hud_detail_sheet.png"))
	world.queue_free()
	await process_frame
	print("HUD visual captures: ","PASS" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
