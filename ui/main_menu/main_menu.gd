extends Control

signal training_requested
signal quit_requested

const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
const MenuActions = preload("res://ui/components/menu_actions.gd")
const MenuModal = preload("res://ui/components/menu_modal.gd")
const MenuPanel = preload("res://ui/components/menu_panel.gd")
var training_button: Button
var details

func _ready() -> void:
	theme = JournalTheme.create()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var background := TextureRect.new()
	background.texture = load("res://ui/assets/field_journal_background_v1.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.size = Vector2(1280, 720)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Fixed composition scales uniformly, preserving readable live controls.
	var canvas := Control.new()
	canvas.name = "Composition"
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	canvas.add_child(background)
	var title := Label.new()
	title.text = "FOREST\nBROTHERS"
	title.position = Vector2(744, 177)
	title.size = Vector2(300, 130)
	title.rotation = -0.10
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 47)
	title.add_theme_color_override("font_color", JournalTheme.INK)
	canvas.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "M E Ž A B R Ā Ļ I"
	subtitle.position = Vector2(768, 307)
	subtitle.rotation = -0.10
	subtitle.add_theme_font_size_override("font_size", 23)
	subtitle.add_theme_color_override("font_color", JournalTheme.INK)
	canvas.add_child(subtitle)
	var menu := MenuActions.new()
	var paper_menu := MenuPanel.new()
	paper_menu.position = Vector2(112, 210)
	paper_menu.size = Vector2(400, 0)
	canvas.add_child(paper_menu)
	paper_menu.add_child(menu)
	for entry in [["Continue", "No campaign save yet."], ["New Game", "Campaign missions are in development."], ["Co-op Game", "Co-op is planned for up to four players; joining is not implemented."]]:
		var unavailable := _button(entry[0] + "  ·  unavailable", menu)
		unavailable.disabled = true
		unavailable.tooltip_text = entry[1]
	training_button = _button("Training", menu)
	training_button.pressed.connect(func(): training_requested.emit())
	_button("Controls", menu).pressed.connect(show_controls)
	_button("Records", menu).pressed.connect(func(): show_message("Records", "Forest Brothers / Mežabrāļi\nLocal development prototype\n\nCampaign records are not implemented. Training progress resets when you leave."))
	_button("Exit", menu).pressed.connect(func(): quit_requested.emit())
	var note := Label.new()
	note.text = "DEVELOPMENT PROTOTYPE  /  TRAINING AVAILABLE"
	note.position = Vector2(112, 625)
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color("fff0d4"))
	note.add_theme_color_override("font_shadow_color", Color.BLACK)
	note.add_theme_constant_override("shadow_offset_x", 1)
	note.add_theme_constant_override("shadow_offset_y", 1)
	canvas.add_child(note)
	details = MenuModal.new()
	add_child(details)
	details.action_selected.connect(func(_id): details.dismiss())
	details.canceled.connect(details.dismiss)
	resized.connect(_fit_composition)
	_fit_composition()
	training_button.grab_focus()

func _fit_composition() -> void:
	var factor := minf(size.x / 1280.0, size.y / 720.0)
	$Composition.scale = Vector2.ONE * factor
	$Composition.position = (size - Vector2(1280, 720) * factor) * 0.5

func _button(caption: String, parent: Node) -> Button:
	return parent.add_action(StringName(caption), caption)

func show_message(caption: String, message: String) -> void:
	details.present(caption, message, [{"id": &"close", "caption": "Back"}])

func show_controls() -> void:
	show_message("Training controls", "WASD move · Mouse look · Shift run · Space jump\nCtrl crouch · Q / E lean · V vault · F interact\nLeft mouse fire · Right mouse aim · R reload\nHold T refill spare magazine · J clear jam\nB clean · G dirty weapon · I inspect · P reset position\nTab opens equipment & inventory.\n\nEscape opens navigation when launched through startup.\nTraining is session-only; leaving discards its progress.")
