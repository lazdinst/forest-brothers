extends Control
## One item per cell. Reject over-capacity snapshots without replacing visible items.
## While dragging, the cell under the cursor is tinted by drop_validator; the rule owner
## still validates the actual drop.
signal item_selected(item: Dictionary)
signal item_menu_requested(item: Dictionary, at: Vector2)
signal item_dropped(item_id: StringName, slot: int, target_id: StringName)
const ItemCard = preload("res://ui/inventory/inventory_item_card.gd")
const ACCEPT := Color("4f7a4a73")
const REJECT := Color("8a3a3280")
var columns := 6
var rows := 7
var cell := 48.0
var cards: Array[Button] = []
var slot_ids := {}
## (item_id, slot, target_id) -> bool. Empty means every in-grid drop is offered.
var drop_validator: Callable
var selected_id: StringName
var hover_slot := -1
var hover_ok := false
var _highlight: ColorRect

func configure(column_count: int, row_count: int, cell_size: float) -> void:
	columns = column_count
	rows = row_count
	cell = cell_size
	custom_minimum_size = Vector2(columns, rows) * cell
	size = custom_minimum_size
	if _highlight == null:
		_highlight = ColorRect.new()
		_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_highlight.hide()
		add_child(_highlight)
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
		var card := ItemCard.new()
		card.setup(item,Vector2.ONE * cell - Vector2(4,4))
		card.position = Vector2(at) * cell + Vector2(2,2)
		card.set_selected(card.item_id == selected_id and selected_id != &"")
		card.pressed.connect(func(): item_selected.emit(item))
		card.menu_requested.connect(func(at_screen: Vector2): item_menu_requested.emit(item,at_screen))
		add_child(card)
		cards.append(card)
	if _highlight != null: move_child(_highlight,-1)
	return true

func select(id: StringName) -> void:
	selected_id = id
	for card in cards: card.set_selected(card.item_id == id and id != &"")

func slot_at(at: Vector2) -> int:
	return floori(at.y/cell)*columns+floori(at.x/cell)

func _can_drop_data(at: Vector2, data: Variant) -> bool:
	var ok: bool = data is Dictionary and data.get("inventory_item_id") is String and Rect2(Vector2.ZERO,size).has_point(at)
	var slot := slot_at(at)
	if ok and drop_validator.is_valid():
		ok = drop_validator.call(StringName(data.inventory_item_id),slot,StringName(slot_ids.get(slot,"")))
	_set_hover(slot if Rect2(Vector2.ZERO,size).has_point(at) else -1,ok)
	return ok

func _drop_data(at: Vector2, data: Variant) -> void:
	_set_hover(-1,false)
	var slot := slot_at(at)
	item_dropped.emit(StringName(data.inventory_item_id),slot,StringName(slot_ids.get(slot,"")))

func _set_hover(slot: int, ok: bool) -> void:
	hover_slot = slot
	hover_ok = ok
	if _highlight == null: return
	_highlight.visible = slot >= 0
	if slot < 0: return
	_highlight.color = ACCEPT if ok else REJECT
	_highlight.position = Vector2(slot % columns, floori(float(slot) / columns)) * cell + Vector2(1,1)
	_highlight.size = Vector2.ONE * cell - Vector2(2,2)

func _process(_delta: float) -> void:
	# Godot gives no "drag left this control" callback, so clear a stale tint here.
	if hover_slot >= 0 and not get_global_rect().has_point(get_global_mouse_position()): _set_hover(-1,false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END: _set_hover(-1,false)

func _draw() -> void:
	var ink := Color("66523c65")
	draw_rect(Rect2(Vector2.ZERO, Vector2(columns,rows)*cell),Color("765e3c16"))
	for x in range(columns+1): draw_line(Vector2(x*cell,0),Vector2(x*cell,rows*cell),ink,1,true)
	for y in range(rows+1): draw_line(Vector2(0,y*cell),Vector2(columns*cell,y*cell),ink,1,true)
