extends SceneTree

const Registry = preload("res://startup/scene_registry.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func press_escape() -> void:
	await create_timer(0.05).timeout
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await create_timer(0.05).timeout
	escape.pressed = false
	Input.parse_input_event(escape)

func capture_frame(filename: String) -> void:
	if "--capture-menu" not in OS.get_cmdline_user_args():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join(filename))

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
	check(startup.content.play_button.has_focus(), "Play is initial keyboard focus")
	startup.content.show_controls()
	check(startup.content.details.visible, "Controls dialog opens")
	check(startup.content.details.theme == startup.navigation_panel.theme, "Details and navigation share one theme resource")
	await capture_frame("forest-brothers-controls-preview.png")
	startup.content.details.dismiss()
	# Exercise the actual button signal, not an alternate test launch path.
	startup.content.training_button.pressed.emit()
	await process_frame
	await physics_frame
	check(startup.training_active, "Button launches training")
	check(startup.content.scene_file_path == Registry.TRAINING, "Existing scene launched unchanged")
	check(startup.content.has_node("Player"), "Training player instantiated")
	await create_timer(0.05).timeout
	var annex = startup.content.get_node("SystemsAnnex")
	annex.open_station(annex.stations[&"depot"], startup.content.get_node("Player"))
	await process_frame
	check(annex._overlay.theme == startup.navigation_panel.theme, "Camp panels use the shared menu theme")
	check(annex._actions.get_child(0).custom_minimum_size.y >= 48, "Dynamic camp buttons use shared sizing")
	await capture_frame("forest-brothers-camp-menu-preview.png")
	await create_timer(0.05).timeout
	var claim := InputEventMouseButton.new()
	claim.button_index = MOUSE_BUTTON_LEFT
	claim.pressed = true
	claim.position = annex._actions.get_child(0).get_global_rect().get_center()
	root.push_input(claim, true)
	claim.pressed = false
	root.push_input(claim, true)
	await process_frame
	check(annex.runtime.cache_claimed and startup.content.get_node("Player").weapon.shots == 0, "Restyled camp action receives click without firing")
	await press_escape()
	check(not annex._overlay.visible and not startup.navigation_open, "Escape closes camp panel without stacking pause menu")
	annex.start_planning()
	await press_escape()
	check(not annex.planning and not startup.navigation_open, "Planning handles Escape before pause navigation")
	var training_instance: int = startup.content.get_instance_id()
	var saved_mode: int = startup.content.process_mode
	await press_escape()
	check(startup.navigation_open, "Escape opens UI-owned navigation")
	check(startup.content.process_mode == Node.PROCESS_MODE_DISABLED, "Training suspended")
	check(not paused, "SceneTree is never globally paused")
	await capture_frame("forest-brothers-pause-preview.png")
	startup.navigation_panel.actions.get_child(0).pressed.emit()
	check(not startup.navigation_open, "Resume closes navigation")
	check(startup.content.process_mode == saved_mode, "Original process mode restored")
	check(startup.content.get_instance_id() == training_instance, "Resume preserves session instance")
	startup.open_navigation()
	var modal_instance: int = startup.navigation_panel.get_instance_id()
	startup.navigation_panel.actions.get_child(1).pressed.emit()
	check(startup.confirming_leave, "Leave action selects confirmation")
	check(startup.navigation_panel.get_instance_id() == modal_instance, "Confirmation reuses the same modal surface")
	check(startup.navigation_panel.heading.text == "Leave training?", "Confirmation replaces pause content")
	check(startup.navigation_panel.actions.get_child_count() == 2, "Only confirmation actions remain")
	check(startup.navigation.get_child_count() == 1, "Navigation owns a single modal, without a separate dialog")
	startup.navigation_panel.actions.get_child(1).grab_focus()
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	root.push_input(tab, true)
	tab.pressed = false
	root.push_input(tab, true)
	await process_frame
	check(startup.navigation_panel.actions.get_child(0).has_focus(), "Tab wraps inside the active modal actions")
	await capture_frame("forest-brothers-leave-preview.png")
	await press_escape()
	check(startup.training_active and startup.navigation_open, "Cancel preserves training")
	check(not startup.confirming_leave and startup.navigation_panel.heading.text == "Training paused", "Escape returns confirmation to pause view")
	startup.navigation_panel.actions.get_child(1).pressed.emit()
	startup.navigation_panel.actions.get_child(1).pressed.emit()
	await process_frame
	check(not startup.training_active and not startup.navigation_open, "Confirmed return reaches menu")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Menu restores visible pointer")
	startup.content.training_button.pressed.emit()
	await process_frame
	check(startup.training_active, "Training can relaunch after return")
	check(startup.content.get_instance_id() != training_instance, "Relaunch creates fresh session")
	startup.show_menu()
	await process_frame
	await capture_frame("forest-brothers-menu-preview.png")
	startup.queue_free()
	await process_frame
	print("Menu/startup checks: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
