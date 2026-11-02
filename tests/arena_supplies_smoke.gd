extends SceneTree
## The combat arena stages a lootable body by the ammunition crate and an assortment of
## loose combat supplies; each can be picked up, rounds are conserved, and reset restages
## them without leaving duplicates behind.
const BodyContainer = preload("res://scripts/inventory/body_container.gd")
const GroundEquipment = preload("res://scripts/inventory/ground_equipment.gd")
const ArenaSupplies = preload("res://scripts/combat/arena_supplies.gd")
var failures: Array[String] = []

func _initialize() -> void:
	# A script error stops _run without quitting; fail instead of hanging forever.
	create_timer(60.0).timeout.connect(func():
		push_error("Arena supplies check timed out")
		quit(1))
	call_deferred("_run")

func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)

func _staged() -> Array:
	return get_nodes_in_group(ArenaSupplies.GROUP).filter(func(node): return not node.is_queued_for_deletion())

func _run() -> void:
	var arena = load("res://scenes/combat/combat_arena.tscn").instantiate()
	root.add_child(arena)
	await _frames(10)
	var player = arena.player
	for enemy in arena.enemies:
		enemy.active = false
	var staged := _staged()
	var bodies := staged.filter(func(node): return node is BodyContainer)
	var pickups := staged.filter(func(node): return node is GroundEquipment)
	_check(bodies.size() == 1 and bodies[0].global_position.distance_to(arena.ammo_crate.global_position) < 5.0, "One lootable body lies near the ammunition crate")
	var gear = bodies[0].inventory
	var kinds := {}
	for item in gear.items.values(): kinds[item.kind] = kinds.get(item.kind, 0) + 1
	_check(gear.equipped() and kinds.get(&"magazine", 0) == 3 and kinds.get(&"ammo_stack", 0) == 1 and gear.total_rounds() == 32, "The body carries a rifle with a magazine, two spares and loose cartridges")
	var seen := {}
	for pickup in pickups:
		var item = pickup.weapon_state.inventory.items[pickup.item_id]
		seen[item.kind] = seen.get(item.kind, 0) + 1
	_check(pickups.size() == 7 and seen.get(&"weapon", 0) == 1 and seen.get(&"magazine", 0) == 3 and seen.get(&"ammo_stack", 0) == 3, "Seven loose supplies: a rifle, three magazines and three cartridge stacks")
	var captions := pickups.map(func(p): return p.get_prompt())
	_check(captions.any(func(c): return c.contains("rifle")) and captions.any(func(c): return c.contains("32 ×")) and not captions.any(func(c): return c.contains("10/") or c.contains("rounds left")), "Pickups say what they are; stacks show counts, magazines never do")
	# Picking up the 14-round stack moves exactly those rounds to the player.
	var player_inventory = player.weapon.state.inventory
	var before: int = player_inventory.total_rounds()
	var stack_pickup = pickups.filter(func(p): return p.get_prompt().contains("14 ×"))[0]
	stack_pickup.interact(player)
	await _frames(2)
	_check(player_inventory.total_rounds() == before + 14 and (not is_instance_valid(stack_pickup) or stack_pickup.is_queued_for_deletion()), "Picking up a stack moves exactly its rounds and removes the pickup")
	# The body opens with F like any other.
	bodies[0].interact(player)
	await _frames(2)
	_check(arena.inventory.is_open and arena.inventory.view.loot == bodies[0], "F on the staged body opens it beside the inventory")
	arena.inventory.close()
	await _frames(1)
	# Reset restages the full set without leaving the old one behind.
	var old_body_id: int = bodies[0].get_instance_id()
	arena.reset_enemies()
	await _frames(3)
	var restaged := _staged()
	_check(restaged.size() == 8 and not restaged.any(func(node): return node.get_instance_id() == old_body_id), "Arena reset restages one body and seven supplies, replacing the old ones")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: staged body near crate, seven assorted supplies, exact pickups, body opens, reset restages")
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
