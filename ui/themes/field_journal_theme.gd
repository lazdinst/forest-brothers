extends RefCounted
## Shared palette and states for menu and training navigation.
const PAPER := Color("dfc49b")
const INK := Color("29251d")
const BURGUNDY := Color("64282b")

static func panel(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func create() -> Theme:
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Georgia", "DejaVu Serif", "serif"])
	theme.default_font = font
	theme.default_font_size = 22
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", Color("fff0d4"))
	theme.set_color("font_pressed_color", "Button", Color("fff0d4"))
	theme.set_color("font_focus_color", "Button", Color("fff0d4"))
	theme.set_color("font_disabled_color", "Button", Color("776b58"))
	theme.set_stylebox("normal", "Button", panel(PAPER, Color("9c8058")))
	theme.set_stylebox("hover", "Button", panel(BURGUNDY, PAPER))
	theme.set_stylebox("pressed", "Button", panel(Color("421d20"), PAPER))
	theme.set_stylebox("disabled", "Button", panel(Color("c3ad88"), Color("9c8058")))
	theme.set_stylebox("focus", "Button", panel(Color("64282b"), Color("fff0d4")))
	theme.set_color("font_color", "Label", PAPER)
	theme.set_color("font_color", "RichTextLabel", PAPER)
	theme.set_stylebox("panel", "PanelContainer", panel(Color("29251df5"), Color("9c8058")))
	theme.set_constant("separation", "VBoxContainer", 5)
	return theme
