extends RefCounted
## Drill supplies staged in the combat arena near the ammunition crate: one searchable body
## and an assortment of loose combat supplies on the ground. Every item is a real physical
## item with its own ID; quantities and positions are placeholders for practice, not balance.
## Arena reset restages them, like the enemies' fresh magazines.
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
const BodyContainer = preload("res://scripts/inventory/body_container.gd")
const GroundEquipment = preload("res://scripts/inventory/ground_equipment.gd")
const GROUP := &"arena_supplies"
const BODY_SPOT := Vector3(6.5, 0, 25.5)

## Holder for loose ground items, in the shape GroundEquipment expects.
class Stock extends RefCounted:
	var inventory
	var busy: StringName = &""

static func stage(arena: Node3D, weapon_id: StringName = &"svt_inspired_training", capacity := 10) -> Array:
	var placed: Array = [_stage_body(arena, weapon_id, capacity)]
	var stock := Stock.new()
	stock.inventory = Inventory.new(weapon_id, capacity, 0, 0, 0)
	stock.inventory.items.clear()
	stock.inventory.active_weapon_id = &""
	var supplies: Array = [
		[_rifle(stock.inventory, 0.8), Vector3(-2.0, 0.06, 21.8)],
		[_magazine(stock.inventory, "Magazine D", 10), Vector3(-4.5, 0.06, 23.0)],
		[_magazine(stock.inventory, "Magazine E", 4), Vector3(-3.3, 0.06, 23.0)],
		[_magazine(stock.inventory, "Magazine F", 0), Vector3(-2.1, 0.06, 23.0)],
		[_stack(stock.inventory, 32), Vector3(-0.6, 0.06, 23.0)],
		[_stack(stock.inventory, 14), Vector3(0.6, 0.06, 23.0)],
		[_stack(stock.inventory, 5), Vector3(1.8, 0.06, 23.0)],
	]
	# A second row of medical supplies, food and water to practise treatment.
	var row := [&"cloth_bandage", &"cloth_bandage", &"field_dressing", &"tourniquet", &"splint", &"sulfa_powder", &"morphine", &"medical_satchel", &"surgical_kit", &"canteen", &"rye_bread", &"tinned_meat"]
	for index in range(row.size()):
		supplies.append([stock.inventory.create_supply(row[index]), Vector3(-4.5 + index * 0.9, 0.06, 20.6)])
	for supply in supplies:
		var item = supply[0]
		item.location = Inventory.Location.new(&"ground", &"world")
		item.location.position = supply[1]
		var pickup := GroundEquipment.new()
		pickup.weapon_state = stock
		pickup.item_id = item.id
		pickup.add_to_group(GROUP)
		arena.add_child(pickup)
		pickup.position = supply[1]
		placed.append(pickup)
	return placed

## A fallen rifleman by the crate: rifle with a few rounds left, two spare magazines, a stack
## and a field dressing.
static func _stage_body(arena: Node3D, weapon_id: StringName, capacity: int) -> Node3D:
	var gear = Inventory.new(weapon_id, capacity, 3, 10, 12)
	gear.items.erase(gear.backpack().id)
	var extra = _magazine(gear, "Magazine C", 7)
	extra.location = gear.empty_location_in(&"pocket", extra.id)
	gear.create_supply(&"field_dressing", gear.empty_location_in(&"pocket"))
	var body := BodyContainer.new()
	body.inventory = gear
	body.add_to_group(GROUP)
	arena.add_child(body)
	body.position = BODY_SPOT
	# Blockout figure lying on the ground; not character art.
	var figure := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.22
	capsule.height = 1.7
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color("4b4a3a")
	capsule.material = cloth
	figure.mesh = capsule
	figure.rotation = Vector3(0, 0.6, PI / 2)
	figure.position.y = 0.22
	body.add_child(figure)
	return body

static func _rifle(inventory, condition: float):
	var gun = Inventory.WeaponInstance.new()
	gun.id = Inventory.new_id("rifle")
	gun.weapon_type_id = inventory.weapon_type_id
	gun.condition = condition
	inventory.items[gun.id] = gun
	return gun

static func _magazine(inventory, label: String, rounds: int):
	var mag = Inventory.MagazineInstance.new()
	mag.id = Inventory.new_id("magazine")
	mag.magazine_type_id = inventory.magazine_type_id
	mag.capacity = inventory.magazine_definitions[inventory.magazine_type_id].capacity
	mag.label = label
	mag.location = Inventory.Location.new(&"ground", &"world")
	for index in range(rounds):
		mag.rounds.append(Inventory.MagazineRound.new(inventory.primary_ammo_id))
	inventory.items[mag.id] = mag
	return mag

static func _stack(inventory, quantity: int):
	var stack = Inventory.AmmoStack.new()
	stack.id = Inventory.new_id("cartridges")
	stack.ammo_type_id = inventory.primary_ammo_id
	stack.quantity = quantity
	inventory.items[stack.id] = stack
	return stack
