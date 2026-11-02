extends SceneTree
const View = preload("res://ui/inventory/inventory_view.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func key_press(key: Key) -> void:
	await create_timer(0.05).timeout
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	root.push_input(event,true)
	event.pressed = false
	root.push_input(event,true)
	await create_timer(0.05).timeout

func _run() -> void:
	var preview = View.instantiate()
	root.add_child(preview)
	await process_frame
	check(preview.data.demo, "Standalone inventory is explicitly sample data")
	check(preview.store_grid.cards.size() == 7, "Sample stores expose all seven resource categories")
	await process_frame
	for index in range(preview.store_grid.cards.size()):
		for other in range(index+1,preview.store_grid.cards.size()):
			check(not preview.store_grid.cards[index].get_rect().intersects(preview.store_grid.cards[other].get_rect()), "Inventory cards fit their cells without overlapping")
	preview._filter_store("rounds")
	check(preview.store_grid.cards.size() == 1, "Ammunition filter")
	preview._filter_store("supplies")
	check(preview.store_grid.cards.size() == 6, "Supply filter excludes cartridges")
	preview.store_grid.cards[0].pressed.emit()
	check("stored" in preview.detail.text, "Selecting a stored item updates its detail")
	preview._filter_store("all")
	check(not preview.character_preview.has_character, "Missing current body uses labelled neutral silhouette")
	var source := Node3D.new()
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	source.add_child(mesh)
	root.add_child(source)
	var before := source.transform
	preview.character_preview.bind_visual(source)
	check(preview.character_preview.has_character and preview.character_preview.viewport.own_world_3d, "Supplied current visual uses an isolated 3D preview")
	preview.character_preview.rotate_character(0.4)
	check(source.transform == before and source.get_child_count() == 1, "Preview rotation never mutates the source character")
	preview.character_preview.bind_visual(null)
	source.queue_free()
	if "--capture-inventory" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("forest-brothers-inventory-preview.png"))
	preview.queue_free()
	await process_frame
	var startup = load("res://startup/startup.tscn").instantiate()
	root.add_child(startup)
	startup.launch_training()
	await create_timer(0.1).timeout
	var player = startup.content.get_node("Player")
	player.weapon.state.loose_rounds = 17
	var rounds_before: int = player.weapon.state.total_rounds()
	var stock_before: Dictionary = startup.content.stock.quantities.duplicate(true)
	var original_mode: int = startup.content.process_mode
	await key_press(KEY_TAB)
	check(startup.inventory_open and not startup.navigation_open, "Tab opens inventory without stacking pause")
	check(not startup.inventory_view.data.demo and startup.inventory_view.data.loose == 17, "Inventory reads the current player state instead of sample quantities")
	check(startup.inventory_view.store_grid.cards.size() == stock_before.size(), "Zero-stock categories remain visible for inspection")
	check(startup.content.process_mode == Node.PROCESS_MODE_DISABLED and not paused, "Only local training is suspended")
	await key_press(KEY_ESCAPE)
	check(not startup.inventory_open and startup.content.process_mode == original_mode, "Escape closes inventory and restores training")
	check(player.weapon.state.total_rounds() == rounds_before and startup.content.stock.quantities == stock_before, "Inspection conserves ammunition and communal stock")
	startup.open_navigation()
	startup._navigation_action(&"inventory")
	check(startup.inventory_open and not startup.navigation_open, "Pause equipment action switches to inventory")
	await key_press(KEY_TAB)
	check(not startup.inventory_open, "Tab also closes inventory")
	var annex = startup.content.get_node("SystemsAnnex")
	annex.open_station(annex.stations[&"depot"],player)
	await key_press(KEY_TAB)
	check(annex._overlay.visible and not startup.inventory_open, "Inventory never stacks over a camp panel")
	annex.close_panel()
	startup.queue_free()
	await process_frame
	print("Inventory UI checks: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
