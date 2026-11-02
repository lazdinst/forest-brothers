extends Control
## The dialogue window for any NPC, driven by a DialogueController. Two views: choosing a topic
## (categories and the topics within them) and the conversation (portrait, name, the NPC's
## current line, your possible replies, Back and Goodbye). Muted parchment styling, a short fade,
## keyboard and mouse: number keys pick a reply, Escape goes back a step and then closes.
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
signal closed
var controller
var definition
var portrait: TextureRect
var silhouette: Control
var name_label: Label
var description_label: Label
var speech: Label
var replies: VBoxContainer
var categories: HBoxContainer
var topic_list: VBoxContainer
var conversation_box: VBoxContainer
var topics_box: VBoxContainer
var back_button: Button
var goodbye_button: Button
var continue_button: Button
var category := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = JournalTheme.create()
	var scrim := ColorRect.new()
	scrim.color = Color(0.04, 0.035, 0.03, 0.72)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	margin.add_child(row)
	# Portrait column.
	var who := PanelContainer.new()
	who.custom_minimum_size = Vector2(250, 0)
	row.add_child(who)
	var who_column := VBoxContainer.new()
	who.add_child(who_column)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(230, 260)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.modulate = Color(0.86, 0.8, 0.72)
	who_column.add_child(portrait)
	silhouette = Control.new()
	silhouette.custom_minimum_size = Vector2(230, 260)
	silhouette.draw.connect(_draw_silhouette)
	who_column.add_child(silhouette)
	name_label = _label(who_column, 24, JournalTheme.BURGUNDY)
	description_label = _label(who_column, 14, Color(JournalTheme.INK, 0.75))
	# Speech column.
	var talk := PanelContainer.new()
	talk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(talk)
	var talk_column := VBoxContainer.new()
	talk_column.add_theme_constant_override("separation", 12)
	talk.add_child(talk_column)
	conversation_box = VBoxContainer.new()
	conversation_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	conversation_box.add_theme_constant_override("separation", 14)
	talk_column.add_child(conversation_box)
	speech = _label(conversation_box, 21, JournalTheme.INK)
	replies = VBoxContainer.new()
	replies.add_theme_constant_override("separation", 6)
	conversation_box.add_child(replies)
	topics_box = VBoxContainer.new()
	topics_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	topics_box.add_theme_constant_override("separation", 10)
	talk_column.add_child(topics_box)
	var ask := _label(topics_box, 19, JournalTheme.BURGUNDY)
	ask.text = "Ask about"
	categories = HBoxContainer.new()
	categories.add_theme_constant_override("separation", 6)
	var category_scroll := ScrollContainer.new()
	category_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	category_scroll.custom_minimum_size.y = 52
	category_scroll.add_child(categories)
	topics_box.add_child(category_scroll)
	var topic_scroll := ScrollContainer.new()
	topic_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	topic_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	topics_box.add_child(topic_scroll)
	topic_list = VBoxContainer.new()
	topic_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topic_list.add_theme_constant_override("separation", 6)
	topic_scroll.add_child(topic_list)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	talk_column.add_child(bottom)
	continue_button = _button(bottom, "Continue", func(): controller.show_topics())
	back_button = _button(bottom, "Back", func(): controller.show_topics())
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(spacer)
	goodbye_button = _button(bottom, "Goodbye", func(): controller.goodbye())
	hide()

## Shows a conversation run by this controller.
func bind(dialogue_controller, npc_definition) -> void:
	if controller != null and controller.changed.is_connected(refresh):
		controller.changed.disconnect(refresh)
	controller = dialogue_controller
	definition = npc_definition
	controller.changed.connect(refresh)
	name_label.text = definition.full_name
	description_label.text = definition.description
	if definition.portrait != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = definition.portrait
		atlas.region = definition.portrait_region if definition.portrait_region.has_area() else Rect2(Vector2.ZERO, definition.portrait.get_size())
		portrait.texture = atlas
	portrait.visible = definition.portrait != null
	silhouette.visible = definition.portrait == null
	category = ""
	show()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	refresh()

func refresh() -> void:
	if controller == null: return
	var talking: bool = controller.view == &"conversation"
	conversation_box.visible = talking
	topics_box.visible = not talking
	continue_button.visible = talking and controller.choices.is_empty()
	back_button.visible = talking and not controller.closing and not controller.choices.is_empty()
	goodbye_button.visible = not controller.closing
	if talking:
		speech.text = "“" + controller.text + "”"
		_clear(replies)
		for index in range(controller.choices.size()):
			_button(replies, "%d.  %s" % [index + 1, controller.choices[index].text], controller.choose.bind(index)).alignment = HORIZONTAL_ALIGNMENT_LEFT
		var first: Button = replies.get_child(0) if replies.get_child_count() > 0 else continue_button
		_focus.call_deferred(first)
	else:
		_show_topics()

func _show_topics() -> void:
	var groups: Array = controller.available_topics()
	if groups.is_empty():
		controller.goodbye()
		return
	if not groups.any(func(group): return group.id == category): category = groups[0].id
	_clear(categories)
	for group in groups:
		var tab := _button(categories, group.title, func(): category = group.id; _show_topics())
		tab.toggle_mode = true
		tab.button_pressed = group.id == category
	_clear(topic_list)
	for group in groups:
		if group.id != category: continue
		for topic in group.topics:
			_button(topic_list, topic.title + ("" if topic.new else "  (again)"), controller.choose_topic.bind(topic.id)).alignment = HORIZONTAL_ALIGNMENT_LEFT
	if topic_list.get_child_count() > 0:
		_focus.call_deferred(topic_list.get_child(0))

func _input(event: InputEvent) -> void:
	if not visible or controller == null: return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if controller.closing: controller.show_topics()
		elif controller.view == &"conversation": controller.show_topics()
		else: closed.emit()
	elif event is InputEventKey and event.pressed and not event.echo and controller.view == &"conversation":
		var index: int = event.keycode - KEY_1
		if index >= 0 and index < mini(9, controller.choices.size()):
			get_viewport().set_input_as_handled()
			controller.choose(index)

func _draw_silhouette() -> void:
	var size := silhouette.size
	var ink := Color(JournalTheme.INK, 0.55)
	silhouette.draw_circle(Vector2(size.x / 2.0, size.y * 0.3), size.y * 0.13, ink)
	silhouette.draw_rect(Rect2(Vector2(size.x / 2.0 - size.y * 0.2, size.y * 0.48), Vector2(size.y * 0.4, size.y * 0.52)), ink)

func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _label(parent: Node, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 40
	button.pressed.connect(action)
	parent.add_child(button)
	return button

## Keyboard focus for a button once it is shown; ignores buttons already gone.
func _focus(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree() and control.is_visible_in_tree():
		control.grab_focus()
