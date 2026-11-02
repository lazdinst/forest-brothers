extends Node
## Local scene navigation. All modal construction lives in shared UI components.
const Registry = preload("res://startup/scene_registry.gd")
const MenuModal = preload("res://ui/components/menu_modal.gd")
const TrainingUIBridge = preload("res://ui/training_ui_bridge.gd")
const InventoryHost = preload("res://ui/inventory/inventory_host.gd")
const GameSession = preload("res://scripts/state/game_session.gd")

var content: Node
var navigation: CanvasLayer
var navigation_panel
var training_ui
var training_active := false
var navigation_open := false
var confirming_leave := false
var previous_mouse_mode: int
var previous_process_mode: int
## Shared with every other scene that has a player; this router only keeps Tab precedence.
var inventory_host
var inventory_open: bool:
	get: return inventory_host != null and inventory_host.is_open
var inventory_view:
	get: return inventory_host.view if inventory_host != null else null

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
	if inventory_host != null:
		inventory_host.queue_free()
		inventory_host = null
	navigation_panel.dismiss()
	navigation_open = false
	confirming_leave = false
	training_active = false
	# Leaving the camp above saved the character and world; the session ends here.
	_replace_content(Registry.MENU)
	GameSession.end()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if content != null:
		content.play_requested.connect(show_play)
		content.training_requested.connect(_launch_sandbox)
		content.quit_requested.connect(func(): get_tree().quit())

## Training is a sandbox: it never plays a saved character or world.
func _launch_sandbox() -> void:
	GameSession.end()
	launch_training()

## Character and world selection; joining a world opens its camp.
func show_play() -> void:
	if not _replace_content(Registry.PLAY):
		show_menu()
		return
	content.back_requested.connect(show_menu)
	content.start_requested.connect(_join_world)

func _join_world(character_id: String, world_id: String) -> void:
	if GameSession.begin(character_id, world_id):
		launch_training()
	else:
		show_menu()
		content.show_message("World unavailable", "The character or world save could not be read.")

func launch_training() -> void:
	if training_active:
		return
	if _replace_content(Registry.TRAINING):
		training_active = true
		training_ui = TrainingUIBridge.new()
		training_ui.training_root = content
		content.add_child(training_ui)
		inventory_host = InventoryHost.new()
		inventory_host.handle_tab = false
		inventory_host.world = content
		inventory_host.player = content.get_node("Player")
		add_child(inventory_host)
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
	if GameSession.active():
		navigation_panel.present("Paused", "%s in %s. The camp and your equipment are saved when you leave." % [GameSession.character.name, GameSession.world.name], [
			{"id": &"resume", "caption": "Resume"},
			{"id": &"leave", "caption": "Save and return to main menu"},
			{"id": &"inventory", "caption": "Equipment & inventory"},
		])
		return
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
			if GameSession.active():
				navigation_panel.present("Leave the camp?", "Save the camp and your equipment and return to the menu?", [
					{"id": &"cancel", "caption": "Stay"},
					{"id": &"confirm_leave", "caption": "Save and return to main menu"},
				])
			else:
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
	inventory_host.open()

func close_inventory() -> void:
	if inventory_open: inventory_host.close()
