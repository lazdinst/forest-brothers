extends Button
## Equipped rifle slot. Left click selects; right click asks for the rifle's action menu;
## ctrl-click stows the rifle in the pack. Drag the rifle out to stow it, or drag a carried
## rifle in to equip it. A dragged magazine or rifle tints the slot while hovering; the
## weapon and inventory owners still validate the actual drop.
signal menu_requested(at: Vector2)
signal inspect_requested
signal stow_requested
signal equip_requested(item_id: StringName)
const ItemCard = preload("res://ui/inventory/inventory_item_card.gd")
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
var weapon_state
var progress := -1.0
## Grid cell size, so the drag preview matches the rifle's footprint in the pack.
var cell := 64.0

func set_progress(value: float) -> void:
	if is_equal_approx(value,progress): return
	progress = value
	queue_redraw()

func _draw() -> void:
	ItemCard.draw_progress(self,size,progress)

## Grabbed at its centre, which is where grids assume a payload without a grab point is held.
func drag_payload() -> Dictionary:
	var gun = weapon_state.inventory.weapon()
	var cells: Vector2i = weapon_state.inventory.footprint(gun)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel",ItemCard.style(Color("e9dcc2b0"),Color("29251d")))
	panel.size = Vector2(cells) * cell * get_global_transform().get_scale()
	panel.position = -panel.size * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(ItemCard.icon({"kind":"rifle"},Rect2(Vector2(5,5),panel.size-Vector2(10,10))))
	root.add_child(panel)
	root.modulate.a = 0.85
	return {"inventory_item_id":str(gun.id),"cells":cells,"rotated":false,"turned":false,"preview":root}

func _get_drag_data(_at: Vector2) -> Variant:
	if weapon_state == null or not weapon_state.equipped(): return null
	var payload := drag_payload()
	set_drag_preview(payload.preview)
	return payload

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and not disabled:
		accept_event()
		menu_requested.emit(get_screen_transform() * event.position)
	elif event is InputEventMouseButton and event.pressed and event.double_click and event.button_index == MOUSE_BUTTON_LEFT and not disabled:
		accept_event()
		inspect_requested.emit()
	elif event is InputEventMouseButton and event.pressed and event.ctrl_pressed and event.button_index == MOUSE_BUTTON_LEFT and not disabled:
		accept_event()
		stow_requested.emit()

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	var inventory = weapon_state.inventory
	var item = inventory.items.get(StringName(data.inventory_item_id)) if data is Dictionary and data.get("inventory_item_id") is String else null
	var ok := false
	if item != null and weapon_state.busy == &"" and inventory.carried(item):
		if item is Inventory.MagazineInstance: ok = weapon_state.equipped() and item.location.kind != &"magwell"
		elif item is Inventory.WeaponInstance: ok = item.location.kind != &"equipped" and item.weapon_type_id == inventory.weapon_type_id
	self_modulate = Color("b6dcae") if ok else Color("e7a59c")
	return ok

func _drop_data(_at: Vector2, data: Variant) -> void:
	self_modulate = Color.WHITE
	var id := StringName(data.inventory_item_id)
	if weapon_state.inventory.items.get(id) is Inventory.WeaponInstance: equip_requested.emit(id)
	else: weapon_state.request_action(&"reload",id)

func _process(_delta: float) -> void:
	if self_modulate != Color.WHITE and not get_global_rect().has_point(get_global_mouse_position()): self_modulate = Color.WHITE

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END: self_modulate = Color.WHITE
