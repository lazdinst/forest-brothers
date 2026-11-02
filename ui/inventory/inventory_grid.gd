extends Control
## One item per cell. Reject over-capacity snapshots without replacing visible items.
signal item_selected(item: Dictionary)
const Symbol = preload("res://ui/inventory/item_symbol.gd")
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
const ButtonScene = preload("res://ui/components/menu_button.tscn")
var columns := 6
var rows := 7
var cell := 48.0
var cards: Array[Button] = []

func configure(column_count: int, row_count: int, cell_size: float) -> void:
	columns = column_count
	rows = row_count
	cell = cell_size
	custom_minimum_size = Vector2(columns, rows) * cell
	size = custom_minimum_size
	queue_redraw()

func show_items(items: Array) -> bool:
	if items.size() > columns * rows:
		return false
	for card in cards:
		remove_child(card)
		card.queue_free()
	cards.clear()
	for index in range(items.size()):
		var item: Dictionary = items[index]
		var at := Vector2i(index % columns, floori(float(index) / columns))
		var card := ButtonScene.instantiate() as Button
		card.text = ""
		card.theme = JournalTheme.create()
		for state in ["hover", "pressed", "focus"]:
			card.add_theme_stylebox_override(state, JournalTheme.paper(Color("e6d5b5"),10))
		card.position = Vector2(at) * cell + Vector2(2,2)
		card.size = Vector2.ONE * cell - Vector2(4,4)
		card.tooltip_text = item.title + " · " + str(item.quantity)
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var label := Label.new()
		label.text = item.title
		label.position = Vector2(9,6)
		label.size.x = card.size.x - 18
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.add_theme_font_size_override("font_size",14)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(label)
		var symbol := Symbol.new()
		symbol.kind = item.get("kind", "parts")
		symbol.position = Vector2(12,24)
		symbol.size = Vector2(card.size.x - 24, maxf(18, card.size.y - 44))
		symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
		symbol.visible = card.size.y >= 80
		card.add_child(symbol)
		var quantity := Label.new()
		quantity.text = str(item.quantity)
		quantity.position = Vector2(9,card.size.y-24)
		quantity.size.x = card.size.x - 18
		quantity.clip_text = true
		quantity.add_theme_font_size_override("font_size",14)
		quantity.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(quantity)
		card.pressed.connect(func(): item_selected.emit(item))
		add_child(card)
		cards.append(card)
	return true

func _draw() -> void:
	var ink := Color("66523c65")
	draw_rect(Rect2(Vector2.ZERO, Vector2(columns,rows)*cell),Color("765e3c16"))
	for x in range(columns+1): draw_line(Vector2(x*cell,0),Vector2(x*cell,rows*cell),ink,1,true)
	for y in range(rows+1): draw_line(Vector2(0,y*cell),Vector2(columns*cell,y*cell),ink,1,true)
