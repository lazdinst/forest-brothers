extends RefCounted
## Quick-use keys, as in Tarkov: 1 is always the primary rifle; 2 to 0 can each be bound to a
## carried item (a supply, a magazine or another rifle) by hovering over it in the inventory and
## pressing the number. Pressing a bound key uses the item: a supply treats the most urgent wound
## it can (or is eaten or drunk), a magazine is loaded into the rifle, a rifle is equipped.
## Bindings follow the item's identity, so they survive moving it between pockets and pack, and
## a binding whose item is no longer carried shows empty. Saved with the character.
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
## Slot numbers 2 to 10; 10 is the 0 key.
const FIRST_BINDABLE := 2
const LAST_SLOT := 10
## Slot -> item id.
var slots := {}

## The slot a number key stands for (1 to 9, and 0 as 10), or 0 for other keys.
static func slot_for_key(physical_keycode: int) -> int:
	if physical_keycode >= KEY_1 and physical_keycode <= KEY_9: return physical_keycode - KEY_0
	return LAST_SLOT if physical_keycode == KEY_0 else 0

static func key_label(slot: int) -> String:
	return "0" if slot == LAST_SLOT else str(slot)

## Supplies (not money or mission items), magazines and rifles can be bound.
static func bindable(inventory, item) -> bool:
	if item == null or not inventory.carried(item): return false
	if item is Inventory.SupplyInstance: return not SupplyCatalog.is_money(item.supply_id) and not SupplyCatalog.is_objective(item.supply_id)
	return item is Inventory.MagazineInstance or item is Inventory.WeaponInstance

## Binds an item to a slot (moving it off any other slot); binding it to its own slot again
## clears it. Returns false for slot 1 or an item that cannot be bound.
func bind(slot: int, item_id: StringName, inventory) -> bool:
	if slot < FIRST_BINDABLE or slot > LAST_SLOT or not bindable(inventory, inventory.items.get(item_id)): return false
	if slots.get(slot) == item_id:
		slots.erase(slot)
		return true
	for other in slots.keys():
		if slots[other] == item_id: slots.erase(other)
	slots[slot] = item_id
	return true

## The item on a slot, or null when nothing bound is still carried.
func item_on(slot: int, inventory):
	var item = inventory.items.get(slots.get(slot, &""))
	return item if item != null and inventory.carried(item) else null

func slot_of(item_id: StringName) -> int:
	for slot in slots:
		if slots[slot] == item_id: return slot
	return 0

func encode() -> Dictionary:
	var saved := {}
	for slot in slots: saved[str(slot)] = str(slots[slot])
	return saved

func restore(saved: Dictionary) -> void:
	slots.clear()
	for key in saved:
		var slot := int(key)
		if slot >= FIRST_BINDABLE and slot <= LAST_SLOT: slots[slot] = StringName(saved[key])
