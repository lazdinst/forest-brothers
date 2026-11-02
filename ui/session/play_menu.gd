extends Control
## Play, Valheim-style: choose or create a character, then choose, create or join a world (a
## local "server": one camp and its mission results). Characters and worlds are separate save
## files (SaveStore), so a character can join any world and brings what it carries. Appearance
## is a placeholder silhouette while character art is frozen. Emits start_requested; the startup
## router begins the session and opens the camp.
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
const SaveStore = preload("res://scripts/state/save_store.gd")
signal start_requested(character_id: String, world_id: String)
signal back_requested
const MAX_NAME := 24

var page := &"characters"
var selected_character := ""
var selected_world := ""
var heading: Label
var note: Label
var list: VBoxContainer
var name_edit: LineEdit
var create_button: Button
var continue_button: Button
var back_button: Button
var portrait: Control
var portrait_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = JournalTheme.create()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var backdrop := ColorRect.new()
	backdrop.color = Color("1d1a15")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 32)
	row.add_theme_constant_override("separation", 24)
	add_child(row)
	var left := PanelContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.4
	row.add_child(left)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	left.add_child(column)
	heading = _label(28, JournalTheme.BURGUNDY)
	column.add_child(heading)
	note = _label(16, JournalTheme.INK)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(note)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	var create_row := HBoxContainer.new()
	column.add_child(create_row)
	name_edit = LineEdit.new()
	name_edit.max_length = MAX_NAME
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_changed.connect(func(_text): _refresh_buttons())
	name_edit.text_submitted.connect(func(_text): create())
	create_row.add_child(name_edit)
	create_button = Button.new()
	create_button.pressed.connect(create)
	create_row.add_child(create_button)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)
	back_button = Button.new()
	back_button.text = "Back"
	back_button.pressed.connect(back)
	buttons.add_child(back_button)
	continue_button = Button.new()
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_button.pressed.connect(confirm)
	buttons.add_child(continue_button)
	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var portrait_column := VBoxContainer.new()
	right.add_child(portrait_column)
	portrait_label = _label(26, JournalTheme.BURGUNDY)
	portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_column.add_child(portrait_label)
	portrait = Control.new()
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.custom_minimum_size = Vector2(240, 320)
	portrait.draw.connect(_draw_portrait)
	portrait_column.add_child(portrait)
	var caption := _label(14, Color(JournalTheme.INK, 0.7))
	caption.text = "Placeholder appearance"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_column.add_child(caption)
	show_characters()

## Page one: the characters on this computer.
func show_characters() -> void:
	page = &"characters"
	heading.text = "Choose a character"
	note.text = "A character keeps what it carries and wears between outings, and brings it into any world it joins."
	name_edit.placeholder_text = "New character's name"
	create_button.text = "Create character"
	continue_button.text = "Continue"
	var records := SaveStore.list("characters")
	if not records.any(func(record): return record.id == selected_character):
		selected_character = records[0].id if not records.is_empty() else ""
	_fill(records, selected_character, func(record): return "%s\n%s" % [record.name, _carry_text(record)])

## Page two: the worlds this character can join.
func show_worlds() -> void:
	page = &"worlds"
	heading.text = "Join a world as %s" % _character_name()
	note.text = "A world is one camp with its stores, people and buildings, and its mission progress. Worlds are hosted on this computer; joining a friend's world over the network is not built yet."
	name_edit.placeholder_text = "New world's name"
	create_button.text = "Create world"
	continue_button.text = "Join world"
	var records := SaveStore.list("worlds")
	if not records.any(func(record): return record.id == selected_world):
		selected_world = records[0].id if not records.is_empty() else ""
	_fill(records, selected_world, func(record): return "%s\n%d missions completed" % [record.name, record.get("missions", {}).get("completed", []).size()])

func _fill(records: Array, chosen: String, describe: Callable) -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	if records.is_empty():
		var empty := _label(16, Color(JournalTheme.INK, 0.7))
		empty.text = "None yet. Enter a name below to create one."
		list.add_child(empty)
	for record in records:
		var entry := Button.new()
		entry.toggle_mode = true
		entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry.text = describe.call(record)
		entry.button_pressed = record.id == chosen
		entry.set_meta(&"id", record.id)
		entry.pressed.connect(choose.bind(record.id))
		list.add_child(entry)
	name_edit.text = ""
	_refresh_buttons()

## Marks a character or world (on the current page) as chosen.
func choose(id: String) -> void:
	if page == &"characters": selected_character = id
	else: selected_world = id
	for entry in list.get_children():
		if entry is Button: entry.button_pressed = entry.get_meta(&"id") == id
	_refresh_buttons()

## Creates a character or world from the typed name and chooses it.
func create() -> bool:
	var typed := name_edit.text.strip_edges()
	if typed.is_empty(): return false
	if page == &"characters":
		var record := SaveStore.create_character(typed)
		if record.is_empty(): return false
		selected_character = record.id
		show_characters()
	else:
		var record := SaveStore.create_world(typed)
		if record.is_empty(): return false
		selected_world = record.id
		show_worlds()
	return true

func confirm() -> void:
	if page == &"characters":
		if selected_character != "": show_worlds()
	elif selected_world != "":
		start_requested.emit(selected_character, selected_world)

func back() -> void:
	if page == &"worlds": show_characters()
	else: back_requested.emit()

func _refresh_buttons() -> void:
	create_button.disabled = name_edit.text.strip_edges().is_empty()
	continue_button.disabled = (selected_character if page == &"characters" else selected_world) == ""
	portrait_label.text = _character_name()
	portrait.queue_redraw()

func _character_name() -> String:
	var record := SaveStore.read("characters", selected_character) if selected_character != "" else {}
	return record.get("name", "")

static func _carry_text(record: Dictionary) -> String:
	var items: Array = record.get("equipment", {}).get("inventory", {}).get("items", [])
	return "Standard kit (new or returned without gear)" if items.is_empty() else "Carrying %d items" % items.size()

## A plain silhouette standing in for the character until appearance options exist.
func _draw_portrait() -> void:
	if selected_character == "": return
	var size := portrait.size
	var ink := Color(JournalTheme.INK, 0.75)
	var centre := Vector2(size.x / 2.0, size.y * 0.22)
	portrait.draw_circle(centre, size.y * 0.09, ink)
	var body := Rect2(Vector2(size.x / 2.0 - size.y * 0.13, size.y * 0.33), Vector2(size.y * 0.26, size.y * 0.42))
	portrait.draw_rect(body, ink)
	for side in [-1.0, 1.0]:
		portrait.draw_rect(Rect2(Vector2(size.x / 2.0 + side * size.y * 0.06 - size.y * 0.045, size.y * 0.74), Vector2(size.y * 0.09, size.y * 0.22)), ink)

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
