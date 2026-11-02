extends StaticBody3D
## Local F-interaction adapter for one persistent item ID, not a second item copy.
var weapon_state
var item_id: StringName
var claimed := false

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.36,0.16,0.22)
	shape.shape = box
	add_child(shape)
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = Vector3(0.28,0.08,0.15)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("5c5547")
	material.roughness = 0.75
	geometry.material = material
	mesh.mesh = geometry
	add_child(mesh)
	var label := Label3D.new()
	label.text = "F · recover equipment"
	label.font_size = 24
	label.position.y = 0.26
	label.pixel_size = 0.002
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func get_prompt() -> String:
	return "" if claimed else "F  Recover dropped equipment"

func interact(actor: Node) -> void:
	if claimed or actor.get("weapon") == null: return
	if weapon_state.busy != &"" or actor.weapon.state.busy != &"": return
	if not weapon_state.inventory.transfer_ground_item_to(item_id,actor.weapon.state.inventory):
		actor.weapon.state.message = weapon_state.inventory.error
		return
	claimed = true
	queue_free()
