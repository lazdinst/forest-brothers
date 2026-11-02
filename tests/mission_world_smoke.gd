extends SceneTree
## Every region's world plays its missions together: each objective item lies at a spot with its
## tag (different spots), the region's and missions' enemies stand at their tagged posts, the
## exits exist, and the HUD names every objective. Carrying one of two items out completes that
## mission only; the shared summary lists both missions, leads back to the mission map, and the
## results are kept for the map. A scavenging outing has no objectives.
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
const MissionRun = preload("res://scripts/missions/mission_run.gd")
const MissionController = preload("res://scripts/missions/mission_controller.gd")
const ObjectiveSpot = preload("res://scripts/missions/objective_spot.gd")
const MissionExit = preload("res://scripts/missions/mission_exit.gd")
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

func _live(group: StringName) -> Array:
	return get_nodes_in_group(group).filter(func(node): return not node.is_queued_for_deletion())

func _run() -> void:
	MissionLaunch.results.clear()
	MissionLaunch.completed.clear()
	for region in CATALOG.regions:
		var name: String = region.id
		MissionLaunch.pending = region.compose(region.missions)
		var world = load(region.scene_path).instantiate()
		root.add_child(world)
		await _frames(8)
		var outing: Resource = world.definition
		_check(world.mission.run.definition == outing and outing.missions == region.missions, "%s: the world plays the handed-over outing" % name)
		var items: Array = _live(MissionController.ITEM_GROUP)
		_check(items.size() == outing.objectives.size(), "%s: one item per objective" % name)
		var spots: Array = _live(ObjectiveSpot.GROUP)
		for objective in outing.objectives:
			var tagged: Array = spots.filter(func(spot): return spot.tag == objective.spot_tag)
			_check(tagged.size() >= 2 and items.any(func(item): return tagged.any(func(spot): return spot.global_position.distance_to(item.global_position) < 0.01)), "%s: %s lies at one of several spots tagged %s" % [name, objective.label, objective.spot_tag])
			_check(world.mission.hud.text.contains("Find " + objective.label), "%s: the HUD names %s" % [name, objective.label])
		var wanted: int = region.enemy_count(region.missions)
		_check(world.enemies.size() == wanted, "%s: %d enemies posted (wanted %d)" % [name, world.enemies.size(), wanted])
		var exits: Array = _live(MissionExit.GROUP)
		_check(exits.size() == region.exit_names.size() and exits.all(func(exit): return region.exit_names.has(exit.label)), "%s: the exits named on the map" % name)
		# Carry out the first mission's item only.
		for enemy in world.enemies:
			enemy.active = false
		var player = world.player
		var first: Resource = region.missions[0]
		var item = items.filter(func(node): return node.weapon_state.inventory.items[node.item_id].supply_id == first.objectives[0].item_id)[0]
		player.global_position = item.global_position + Vector3(0, 0.02, 0.8)
		item.interact(player)
		await _frames(3)
		player.global_position = exits[0].global_position + Vector3(0, 0.02, 0)
		await _frames(60 * 6)
		var summary = world.mission.summary_screen
		var text: String = summary.text() if summary.visible else ""
		_check(world.mission.run.outcome() == MissionRun.RETURNED and summary.visible and summary.continue_button.text == "Return to the mission map", "%s: leaving with one of two items is an early return with the summary and a way back" % name)
		_check(text.contains(first.title) and text.contains(region.missions[1].title) and text.contains("Not completed"), "%s: the summary lists each mission taken" % name)
		_check(first.reward_text() != "" and text.contains("camp receives " + first.reward_text()), "%s: the summary names the completed mission's reward" % name)
		_check(MissionLaunch.results.get(first.id) == MissionRun.SUCCESS and MissionLaunch.completed.has(first.id), "%s: the carried-out mission is completed" % name)
		_check(MissionLaunch.results.get(region.missions[1].id) == MissionRun.RETURNED and not MissionLaunch.completed.has(region.missions[1].id), "%s: the other mission stays open" % name)
		world.queue_free()
		await _frames(3)
	# Scavenging: no missions, no items, the HUD says so.
	var region: Resource = CATALOG.regions[0]
	MissionLaunch.pending = region.compose([])
	var world = load(region.scene_path).instantiate()
	root.add_child(world)
	await _frames(8)
	_check(_live(MissionController.ITEM_GROUP).is_empty() and world.enemies.size() == region.enemy_count([]) and world.mission.hud.text.contains("Scavenging"), "A scavenging outing: no items, the region's own enemies, a HUD line")
	world.queue_free()
	await _frames(3)
	MissionLaunch.pending = null
	MissionLaunch.results.clear()
	MissionLaunch.completed.clear()
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: every region plays its missions together: tagged items and enemies, exits, HUD, per-mission results in the summary and for the map, scavenging")
	quit(0 if failures.is_empty() else 1)
