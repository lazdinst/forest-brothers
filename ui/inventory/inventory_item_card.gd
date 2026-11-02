extends Button
## Drag payload carries only an item ID; the rule owner validates every drop.
var item_id: StringName

func _get_drag_data(_at: Vector2) -> Variant:
	if item_id == &"": return null
	var preview = preload("res://ui/components/menu_panel.gd").new()
	var label := Label.new()
	label.text = tooltip_text
	preview.add_child(label)
	set_drag_preview(preview)
	return {"inventory_item_id":str(item_id)}

func _can_drop_data(at: Vector2, data: Variant) -> bool:
	return get_parent()._can_drop_data(position+at,data)

func _drop_data(at: Vector2, data: Variant) -> void:
	get_parent()._drop_data(position+at,data)
