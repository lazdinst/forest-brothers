extends SceneTree
## Physical relief/trench traversal on the actual F5 scene, plus GPU evidence.
const Layout = preload("res://scripts/environment/forest_layout.gd")
var failures: Array[String] = []
var world: Node3D
var player

func _initialize() -> void:
	call_deferred("_run")

func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _place(x: float, z: float, yaw: float = 0.0) -> void:
	player.position = Vector3(x,Layout.height(x,z)+0.03,z)
	player.velocity = Vector3.ZERO
	player.rotation = Vector3(0,yaw,0)
	player.camera.rotation = Vector3.ZERO
	await _frames(10)

func _ray(a: Vector3,b: Vector3) -> Dictionary:
	return world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1,[player.get_rid()]))

func _evidence(directory: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	player.set_physics_process(false)
	# Choose an open spot for repeatable inspection instead of putting the
	# evidence camera inside a crown when a seed/mesh recipe changes.
	var interior := Vector2(-24,-25)
	var best_clearance := 0.0
	var tree_positions: Array[Vector2] = []
	for child in world.get_node("WoodlandProps/GeneratedForest").get_children():
		if child.name.begins_with("TreeBody"):
			tree_positions.append(Vector2(child.position.x,child.position.z))
	for x in range(-33,-21):
		for z in range(-38,-22):
			var clearance := 100.0
			for tree in tree_positions:
				clearance = minf(clearance,Vector2(x,z).distance_to(tree))
			if clearance > best_clearance:
				best_clearance = clearance
				interior = Vector2(x,z)
	var views := [
		["training_forest",Vector3(0,0.03,9),Vector3(-13,1.5,22)],
		["forest_interior",Vector3(interior.x,Layout.height(interior.x,interior.y)+0.03,interior.y),Vector3(interior.x-6,2,interior.y-9)],
		["trench_inside",Vector3(-9,-1.52,24),Vector3(-9,-0.5,31)],
		["trench_entry",Vector3(-3,Layout.height(-3,20)+0.03,20),Vector3(-11,-0.7,26)]
	]
	var report: Dictionary = {"engine":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"viewport":str(root.size),"seed":Layout.SEED,"counts":world.get_node("WoodlandProps/GeneratedForest").get_meta("counts"),"conditions":"Actual F5 scene including active camp annex/character prototypes; default shadowed sun + depth fog, 1280x720, uncapped process-frame intervals, 300 samples/view after 30 settling physics ticks; not GPU timestamps or prolonged playtesting.","views":[]}
	for view in views:
		player.position = view[1]
		player.camera.look_at(view[2])
		await _frames(30)
		var samples: Array[float] = []
		var max_draws := 0.0
		var max_primitives := 0.0
		var previous := Time.get_ticks_usec()
		for i in range(300):
			await process_frame
			var now := Time.get_ticks_usec()
			samples.append((now-previous)/1000.0)
			previous = now
			max_draws = maxf(max_draws,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			max_primitives = maxf(max_primitives,Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		samples.sort()
		report.views.append({"name":view[0],"median_ms":samples[150],"p95_ms":samples[285],"draw_calls_max":max_draws,"rendered_primitives_max":max_primitives})
		await RenderingServer.frame_post_draw
		_check(root.get_texture().get_image().save_png(directory.path_join(view[0]+".png"))==OK,"Save forest evidence "+view[0])
	report.texture_bytes_process = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	report.video_bytes_process = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	var file := FileAccess.open(directory.path_join("forest_measurements.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("FOREST MEASUREMENTS ",JSON.stringify(report))

func _run() -> void:
	var baked_text := FileAccess.get_file_as_string("res://assets/environment/scenes/training_forest_generated.tscn")
	_check(baked_text.contains("buffer = PackedFloat32Array("),"Baked forest retains actual MultiMesh transform buffers")
	world = load("res://scenes/prototype/camp_test.tscn").instantiate()
	root.add_child(world)
	player = world.get_node("Player")
	await _frames(20)
	var heights: Array[float] = []
	for point in [Vector2(-28,-25),Vector2(-27,17),Vector2(-22,34)]:
		var hit := _ray(Vector3(point.x,8,point.y),Vector3(point.x,-4,point.y))
		_check(not hit.is_empty(),"Physical terrain exists at "+str(point))
		if not hit.is_empty():
			heights.append(hit.position.y)
			_check(absf(hit.position.y-Layout.height(point.x,point.y))<0.06,"Terrain mesh and source height agree")
	_check(heights.max()-heights.min()>0.4,"Real terrain has distinct low rises and hollows")
	await _place(0,12,PI)
	Input.action_press("move_forward")
	await _frames(140)
	Input.action_release("move_forward")
	_check(player.position.z>18 and player.is_on_floor(),"Walk beyond the former box perimeter onto the forest terrain")
	await _place(-9,18.5,PI)
	Input.action_press("move_forward")
	await _frames(150)
	Input.action_release("move_forward")
	_check(player.position.z>24 and player.position.y < -1.3 and player.is_on_floor(),"Walk down the ramp into the excavated trench")
	await _place(-9,27,PI)
	Input.action_press("move_right")
	await _frames(150) # Configured strafe speed and acceleration.
	Input.action_release("move_right")
	_check(player.position.x < -15 and player.position.y < -1.3,"Walk into the connected side branch")
	await _place(-9,24)
	Input.action_press("move_right")
	await _frames(35)
	Input.action_release("move_right")
	_check(player.position.x < -7.7,"Trench sidewall blocks ordinary walking")
	_check(not _ray(Vector3(-9,-0.2,25),Vector3(-6,-0.2,25)).is_empty(),"Earth wall blocks a weapon-height ray from inside trench")
	_check(_ray(Vector3(-9,-0.2,24),Vector3(-9,-0.2,30)).is_empty(),"Trench sight line stays open along its length")
	await _place(-9,25)
	Input.action_press("move_forward")
	await _frames(170)
	Input.action_release("move_forward")
	_check(player.position.z<18 and player.position.y > -0.7,"Return to the woodland using the ramp")
	if DisplayServer.get_name() != "headless":
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--evidence="):
				await _evidence(arg.trim_prefix("--evidence="))
	for failure in failures:
		push_error(failure)
	print("FOREST TERRAIN CHECK: ","PASS" if failures.is_empty() else "FAIL")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
