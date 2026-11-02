extends Control
## The end-of-outing summary for every mission: mission title, headline, then titled sections of
## label/value rows, and a continue button. Renders a MissionReport dictionary; it knows nothing
## about any particular mission.
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
signal continue_requested
var title_label: Label
var headline: Label
var sections: VBoxContainer
var continue_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = JournalTheme.create()
	var scrim := ColorRect.new()
	scrim.color = Color(JournalTheme.SCRIM, 0.72)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	centre.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	title_label = _label(16, JournalTheme.INK)
	column.add_child(title_label)
	headline = _label(28, JournalTheme.BURGUNDY)
	column.add_child(headline)
	sections = VBoxContainer.new()
	sections.add_theme_constant_override("separation", 10)
	column.add_child(sections)
	continue_button = Button.new()
	continue_button.text = "Go again"
	continue_button.pressed.connect(func(): continue_requested.emit())
	column.add_child(continue_button)
	hide()

## Shows a report from MissionReport.build().
func present(report: Dictionary, button_text := "Go again") -> void:
	title_label.text = report.get("title", "")
	headline.text = report.get("headline", "")
	continue_button.text = button_text
	for child in sections.get_children():
		sections.remove_child(child)
		child.queue_free()
	for section in report.get("sections", []):
		var heading := _label(19, JournalTheme.BURGUNDY)
		heading.text = section.heading
		sections.add_child(heading)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 24)
		for row in section.rows:
			var name_label := _label(17, JournalTheme.INK)
			name_label.text = str(row[0])
			# One label width for every section, so values line up down the page.
			name_label.custom_minimum_size.x = 230
			grid.add_child(name_label)
			var value := _label(17, JournalTheme.INK)
			value.text = str(row[1])
			value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			value.custom_minimum_size.x = 260
			grid.add_child(value)
		sections.add_child(grid)
	show()

## Every label and value shown, in order, for checks and accessibility tools.
func text() -> String:
	var parts: Array[String] = [title_label.text, headline.text]
	for node in sections.get_children():
		if node is Label: parts.append(node.text)
		else: for cell in node.get_children(): parts.append(cell.text)
	return "\n".join(parts)

func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
