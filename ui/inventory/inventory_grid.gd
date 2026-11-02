extends Control
## Items cover their footprint's cells. Reject overlapping or out-of-grid snapshots without
## replacing visible items. While dragging, the footprint under the cursor is tinted by
## drop_validator; the rule owner still validates the actual drop.
signal item_selected(item: Dictionary)
signal item_menu_requested(item: Dictionary, at: Vector2)
signal item_dropped(item_id: StringName, slot: int, target_id: StringName, rotated: bool)
const ItemCard = preload("res://ui/inventory/inventory_item_card.gd")
const ACCEPT := Color("4f7a4a73")
const REJECT := Color("8a3a3280")
var columns := 6
var rows := 7
var cell := 48.0
var cards: Array[Button] = []
## Every covered cell index -> item ID.
var slot_ids := {}
## (item_id, slot, target_id, rotated) -> bool. Empty means every in-grid drop is offered.
var drop_validator: Callable
var selected_id: StringName
var hover_active := false
var hover_ok := false
var _last_at := Vector2.ZERO
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

func bounds() -> Rect2i:
	return Rect2i(0,0,columns,rows)

func show_items(items: Array) -> bool:
	var covered := {}
	for index in range(items.size()):
		var item: Dictionary = items[index]
		var slot: int = item.get("slot",index)
		var footprint := Rect2i(Vector2i(slot % columns, floori(float(slot) / columns)),item.get("size",Vector2i.ONE))
		if slot < 0 or not bounds().encloses(footprint): return false
		for y in range(footprint.position.y,footprint.end.y):
			for x in range(footprint.position.x,footprint.end.x):
				if covered.has(y*columns+x): return false
				covered[y*columns+x] = item.get("id","")
	for card in cards:
		remove_child(card)
		card.queue_free()
	cards.clear()
	slot_ids = covered
	for index in range(items.size()):
		var item: Dictionary = items[index]
		var slot: int = item.get("slot",index)
		var at := Vector2i(slot % columns, floori(float(slot) / columns))
		var card := ItemCard.new()
		card.setup(item,Vector2(item.get("size",Vector2i.ONE)) * cell - Vector2(4,4))
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

## Where a dragged item would land: its top-left cell follows the grab point, so a long
## rifle moves with the part the cursor holds. A turned drag rotates about that point.
func drop_target(at: Vector2, data: Dictionary) -> Dictionary:
	var cells: Vector2i = data.get("cells",Vector2i.ONE)
	var turned: bool = data.get("turned",false)
	var grab: Vector2 = data.get("grab",Vector2(cells) * cell * 0.5)
	var offset := -grab
	var shape := cells
	if turned:
		offset = Vector2(-(cells.y*cell - grab.y),-grab.x)
		shape = Vector2i(cells.y,cells.x)
	var corner := Vector2i(((at + offset) / cell).round())
	var under := Vector2i((at / cell).floor())
	return {"area":Rect2i(corner,shape),"slot":corner.y*columns+corner.x,"rotated":bool(data.get("rotated",false)) != turned,"target_id":StringName(slot_ids.get(under.y*columns+under.x,""))}

func _can_drop_data(at: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.get("inventory_item_id") is String and Rect2(Vector2.ZERO,size).has_point(at)):
		_set_hover(Rect2i(),false,false)
		return false
	_last_at = at
	var target := drop_target(at,data)
	var ok: bool = bounds().encloses(target.area)
	if ok and drop_validator.is_valid():
		ok = drop_validator.call(StringName(data.inventory_item_id),target.slot,target.target_id,target.rotated)
	_set_hover(target.area.intersection(bounds()),true,ok)
	return ok

## Re-evaluate after the drag changes without a mouse move (R rotates it).
func refresh_hover(data: Dictionary) -> void:
	if hover_active: _can_drop_data(_last_at,data)

func _drop_data(at: Vector2, data: Variant) -> void:
	_set_hover(Rect2i(),false,false)
	var target := drop_target(at,data)
	item_dropped.emit(StringName(data.inventory_item_id),target.slot,target.target_id,target.rotated)

func _set_hover(area: Rect2i, active: bool, ok: bool) -> void:
	hover_active = active
	hover_ok = ok
	if _highlight == null: return
	_highlight.visible = active and area.has_area()
	if not _highlight.visible: return
	_highlight.color = ACCEPT if ok else REJECT
	_highlight.position = Vector2(area.position) * cell + Vector2(1,1)
	_highlight.size = Vector2(area.size) * cell - Vector2(2,2)

func _process(_delta: float) -> void:
	# Godot gives no "drag left this control" callback, so clear a stale tint here.
	if hover_active and not get_global_rect().has_point(get_global_mouse_position()): _set_hover(Rect2i(),false,false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END: _set_hover(Rect2i(),false,false)

func _draw() -> void:
	var ink := Color("66523c65")
	draw_rect(Rect2(Vector2.ZERO, Vector2(columns,rows)*cell),Color("765e3c16"))
	for x in range(columns+1): draw_line(Vector2(x*cell,0),Vector2(x*cell,rows*cell),ink,1,true)
	for y in range(rows+1): draw_line(Vector2(0,y*cell),Vector2(columns*cell,y*cell),ink,1,true)
