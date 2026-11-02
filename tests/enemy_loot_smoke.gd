extends SceneTree
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
func _loot_rounds() -> int:
	var total := 0
	var seen := {}
	for pickup in get_nodes_in_group(&"combat_loot"):
		var inventory = pickup.weapon_state.inventory
		if seen.has(inventory):
			continue
		seen[inventory] = true
		total += inventory.total_rounds()
	return total
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
	# Downed is not dead: nothing drops yet.
	target.receive_hit(100, target.global_position + Vector3.UP, Vector3.FORWARD, player, &"torso")
	await _frames(2)
	_check(get_nodes_in_group(&"combat_loot").is_empty(), "A downed enemy keeps its gear")
	target.receive_hit(1, target.global_position, Vector3.FORWARD, player, &"legs")
	await _frames(3)
	var pickups := get_nodes_in_group(&"combat_loot")
	_check(pickups.size() == 3, "Dead enemy drops each magazine it carried (%d)" % pickups.size())
	_check(_loot_rounds() == carried_before and target.total_rounds() == 0, "Dropped rounds equal what the enemy carried")
	_check(pickups.all(func(p): return p.global_position.distance_to(target.global_position) < 1.5), "Loot lies at the body")
	# Recover one magazine into the player's carried inventory.
	var player_inventory = player.weapon.state.inventory
	var player_before: int = player_inventory.total_rounds()
	var first = pickups[0]
	var first_id: StringName = first.item_id
	var moved: int = first.weapon_state.inventory.magazine(first.item_id).rounds.size()
	var loot_before := _loot_rounds()
	first.interact(player)
	await _frames(2)
	if player_inventory.items.has(first_id):
		_check(player_inventory.total_rounds() == player_before + moved, "Recovered magazine keeps its exact rounds")
		_check(_loot_rounds() == loot_before - moved, "Recovered rounds leave the ground")
		_check(not is_instance_valid(first) or first.is_queued_for_deletion(), "Recovered pickup disappears")
	else:
		_check(player.weapon.state.message != "", "Full inventory refuses recovery with a message")
	# Reset clears remaining loot so repeated drills cannot duplicate ammunition.
	arena.reset_enemies()
	await _frames(3)
	_check(get_nodes_in_group(&"combat_loot").is_empty(), "Arena reset removes leftover loot")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: no drop while downed, magazines drop on death, rounds conserved, recover with exact rounds, reset clears loot")
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
