extends SceneTree
## The mission world plays every mission in the catalog: the objective item lies at a spot with
## the mission's tag, the requested enemies stand at their tagged posts, both exits exist, and
## carrying the item out ends with the shared summary, a button back to the mission map, and
## the result recorded for the map.
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
const MissionRun = preload("res://scripts/missions/mission_run.gd")
const MissionController = preload("res://scripts/missions/mission_controller.gd")
const ObjectiveSpot = preload("res://scripts/missions/objective_spot.gd")
const MissionExit = preload("res://scripts/missions/mission_exit.gd")
const CATALOG = preload("res://missions/catalog.tres")
const WorldScene = preload("res://scenes/missions/mission_world.tscn")
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
	_check(CATALOG.missions.size() >= 3, "The catalog offers several missions")
	for definition in CATALOG.missions:
		MissionLaunch.pending = definition
		var world = WorldScene.instantiate()
		root.add_child(world)
		await _frames(8)
		var name: String = definition.id
		_check(world.definition == definition and world.mission.run.definition == definition, "%s: the world plays the handed-over mission" % name)
		var items: Array = get_nodes_in_group(MissionController.ITEM_GROUP).filter(func(node): return not node.is_queued_for_deletion())
		var tagged: Array = get_nodes_in_group(ObjectiveSpot.GROUP).filter(func(spot): return spot.tag == definition.objectives[0].spot_tag)
		_check(items.size() == 1 and tagged.any(func(spot): return spot.global_position.distance_to(items[0].global_position) < 0.01), "%s: the objective item lies at a spot tagged %s" % [name, definition.objectives[0].spot_tag])
		var wanted := 0
		for tag in definition.enemy_groups:
			wanted += int(definition.enemy_groups[tag])
		_check(world.enemies.size() == wanted, "%s: %d enemies posted (wanted %d)" % [name, world.enemies.size(), wanted])
		_check(get_nodes_in_group(MissionExit.GROUP).size() == 2, "%s: two exits" % name)
		_check(world.mission.hud.text.contains("Find " + definition.objectives[0].label), "%s: the HUD names the objective" % name)
		if definition == CATALOG.missions[0]:
			# Carry it out: the summary leads back to the mission map and the result is kept.
			for enemy in world.enemies:
				enemy.active = false
			var player = world.player
			player.global_position = items[0].global_position + Vector3(0, 0.02, 0.8)
			items[0].interact(player)
			await _frames(3)
			player.global_position = Vector3(-64, 0.02, 0)
			await _frames(60 * 6)
			var summary = world.mission.summary_screen
			_check(world.mission.run.outcome() == MissionRun.SUCCESS and summary.visible and summary.continue_button.text == "Return to the mission map", "%s: carrying it out ends with the summary and a way back to the map" % name)
			_check(MissionLaunch.results.get(definition.id) == MissionRun.SUCCESS, "%s: the result is kept for the mission map" % name)
		world.queue_free()
		await _frames(3)
	MissionLaunch.pending = null
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: every catalog mission plays in the world: item at a tagged spot, tagged enemies, exits, HUD, extraction summary back to the map, result kept")
	quit(0 if failures.is_empty() else 1)
