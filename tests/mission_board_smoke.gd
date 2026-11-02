extends SceneTree
## The mission map: one pin per catalog region; choosing a pin shows the region and its missions
## (open ones ticked, completed ones disabled); results mark the missions; Deploy hands over the
## region composed with the ticked missions, or a scavenging outing when none are ticked.
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
const MissionRun = preload("res://scripts/missions/mission_run.gd")
const CATALOG = preload("res://missions/catalog.tres")
const BoardScene = preload("res://scenes/missions/mission_board.tscn")
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func _frames(count: int) -> void:
	for i in range(count):
		await process_frame
func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)

func _run() -> void:
	MissionLaunch.results.clear()
	MissionLaunch.completed.clear()
	var first: Resource = CATALOG.regions[0]
	var last: Resource = CATALOG.regions[CATALOG.regions.size() - 1]
	_check(CATALOG.regions.size() >= 2 and CATALOG.regions.all(func(region): return region.missions.size() >= 2), "Several regions, each with several missions")
	MissionLaunch.results[first.missions[1].id] = MissionRun.RETURNED
	MissionLaunch.results[first.missions[0].id] = MissionRun.SUCCESS
	MissionLaunch.completed[first.missions[0].id] = true
	var board = BoardScene.instantiate()
	root.add_child(board)
	await _frames(5)
	_check(board.pins.size() == CATALOG.regions.size(), "One pin per region")
	_check(board.selected == first and board.title_label.text == first.title, "The first region is selected at start")
	var inside := Rect2(Vector2.ZERO, board.map.size)
	_check(board.pins.values().all(func(pin): return inside.has_point(pin.position + Vector2(10, pin.size.y / 2.0))), "Pins sit on the map")
	_check(board.pins[first.id].text.contains("%d open" % (first.missions.size() - 1)), "The pin counts open missions")
	_check(board.mission_boxes[first.missions[0].id].disabled and board.mission_boxes[first.missions[0].id].text.contains("completed"), "A completed mission is no longer offered")
	_check(board.chosen() == first.missions.slice(1), "Open missions start ticked")
	_check(board.missions_list.get_children().any(func(node): return node is Label and node.text.contains("Last outing: Returned early")), "An earlier result marks its mission")
	board.pins[last.id].emit_signal("pressed")
	await _frames(2)
	_check(board.selected == last and board.title_label.text == last.title and board.description_label.text == last.description, "Choosing a pin shows that region")
	_check(board.details_label.text.contains("Time limit") and board.details_label.text.contains("Exits: " + last.exit_names[0]) and board.details_label.text.contains("Expected resistance"), "The region lists time limit, exits and resistance")
	_check(last.missions.all(func(mission): return board.details_label.text.contains("bring out " + mission.objectives[0].label)), "Every ticked mission's objective is listed")
	board.mission_boxes[last.missions[0].id].button_pressed = false
	await _frames(1)
	_check(not board.details_label.text.contains("bring out " + last.missions[0].objectives[0].label), "Unticking a mission drops its objective")
	var handed := {"region": null, "chosen": []}
	board.deploy_requested.connect(func(region, picked): handed.region = region; handed.chosen = picked)
	board.deploy_button.emit_signal("pressed")
	var outing: Resource = MissionLaunch.pending
	_check(handed.region == last and handed.chosen == last.missions.slice(1), "Deploy hands over the region and the ticked missions")
	_check(outing != null and outing.region == last and outing.missions == last.missions.slice(1) and outing.objectives.size() == last.missions.size() - 1 and outing.time_limit_seconds == last.time_limit_seconds, "The outing combines the region's rules with the ticked missions")
	_check(outing.enemy_groups.size() > 0 and last.enemy_count(handed.chosen) == outing.enemy_groups.values().reduce(func(sum, value): return sum + value, 0), "The outing posts the region's enemies plus the missions'")
	for mission in last.missions:
		board.mission_boxes[mission.id].button_pressed = false
	await _frames(1)
	_check(board.deploy_button.text.contains("scavenging"), "No mission ticked is a scavenging outing")
	board.deploy_button.emit_signal("pressed")
	_check(MissionLaunch.pending.objectives.is_empty() and MissionLaunch.pending.missions.is_empty(), "A scavenging outing has no objectives")
	MissionLaunch.pending = null
	MissionLaunch.results.clear()
	MissionLaunch.completed.clear()
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: pins per region, missions ticked or completed, results marked, deploy composes the region with the ticked missions or scavenging")
	board.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
