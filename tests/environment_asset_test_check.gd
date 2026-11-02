extends SceneTree
## Coverage and navigation through the real gallery, plus optional rendered evidence.
const Catalog = preload("res://scripts/environment/nature_asset_catalog.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	var gallery = load("res://scenes/environment/environment_asset_test.tscn").instantiate()
	root.add_child(gallery)
	await _frames(15)
	var player = gallery.player
	_check(not player.weapon.visible,"Inspection view has no weapon covering the specimens")
	var fire := InputEventMouseButton.new()
	fire.button_index = MOUSE_BUTTON_LEFT
	fire.pressed = true
	player._unhandled_input(fire)
	_check(not player.weapon._fire_requested,"Gallery clicks do not issue invisible weapon shots")
	var paths: Array[String] = []
	for item in Catalog.ITEMS:
		paths.append(Catalog.resource_path(item))
	# Catch omissions when new standalone nature scenes are added to the library.
	for file in DirAccess.get_files_at(Catalog.BASE+"scenes"):
		if file.ends_with(".tscn") and file not in ["crate_v1.tscn","training_forest_generated.tscn","pine_debris_generated.tscn"]:
			_check(Catalog.BASE+"scenes/"+file in paths,"Nature scene is listed: "+file)
	for file in ["grass_tuft_v1.res","leaf_litter_v1.res","moss_clump_v1.tres"]:
		_check(Catalog.BASE+"meshes/"+file in paths,"Loose ground-cover mesh is listed: "+file)
	var previous_end := -INF
	for i in range(gallery.stations.size()):
		var station: Node3D = gallery.stations[i]
		var asset: Node3D = station.get_node("Asset")
		var box: AABB = Catalog.bounds(asset)
		_check(box.size.length()>0,"Asset has visible geometry: "+str(station.get_meta("asset_id")))
		_check(station.get_node("AssetLabel").text.contains(station.get_meta("title")),"Every station has its own identifying label")
		var left: float = station.position.x+asset.position.x+box.position.x
		_check(left>previous_end,"Neighboring specimen geometry does not overlap")
		previous_end = station.position.x+asset.position.x+box.end.x
		_check(asset.position.z+box.end.z<0,"Geometry leaves the front walking lane clear")
		gallery.visit(i)
		await _frames(3)
		_check(player.is_on_floor(),"Each quick-jump lands on solid floor")
		var start_x: float = player.position.x
		Input.action_press("move_right")
		await _frames(8)
		Input.action_release("move_right")
		_check(player.position.x>start_x+0.25,"Walk along the aisle beside every specimen")
	gallery.visit(0)
	var event := InputEventKey.new()
	event.keycode = KEY_PAGEDOWN
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(3)
	_check(gallery.selected==1,"Page Down reaches the next labeled specimen")
	event = InputEventKey.new()
	event.keycode = KEY_PAGEUP
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(3)
	_check(gallery.selected==0,"Page Up returns to the previous specimen")
	gallery.visit(-1)
	_check(gallery.selected==0,"Previous at first station stays within the gallery")
	gallery.visit(999)
	_check(gallery.selected==gallery.stations.size()-1,"Next at last station stays within the gallery")
	if DisplayServer.get_name()!="headless":
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--evidence="):
				var directory := arg.trim_prefix("--evidence=")
				DirAccess.make_dir_recursive_absolute(directory)
				player.set_physics_process(false)
				for view in [[2,"trees",Vector3(0,0,17),Vector3(0,7,-4)],[5,"original_deadwood",Vector3(-2,0,6.2),Vector3(-2,0.6,-2)],[7,"pine_deadwood",Vector3(-4,0,7),Vector3(-4,0.7,-3)],[13,"ground_cover",Vector3(0,0,5.2),Vector3(0,0.5,-0.5)]]:
					gallery.visit(view[0])
					var station: Node3D = gallery.stations[view[0]]
					player.position = station.position+view[2]+Vector3.UP*0.03
					player.camera.look_at(station.position+view[3])
					await _frames(15)
					await RenderingServer.frame_post_draw
					_check(root.get_texture().get_image().save_png(directory.path_join(view[1]+".png"))==OK,"Save gallery evidence")
	for failure in failures:
		push_error(failure)
	print("ENVIRONMENT ASSET TEST: ","PASS" if failures.is_empty() else "FAIL", " / ",gallery.stations.size()," labeled assets")
	gallery.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
