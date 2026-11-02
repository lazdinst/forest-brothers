extends RefCounted
## Shared palette and states for menu and training navigation.
const PAPER := Color("dfc49b")
const INK := Color("29251d")
const BURGUNDY := Color("64282b")
const SCRIM := Color("15130fef")
static var _shared_theme: Theme

static func paper(tint: Color, padding := 12.0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = preload("res://ui/assets/paper_sheet_v1.png")
	style.modulate_color = tint
	for edge in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(edge, 16)
		style.set_content_margin(edge, padding)
	if padding < 20:
		style.set_texture_margin(SIDE_TOP, 4)
		style.set_texture_margin(SIDE_BOTTOM, 4)
		style.content_margin_left = 24
		style.content_margin_right = 24
	return style

static func create() -> Theme:
	if _shared_theme != null:
		return _shared_theme
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
	theme.set_stylebox("normal", "Button", paper(Color("f3e5cf"), 10))
	theme.set_stylebox("hover", "Button", paper(Color("793638"), 10))
	theme.set_stylebox("pressed", "Button", paper(Color("53272a"), 10))
	theme.set_stylebox("disabled", "Button", paper(Color("d1c1a6"), 10))
	theme.set_stylebox("focus", "Button", paper(Color("793638"), 10))
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "RichTextLabel", INK)
	theme.set_stylebox("panel", "PanelContainer", paper(Color.WHITE, 20))
	theme.set_stylebox("normal", "LineEdit", paper(Color.WHITE,10))
	theme.set_stylebox("focus", "LineEdit", paper(Color("ead8b9"),10))
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("caret_color", "LineEdit", INK)
	theme.set_constant("separation", "VBoxContainer", 0)
	_shared_theme = theme
	return theme
