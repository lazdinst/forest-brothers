extends Control
## End-of-outing debrief over the scene: headline, summary lines and a button to go again.
## Presentation only; the mission rules build the content (ArenaMission.debrief()).
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
signal restart_requested
var headline: Label
var summary: Label

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
	panel.custom_minimum_size = Vector2(520, 0)
	centre.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	headline = Label.new()
	headline.add_theme_font_size_override("font_size", 28)
	headline.add_theme_color_override("font_color", JournalTheme.BURGUNDY)
	column.add_child(headline)
	summary = Label.new()
	summary.add_theme_font_size_override("font_size", 18)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary)
	var again := Button.new()
	again.text = "Go again"
	again.pressed.connect(func(): restart_requested.emit())
	column.add_child(again)
	hide()

## Shows a debrief dictionary {headline, lines}.
func present(report: Dictionary) -> void:
	headline.text = report.get("headline", "")
	summary.text = "\n".join(report.get("lines", []))
	show()
