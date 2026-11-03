extends SceneTree
## Tab only opens and closes the inventory: holding it (key repeats) never walks keyboard focus
## through the inventory's buttons, and a single press still closes it.
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
func _tab(echo: bool, pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_TAB
	event.physical_keycode = KEY_TAB
	event.pressed = pressed
	event.echo = echo
	root.push_input(event)

func _run() -> void:
	var camp = load("res://scenes/camp/forest_camp.tscn").instantiate()
	root.add_child(camp)
	current_scene = camp
	await _frames(8)
	camp.inventory.open()
	await _frames(2)
	var view = camp.inventory.view
	# Give one button focus, as a click would, then hold Tab.
	view.close_button.grab_focus()
	await _frames(1)
	var focused: Control = root.gui_get_focus_owner()
	for i in range(12):
		_tab(true)
		await _frames(1)
	_check(camp.inventory.is_open and root.gui_get_focus_owner() == focused, "Holding Tab does not move focus through the buttons (now %s)" % root.gui_get_focus_owner())
	_tab(false, false)
	await _frames(1)
	_tab(false)
	await _frames(2)
	_check(not camp.inventory.is_open, "A single Tab press closes the inventory")
	camp.queue_free()
	await _frames(2)
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: holding Tab never cycles inventory buttons; one press closes it")
	quit(0 if failures.is_empty() else 1)
