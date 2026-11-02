extends Control
## One item per cell. Reject over-capacity snapshots without replacing visible items.
signal item_selected(item: Dictionary)
signal item_dropped(item_id: StringName, slot: int, target_id: StringName)
const Symbol = preload("res://ui/inventory/item_symbol.gd")
const JournalTheme = preload("res://ui/themes/field_journal_theme.gd")
const ButtonScene = preload("res://ui/components/menu_button.tscn")
const ItemCard = preload("res://ui/inventory/inventory_item_card.gd")
const AmmunitionArt = preload("res://ui/inventory/ammunition_art.gd")
var columns := 6
var rows := 7
var cell := 48.0
var cards: Array[Button] = []
var slot_ids := {}

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
	var requested_slots := {}
	for index in range(items.size()):
		var slot: int = items[index].get("slot",index)
		if slot < 0 or slot >= columns*rows or requested_slots.has(slot): return false
		requested_slots[slot] = items[index].get("id","")
	for card in cards:
		remove_child(card)
		card.queue_free()
	cards.clear()
	slot_ids = requested_slots
	for index in range(items.size()):
		var item: Dictionary = items[index]
		var slot: int = item.get("slot",index)
		var at := Vector2i(slot % columns, floori(float(slot) / columns))
		var card := ButtonScene.instantiate() as Button
		card.set_script(ItemCard)
		card.set("item_id",StringName(item.get("id","")))
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
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.add_theme_font_size_override("font_size",14)
		label.size = Vector2(card.size.x-18,20)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(label)
		var symbol = AmmunitionArt.new() if item.get("kind","") in ["magazine","rounds","rifle"] else Symbol.new()
		symbol.kind = item.get("kind", "parts")
		if symbol is AmmunitionArt: symbol.status = str(item.quantity)
		symbol.position = Vector2(12,24)
		symbol.size = Vector2(card.size.x - 24, maxf(18, card.size.y - 48))
		symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
		symbol.visible = card.size.y >= 80
		card.add_child(symbol)
		var quantity := Label.new()
		quantity.text = str(item.quantity)
		quantity.position = Vector2(5,card.size.y-22)
		quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quantity.clip_text = true
		quantity.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		quantity.add_theme_font_size_override("font_size",11 if item.get("kind","")=="magazine" else 14)
		quantity.size = Vector2(card.size.x-10,20)
		quantity.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(quantity)
		card.pressed.connect(func(): item_selected.emit(item))
		add_child(card)
		cards.append(card)
	return true

func _can_drop_data(at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("inventory_item_id") is String and Rect2(Vector2.ZERO,size).has_point(at)

func _drop_data(at: Vector2, data: Variant) -> void:
	var slot := floori(at.y/cell)*columns+floori(at.x/cell)
	item_dropped.emit(StringName(data.inventory_item_id),slot,StringName(slot_ids.get(slot,"")))

func _draw() -> void:
	var ink := Color("66523c65")
	draw_rect(Rect2(Vector2.ZERO, Vector2(columns,rows)*cell),Color("765e3c16"))
	for x in range(columns+1): draw_line(Vector2(x*cell,0),Vector2(x*cell,rows*cell),ink,1,true)
	for y in range(rows+1): draw_line(Vector2(0,y*cell),Vector2(columns*cell,y*cell),ink,1,true)
