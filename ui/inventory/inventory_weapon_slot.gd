extends Button
var weapon_state

func _get_drag_data(_at: Vector2) -> Variant:
	if weapon_state == null or not weapon_state.equipped(): return null
	var preview = preload("res://ui/components/menu_panel.gd").new()
	var label := Label.new()
	label.text = "Rifle"
	preview.add_child(label)
	set_drag_preview(preview)
	return {"inventory_item_id":str(weapon_state.inventory.active_weapon_id)}

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("inventory_item_id") is String and weapon_state.inventory.magazine(StringName(data.inventory_item_id)) != null

func _drop_data(_at: Vector2, data: Variant) -> void:
	weapon_state.request_action(&"reload",StringName(data.inventory_item_id))
