extends "res://scripts/camp/storage_chest.gd"
## The camp's goods chest: communal storage for carried things (supplies, magazines, cartridges,
## spare rifles). Money goes in the cash chest and mission objective items are handed in, so
## neither goes here; a backpack stays worn. Its contents are saved with the world's camp.
signal contents_changed

func _init() -> void:
	title = "GOODS CHEST"
	# A large communal stash (owner: "like 1000 squares"); the inventory scrolls through it.
	columns = 10
	rows = 100
	cell = 36

func _ready() -> void:
	super._ready()
	inventory.changed.connect(func(): contents_changed.emit())

func accepts(item) -> bool:
	if item is Inventory.BackpackInstance: return false
	if item is Inventory.SupplyInstance and (SupplyCatalog.is_money(item.supply_id) or SupplyCatalog.is_objective(item.supply_id)): return false
	return true

## JSON-safe contents for the world save.
func encode() -> Dictionary:
	return inventory.encode()

## Replaces the contents with a saved snapshot; an unreadable one leaves the chest empty.
func restore(snapshot: Dictionary) -> bool:
	if inventory == null:
		inventory = empty_inventory()
		inventory.changed.connect(func(): contents_changed.emit())
	if snapshot.is_empty(): return true
	# A save from a smaller chest of the same width restores into it, then grows to full size.
	var capacity := columns * rows
	inventory.pack_capacity = int(snapshot.get("pack_capacity", capacity))
	var restored: bool = inventory.restore(snapshot)
	inventory.pack_capacity = capacity
	if not restored:
		push_warning("Goods chest contents could not be restored: " + inventory.error)
	return restored
