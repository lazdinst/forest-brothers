extends SceneTree
## Dead enemies keep their rifle and magazines on the body. F opens the body beside the
## player's inventory; searching reveals items one at a time; taking conserves every round.
const BodyContainer = preload("res://scripts/inventory/body_container.gd")
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
var failures: Array[String] = []
func _initialize() -> void:
	# A script error stops _run without quitting; fail instead of hanging forever.
	create_timer(60.0).timeout.connect(func():
		push_error("Enemy loot check timed out")
		quit(1))
	call_deferred("_run")
func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)
func _loot_rounds() -> int:
	var total := 0
	var seen := {}
	for node in get_nodes_in_group(&"combat_loot"):
		var inventory = node.inventory if node is BodyContainer else node.weapon_state.inventory
		if seen.has(inventory):
			continue
		seen[inventory] = true
		total += inventory.total_rounds()
	return total
func _bodies() -> Array:
	return get_nodes_in_group(&"combat_loot").filter(func(node): return node is BodyContainer)
func _run() -> void:
	var arena = load("res://scenes/combat/combat_arena.tscn").instantiate()
	root.add_child(arena)
	await _frames(10)
	var player = arena.player
	for enemy in arena.enemies:
		enemy.active = false
	var target = arena.enemies[0]
	target.rounds_in_magazine = 7
	target.spare_magazines.assign([10, 4])
	var carried_before: int = target.total_rounds()
	# Downed is not dead: nothing is left behind yet.
	target.receive_hit(100, target.global_position + Vector3.UP, Vector3.FORWARD, player, &"torso")
	await _frames(2)
	_check(get_nodes_in_group(&"combat_loot").is_empty(), "A downed enemy keeps its gear")
	target.receive_hit(1, target.global_position, Vector3.FORWARD, player, &"legs")
	await _frames(3)
	var bodies := _bodies()
	_check(bodies.size() == 1 and get_nodes_in_group(&"combat_loot").size() == 1, "A dead enemy leaves one searchable body and nothing on the ground")
	var body = bodies[0]
	var gear = body.inventory
	_check(_loot_rounds() == carried_before and target.total_rounds() == 0, "The body holds exactly the rounds the enemy carried")
	_check(body.global_position.distance_to(target.global_position) < 1.5, "The body lies where the enemy fell")
	_check(gear.equipped() and gear.magazine(gear.weapon().inserted_magazine_id).rounds.size() == 7 and gear.backpack() == null, "The rifle stays on the body with its magazine inside")
	_check(body.searching() and body.revealed == 0 and body.get_prompt().contains("Search"), "Nothing is known until searched")
	# F opens the body beside the player's own gear; searching only advances while open.
	player.global_position = body.global_position + Vector3(0, 0, 1.6)
	await _frames(2)
	player.camera.look_at(body.global_position + Vector3.UP * 0.15)
	await _frames(2)
	player.refresh_interaction_target()
	_check(player.interaction_target == body and player.get_interaction_prompt().contains("Search"), "The F ray finds the body and prompts a search")
	player.try_interact()
	await _frames(2)
	var view = arena.inventory.view
	_check(arena.inventory.is_open and view != null and view.loot == body and view.loot_heading.visible and not view.ammunition_status.visible, "F opens the inventory with the body beside it")
	_check(view.body_rifle_grid.cards.is_empty() and view.body_pocket_grid.cards.is_empty(), "Unsearched items are hidden")
	var rifle_id: StringName = gear.active_weapon_id
	view._take(rifle_id)
	_check(gear.items.has(rifle_id), "Items cannot be taken before they are found")
	await create_timer(BodyContainer.SEARCH_SECONDS_PER_ITEM + 0.2).timeout
	_check(body.revealed == 1 and view.body_rifle_grid.cards.size() == 1 and view.body_pocket_grid.cards.is_empty(), "The search reveals the rifle first, one item at a time")
	var player_inventory = player.weapon.state.inventory
	var player_before: int = player_inventory.total_rounds()
	var rifle_payload: Dictionary = view.body_rifle_grid.cards[0].drag_payload(Vector2(32,32))
	var pack_spot: Vector2 = Vector2(2.5,2.5) * view.pack_grid.cell
	_check(view.pack_grid._can_drop_data(pack_spot, rifle_payload) and not view.pocket_grid._can_drop_data(Vector2(32,32), rifle_payload), "The body's rifle can be dragged into free pack space but not a pocket")
	view.pack_grid._drop_data(pack_spot, rifle_payload)
	_check(player_inventory.items.has(rifle_id) and player_inventory.items[rifle_id].location.kind == &"pack" and player_inventory.total_rounds() == player_before + 7, "Dragging takes the rifle with its loaded magazine")
	_check(view.body_rifle_grid.cards.is_empty() and not view.body_rifle_grid.drop_validator.call(rifle_id, 0, &"", false, false), "Taken items leave the body and nothing is put back")
	while body.searching():
		await create_timer(0.1).timeout
	await _frames(1)
	_check(view.body_pocket_grid.cards.size() == 3, "The search then reveals both spare magazines and a few rubles")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("forest-brothers-body-loot.png"))
	var ctrl := InputEventMouseButton.new()
	ctrl.button_index = MOUSE_BUTTON_LEFT
	ctrl.pressed = true
	ctrl.ctrl_pressed = true
	while not view.body_pocket_grid.cards.is_empty():
		var count: int = view.body_pocket_grid.cards.size()
		view.body_pocket_grid.cards[0]._gui_input(ctrl)
		if view.body_pocket_grid.cards.size() == count:
			break
	_check(gear.total_rounds() == 0 and player_inventory.total_rounds() == player_before + carried_before, "Ctrl-click takes the rest; every round is conserved")
	_check(view.loot_heading.text.contains("nothing left"), "An emptied body says so")
	arena.inventory.close()
	await _frames(1)
	# More magazines than four pockets: the rest lie beside the body instead of vanishing.
	var second = arena.enemies[1]
	second.rounds_in_magazine = 3
	second.spare_magazines.assign([10, 10, 10, 10, 10])
	var second_rounds: int = second.total_rounds()
	var loot_before := _loot_rounds()
	second.receive_hit(100, second.global_position + Vector3.UP, Vector3.FORWARD, player, &"torso")
	await _frames(2)
	second.receive_hit(1, second.global_position, Vector3.FORWARD, player, &"legs")
	await _frames(3)
	_check(_bodies().size() == 2 and get_nodes_in_group(&"combat_loot").size() == 3, "Overflow magazines lie beside the body")
	_check(_loot_rounds() == loot_before + second_rounds, "Overflow keeps every round")
	# Reset clears remaining loot so repeated drills cannot duplicate ammunition.
	arena.reset_enemies()
	await _frames(3)
	_check(get_nodes_in_group(&"combat_loot").is_empty(), "Arena reset removes leftover bodies and loot")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: gear stays on the body, F opens it, search reveals one by one, taking conserves rounds, overflow and reset handled")
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
