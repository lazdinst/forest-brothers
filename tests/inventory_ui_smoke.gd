extends SceneTree
const View = preload("res://ui/inventory/inventory_view.tscn")
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
var failures := 0
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func key_press(key: Key) -> void:
	await create_timer(0.05).timeout
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	root.push_input(event,true)
	event.pressed = false
	root.push_input(event,true)
	await create_timer(0.05).timeout
func _run() -> void:
	var preview = View.instantiate()
	root.add_child(preview)
	await process_frame
	var state = preview.weapon_state
	var inv = state.inventory
	var b: StringName = inv.initial_magazine_ids[1]
	check(preview.pocket_grid.columns == 4 and preview.pocket_grid.rows == 1 and preview.pocket_grid.cards.size() == 2,"Four pockets; exactly one spare magazine and one cartridge stack")
	check(preview.pack_grid.cards.is_empty() and not preview.data.has("stock"),"No invented pack possessions or camp stock")
	check(preview.rifle_art.inserted and preview.data.magazine_knowledge.begins_with("Unknown"),"Rifle displays its inserted magazine without exact contents")
	check(not preview.ammunition_status.text.contains("10/10") and not preview.ammunition_status.text.contains("10 / 10"),"Magazine counts never appear in inventory summary")
	if "--capture-inventory" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("forest-brothers-inventory-preview.png"))
	check(inv.remove_magazine(),"Physical inserted magazine can be removed into a free slot")
	preview._refresh()
	check(not preview.rifle_art.inserted and preview.data.magazine_id == "","Rifle inventory image removes its separate magazine attachment")
	if "--capture-inventory" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("forest-brothers-inventory-no-magazine.png"))
	check(inv.insert_magazine(inv.initial_magazine_ids[0]),"Reinserting restores the same magazine ID")
	preview._refresh()
	for card in preview.pocket_grid.cards: check(card.size == Vector2.ONE*(preview.pocket_grid.cell-4),"One square per physical item")
	preview._drop_in_grid(b,5,&"",&"pack")
	check(inv.magazine(b).location.kind == &"pack" and inv.magazine(b).location.slot == 5,"Drag handler moves the same magazine ID to a specific pack slot")
	preview._drop_in_grid(b,0,&"",&"pocket")
	var stack_id: StringName
	for item in inv.items.values():
		if item is Inventory.AmmoStack: stack_id = item.id
	preview.selected_id = stack_id
	preview.split_amount.value = 10
	preview._inventory_action(&"split")
	check(preview.pocket_grid.cards.size() == 3 and state.loose_rounds == 32,"UI split creates another physical stack and conserves rounds")
	preview.selected_id = b
	preview._show_context()
	check(preview.context.message.text.begins_with("Unknown"),"Magazine context starts with unknown knowledge")
	if "--capture-inventory" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("forest-brothers-magazine-actions.png"))
	preview._inventory_action(&"inspect")
	await create_timer(0.95).timeout
	check(inv.knowledge(b) == "Almost full","Inventory clock completes timed inspection on the actual state")
	check(state.request_action(&"unload",b),"Unloading action begins")
	await create_timer(0.4).timeout
	check(inv.knowledge(b).begins_with("Unknown") and state.total_rounds() == 52,"Unloading invalidates category and returns a conserved cartridge to a stack")
	preview.selected_id = b
	preview._inventory_action(&"pack")
	await create_timer(0.45).timeout
	check(inv.magazine(b).rounds.size() == 10 and state.total_rounds() == 52,"UI fill returns the magazine to capacity without creating rounds")
	# A fifth item snapshot must reject rather than hiding or displacing inventory.
	var examples: Array = []
	for index in range(4): examples.append({"id":str(index),"title":"Item","kind":"cloth","quantity":"1","span":Vector2i(3,2)})
	check(preview.pocket_grid.show_items(examples),"Four one-cell items fit even with legacy span metadata")
	var visible_cards: Array = preview.pocket_grid.cards.duplicate()
	examples.append(examples[0])
	check(not preview.pocket_grid.show_items(examples) and preview.pocket_grid.cards == visible_cards,"A fifth pocket item rejects without replacing visible items")
	preview._refresh()
	preview.queue_free()
	await process_frame
	var startup = load("res://startup/startup.tscn").instantiate()
	root.add_child(startup)
	startup.launch_training()
	await create_timer(0.2).timeout
	var player = startup.content.get_node("Player")
	var gun = player.weapon
	gun.state.loose_rounds = 17
	var total: int = gun.state.total_rounds()
	var stock: Dictionary = startup.content.stock.quantities.duplicate(true)
	var old_mode: int = startup.content.process_mode
	await key_press(KEY_TAB)
	check(startup.inventory_open and not startup.navigation_open and startup.inventory_view.data.loose == 17,"Tab opens the real carried inventory without stacking pause")
	check(startup.content.process_mode == Node.PROCESS_MODE_DISABLED and not paused,"Only local training suspends")
	var pace_before: int = player.locomotion.speed_setting
	var stance_before: int = player.locomotion.stance_level
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	wheel.position = Vector2(600,400)
	root.push_input(wheel,true)
	await process_frame
	check(player.locomotion.speed_setting == pace_before and player.locomotion.stance_level == stance_before,"Inventory scrolling cannot change gameplay pace or height")
	var mag_id: StringName = gun.state.inventory.initial_magazine_ids[1]
	startup.inventory_view.selected_id = mag_id
	startup.inventory_view._inventory_action(&"drop")
	check(gun._ground_items.has(mag_id) and gun.state.inventory.magazine(mag_id).location.kind == &"ground","Inventory drop creates an actual world interaction with the same item ID")
	await key_press(KEY_ESCAPE)
	check(not startup.inventory_open and startup.content.process_mode == old_mode,"Escape restores game controls")
	var pickup = gun._ground_items[mag_id]
	player.camera.look_at(pickup.global_position)
	await create_timer(0.1).timeout
	player.refresh_interaction_target()
	check(player.interaction_target == pickup,"Dropped magazine is visible to the actual F interaction ray")
	player.try_interact()
	await process_frame
	check(gun.state.inventory.magazine(mag_id).location.kind in [&"pocket",&"pack"],"F recovers the same physical magazine")
	check(gun.state.total_rounds() == total and startup.content.stock.quantities == stock,"Inventory operations conserve ammunition and leave communal stock untouched")
	var rifle_id: StringName = gun.state.inventory.active_weapon_id
	check(gun.drop_inventory_item(rifle_id),"Whole rifle can be dropped with inserted magazine")
	check(not gun.state.equipped() and not gun.state.try_fire(1),"Dropped rifle cannot fire")
	gun._ground_items[rifle_id].interact(player)
	check(gun.state.equipped() and gun.state.inventory.weapon().inserted_magazine_id != &"","Recovering rifle preserves nested magazine")
	await key_press(KEY_K)
	await create_timer(0.8).timeout
	var before: int = gun.state.total_rounds()
	gun.rng.seed = 12345
	gun.command(&"fire")
	await create_timer(0.1).timeout
	check(gun.shots == 1 and gun.state.total_rounds() == before-1,"Actual weapon controller fires through physical chamber rules")
	startup.open_navigation()
	startup._navigation_action(&"inventory")
	check(startup.inventory_open and not startup.navigation_open,"Pause menu switches to inventory")
	await key_press(KEY_TAB)
	check(not startup.inventory_open,"Tab closes inventory")
	startup.queue_free()
	await process_frame
	print("Inventory UI checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
