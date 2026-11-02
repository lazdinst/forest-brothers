extends SceneTree
## The camp connects to the missions: the HQ's mission-planning table opens the mission map,
## the map leads back to camp, an outing deployed from the map returns to camp after its
## summary, the combat arena opened from camp returns there too, and through startup the
## return lands in the camp route rather than the main menu.
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
const CAMP := "res://scenes/prototype/camp_test.tscn"
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

func _press(annex, caption: String) -> bool:
	for button in annex._actions.get_children():
		if button is Button and button.text.begins_with(caption):
			button.emit_signal("pressed")
			return true
	return false

func _open_camp() -> Node:
	change_scene_to_file(CAMP)
	await _frames(14)
	return current_scene

func _run() -> void:
	MissionLaunch.camp_scene = ""
	MissionLaunch.completed.clear()
	var camp: Node = await _open_camp()
	var annex = camp.get_node("SystemsAnnex")
	annex.open_station(annex.stations[&"hq"], camp.get_node("Player"))
	await _frames(2)
	_check(_press(annex, "Open the mission map"), "The HQ offers the mission map")
	await _frames(6)
	var board: Node = current_scene
	_check(board != null and board.scene_file_path == MissionLaunch.BOARD_SCENE and MissionLaunch.camp_scene == CAMP, "The mission map opens and remembers the camp")
	_check(board.back_button.visible, "The map offers a way back to camp")
	board.back_button.emit_signal("pressed")
	await _frames(14)
	_check(current_scene != null and current_scene.scene_file_path == CAMP, "Back to camp from the map")
	# Plan a scavenging outing in the forest and come back through the summary.
	annex = current_scene.get_node("SystemsAnnex")
	annex.open_station(annex.stations[&"hq"], current_scene.get_node("Player"))
	await _frames(2)
	_press(annex, "Open the mission map")
	await _frames(6)
	board = current_scene
	var region: Resource = board.catalog.regions[board.catalog.regions.size() - 1]
	board.select(region.id)
	for box in board.mission_boxes.values():
		box.button_pressed = false
	board.deploy_button.emit_signal("pressed")
	await _frames(14)
	var world: Node = current_scene
	_check(world != null and world.scene_file_path == region.scene_path and world.mission.continue_text == "Return to camp", "Deploying opens the region; its summary leads back to camp")
	for enemy in world.enemies:
		enemy.active = false
	var exit: Node3D = get_nodes_in_group(&"mission_exits")[0] if not get_nodes_in_group(&"mission_exits").is_empty() else null
	_check(exit != null, "The region has an exit")
	if exit != null:
		world.player.global_position = exit.global_position + Vector3(0, 0.02, 0)
		await _frames(60 * 6)
		_check(world.mission.summary_screen.visible, "Leaving shows the summary")
		world.mission.summary_screen.continue_button.emit_signal("pressed")
		await _frames(14)
		_check(current_scene != null and current_scene.scene_file_path == CAMP, "After the summary the player is back at camp")
	# The combat arena from camp.
	annex = current_scene.get_node("SystemsAnnex")
	annex.open_station(annex.stations[&"hq"], current_scene.get_node("Player"))
	await _frames(2)
	_check(_press(annex, "Combat arena"), "The HQ offers the combat arena")
	await _frames(14)
	var arena: Node = current_scene
	_check(arena != null and arena.scene_file_path == "res://scenes/combat/combat_arena.tscn" and arena.mission.continue_text == "Return to camp", "The arena opened from camp leads back to camp")
	# Through startup the camp is the training route, not the main menu.
	MissionLaunch.camp_scene = MissionLaunch.STARTUP_SCENE
	MissionLaunch.return_to_camp(self)
	await _frames(14)
	_check(current_scene != null and current_scene.scene_file_path == MissionLaunch.STARTUP_SCENE and current_scene.training_active, "Returning through startup opens the camp")
	OS.set_environment("FOREST_BROTHERS_START", "")
	MissionLaunch.camp_scene = ""
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: camp HQ opens the mission map and arena; map, outing summary and arena lead back to camp, also through startup")
	quit(0 if failures.is_empty() else 1)
