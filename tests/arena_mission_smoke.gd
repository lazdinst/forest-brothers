extends SceneTree
## The arena outing: the dispatch lies at one of the spots, the objective reads "find" then
## "reach the exit", standing 5 s in the exit leaves (stepping out resets the count), leaving
## with the dispatch completes, leaving without it is an early return, death leaves the dispatch
## on the body, and each end stops the enemies and shows a debrief.
const ArenaMission = preload("res://scripts/combat/arena_mission.gd")
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

func _run() -> void:
	var arena = load("res://scenes/combat/combat_arena.tscn").instantiate()
	root.add_child(arena)
	await _frames(10)
	_calm(arena)
	var player = arena.player
	var inventory = player.weapon.state.inventory
	var mission = arena.mission
	_check(mission.state == ArenaMission.ACTIVE and is_instance_valid(arena.document), "An outing starts with the dispatch placed")
	_check(arena.DOCUMENT_SPOTS.any(func(spot): return spot.distance_to(arena.document.position) < 0.01), "The dispatch lies at one of the hiding spots")
	_check(arena._objective.text.contains("find the sealed dispatch"), "The objective says to find the dispatch")
	# Leaving early without the dispatch.
	player.global_position = arena.EXIT_AT + Vector3(0, 0.02, 0)
	await _frames(60)
	_check(arena._objective.text.contains("Leaving in") and arena._objective.text.contains("without"), "In the exit a countdown shows, warning there is no dispatch")
	await _frames(60 * 5)
	_check(mission.state == ArenaMission.LEFT and arena.debrief.visible and arena.debrief.headline.text.contains("without"), "Five seconds in the exit leaves the area: early return debrief")
	_check(arena.enemies.all(func(enemy): return not enemy.active), "Enemies stand down when the outing ends")
	_check(not arena.debrief.summary.text.is_empty() and arena.debrief.summary.text.contains("Rounds carried"), "The debrief summarises the outing")
	# A fresh outing: pick the dispatch up and carry it out.
	arena.restart()
	await _frames(5)
	_calm(arena)
	mission = arena.mission
	_check(mission.state == ArenaMission.ACTIVE and not arena.debrief.visible, "Going again starts a fresh outing")
	player.global_position = arena.document.global_position + Vector3(0, 0.02, 0.8)
	arena.document.interact(player)
	await _frames(3)
	_check(ArenaMission.carries_document(inventory), "Picking up the dispatch puts it in the player's inventory")
	var dispatch = inventory.items.values().filter(func(item): return item.kind == &"supply" and item.supply_id == ArenaMission.DOCUMENT)[0]
	_check(player.body.treatment_problem(arena.ArenaMission.SupplyCatalog.get_def(dispatch.supply_id), &"", 1) != "", "The dispatch cannot be used like a supply")
	_check(arena._objective.text.contains("reach the exit"), "The objective now says to reach the exit")
	# Stepping out resets the countdown.
	player.global_position = arena.EXIT_AT + Vector3(0, 0.02, 0)
	await _frames(60 * 3)
	player.global_position = arena.EXIT_AT + Vector3(6, 0.02, 0)
	await _frames(5)
	_check(mission.state == ArenaMission.ACTIVE and mission.exit_left < 0.0, "Stepping out of the exit cancels leaving")
	player.global_position = arena.EXIT_AT + Vector3(0, 0.02, 0)
	await _frames(60 * 3)
	_check(mission.state == ArenaMission.ACTIVE, "Coming back starts the count again")
	await _frames(60 * 3)
	_check(mission.state == ArenaMission.COMPLETE and arena.debrief.headline.text.contains("recovered"), "Leaving with the dispatch completes the mission")
	# Death while carrying it: the dispatch stays on the body.
	arena.restart()
	await _frames(5)
	_calm(arena)
	mission = arena.mission
	player.global_position = arena.document.global_position + Vector3(0, 0.02, 0.8)
	arena.document.interact(player)
	await _frames(3)
	player.receive_hit(60, player.global_position + Vector3.UP * 1.7, Vector3.FORWARD, null, &"head")
	await _frames(3)
	_check(mission.state == ArenaMission.KILLED and arena.debrief.headline.text.contains("Killed"), "Death ends the outing with a debrief")
	_check(ArenaMission.carries_document(inventory) and arena.debrief.summary.text.contains("including the dispatch"), "The dispatch stays with the carried gear on the body")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: dispatch placed at a spot, find/exit objective, leave early, carry out to complete, exit count resets, death leaves it on the body, debriefs")
	arena.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
