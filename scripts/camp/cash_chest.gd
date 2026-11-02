extends StaticBody3D
## The camp's cash chest: the treasury as a container you open with F, beside your own carried
## inventory, to put rubles and lats in or take them out. It holds only money. The camp stock's
## rubles and lats are the authority (saved with the world, spent at the contact); opening the
## chest lays that money out as stacks, and every change inside it writes the totals back.
## Offers the same container interface as a searched body, already searched.
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
const CRATE: PackedScene = preload("res://assets/environment/scenes/crate_v1.tscn")
const CURRENCIES: Array[StringName] = [&"rubles", &"lats"]
signal search_progressed
## Shown as the container's heading in the inventory.
const TITLE := "CASH CHEST"
var stock
var inventory
## Container interface: transfers are refused while the holder is mid-action; a chest never is.
var busy: StringName = &""
## The view accepts drops into this container.
var storage := true
var _syncing := false

func _init(camp_stock = null) -> void:
	stock = camp_stock

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
	if stock != null and not stock.changed.is_connected(refill):
		stock.changed.connect(refill)
	refill()

func get_prompt() -> String:
	return "F  Open the cash chest (%d rubles, %d lats)" % [stock.count(&"rubles"), stock.count(&"lats")]

func interact(actor: Node) -> void:
	refill()
	for host in get_tree().get_nodes_in_group(&"inventory_host"):
		if host.player == actor:
			host.open(self)
			return

## Lays the treasury out as stacks of at most one item's worth each.
func refill() -> void:
	if _syncing: return
	_syncing = true
	inventory = Inventory.new(&"svt_inspired_training", 10, 0, 0, 0)
	for item in inventory.items.values().duplicate():
		if not item is Inventory.BackpackInstance: inventory.items.erase(item.id)
	inventory.active_weapon_id = &""
	inventory.pack_columns = 7
	inventory.pack_capacity = 14
	for currency in CURRENCIES:
		var left: int = stock.count(currency) if stock != null else 0
		var most := int(SupplyCatalog.get_def(currency).uses)
		while left > 0:
			var spot = inventory.empty_location_in(&"pack")
			if spot == null: break
			inventory.create_supply(currency, spot, mini(left, most))
			left -= mini(left, most)
	inventory.changed.connect(_write_back)
	_syncing = false

## Whether an item may go into the chest: money only.
func accepts(item) -> bool:
	return item is Inventory.SupplyInstance and SupplyCatalog.is_money(item.supply_id)

## The totals inside the chest become the treasury.
func _write_back() -> void:
	if _syncing or stock == null: return
	_syncing = true
	for currency in CURRENCIES:
		stock.quantities[currency] = total(currency)
	stock.changed.emit()
	_syncing = false

func total(currency: StringName) -> int:
	var sum := 0
	for item in inventory.items.values():
		if item is Inventory.SupplyInstance and item.supply_id == currency: sum += item.uses
	return sum

# --- Container interface shared with searched bodies -------------------------------------------

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
