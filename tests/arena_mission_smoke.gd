extends SceneTree
## The arena hosting a mission through the generic controller: the definition's objective item
## lies at one of the map's tagged spots, the HUD reads "find" then "take it to an exit",
## standing in the exit leaves (stepping out resets), leaving with the item completes, leaving
## without it returns early, death leaves it on the body, and each end shows the shared summary.
const MissionRun = preload("res://scripts/missions/mission_run.gd")
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
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
func _calm(arena) -> void:
	for enemy in arena.enemies:
		enemy.active = false
func _item(arena) -> Node3D:
	return arena.get_tree().get_nodes_in_group(arena.MissionController.ITEM_GROUP).filter(func(node): return not node.is_queued_for_deletion())[0]

func _run() -> void:
	var arena = load("res://scenes/combat/combat_arena.tscn").instantiate()
	root.add_child(arena)
	await _frames(10)
	_calm(arena)
	var player = arena.player
	var inventory = player.weapon.state.inventory
	var mission = arena.mission
	var run = mission.run
	var id: StringName = mission.participant_id(player)
	var dispatch := _item(arena)
	_check(run.participants.size() == 1 and run.state_of(id) == MissionRun.ACTIVE, "The mission starts with the player as its participant")
	_check(arena.DISPATCH_SPOTS.any(func(spot): return spot.distance_to(dispatch.global_position) < 0.01), "The objective item lies at one of the map's tagged spots")
	await _frames(2)
	_check(mission.hud.text.contains("Find the sealed dispatch"), "The HUD says to find the dispatch")
	# Leaving early without the dispatch.
	player.global_position = arena.EXIT_AT + Vector3(0, 0.02, 0)
	await _frames(60)
	_check(mission.hud.text.contains("Leaving in") and mission.hud.text.contains("objectives incomplete"), "In the exit a countdown shows, warning the objective is incomplete")
	await _frames(60 * 5)
	_check(run.state_of(id) == MissionRun.EXTRACTED and run.outcome() == MissionRun.RETURNED, "Five seconds in the exit leaves the area: an early return")
	_check(mission.summary_screen.visible and mission.summary_screen.headline.text == "Returned to camp" and mission.summary_screen.text().contains("Not recovered"), "The shared summary shows the early return")
	_check(arena.enemies.all(func(enemy): return not enemy.active), "Enemies stand down when nobody is left in the area")
	# A fresh outing: carry the dispatch out.
	arena.restart()
	await _frames(5)
	_calm(arena)
	run = mission.run
	_check(run.state_of(id) == MissionRun.ACTIVE and not mission.summary_screen.visible, "Going again starts a fresh outing")
	dispatch = _item(arena)
	player.global_position = dispatch.global_position + Vector3(0, 0.02, 0.8)
	dispatch.interact(player)
	await _frames(3)
	_check(MissionRun.carries(inventory, &"sealed_dispatch") and mission.hud.text.contains("Take the sealed dispatch to an exit"), "Picked up, the HUD says to take it to an exit")
	_check(player.body.treatment_problem(SupplyCatalog.get_def(&"sealed_dispatch"), &"", 1) != "", "The dispatch cannot be used like a supply")
	player.global_position = arena.EXIT_AT + Vector3(0, 0.02, 0)
	await _frames(60 * 3)
	player.global_position = arena.EXIT_AT + Vector3(6, 0.02, 0)
	await _frames(5)
	_check(run.state_of(id) == MissionRun.ACTIVE and run.participants[id].exit_left < 0.0, "Stepping out of the exit cancels leaving")
	player.global_position = arena.EXIT_AT + Vector3(0, 0.02, 0)
	await _frames(60 * 6)
	_check(run.outcome() == MissionRun.SUCCESS and mission.summary_screen.headline.text == "Mission complete" and mission.summary_screen.text().contains("Carried out") and mission.summary_screen.text().contains("forest path"), "Leaving with the dispatch completes the mission")
	# Death while carrying it.
	arena.restart()
	await _frames(5)
	_calm(arena)
	run = mission.run
	dispatch = _item(arena)
	player.global_position = dispatch.global_position + Vector3(0, 0.02, 0.8)
	dispatch.interact(player)
	await _frames(3)
	player.receive_hit(60, player.global_position + Vector3.UP * 1.7, Vector3.FORWARD, null, &"head")
	await _frames(3)
	_check(run.state_of(id) == MissionRun.KILLED and run.outcome() == MissionRun.FAILED and mission.summary_screen.headline.text == "Killed in action", "Death ends the outing with the shared summary")
	_check(MissionRun.carries(inventory, &"sealed_dispatch") and mission.summary_screen.text().contains("On a fallen body") and mission.summary_screen.text().contains("Left on your body"), "The dispatch stays with the carried gear on the body")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: controller places the item at a tagged spot, HUD find/take, early return, complete, exit reset, death on body, shared summary")
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
