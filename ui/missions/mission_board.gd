extends Control
## The mission map: a paper map of the district with a pin for every mission in the catalog.
## Choosing a pin shows its briefing; Deploy hands the definition to its world scene through
## MissionLaunch. Results from this run of the game mark the pins. Works for any catalog: no
## mission is named here. The map drawing is a stylised placeholder, not a historical map.
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
const MissionRun = preload("res://scripts/missions/mission_run.gd")
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
## Emitted instead of changing scene when the board is not the running scene (tests, embedding).
signal deploy_requested(definition: Resource)
@export var catalog: Resource = preload("res://missions/catalog.tres")
var selected: Resource
var map: Control
var pins := {}
var area_label: Label
var title_label: Label
var briefing_label: Label
var details_label: Label
var deploy_button: Button

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
	map_panel.size_flags_stretch_ratio = 1.6
	row.add_child(map_panel)
	var map_column := VBoxContainer.new()
	map_panel.add_child(map_column)
	var heading := _label(26, JournalTheme.BURGUNDY)
	heading.text = "Mission map"
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
	area_label = _label(16, JournalTheme.INK)
	column.add_child(area_label)
	title_label = _label(26, JournalTheme.BURGUNDY)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title_label)
	briefing_label = _label(17, JournalTheme.INK)
	briefing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(briefing_label)
	details_label = _label(17, JournalTheme.INK)
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(details_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	deploy_button = Button.new()
	deploy_button.text = "Deploy"
	deploy_button.pressed.connect(deploy)
	column.add_child(deploy_button)
	for mission in catalog.missions:
		var pin := Button.new()
		pin.toggle_mode = true
		pin.add_theme_font_size_override("font_size", 15)
		pin.pressed.connect(select.bind(mission.id))
		map.add_child(pin)
		pins[mission.id] = pin
	_refresh_pins()
	if not catalog.missions.is_empty():
		select(catalog.missions[0].id)

## Shows a mission's briefing and marks its pin.
func select(id: StringName) -> void:
	selected = catalog.find(id)
	if selected == null: return
	for key in pins:
		pins[key].button_pressed = key == id
	area_label.text = selected.area_name
	title_label.text = selected.title
	briefing_label.text = selected.briefing
	var lines: Array[String] = []
	for objective in selected.objectives:
		lines.append("Objective: bring out %s" % objective.label)
	lines.append("Time limit: %d minutes" % int(selected.time_limit_seconds / 60.0) if selected.time_limit_seconds > 0.0 else "No time limit")
	lines.append("Expected resistance: " + resistance(selected))
	lines.append("Exits: get out through any marked exit")
	if MissionLaunch.results.has(selected.id):
		lines.append("Last outing: " + RESULT_TEXT.get(MissionLaunch.results[selected.id], "unknown"))
	details_label.text = "\n".join(lines)

## A rough word for how many enemies the mission posts, not the exact count.
static func resistance(definition: Resource) -> String:
	var total := 0
	for tag in definition.enemy_groups:
		total += int(definition.enemy_groups[tag])
	if total <= 3: return "light"
	return "moderate" if total <= 4 else "heavy"

func deploy() -> void:
	if selected == null: return
	if get_tree().current_scene == self:
		MissionLaunch.deploy(get_tree(), selected)
	else:
		MissionLaunch.pending = selected
		deploy_requested.emit(selected)

func _refresh_pins() -> void:
	for mission in catalog.missions:
		var result: String = RESULT_TEXT.get(MissionLaunch.results.get(mission.id, &""), "")
		pins[mission.id].text = mission.title + ("  (%s)" % result.to_lower() if result != "" else "")
	_place_pins()

func _place_pins() -> void:
	for mission in catalog.missions:
		# The map can resize before the pins exist.
		if not pins.has(mission.id): continue
		var pin: Button = pins[mission.id]
		pin.reset_size()
		# The label starts beside the mission's dot and stays on the map; the dot marks the place.
		var at: Vector2 = map.size * mission.board_position
		var x := at.x + 12.0
		if x + pin.size.x > map.size.x: x = at.x - 12.0 - pin.size.x
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
	for mission in catalog.missions:
		var at: Vector2 = mission.board_position * size
		map.draw_circle(at, 7.0, JournalTheme.BURGUNDY)
		map.draw_circle(at, 3.0, JournalTheme.PAPER)

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
