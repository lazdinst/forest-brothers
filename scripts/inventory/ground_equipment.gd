extends StaticBody3D
## Local F-interaction adapter for one persistent item ID, not a second item copy.
## Its blockout shape and label follow the item, so different supplies read apart.
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
var weapon_state
var item_id: StringName
var claimed := false

## Blockout size and colour per item kind; placeholders, not item art.
const LOOKS := {
	&"weapon":[Vector3(1.1,0.07,0.16),Color("5a4632")],
	&"magazine":[Vector3(0.17,0.05,0.09),Color("3d3f42")],
	&"ammo_stack":[Vector3(0.13,0.05,0.09),Color("9a7a3c")],
	&"backpack":[Vector3(0.5,0.22,0.36),Color("5b5a3e")],
	&"supply":[Vector3(0.16,0.07,0.12),Color("d6ccb4")],
}

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var item = weapon_state.inventory.items.get(item_id) if weapon_state != null else null
	var look: Array = LOOKS.get(item.kind if item != null else &"",[Vector3(0.28,0.08,0.15),Color("5c5547")])
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = look[0] + Vector3(0.08,0.08,0.08)
	shape.shape = box
	add_child(shape)
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = look[0]
	var material := StandardMaterial3D.new()
	material.albedo_color = look[1]
	material.roughness = 0.75
	geometry.material = material
	mesh.mesh = geometry
	add_child(mesh)
	var label := Label3D.new()
	label.text = "F · " + caption()
	label.font_size = 24
	label.position.y = 0.26
	label.pixel_size = 0.002
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

## What the item is, as a carrier would see it: stacks show their count, magazines never do.
func caption() -> String:
	var inventory = weapon_state.inventory if weapon_state != null else null
	var item = inventory.items.get(item_id) if inventory != null else null
	if item == null: return "recover equipment"
	match item.kind:
		&"weapon": return "rifle"
		&"magazine": return item.label.to_lower()
		&"ammo_stack": return "%d × %s" % [item.quantity,inventory.ammo_definitions[item.ammo_type_id].display_name]
		&"backpack": return item.label.to_lower()
		&"supply": return SupplyCatalog.get_def(item.supply_id).name.to_lower()
	return "recover equipment"

func get_prompt() -> String:
	return "" if claimed else "F  Pick up " + caption()

func interact(actor: Node) -> void:
	if claimed or actor.get("weapon") == null: return
	if weapon_state.busy != &"" or actor.weapon.state.busy != &"": return
	if not weapon_state.inventory.transfer_ground_item_to(item_id,actor.weapon.state.inventory):
		actor.weapon.state.message = weapon_state.inventory.error
		return
	claimed = true
	queue_free()
