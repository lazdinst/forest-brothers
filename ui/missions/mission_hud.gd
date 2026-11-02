extends Label
## Objective lines at the top left of the screen for any mission: what to find, where to take
## it, the exit countdown and the time left near the limit. Reads MissionRun.hud_lines().
var run
var participant: StringName

func _ready() -> void:
	position = Vector2(24, 20)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 4)

func _process(_delta: float) -> void:
	text = "\n".join(run.hud_lines(participant)) if run != null else ""
