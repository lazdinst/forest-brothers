extends SceneTree

const Registry = preload("res://startup/scene_registry.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	check(Registry.resolve_route([], "") == "menu", "Default must show menu")
	check(Registry.resolve_route([], "training") == "training", "Environment override")
	check(Registry.resolve_route(["--start=menu"], "training") == "menu", "CLI wins")
	check(Registry.resolve_route(["--start=invalid"], "training") == "menu", "Unknown CLI fails to menu")
	check(Registry.resolve_route(["--unrelated"], "training") == "training", "Other CLI options ignored")
	var startup = load("res://startup/startup.tscn").instantiate()
	root.add_child(startup)
	await process_frame
	var expected := Registry.resolve_route(OS.get_cmdline_user_args(), OS.get_environment("FOREST_BROTHERS_START"))
	check(startup.training_active == (expected == "training"), "Actual startup follows requested route")
	startup.show_menu()
	await process_frame
	check(not startup.training_active, "Menu active")
	check(startup.content.training_button.has_focus(), "Training is initial keyboard focus")
	startup.content.show_controls()
	check(startup.content.details.visible, "Controls dialog opens")
	startup.content.details.hide()
	# Exercise the actual button signal, not an alternate test launch path.
	startup.content.training_button.pressed.emit()
	await process_frame
	await physics_frame
	check(startup.training_active, "Button launches training")
	check(startup.content.scene_file_path == Registry.TRAINING, "Existing scene launched unchanged")
	check(startup.content.has_node("Player"), "Training player instantiated")
	var training_instance: int = startup.content.get_instance_id()
	var saved_mode: int = startup.content.process_mode
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	await create_timer(0.05).timeout
	Input.parse_input_event(escape)
	await create_timer(0.05).timeout
	escape.pressed = false
	Input.parse_input_event(escape)
	check(startup.navigation_open, "Escape opens UI-owned navigation")
	check(startup.content.process_mode == Node.PROCESS_MODE_DISABLED, "Training suspended")
	check(not paused, "SceneTree is never globally paused")
	startup.resume_button.pressed.emit()
	check(not startup.navigation_open, "Resume closes navigation")
	check(startup.content.process_mode == saved_mode, "Original process mode restored")
	check(startup.content.get_instance_id() == training_instance, "Resume preserves session instance")
	startup.open_navigation()
	startup.confirm_leave.popup_centered()
	startup.confirm_leave.canceled.emit()
	startup.confirm_leave.hide()
	check(startup.training_active and startup.navigation_open, "Cancel preserves training")
	startup.confirm_leave.confirmed.emit()
	await process_frame
	check(not startup.training_active and not startup.navigation_open, "Confirmed return reaches menu")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Menu restores visible pointer")
	startup.content.training_button.pressed.emit()
	await process_frame
	check(startup.training_active, "Training can relaunch after return")
	check(startup.content.get_instance_id() != training_instance, "Relaunch creates fresh session")
	startup.show_menu()
	await process_frame
	if "--capture-menu" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("forest-brothers-menu-preview.png"))
	startup.queue_free()
	await process_frame
	print("Menu/startup checks: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
