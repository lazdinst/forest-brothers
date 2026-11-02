extends SceneTree
## Actual-renderer asset checks; emits images and structural costs, not FPS claims.
var stage: Node3D
var camera: Camera3D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):
			directory=arg.trim_prefix("--evidence=")
	if directory.is_empty() or DisplayServer.get_name()=="headless":
		push_error("Use actual renderer and -- --evidence=<directory>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(directory)
	stage=Node3D.new()
	root.add_child(stage)
	var env:=WorldEnvironment.new()
	var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR
	settings.background_color=Color(0.37,0.41,0.38)
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color=Color(0.7,0.75,0.68)
	settings.ambient_light_energy=0.55
	env.environment=settings
	stage.add_child(env)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-45,-35,0)
	sun.light_color=Color(0.9,0.92,0.86)
	sun.light_energy=1.0
	sun.shadow_enabled=true
	stage.add_child(sun)
	var ground:=MeshInstance3D.new()
	var plane:=PlaneMesh.new()
	plane.size=Vector2(70,70)
	plane.material=load("res://assets/environment/materials/moss_ground_v1.tres")
	ground.mesh=plane
	stage.add_child(ground)
	camera=Camera3D.new()
	camera.current=true
	camera.fov=60
	stage.add_child(camera)
	var views:=[
		["pine_whole","forest_pine_v1",Vector3(14,1.6,21),Vector3(0,7,0)],
		["pine_bark","forest_pine_v1",Vector3(1.5,1.6,2),Vector3(0,1.8,0)],
		["pine_upper","forest_pine_v1",Vector3(3,10,4),Vector3(0.2,10,0)],
		["pine_crown","forest_pine_v1",Vector3(7,8,10),Vector3(0.2,12,0)],
		["fallen_pine","pine_fallen_v2",Vector3(6,2.3,7),Vector3(0,0.4,0)],
		["fallen_break","pine_fallen_v2",Vector3(-5.8,0.9,1.8),Vector3(-4.45,0.38,0)],
		["rotten_pine","pine_rotten_v2",Vector3(5,1.8,5),Vector3(0,0.45,0)],
		["rotten_hollow","pine_rotten_v2",Vector3(-5,0.7,0.8),Vector3(-3.7,0.3,0)],
		["moss_detail","pine_rotten_v2",Vector3(0,0.9,1.2),Vector3(0,0.55,0)],
		["broken_branch","pine_branch_broken_v2",Vector3(-1.7,0.75,1.6),Vector3(-0.45,0.12,0)],
		["dead_branch","pine_branch_dead_v2",Vector3(1.5,1.2,1.6),Vector3(0,0.12,0)],
		["broken_snag","pine_snag_v2",Vector3(8,1.6,9),Vector3(0,3,0)]
	]
	var report:={"adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"viewport":str(root.size),"assets":{}}
	for view in views:
		var asset=load("res://assets/environment/scenes/"+view[1]+".tscn").instantiate()
		stage.add_child(asset)
		camera.position=view[2]
		camera.look_at(view[3])
		for i in range(16):
			await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(directory.path_join(view[0]+".png"))!=OK:
			quit(1)
			return
		var triangles:=0
		for child in asset.get_children():
			if child is MeshInstance3D:
				triangles+=child.mesh.get_faces().size()/3
		report.assets[view[1]]={"triangles":triangles,"rendered_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
		asset.queue_free()
		await process_frame
	var file:=FileAccess.open(directory.path_join("pine_review.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("PINE VISUAL REVIEW ",JSON.stringify(report))
	stage.queue_free()
	await process_frame
	quit()
