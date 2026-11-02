extends Button
## Equipped rifle slot. Left click selects; right click asks for the rifle's action menu.
## A dragged magazine tints the slot while hovering; reload still validates in the weapon owner.
signal menu_requested(at: Vector2)
signal inspect_requested
const ItemCard = preload("res://ui/inventory/inventory_item_card.gd")
var weapon_state
var progress := -1.0

func set_progress(value: float) -> void:
	if is_equal_approx(value,progress): return
	progress = value
	queue_redraw()

func _draw() -> void:
	ItemCard.draw_progress(self,size,progress)

func _get_drag_data(_at: Vector2) -> Variant:
	if weapon_state == null or not weapon_state.equipped(): return null
	var preview = preload("res://ui/components/menu_panel.gd").new()
	var label := Label.new()
	label.text = "Rifle"
	preview.add_child(label)
	set_drag_preview(preview)
	var gun = weapon_state.inventory.weapon()
	return {"inventory_item_id":str(gun.id),"cells":weapon_state.inventory.footprint(gun),"rotated":false,"turned":false,"preview":preview}

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and not disabled:
		accept_event()
		menu_requested.emit(get_screen_transform() * event.position)
	elif event is InputEventMouseButton and event.pressed and event.double_click and event.button_index == MOUSE_BUTTON_LEFT and not disabled:
		accept_event()
		inspect_requested.emit()

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	var mag = weapon_state.inventory.magazine(StringName(data.inventory_item_id)) if data is Dictionary and data.get("inventory_item_id") is String else null
	var ok: bool = mag != null and weapon_state.busy == &"" and weapon_state.equipped() and weapon_state.inventory.carried(mag) and mag.location.kind != &"magwell"
	self_modulate = Color("b6dcae") if ok else Color("e7a59c")
	return ok

func _drop_data(_at: Vector2, data: Variant) -> void:
	self_modulate = Color.WHITE
	weapon_state.request_action(&"reload",StringName(data.inventory_item_id))

func _process(_delta: float) -> void:
	if self_modulate != Color.WHITE and not get_global_rect().has_point(get_global_mouse_position()): self_modulate = Color.WHITE

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END: self_modulate = Color.WHITE
