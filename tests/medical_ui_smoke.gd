extends SceneTree
## End to end in the combat arena: wounds keep bleeding with the inventory open, the health
## figure shows each part, and supplies treat by right-click menu, by dragging onto a body
## part, and by alt-click. Ground pickups name the supply.
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
const PlayerHealth = preload("res://scripts/health/player_health.gd")
const ArenaSupplies = preload("res://scripts/combat/arena_supplies.gd")
var failures: Array[String] = []

func _initialize() -> void:
	# A script error stops _run without quitting; fail instead of hanging forever.
	create_timer(90.0).timeout.connect(func():
		push_error("Medical UI check timed out")
		quit(1))
	call_deferred("_run")

func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)

func _give(inventory, supply_id: StringName):
	var probe := Inventory.SupplyInstance.new()
	probe.supply_id = supply_id
	return inventory.create_supply(supply_id, inventory.empty_location(&"", inventory.footprint(probe)))

func _card(view, id: StringName) -> Button:
	for grid in [view.pocket_grid, view.pack_grid]:
		for card in grid.cards:
			if card.item_id == id: return card
	return null

func _finish(health) -> void:
	for step in range(200):
		if health.treatment.is_empty(): return
		await create_timer(0.05).timeout

func _run() -> void:
	var arena = load("res://scenes/combat/combat_arena.tscn").instantiate()
	root.add_child(arena)
	await _frames(10)
	for enemy in arena.enemies:
		enemy.active = false
	var player = arena.player
	var health = player.body
	var inventory = player.weapon.state.inventory
	var labels: Array = get_nodes_in_group(ArenaSupplies.GROUP).map(func(node): return node.get_prompt() if node.has_method("get_prompt") else "")
	_check(labels.any(func(text): return text.contains("cloth bandage")) and labels.any(func(text): return text.contains("medical satchel")), "Arena ground supplies name what they are")
	# Bleeding runs in play.
	health.light_bleeding[PlayerHealth.THORAX] = true
	var thorax: float = health.health[PlayerHealth.THORAX]
	await create_timer(1.0).timeout
	_check(health.health[PlayerHealth.THORAX] < thorax, "Bleeding drains health during play")
	health.light_bleeding[PlayerHealth.THORAX] = false
	# Wounds and supplies, then open the inventory.
	health.light_bleeding[PlayerHealth.LEFT_ARM] = true
	health.heavy_bleeding[PlayerHealth.RIGHT_LEG] = true
	health.fractured[PlayerHealth.RIGHT_LEG] = true
	var bandage = _give(inventory, &"cloth_bandage")
	var dressing = _give(inventory, &"field_dressing")
	var morphine = _give(inventory, &"morphine")
	var splint = _give(inventory, &"splint")
	var canteen = _give(inventory, &"canteen")
	health.hydration = 50.0
	arena.inventory.open()
	await _frames(3)
	var view = arena.inventory.view
	_check(view.health == health and view.part_buttons.size() == 7, "The inventory shows the player's own seven body parts")
	var leg_button: Button = view.part_buttons.filter(func(b): return b.part == PlayerHealth.RIGHT_LEG)[0]
	var head_button: Button = view.part_buttons.filter(func(b): return b.part == PlayerHealth.HEAD)[0]
	_check(leg_button.text.contains("HEAVY") and leg_button.text.contains("broken") and view.health_status.text.contains("Heavy bleeding") and view.health_summary.text.contains("Energy"), "The health figure and summary show injuries, energy and water")
	var arm_before: float = health.health[PlayerHealth.LEFT_ARM]
	await create_timer(1.0).timeout
	_check(health.health[PlayerHealth.LEFT_ARM] < arm_before, "Wounds keep bleeding with the inventory open")
	# Right-click a bandage: it offers only the part it can help.
	view._open_menu_for(bandage.id, Vector2(100, 100))
	_check(view._menu_actions.has(StringName("treat:left_arm")) and not view._menu_actions.has(StringName("treat:right_leg")), "A bandage offers the light bleed, not the heavy one")
	view.item_menu.id_pressed.emit(view._menu_actions.find(StringName("treat:left_arm")))
	await create_timer(0.5).timeout
	_check(_card(view, bandage.id) != null and _card(view, bandage.id).progress > 0.0, "The supply being used shows treatment progress")
	await _finish(health)
	_check(not health.light_bleeding[PlayerHealth.LEFT_ARM] and not inventory.items.has(bandage.id), "The bandage stops the bleed and is used up")
	# Drag a field dressing onto the body part.
	var payload: Dictionary = _card(view, dressing.id).drag_payload(Vector2(10, 10))
	_check(leg_button._can_drop_data(Vector2.ZERO, payload) and not head_button._can_drop_data(Vector2.ZERO, payload), "A dressing can be dropped on the bleeding leg, not a healthy head")
	leg_button._drop_data(Vector2.ZERO, payload)
	await _finish(health)
	_check(not health.heavy_bleeding[PlayerHealth.RIGHT_LEG] and not inventory.items.has(dressing.id), "Dropping a dressing on a part treats that part")
	# Right-click the body part to choose a supply for it.
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	view._part_input(right, leg_button)
	var with_splint := StringName("treatwith:%s:%s" % [splint.id, PlayerHealth.RIGHT_LEG])
	_check(view._menu_actions.has(with_splint), "Right-clicking a broken leg offers the splint")
	view.item_menu.id_pressed.emit(view._menu_actions.find(with_splint))
	await _finish(health)
	_check(not health.fractured[PlayerHealth.RIGHT_LEG], "The splint sets the leg")
	# Alt-click uses supplies that need no body part.
	var alt := InputEventMouseButton.new()
	alt.button_index = MOUSE_BUTTON_LEFT
	alt.pressed = true
	alt.alt_pressed = true
	_card(view, morphine.id)._gui_input(alt)
	await _finish(health)
	_check(health.painkiller_left > 0.0 and view.health_status.text.contains("Morphine"), "Alt-click takes morphine and the summary shows it")
	_card(view, canteen.id)._gui_input(alt)
	await _finish(health)
	await _frames(2)
	_check(canteen.uses == 2 and health.hydration > 70.0 and _card(view, canteen.id).item.quantity == "2", "Alt-click drinks from the canteen, which shows what is left")
	# Double-click inspects a supply.
	var satchel = _give(inventory, &"medical_satchel")
	view._refresh()
	var double := InputEventMouseButton.new()
	double.button_index = MOUSE_BUTTON_LEFT
	double.pressed = true
	double.double_click = true
	_card(view, satchel.id)._gui_input(double)
	_check(view.inspect_title.text == "Medical satchel" and view.inspect_body.text.contains("300 of 300"), "Inspecting a satchel shows its remaining supply")
	if "--capture" in OS.get_cmdline_user_args():
		health.heavy_bleeding[PlayerHealth.LEFT_LEG] = true
		health.health[PlayerHealth.LEFT_LEG] = 21.0
		health.fractured[PlayerHealth.LEFT_ARM] = true
		view._refresh()
		await _frames(2)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("forest-brothers-health-view.png"))
	arena.inventory.close()
	for failure in failures:
		push_error(failure)
	print("Medical UI checks: ", "PASS" if failures.is_empty() else "FAIL")
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
