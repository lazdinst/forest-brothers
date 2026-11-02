extends SceneTree
## Repeatable rendered asset review. No main-scene or player/weapon changes.
var sample: Node3D
var camera: Camera3D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.37,0.41,0.38)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.7,0.75,0.68)
	settings.ambient_light_energy = 0.5
	env.environment = settings
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-35,0)
	sun.light_color = Color(0.9,0.92,0.86)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	stage.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60,60)
	plane.material = load("res://assets/environment/materials/moss_ground_v1.tres")
	floor_mesh.mesh = plane
	stage.add_child(floor_mesh)
	sample = load("res://assets/environment/scenes/forest_birch_v1.tscn").instantiate()
	stage.add_child(sample)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 60
	stage.add_child(camera)
	var directory := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):
			directory = arg.trim_prefix("--evidence=")
	if directory.is_empty() or DisplayServer.get_name()=="headless":
		push_error("Run with actual renderer and -- --evidence=<writable directory>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(directory)
	var report := {"adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"viewport":str(root.size),"wood_triangles":sample.get_node("Trunk").mesh.get_faces().size()/3,"foliage_triangles":sample.get_node("Crown").mesh.get_faces().size()/3,"views":[]}
	var leaf_vertices: PackedVector3Array = sample.get_node("Crown").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var leaf_center := (leaf_vertices[0]+leaf_vertices[1]+leaf_vertices[2])/3.0
	var leaf_normal := (leaf_vertices[2]-leaf_vertices[0]).cross(leaf_vertices[1]-leaf_vertices[0]).normalized()
	for view in [["whole",Vector3(8,1.6,13),Vector3(0,5,0)],["bark",Vector3(1.45,1.6,1.8),Vector3(0.05,1.8,0)],["bark_seam",Vector3(-2.2,1.6,0.1),Vector3(0,1.8,0)],["leaf_skin",leaf_center+leaf_normal*0.3,leaf_center],["crown",Vector3(5,5,7),Vector3(0,7,0)],["reverse",Vector3(-8,1.6,-11),Vector3(0,5,0)]]:
		camera.position = view[1]
		camera.look_at(view[2])
		for i in range(20):
			await process_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png(directory.path_join(view[0]+".png"))
		if error != OK:
			push_error("Cannot save birch review")
			quit(1)
			return
		report.views.append({"name":view[0],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"rendered_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	for view in [["root_eye",Vector3(1.0,1.6,1.3),Vector3(0,0.15,0)],["root_low",Vector3(1.15,0.45,1.25),Vector3(0,0.23,0)],["root_back",Vector3(-1.3,0.65,-1.15),Vector3(0,0.2,0)]]:
		camera.position = view[1]
		camera.look_at(view[2])
		for i in range(12):
			await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(directory.path_join(view[0]+".png"))!=OK:
			quit(1)
			return
	var file := FileAccess.open(directory.path_join("birch_review.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("BIRCH RENDER REVIEW ",JSON.stringify(report))
	stage.queue_free()
	await process_frame
	quit()
