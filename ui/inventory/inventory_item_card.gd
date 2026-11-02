extends Button
## Compact flat item cell. Drag payload carries only an item ID; the rule owner validates every drop.
## Left click selects (Button.pressed); right click asks for the item's action menu.
signal menu_requested(at: Vector2)
const Symbol = preload("res://ui/inventory/item_symbol.gd")
const AmmunitionArt = preload("res://ui/inventory/ammunition_art.gd")
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
var item_id: StringName
var item: Dictionary
var selected := false

static func style(fill: Color, border: Color, width := 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	return box

## Icon used both by the cell and by its drag preview.
static func icon(record: Dictionary, dimensions: Vector2) -> Control:
	var symbol = AmmunitionArt.new() if record.get("kind","") in ["magazine","rounds","rifle"] else Symbol.new()
	symbol.kind = record.get("kind","parts")
	if symbol is AmmunitionArt: symbol.status = str(record.get("quantity",""))
	symbol.size = dimensions
	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return symbol

static func _small_label(text: String, font_size: int, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",JournalTheme.INK)
	label.size = Vector2(width,font_size+4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func setup(record: Dictionary, dimensions: Vector2) -> void:
	item = record
	item_id = StringName(record.get("id",""))
	text = ""
	size = dimensions
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "%s · %s" % [record.get("title","Item"),record.get("quantity","")]
	add_theme_stylebox_override("hover",style(Color("f1e6cf"),JournalTheme.INK))
	add_theme_stylebox_override("pressed",style(Color("e2d2b2"),JournalTheme.INK))
	_apply_selection()
	var symbol := icon(record,dimensions-Vector2(10,26))
	symbol.position = Vector2(5,13)
	add_child(symbol)
	# Short name top-right and count bottom-right.
	var title := _small_label(record.get("title","Item"),10,dimensions.x-6)
	title.position = Vector2(3,0)
	add_child(title)
	var quantity := _small_label(str(record.get("quantity","")),10 if record.get("kind","") == "magazine" else 12,dimensions.x-6)
	quantity.position = Vector2(3,dimensions.y-17)
	add_child(quantity)

func set_selected(value: bool) -> void:
	selected = value
	_apply_selection()

func _apply_selection() -> void:
	add_theme_stylebox_override("normal",style(Color("e9dcc2d9"),JournalTheme.BURGUNDY if selected else Color("29251d66"),2 if selected else 1))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		accept_event()
		menu_requested.emit(get_screen_transform() * event.position)

func drag_preview() -> Control:
	var preview := Panel.new()
	preview.add_theme_stylebox_override("panel",style(Color("e9dcc2b0"),JournalTheme.INK))
	preview.size = size * get_global_transform().get_scale()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var symbol := icon(item,preview.size-Vector2(10,10))
	symbol.position = Vector2(5,5)
	preview.add_child(symbol)
	preview.modulate.a = 0.85
	return preview

func _get_drag_data(_at: Vector2) -> Variant:
	if item_id == &"": return null
	set_drag_preview(drag_preview())
	return {"inventory_item_id":str(item_id)}

func _can_drop_data(at: Vector2, data: Variant) -> bool:
	return get_parent()._can_drop_data(position+at,data)

func _drop_data(at: Vector2, data: Variant) -> void:
	get_parent()._drop_data(position+at,data)
