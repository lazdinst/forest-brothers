extends SceneTree
## Rubles and lats: carried as items (never used like supplies), deposited into the camp
## treasury at the quartermaster, spent at the contact's fixed prices (lats buy more), saved with
## the camp, carried on enemies' bodies and hidden in regions, and paid by missions.
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
const PlayerHealth = preload("res://scripts/health/player_health.gd")
const Runtime = preload("res://scripts/camp/camp_runtime.gd")
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
const MissionController = preload("res://scripts/missions/mission_controller.gd")
const CATALOG = preload("res://missions/catalog.tres")
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

class Holder extends RefCounted:
	var inventory
	func equipped() -> bool: return true

func _run() -> void:
	_check(SupplyCatalog.is_money(&"rubles") and SupplyCatalog.is_money(&"lats") and not SupplyCatalog.is_money(&"field_dressing"), "Rubles and lats are money")
	var health := PlayerHealth.new()
	_check(health.treatment_problem(SupplyCatalog.get_def(&"rubles"), &"", 10) != "", "Money is never used like a supply")
	# Same money combines into one stack, up to a full stack; different money does not.
	var purse = Inventory.new()
	var first = purse.create_supply(&"rubles", purse.empty_location(&"", Vector2i.ONE), 300)
	var second = purse.create_supply(&"rubles", purse.empty_location(&"", Vector2i.ONE), 300)
	var coins = purse.create_supply(&"lats", purse.empty_location(&"", Vector2i.ONE), 4)
	var more_coins = purse.create_supply(&"lats", purse.empty_location(&"", Vector2i.ONE), 6)
	_check(not purse.can_merge_money_into(first.id, purse, coins.id), "Rubles and lats stay apart")
	_check(purse.merge_money_into(more_coins.id, purse, coins.id) and coins.uses == 10 and not purse.items.has(more_coins.id), "Lats combine into one stack")
	_check(purse.merge_money_into(first.id, purse, second.id) and second.uses == 500 and first.uses == 100 and purse.items.has(first.id), "Rubles combine up to a full stack; the rest stays")
	_check(not purse.can_merge_money_into(first.id, purse, second.id), "A full stack takes no more")
	# Deposit and buy.
	var runtime := Runtime.new()
	var holder := Holder.new()
	holder.inventory = Inventory.new()
	var inventory = holder.inventory
	inventory.create_supply(&"rubles", inventory.empty_location(&"", Vector2i.ONE), 70)
	inventory.create_supply(&"lats", inventory.empty_location(&"", Vector2i.ONE), 3)
	var dropped = inventory.create_supply(&"rubles", null, 25)
	_check(runtime.deposit_money(holder) and runtime.stock.count(&"rubles") == 70 and runtime.stock.count(&"lats") == 3, "Depositing moves carried money into the treasury")
	_check(not inventory.items.values().any(func(item): return item.kind == &"supply" and SupplyCatalog.is_money(item.supply_id) and inventory.carried(item)) and inventory.items.has(dropped.id), "Carried money leaves the inventory; money lying elsewhere stays")
	_check(not runtime.deposit_money(holder), "Nothing left to deposit")
	var medicine: int = runtime.stock.count(&"medicine")
	_check(runtime.buy(&"medicine", &"rubles") and runtime.stock.count(&"rubles") == 70 - int(Runtime.PRICES.medicine.rubles) and runtime.stock.count(&"medicine") == medicine + 1, "The contact sells medicine for rubles from the treasury")
	_check(runtime.buy(&"rounds", &"lats") and runtime.stock.count(&"lats") == 3 - int(Runtime.PRICES.rounds.lats), "And for lats")
	_check(Runtime.PRICES.values().all(func(offer): return offer.lats * 10 <= offer.rubles), "A lat buys at least ten rubles' worth")
	runtime.stock.quantities[&"rubles"] = 5
	_check(not runtime.buy(&"medicine", &"rubles") and runtime.stock.count(&"rubles") == 5, "Short of money, nothing is bought")
	var restored := Runtime.new()
	restored.restore(runtime.encode())
	_check(restored.stock.count(&"rubles") == 5 and restored.stock.count(&"lats") == runtime.stock.count(&"lats"), "The treasury is saved with the camp")
	# Missions pay money; regions hide it.
	_check(CATALOG.regions.any(func(region): return region.missions.any(func(mission): return mission.rewards.has("rubles") or mission.rewards.has("lats"))), "Some missions pay money")
	var region: Resource = CATALOG.regions[0]
	MissionLaunch.pending = region.compose(region.missions)
	var world = load(region.scene_path).instantiate()
	root.add_child(world)
	await _frames(8)
	var hidden: Array = get_nodes_in_group(MissionController.LOOSE_GROUP).filter(func(node): return not node.is_queued_for_deletion())
	var kinds: Array = hidden.map(func(node): return node.weapon_state.inventory.items[node.item_id].supply_id)
	_check(kinds.has(&"rubles"), "The region hides a bundle of rubles")
	var items: Array = get_nodes_in_group(MissionController.ITEM_GROUP)
	_check(hidden.all(func(node): return items.all(func(item): return item.global_position.distance_to(node.global_position) > 0.5)), "Hidden money never shares a spot with a mission item")
	# An enemy's body carries rubles.
	var enemy = world.enemies[0]
	enemy.receive_hit(200, enemy.global_position + Vector3.UP * 1.5, Vector3.FORWARD, world.player, &"head")
	await _frames(30)
	var bodies: Array = get_nodes_in_group(&"combat_loot").filter(func(node): return node.get("inventory") != null)
	_check(bodies.any(func(body): return body.inventory.items.values().any(func(item): return item.kind == &"supply" and item.supply_id == &"rubles" and item.uses > 0)), "A dead enemy carries rubles")
	world.queue_free()
	MissionLaunch.pending = null
	await _frames(3)
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: money is carried not used, deposited to the treasury, spent at fixed prices in rubles or lats, saved, hidden in regions, on enemy bodies, paid by missions")
	quit(0 if failures.is_empty() else 1)
