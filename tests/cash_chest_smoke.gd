extends SceneTree
## The camp cash chest: F opens it beside the carried inventory; it shows the treasury as money
## stacks; carried rubles and lats go in (drag or ctrl-click) and come out, and every move
## changes the treasury exactly; nothing but money goes in.
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)

func _run() -> void:
	var startup = load("res://startup/startup.tscn").instantiate()
	root.add_child(startup)
	await _frames(2)
	startup.launch_training()
	await _frames(14)
	var camp = startup.content
	var player = camp.get_node("Player")
	var chest = camp.get_node("SystemsAnnex").cash_chest
	var stock = camp.stock
	var rubles: int = stock.count(&"rubles")
	var lats: int = stock.count(&"lats")
	_check(chest != null and chest.total(&"rubles") == rubles and chest.total(&"lats") == lats, "The chest holds the treasury")
	_check(chest.get_prompt().contains("%d rubles" % rubles), "Its prompt shows what is inside")
	var inventory = player.weapon.state.inventory
	var carried = inventory.create_supply(&"rubles", inventory.empty_location(&"", Vector2i.ONE), 50)
	chest.interact(player)
	await _frames(2)
	var view = startup.inventory_host.view
	_check(startup.inventory_open and view.loot == chest and view.loot_heading.text.contains("CASH CHEST"), "F opens the chest beside the carried inventory")
	_check(view.body_pocket_grid.cards.size() == chest.visible_items().size() and not view.body_rifle_grid.visible, "The chest shows its money stacks in one grid")
	var magazine_id: StringName = inventory.initial_magazine_ids[1]
	_check(not view._can_store(magazine_id, 5, &"", false, false), "Only money goes in")
	_check(view._can_store(carried.id, 6, &"", false, false), "Carried money can be dropped in")
	view._quick({"id":str(carried.id)}, &"move")
	await _frames(1)
	_check(not inventory.items.has(carried.id) and stock.count(&"rubles") == rubles + 50, "Ctrl-click puts carried rubles in; the treasury grows")
	var stack = chest.visible_items().filter(func(item): return item.supply_id == &"lats")[0]
	view._take(stack.id)
	await _frames(1)
	_check(inventory.items.has(stack.id) and stock.count(&"lats") == 0, "Taking lats out moves them to the carrier and out of the treasury")
	view._store(stack.id, 10, &"", false, false)
	await _frames(1)
	_check(stock.count(&"lats") == lats and not inventory.items.has(stack.id), "Dropping them back restores the treasury")
	startup.close_inventory()
	await _frames(2)
	stock.add(&"rubles", 7)
	_check(chest.total(&"rubles") == rubles + 57, "Treasury changes elsewhere (contact, rewards) show in the chest")
	startup.queue_free()
	await _frames(2)
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: the cash chest opens beside the inventory, shows the treasury, takes money in and gives it out exactly, refuses other items")
	quit(0 if failures.is_empty() else 1)
