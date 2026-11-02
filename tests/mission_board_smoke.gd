extends SceneTree
## The mission map: one pin per catalog mission, choosing a pin shows its briefing, results from
## earlier outings mark pins and briefings, and Deploy hands the chosen definition over.
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
	MissionLaunch.record(CATALOG.missions[1], MissionRun.RETURNED)
	var board = BoardScene.instantiate()
	root.add_child(board)
	await _frames(5)
	_check(board.pins.size() == CATALOG.missions.size(), "One pin per mission")
	_check(board.selected == CATALOG.missions[0] and board.title_label.text == CATALOG.missions[0].title, "The first mission is selected at start")
	var inside := Rect2(Vector2.ZERO, board.map.size)
	_check(board.pins.values().all(func(pin): return inside.has_point(pin.position + Vector2(10, pin.size.y / 2.0))), "Pins sit on the map")
	var last: Resource = CATALOG.missions[CATALOG.missions.size() - 1]
	board.pins[last.id].emit_signal("pressed")
	await _frames(2)
	_check(board.selected == last and board.title_label.text == last.title and board.briefing_label.text == last.briefing, "Choosing a pin shows that mission's briefing")
	_check(board.details_label.text.contains("Objective: bring out " + last.objectives[0].label) and board.details_label.text.contains("Time limit") and board.details_label.text.contains("Expected resistance"), "The briefing lists objective, time limit and resistance")
	_check(board.pins[CATALOG.missions[1].id].text.contains("returned early"), "An earlier result marks the pin")
	board.select(CATALOG.missions[1].id)
	_check(board.details_label.text.contains("Last outing: Returned early"), "And the briefing")
	var handed := {"definition": null}
	board.deploy_requested.connect(func(definition): handed.definition = definition)
	board.deploy_button.emit_signal("pressed")
	_check(handed.definition == CATALOG.missions[1] and MissionLaunch.pending == CATALOG.missions[1], "Deploy hands the chosen mission over")
	MissionLaunch.pending = null
	MissionLaunch.results.clear()
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: pins per mission on the map, briefing per pin, results marked, deploy hands over the definition")
	board.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
