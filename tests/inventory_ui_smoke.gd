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
	check(not preview.data.has("stock"), "Personal inventory has no camp-stock data")
	check(preview.pocket_grid.columns == 4 and preview.pocket_grid.rows == 1, "Pockets are exactly four squares in a line")
	await process_frame
	for grid in [preview.pack_grid,preview.pocket_grid]:
		for index in range(grid.cards.size()):
			check(grid.cards[index].size == Vector2.ONE * (grid.cell-4), "Every carried item occupies exactly one square")
			for other in range(index+1,grid.cards.size()):
				check(not grid.cards[index].get_rect().intersects(grid.cards[other].get_rect()), "Carried item cards never overlap")
	var pocket_examples: Array = []
	for index in range(4):
		pocket_examples.append({"id":str(index),"title":"Item","quantity":"1","kind":"cloth","span":Vector2i(3,2)})
	check(preview.pocket_grid.show_items(pocket_examples), "Four pocket items fit even if legacy multi-cell spans are supplied")
	check(preview.pocket_grid.cards[3].position.y == preview.pocket_grid.cards[0].position.y, "All four pocket items stay on one row")
	var pocket_cards: Array = preview.pocket_grid.cards.duplicate()
	pocket_examples.append(pocket_examples[0])
	check(not preview.pocket_grid.show_items(pocket_examples), "A fifth pocket item is rejected")
	check(preview.pocket_grid.cards == pocket_cards, "Rejecting pocket overflow preserves visible items")
	preview.pocket_grid.show_items(preview.data.pocket_items)
	preview.pack_grid.cards[0].pressed.emit()
	check("Folded coat" in preview.detail.text, "Selecting a carried item updates its detail")
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
	check(not startup.inventory_view.data.has("stock"), "Training inventory does not read camp stores")
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
