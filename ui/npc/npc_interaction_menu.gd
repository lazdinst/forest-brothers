extends Control
## The first window when you interact with any NPC: their name and the interactions their
## definition offers (Talk, Trade, Leave, and later others). Keyboard and mouse; Escape leaves.
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
signal action_chosen(action: StringName)
const CAPTIONS := {&"talk": "Talk", &"trade": "Trade", &"leave": "Leave", &"recruit": "Recruit",
	&"give": "Give item", &"help": "Request help", &"examine": "Examine", &"follow": "Follow", &"assign": "Assign task"}
var name_label: Label
var description_label: Label
var buttons: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = JournalTheme.create()
	var scrim := ColorRect.new()
	scrim.color = Color(0.05, 0.045, 0.035, 0.6)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	centre.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", JournalTheme.BURGUNDY)
	column.add_child(name_label)
	description_label = Label.new()
	description_label.add_theme_font_size_override("font_size", 15)
	description_label.add_theme_color_override("font_color", Color(JournalTheme.INK, 0.8))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description_label)
	buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	column.add_child(buttons)
	hide()

## Shows the NPC's name and their interactions; the first one has keyboard focus.
func present(definition) -> void:
	name_label.text = definition.full_name
	description_label.text = definition.description
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	for action in definition.actions:
		var button := Button.new()
		button.text = CAPTIONS.get(action, String(action).capitalize())
		button.custom_minimum_size.y = 44
		button.pressed.connect(func(): action_chosen.emit(action))
		buttons.add_child(button)
	show()
	if buttons.get_child_count() > 0:
		_focus.call_deferred(buttons.get_child(0))

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel") and not event.is_echo():
		action_chosen.emit(&"leave")
		get_viewport().set_input_as_handled()

## Keyboard focus for a button once it is shown; ignores buttons already gone.
func _focus(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree() and control.is_visible_in_tree():
		control.grab_focus()
