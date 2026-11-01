extends StaticBody3D
## Emits a one-shot collection request into the local prototype session.

signal collected(item_id: StringName, amount: int)

@export var item_id: StringName = &"food"
@export var display_name: String = "Food tin"
@export var amount: int = 1
var claimed: bool = false


func get_prompt() -> String:
	return "" if claimed else "F  Collect %s" % display_name


func interact(_actor: Node) -> void:
	if claimed:
		return
	claimed = true
	collected.emit(item_id, amount)
	hide()
	set_collision_layer_value(1, false)
	queue_free()
