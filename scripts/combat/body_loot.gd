extends RefCounted
## Turns a dead enemy's remaining magazines into recoverable ground items at its body.
## Round counts move exactly; nothing is created. The enemy's rifle stays with the body for now.
const AmmunitionInventory = preload("res://scripts/inventory/ammunition_inventory.gd")
const GroundEquipment = preload("res://scripts/inventory/ground_equipment.gd")
const GROUP := &"combat_loot"
## GroundEquipment refuses transfers while its holder is mid-action; a body never is.
var busy: StringName = &""
var inventory

static func drop(enemy: Node3D, weapon_id: StringName = &"svt_inspired_training") -> Array:
	var counts: Array[int] = [enemy.rounds_in_magazine]
	counts.append_array(enemy.spare_magazines)
	var loot = new()
	loot.inventory = AmmunitionInventory.new(weapon_id, enemy.magazine_size, counts[0], counts[1] if counts.size() > 1 else 0, 0)
	var inventory = loot.inventory
	var gun = inventory.weapon()
	gun.inserted_magazine_id = &""
	var magazines: Array = []
	for id in inventory.initial_magazine_ids:
		magazines.append(inventory.magazine(id))
	if counts.size() < 2:
		inventory.items.erase(magazines[1].id)
		magazines.resize(1)
	for index in range(2, counts.size()):
		var extra = AmmunitionInventory.MagazineInstance.new()
		extra.id = AmmunitionInventory.new_id("magazine")
		extra.magazine_type_id = inventory.magazine_type_id
		extra.capacity = enemy.magazine_size
		extra.label = "Magazine %s" % char(65 + index)
		for round_index in range(counts[index]):
			extra.rounds.append(AmmunitionInventory.MagazineRound.new(inventory.primary_ammo_id))
		inventory.items[extra.id] = extra
		magazines.append(extra)
	var pickups: Array = []
	var space := enemy.get_world_3d().direct_space_state
	for index in range(magazines.size()):
		var spot: Vector3 = enemy.global_position + Vector3(cos(index * 2.1) * 0.6, 0.0, sin(index * 2.1) * 0.6)
		var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(spot + Vector3.UP, spot + Vector3.DOWN * 3, 1, [enemy.get_rid()]))
		var at: Vector3 = (ground.position if not ground.is_empty() else spot) + Vector3.UP * 0.12
		var location = AmmunitionInventory.Location.new(&"ground", &"world")
		location.position = at
		magazines[index].location = location
		var pickup := GroundEquipment.new()
		pickup.weapon_state = loot
		pickup.item_id = magazines[index].id
		pickup.add_to_group(GROUP)
		enemy.get_parent().add_child(pickup)
		pickup.global_position = at
		pickups.append(pickup)
	# Custody moved to the ground; the body no longer carries these rounds.
	enemy.rounds_in_magazine = 0
	enemy.spare_magazines.clear()
	return pickups
