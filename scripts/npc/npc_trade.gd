extends RefCounted
## What one NPC trades, for any NPC with trade stock: a few lots of goods at fixed prices in
## rubles or lats, paid from the camp treasury, with limited stock that comes back slowly (some
## lots per outing) rather than an endless shop. Bought items go to the carried inventory, or the
## goods chest when there is no room; bought stores go to the camp stores. Selling uses the camp's
## cheap sale values. Stock left is kept in the NPC's saved state.
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
var definition
var state
## CampRuntime: the treasury (stock), sale values and selling.
var runtime
## Inventories bought items may go to, in order (carried, then the goods chest).
var destinations: Array = []

func _init(npc_definition, npc_state, camp_runtime) -> void:
	definition = npc_definition
	state = npc_state
	runtime = camp_runtime

## Brings lots back for the outings since the last restock; a first meeting starts full.
func restock(outing: int) -> void:
	for lot in definition.trade_stock:
		var id := str(lot.id)
		if not state.stock_left.has(id) or state.restocked_outing < 0:
			state.stock_left[id] = int(lot.get("max", 1))
		elif outing > state.restocked_outing:
			state.stock_left[id] = mini(int(lot.get("max", 1)), state.stock_left[id] + int(lot.get("restock", 1)) * (outing - state.restocked_outing))
	state.restocked_outing = maxi(outing, state.restocked_outing)

## The lots on offer: [{"id", "label", "amount", "rubles", "lats", "left"}].
func offers() -> Array:
	var list: Array = []
	for lot in definition.trade_stock:
		list.append({"id": str(lot.id), "label": str(lot.label), "amount": int(lot.get("amount", 1)),
			"rubles": int(lot.rubles), "lats": int(lot.lats), "left": int(state.stock_left.get(str(lot.id), 0))})
	return list

func can_buy(id: String, currency: StringName) -> bool:
	var lot := _lot(id)
	return not lot.is_empty() and int(state.stock_left.get(id, 0)) > 0 and runtime.stock.count(currency) >= int(lot[str(currency)]) and (lot.kind == "stores" or _room_for(StringName(lot.supply)) != null)

## Buys one lot, paying from the treasury.
func buy(id: String, currency: StringName) -> bool:
	if not can_buy(id, currency):
		runtime.message = "He has none left, or the cash chest is short, or there is nowhere to put it."
		return false
	var lot := _lot(id)
	if lot.kind == "stores":
		if not runtime.stock.try_exchange({currency: int(lot[str(currency)])}, {StringName(lot.stock): int(lot.get("amount", 1))}): return false
	else:
		var holder = _room_for(StringName(lot.supply))
		if not runtime.stock.try_exchange({currency: int(lot[str(currency)])}, {}): return false
		for count in range(int(lot.get("amount", 1))):
			var spot = holder.empty_location(&"", _size(StringName(lot.supply)))
			if spot == null: break
			holder.create_supply(StringName(lot.supply), spot)
	state.stock_left[id] = int(state.stock_left[id]) - 1
	state.flags["provided_supplies"] = true
	runtime.message = "Bought %s for %d %s." % [str(lot.label).to_lower(), int(lot[str(currency)]), currency]
	return true

## Hands a supply item over as a gift (no payment); returns false when there is no room anywhere.
func give(supply_id: StringName) -> bool:
	var holder = _room_for(supply_id)
	if holder == null: return false
	holder.create_supply(supply_id, holder.empty_location(&"", _size(supply_id)))
	return true

func _room_for(supply_id: StringName):
	for inventory in destinations:
		if inventory != null and inventory.empty_location(&"", _size(supply_id)) != null: return inventory
	return null

static func _size(supply_id: StringName) -> Vector2i:
	return SupplyCatalog.get_def(supply_id).get("size", Vector2i.ONE)

func _lot(id: String) -> Dictionary:
	for lot in definition.trade_stock:
		if str(lot.id) == id: return lot
	return {}
