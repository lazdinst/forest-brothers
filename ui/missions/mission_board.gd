extends Control
## The mission map: a paper map of the district with a pin for every region in the catalog,
## as in choosing a location before a raid. Choosing a pin shows the region (description, time
## limit, exits, rough resistance) and its missions; the player ticks any open missions to take
## along, or none for a scavenging outing, and Deploy hands the composed outing to the region's
## world scene through MissionLaunch. Completed missions are no longer offered; results from this
## run of the game mark them. Nothing here names a region or mission. The map drawing is a
## stylised placeholder, not a historical map.
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
const MissionRun = preload("res://scripts/missions/mission_run.gd")
## Emitted instead of changing scene when the board is not the running scene (tests, embedding).
signal deploy_requested(region: Resource, chosen: Array)
@export var catalog: Resource = preload("res://missions/catalog.tres")
var selected: Resource
var map: Control
## Region id -> pin button.
var pins := {}
## Mission id -> CheckBox, for the selected region.
var mission_boxes := {}
var title_label: Label
var description_label: Label
var details_label: Label
var missions_list: VBoxContainer
var deploy_button: Button
## Shown when the map was opened from the camp.
var back_button: Button

const RESULT_TEXT := {MissionRun.SUCCESS:"Completed",MissionRun.RETURNED:"Returned early",MissionRun.FAILED:"Failed"}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = JournalTheme.create()
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var backdrop := ColorRect.new()
	backdrop.color = Color("1d1a15")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	row.add_theme_constant_override("separation", 24)
	add_child(row)
	var map_panel := PanelContainer.new()
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_stretch_ratio = 1.5
	row.add_child(map_panel)
	var map_column := VBoxContainer.new()
	map_panel.add_child(map_column)
	var heading := _label(26, JournalTheme.BURGUNDY)
	heading.text = "Mission map: choose a region"
	map_column.add_child(heading)
	map = Control.new()
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.custom_minimum_size = Vector2(420, 360)
	map.draw.connect(_draw_map)
	map.resized.connect(_place_pins)
	map_column.add_child(map)
	var side := PanelContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(side)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	side.add_child(column)
	title_label = _label(28, JournalTheme.BURGUNDY)
	column.add_child(title_label)
	description_label = _label(17, JournalTheme.INK)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description_label)
	details_label = _label(17, JournalTheme.INK)
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(details_label)
	var missions_heading := _label(20, JournalTheme.BURGUNDY)
	missions_heading.text = "Missions to take along"
	column.add_child(missions_heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	missions_list = VBoxContainer.new()
	missions_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	missions_list.add_theme_constant_override("separation", 6)
	scroll.add_child(missions_list)
	deploy_button = Button.new()
	deploy_button.pressed.connect(deploy)
	column.add_child(deploy_button)
	back_button = Button.new()
	back_button.text = "Back to camp"
	back_button.visible = MissionLaunch.camp_scene != ""
	back_button.pressed.connect(back_to_camp)
	column.add_child(back_button)
	for region in catalog.regions:
		var pin := Button.new()
		pin.toggle_mode = true
		pin.add_theme_font_size_override("font_size", 16)
		pin.pressed.connect(select.bind(region.id))
		map.add_child(pin)
		pins[region.id] = pin
	_refresh_pins()
	if not catalog.regions.is_empty():
		select(catalog.regions[0].id)

## Shows a region and its missions; open missions start ticked.
func select(id: StringName) -> void:
	selected = catalog.find_region(id)
	if selected == null: return
	for key in pins:
		pins[key].button_pressed = key == id
	title_label.text = selected.title
	description_label.text = selected.description
	for child in missions_list.get_children():
		missions_list.remove_child(child)
		child.queue_free()
	mission_boxes.clear()
	for mission in selected.missions:
		var done: bool = MissionLaunch.completed.has(mission.id)
		var box := CheckBox.new()
		box.text = "%s  (%s)%s" % [mission.title, mission.area_name, "  completed" if done else ""]
		box.button_pressed = not done
		box.disabled = done
		box.toggled.connect(func(_on): _refresh_details())
		missions_list.add_child(box)
		mission_boxes[mission.id] = box
		var note := _label(15, Color(JournalTheme.INK, 0.8))
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var lines: Array[String] = []
		if not done:
			lines.append(mission.briefing)
			if mission.reward_text() != "": lines.append("Reward to camp: " + mission.reward_text())
		if MissionLaunch.results.has(mission.id):
			lines.append("Last outing: " + RESULT_TEXT.get(MissionLaunch.results[mission.id], "unknown"))
		note.text = "\n".join(lines)
		note.visible = not lines.is_empty()
		missions_list.add_child(note)
	_refresh_details()

## The open missions currently ticked for the selected region.
func chosen() -> Array:
	if selected == null: return []
	return selected.missions.filter(func(mission): return mission_boxes.has(mission.id) and mission_boxes[mission.id].button_pressed and not mission_boxes[mission.id].disabled)

func _refresh_details() -> void:
	var picked := chosen()
	var lines: Array[String] = []
	lines.append("Time limit: %d minutes" % int(selected.time_limit_seconds / 60.0) if selected.time_limit_seconds > 0.0 else "No time limit")
	lines.append("Exits: " + (", ".join(selected.exit_names) if not selected.exit_names.is_empty() else "any marked exit"))
	lines.append("Expected resistance: " + resistance(selected, picked))
	for mission in picked:
		for objective in mission.objectives:
			lines.append("Objective: bring out %s" % objective.label)
	details_label.text = "\n".join(lines)
	deploy_button.text = "Deploy to %s%s" % [selected.title, "" if not picked.is_empty() else " (scavenging only)"]

## A rough word for how many enemies the outing posts, not the exact count.
static func resistance(region: Resource, picked: Array) -> String:
	var total: int = region.enemy_count(picked)
	if total <= 3: return "light"
	return "moderate" if total <= 5 else "heavy"

func deploy() -> void:
	if selected == null: return
	var picked := chosen()
	if get_tree().current_scene == self:
		MissionLaunch.deploy(get_tree(), selected, picked)
	else:
		MissionLaunch.pending = selected.compose(picked)
		deploy_requested.emit(selected, picked)

func back_to_camp() -> void:
	if get_tree().current_scene == self:
		MissionLaunch.return_to_camp(get_tree())

func _refresh_pins() -> void:
	for region in catalog.regions:
		var open: int = region.missions.filter(func(mission): return not MissionLaunch.completed.has(mission.id)).size()
		pins[region.id].text = "%s  (%d open)" % [region.title, open]
	_place_pins()

func _place_pins() -> void:
	for region in catalog.regions:
		# The map can resize before the pins exist.
		if not pins.has(region.id): continue
		var pin: Button = pins[region.id]
		pin.reset_size()
		# The label starts beside the region's dot and stays on the map; the dot marks the place.
		var at: Vector2 = map.size * region.board_position
		var x := at.x + 14.0
		if x + pin.size.x > map.size.x: x = at.x - 14.0 - pin.size.x
		pin.position = Vector2(clampf(x, 0.0, maxf(0.0, map.size.x - pin.size.x)), at.y - pin.size.y / 2.0)
	map.queue_redraw()

## A stylised district: forest to the west, a road north to south, a stream, fields.
func _draw_map() -> void:
	var size := map.size
	var ink := Color(JournalTheme.INK, 0.55)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1946
	for index in range(70):
		var at := Vector2(rng.randf_range(0.02, 0.36), rng.randf_range(0.03, 0.97)) * size
		map.draw_circle(at, rng.randf_range(6, 12), Color(0.24, 0.32, 0.2, 0.35))
		map.draw_arc(at, 7, 0, TAU, 10, ink, 1.0, true)
	map.draw_line(Vector2(0.56, 0.0) * size, Vector2(0.56, 1.0) * size, Color(0.42, 0.33, 0.22, 0.8), 5.0, true)
	var stream := PackedVector2Array()
	for step in range(21):
		var t := step / 20.0
		stream.append(Vector2(0.38 + t * 0.6, 0.08 + sin(t * 5.0) * 0.04) * size)
	map.draw_polyline(stream, Color(0.3, 0.42, 0.5, 0.7), 3.0, true)
	for field in [Rect2(0.68, 0.14, 0.2, 0.16), Rect2(0.64, 0.58, 0.16, 0.26)]:
		map.draw_rect(Rect2(field.position * size, field.size * size), ink, false, 1.0)
	map.draw_string(ThemeDB.fallback_font, Vector2(0.05, 0.05) * size + Vector2(0, 14), "forest", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ink)
	map.draw_string(ThemeDB.fallback_font, Vector2(0.575, 0.98) * size, "road", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ink)
	for region in catalog.regions:
		var at: Vector2 = region.board_position * size
		map.draw_arc(at, 34.0, 0, TAU, 32, Color(JournalTheme.BURGUNDY, 0.5), 2.0, true)
		map.draw_circle(at, 8.0, JournalTheme.BURGUNDY)
		map.draw_circle(at, 3.0, JournalTheme.PAPER)

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
