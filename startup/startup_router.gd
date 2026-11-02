extends Node
## Local scene navigation. All modal construction lives in shared UI components.
const Registry = preload("res://startup/scene_registry.gd")
const MenuModal = preload("res://ui/components/menu_modal.gd")
const TrainingUIBridge = preload("res://ui/training_ui_bridge.gd")
const InventoryScene = preload("res://ui/inventory/inventory_view.tscn")
const InventorySnapshot = preload("res://ui/inventory/inventory_snapshot.gd")

var content: Node
var navigation: CanvasLayer
var navigation_panel
var training_ui
var training_active := false
var navigation_open := false
var confirming_leave := false
var previous_mouse_mode: int
var previous_process_mode: int
var inventory_open := false
var inventory_layer: CanvasLayer
var inventory_view

func _ready() -> void:
	navigation = CanvasLayer.new()
	navigation.layer = 100
	add_child(navigation)
	navigation_panel = MenuModal.new()
	navigation.add_child(navigation_panel)
	navigation_panel.action_selected.connect(_navigation_action)
	navigation_panel.canceled.connect(_cancel_navigation)
	var route := Registry.resolve_route(OS.get_cmdline_user_args(), OS.get_environment("FOREST_BROTHERS_START"))
	if route == "training":
		launch_training()
	else:
		show_menu()

func show_menu() -> void:
	if inventory_open: close_inventory()
	navigation_panel.dismiss()
	navigation_open = false
	confirming_leave = false
	training_active = false
	_replace_content(Registry.MENU)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if content != null:
		content.training_requested.connect(launch_training)
		content.quit_requested.connect(func(): get_tree().quit())

func launch_training() -> void:
	if training_active:
		return
	if _replace_content(Registry.TRAINING):
		training_active = true
		training_ui = TrainingUIBridge.new()
		training_ui.training_root = content
		content.add_child(training_ui)
	else:
		show_menu()
		content.show_message("Training unavailable", "Could not load the training scene. See the Godot output for details.")

func _replace_content(path: String) -> bool:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Startup could not load: " + path)
		return false
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content = packed.instantiate()
	add_child(content)
	return true

func _input(event: InputEvent) -> void:
	if inventory_open:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
			close_inventory()
			get_viewport().set_input_as_handled()
		return
	if training_active and not navigation_open and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		if not is_instance_valid(training_ui) or not training_ui.has_active_context():
			open_inventory()
			get_viewport().set_input_as_handled()
		return
	if not training_active or not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	# Camp panels and planning get their existing Escape first. Never stack pause UI.
	if not navigation_open and is_instance_valid(training_ui) and training_ui.has_active_context():
		return
	if navigation_open:
		_cancel_navigation()
	else:
		open_navigation()
	get_viewport().set_input_as_handled()

func open_navigation() -> void:
	if not training_active or navigation_open:
		return
	if is_instance_valid(training_ui) and training_ui.has_active_context():
		return
	previous_mouse_mode = Input.mouse_mode
	previous_process_mode = content.process_mode
	content.process_mode = Node.PROCESS_MODE_DISABLED
	navigation_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_present_pause()

func _present_pause() -> void:
	confirming_leave = false
	navigation_panel.present("Training paused", "Leaving discards this training session.", [
		{"id": &"resume", "caption": "Resume training"},
		{"id": &"leave", "caption": "Return to main menu"},
		{"id": &"inventory", "caption": "Equipment & inventory"},
	])

func _navigation_action(action_id: StringName) -> void:
	match action_id:
		&"inventory": open_inventory()
		&"resume": close_navigation()
		&"leave":
			confirming_leave = true
			# Replace the existing surface rather than opening a second dialog over it.
			navigation_panel.present("Leave training?", "Return to the menu and discard this training session?", [
				{"id": &"cancel", "caption": "Keep training"},
				{"id": &"confirm_leave", "caption": "Return to main menu"},
			])
		&"cancel": _present_pause()
		&"confirm_leave": show_menu()

func _cancel_navigation() -> void:
	if confirming_leave:
		_present_pause()
	else:
		close_navigation()

func close_navigation() -> void:
	if not navigation_open:
		return
	navigation_open = false
	confirming_leave = false
	navigation_panel.dismiss()
	content.process_mode = previous_process_mode
	Input.mouse_mode = previous_mouse_mode

func open_inventory() -> void:
	if not training_active or inventory_open:
		return
	if is_instance_valid(training_ui) and training_ui.has_active_context():
		return
	if navigation_open: close_navigation()
	content.get_node("Player").weapon.prepare_inventory()
	previous_process_mode = content.process_mode
	previous_mouse_mode = Input.mouse_mode
	content.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	inventory_layer = CanvasLayer.new()
	inventory_layer.layer = 110
	add_child(inventory_layer)
	inventory_view = InventoryScene.instantiate()
	inventory_view.data = InventorySnapshot.from_training(content.get_node("Player"))
	inventory_view.drop_requested.connect(content.get_node("Player").weapon.drop_inventory_item)
	inventory_layer.add_child(inventory_view)
	inventory_view.closed.connect(close_inventory)
	inventory_open = true

func close_inventory() -> void:
	if not inventory_open: return
	inventory_open = false
	remove_child(inventory_layer)
	inventory_layer.queue_free()
	content.process_mode = previous_process_mode
	Input.mouse_mode = previous_mouse_mode
