extends Node
## Standalone local training navigation, never an autoload or campaign authority.
const Registry = preload("res://startup/scene_registry.gd")
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
const MenuButtonScene = preload("res://ui/components/menu_button.tscn")

var content: Node
var navigation: CanvasLayer
var navigation_panel: Control
var resume_button: Button
var confirm_leave: ConfirmationDialog
var training_active := false
var navigation_open := false
var previous_mouse_mode: int
var previous_process_mode: int

func _ready() -> void:
	_build_navigation()
	var route := Registry.resolve_route(OS.get_cmdline_user_args(), OS.get_environment("FOREST_BROTHERS_START"))
	if route == "training":
		launch_training()
	else:
		show_menu()

func _build_navigation() -> void:
	navigation = CanvasLayer.new()
	navigation.layer = 100
	add_child(navigation)
	navigation_panel = PanelContainer.new()
	navigation_panel.theme = JournalTheme.create()
	navigation_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	navigation.add_child(navigation_panel)
	var center := CenterContainer.new()
	navigation_panel.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 450
	center.add_child(column)
	var heading := Label.new()
	heading.text = "Training paused"
	column.add_child(heading)
	resume_button = MenuButtonScene.instantiate()
	resume_button.text = "Resume training"
	column.add_child(resume_button)
	resume_button.pressed.connect(close_navigation)
	var leave := MenuButtonScene.instantiate() as Button
	leave.text = "Return to main menu"
	column.add_child(leave)
	leave.pressed.connect(func(): confirm_leave.popup_centered())
	var note := Label.new()
	note.text = "Leaving discards this training session."
	note.add_theme_font_size_override("font_size", 17)
	column.add_child(note)
	confirm_leave = ConfirmationDialog.new()
	confirm_leave.title = "Leave training?"
	confirm_leave.dialog_text = "Return to the menu and discard this training session?"
	confirm_leave.ok_button_text = "Return to menu"
	navigation.add_child(confirm_leave)
	confirm_leave.confirmed.connect(show_menu)
	confirm_leave.canceled.connect(func(): resume_button.grab_focus())
	navigation_panel.hide()

func show_menu() -> void:
	confirm_leave.hide()
	navigation_panel.hide()
	navigation_open = false
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
	else:
		show_menu()
		content.show_message("Training unavailable", "Could not load the training scene. See the Godot output for details.")

func _replace_content(path: String) -> bool:
	# Load first so a missing route cannot strand the user on an empty screen.
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
	if training_active and event.is_action_pressed("ui_cancel") and not event.is_echo():
		if confirm_leave.visible:
			confirm_leave.hide()
			resume_button.grab_focus()
		elif navigation_open:
			close_navigation()
		else:
			open_navigation()
		get_viewport().set_input_as_handled()

func open_navigation() -> void:
	if not training_active or navigation_open:
		return
	previous_mouse_mode = Input.mouse_mode
	previous_process_mode = content.process_mode
	# Disable only the owned local test scene, never SceneTree.paused.
	content.process_mode = Node.PROCESS_MODE_DISABLED
	navigation_open = true
	navigation_panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_button.grab_focus()

func close_navigation() -> void:
	if not navigation_open:
		return
	navigation_open = false
	navigation_panel.hide()
	content.process_mode = previous_process_mode
	Input.mouse_mode = previous_mouse_mode
