extends "res://scripts/camp/storage_chest.gd"
## The camp's cash chest: the treasury as a container. It holds only rubles and lats. The camp
## stock's rubles and lats are the authority (saved with the world, spent at the contact);
## opening the chest lays that money out as stacks, and every change inside it writes the totals
## back.
const CURRENCIES: Array[StringName] = [&"rubles", &"lats"]
var stock
var _syncing := false

func _init(camp_stock = null) -> void:
	stock = camp_stock
	title = "CASH CHEST"
	cell = 48

func _ready() -> void:
	super._ready()
	if stock != null and not stock.changed.is_connected(refill):
		stock.changed.connect(refill)
	refill()

func get_prompt() -> String:
	return "F  Open the cash chest (%d rubles, %d lats)" % [stock.count(&"rubles"), stock.count(&"lats")]

func interact(actor: Node) -> void:
	refill()
	super.interact(actor)

## Lays the treasury out as stacks of at most one item's worth each.
func refill() -> void:
	if _syncing: return
	_syncing = true
	inventory = empty_inventory()
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

## Money only.
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
