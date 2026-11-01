extends VBoxContainer
## Reusable action list. Views provide IDs/captions; this owns button creation.
signal action_selected(action_id: StringName)

const ButtonScene = preload("res://ui/components/menu_button.tscn")
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")

func _init() -> void:
	theme = JournalTheme.create()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func add_action(action_id: StringName, caption: String, enabled := true, hint := "") -> Button:
	var button := ButtonScene.instantiate() as Button
	button.text = caption
	button.disabled = not enabled
	button.tooltip_text = hint
	button.pressed.connect(func(): action_selected.emit(action_id))
	add_child(button)
	_update_focus_links()
	return button

func _update_focus_links() -> void:
	var enabled_buttons: Array[Button] = []
	for button in get_children():
		if button is Button and not button.disabled:
			enabled_buttons.append(button)
	for index in range(enabled_buttons.size()):
		var button := enabled_buttons[index]
		var next := enabled_buttons[(index + 1) % enabled_buttons.size()]
		var previous := enabled_buttons[(index - 1 + enabled_buttons.size()) % enabled_buttons.size()]
		button.focus_next = button.get_path_to(next)
		button.focus_previous = button.get_path_to(previous)
		button.focus_neighbor_bottom = button.focus_next
		button.focus_neighbor_top = button.focus_previous

func clear_actions() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

static func style_existing_button(button: Button) -> void:
	# Compatibility for existing training views, preserving their action callbacks.
	button.theme = JournalTheme.create()
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 48)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
