extends StaticBody3D
## A camp chest: a container you open with F, beside your own carried inventory, to put items
## in or take them out. Offers the same container interface as a searched body, already searched,
## plus `storage` so the inventory view accepts drops. Subclasses choose what it accepts and how
## its contents are kept. The crate is the environment library's crate.
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
const CRATE: PackedScene = preload("res://assets/environment/scenes/crate_v1.tscn")
signal search_progressed
## Shown as the container's heading in the inventory.
var title := "CHEST"
var inventory
## Container interface: transfers are refused while the holder is mid-action; a chest never is.
var busy: StringName = &""
## The view accepts drops into this container, laid out in a grid of this shape.
var storage := true
var columns := 7
var rows := 2
var cell := 64

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.06, 0.82, 0.84)
	shape.shape = box
	shape.position.y = 0.41
	add_child(shape)
	add_child(CRATE.instantiate())
	if inventory == null:
		inventory = empty_inventory()

## An inventory that is only a grid of pack space (it keeps the backpack that holds the grid).
func empty_inventory():
	var holder = Inventory.new(&"svt_inspired_training", 10, 0, 0, 0)
	for item in holder.items.values().duplicate():
		if not item is Inventory.BackpackInstance: holder.items.erase(item.id)
	holder.active_weapon_id = &""
	holder.pack_columns = columns
	holder.pack_capacity = columns * rows
	return holder

func get_prompt() -> String:
	return "F  Open the " + title.to_lower()

func interact(actor: Node) -> void:
	for host in get_tree().get_nodes_in_group(&"inventory_host"):
		if host.player == actor:
			host.open(self)
			return

## Whether an item may go in; subclasses narrow this.
func accepts(_item) -> bool:
	return true

func searching() -> bool:
	return false

func search_progress() -> float:
	return -1.0

func advance_search(_delta: float) -> void:
	pass

func is_revealed(id: StringName) -> bool:
	return inventory.items.has(id)

func visible_items() -> Array:
	return inventory.items.values().filter(func(item): return item.location.kind == &"pack")
