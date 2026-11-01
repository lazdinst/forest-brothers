extends Control
## One modal surface, including confirmation. Present replaces its content in place.
signal action_selected(action_id: StringName)
signal canceled

const MenuPanel = preload("res://ui/components/menu_panel.gd")
const MenuActions = preload("res://ui/components/menu_actions.gd")
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")

var heading: Label
var message: Label
var actions
var panel: PanelContainer
var scroll: ScrollContainer
var _previous_focus: WeakRef

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = JournalTheme.create()
	var scrim := ColorRect.new()
	scrim.color = JournalTheme.SCRIM
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = MenuPanel.new()
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 29)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(heading)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message.add_theme_font_size_override("font_size", 19)
	scroll.add_child(message)
	actions = MenuActions.new()
	column.add_child(actions)
	actions.action_selected.connect(func(action_id): action_selected.emit(action_id))
	resized.connect(_fit_panel)
	_fit_panel()
	hide()

func _fit_panel() -> void:
	panel.custom_minimum_size.x = minf(680, maxf(240, size.x - 48))

func present(caption: String, text: String, choices: Array) -> void:
	if not visible:
		var focused := get_viewport().gui_get_focus_owner()
		_previous_focus = weakref(focused) if focused != null else null
	heading.text = caption
	message.text = text
	scroll.scroll_vertical = 0
	# Short confirmations stay compact; long help text scrolls inside the same frame.
	scroll.custom_minimum_size.y = minf(260, maxf(60, text.split("\n").size() * 28 + ceilf(text.length() / 72.0) * 22))
	actions.clear_actions()
	for choice in choices:
		actions.add_action(choice.id, choice.caption)
	show()
	if actions.get_child_count() > 0:
		actions.get_child(0).grab_focus()

func dismiss() -> void:
	hide()
	if _previous_focus != null:
		var previous = _previous_focus.get_ref()
		if is_instance_valid(previous) and previous.is_visible_in_tree():
			previous.grab_focus()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel") and not event.is_echo():
		canceled.emit()
		get_viewport().set_input_as_handled()
