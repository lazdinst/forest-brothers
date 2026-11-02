extends SceneTree
## Escape backs out of menus: the Play screens step back a page (worlds to characters, then out
## to the main menu), the mission map leaves for camp when opened from there, and a mission world
## opens a pause menu that suspends the world, which Escape closes again.
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
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
func _escape() -> void:
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	Input.parse_input_event(escape)
	await _frames(2)
	escape.pressed = false
	Input.parse_input_event(escape)
	await _frames(1)

func _run() -> void:
	var play = load("res://ui/session/play_menu.tscn").instantiate()
	root.add_child(play)
	await _frames(2)
	var backed := [false]
	play.back_requested.connect(func(): backed[0] = true)
	play.show_worlds()
	await _escape()
	_check(play.page == &"characters" and not backed[0], "Escape on the worlds page goes back to characters")
	await _escape()
	_check(backed[0], "Escape on the characters page goes back to the main menu")
	play.queue_free()

	var board = load("res://scenes/missions/mission_board.tscn").instantiate()
	MissionLaunch.camp_scene = ""
	root.add_child(board)
	await _frames(2)
	_check(not board.back_button.visible, "The map opened directly has no way back to camp")
	board.queue_free()

	var region: Resource = CATALOG.regions[0]
	MissionLaunch.pending = region.compose(region.missions)
	var world = load(region.scene_path).instantiate()
	root.add_child(world)
	await _frames(8)
	for enemy in world.enemies:
		enemy.active = false
	await _escape()
	_check(world.pause_menu.visible and world.process_mode == Node.PROCESS_MODE_DISABLED, "Escape in a mission opens the pause menu and suspends the world")
	await _escape()
	_check(not world.pause_menu.visible and world.process_mode != Node.PROCESS_MODE_DISABLED, "Escape again resumes")
	world.pause()
	world.pause_menu.action_selected.emit(&"inventory")
	await _frames(2)
	_check(not world.pause_menu.visible and world.inventory.is_open, "The pause menu opens the inventory")
	await _escape()
	_check(not world.inventory.is_open and not world.pause_menu.visible, "Escape closes the inventory without opening the pause menu")
	MissionLaunch.pending = null
	world.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: Escape steps back through Play, and pauses and resumes a mission")
	quit(0 if failures.is_empty() else 1)
