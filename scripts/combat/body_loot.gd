extends RefCounted
## Leaves a dead enemy's rifle and magazines on its body as a searchable container, with a few
## rubles. Round counts move exactly. The rifle keeps its inserted magazine.
const AmmunitionInventory = preload("res://scripts/inventory/ammunition_inventory.gd")
const BodyContainer = preload("res://scripts/inventory/body_container.gd")
const GroundEquipment = preload("res://scripts/inventory/ground_equipment.gd")
const GROUP := &"combat_loot"

static func drop(enemy: Node3D, weapon_id: StringName = &"svt_inspired_training") -> Array:
	var counts: Array[int] = [enemy.rounds_in_magazine]
	counts.append_array(enemy.spare_magazines)
	var inventory = AmmunitionInventory.new(weapon_id, enemy.magazine_size, counts[0], counts[1] if counts.size() > 1 else 0, 0)
	# Enemies carry no backpack; their spares sit in pockets.
	inventory.items.erase(inventory.backpack().id)
	if counts.size() < 2:
		inventory.items.erase(inventory.initial_magazine_ids[1])
	var overflow: Array = []
	for index in range(2, counts.size()):
		var extra = AmmunitionInventory.MagazineInstance.new()
		extra.id = AmmunitionInventory.new_id("magazine")
		extra.magazine_type_id = inventory.magazine_type_id
		extra.capacity = enemy.magazine_size
		extra.label = "Magazine %s" % char(65 + index)
		for round_index in range(counts[index]):
			extra.rounds.append(AmmunitionInventory.MagazineRound.new(inventory.primary_ammo_id))
		extra.location = AmmunitionInventory.Location.new(&"ground", &"world")
		inventory.items[extra.id] = extra
		var pocket = inventory.empty_location_in(&"pocket", extra.id)
		if pocket != null: extra.location = pocket
		else: overflow.append(extra)
	# A few rubles in a pocket, when one is free (placeholder amounts).
	var pocket_for_money = inventory.empty_location_in(&"pocket")
	if pocket_for_money != null:
		inventory.create_supply(&"rubles", pocket_for_money, randi_range(5, 40))
	var space := enemy.get_world_3d().direct_space_state
	var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(enemy.global_position + Vector3.UP, enemy.global_position + Vector3.DOWN * 3, 1, [enemy.get_rid()]))
	var body := BodyContainer.new()
	body.inventory = inventory
	body.add_to_group(GROUP)
	enemy.get_parent().add_child(body)
	body.global_position = ground.position if not ground.is_empty() else enemy.global_position
	var placed: Array = [body]
	# More magazines than pockets: the rest lie beside the body rather than vanish.
	for index in range(overflow.size()):
		var spot: Vector3 = body.global_position + Vector3(cos(index * 2.1) * 0.8, 0.12, sin(index * 2.1) * 0.8)
		overflow[index].location.position = spot
		var pickup := GroundEquipment.new()
		pickup.weapon_state = body
		pickup.item_id = overflow[index].id
		pickup.add_to_group(GROUP)
		enemy.get_parent().add_child(pickup)
		pickup.global_position = spot
		placed.append(pickup)
	# Custody moved to the body; the enemy's own counters no longer hold these rounds.
	enemy.rounds_in_magazine = 0
	enemy.spare_magazines.clear()
	return placed
