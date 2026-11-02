extends RefCounted
## Sanitized UI projection: exact magazine contents never enter labels or tooltips.
const WeaponState = preload("res://scripts/weapons/prototype_weapon_state.gd")
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")

static func record(item, inventory) -> Dictionary:
	var result := {"id":str(item.id),"slot":item.location.slot,"title":"Item","quantity":"","kind":"parts","size":inventory.footprint(item,item.location.rotated),"rotated":item.location.rotated}
	if item is Inventory.MagazineInstance:
		result.merge({"title":item.label,"quantity":inventory.knowledge(item.id),"kind":"magazine"},true)
	elif item is Inventory.AmmoStack:
		result.merge({"title":inventory.ammo_definitions[item.ammo_type_id].display_name,"quantity":str(item.quantity),"kind":"rounds"},true)
	elif item is Inventory.BackpackInstance:
		result.merge({"title":item.label,"quantity":"Worn" if item.location.kind==&"worn" else "","kind":"backpack"},true)
	elif item is Inventory.WeaponInstance:
		result.merge({"title":"Rifle","quantity":"Equipped" if item.location.kind==&"equipped" else "Carried","kind":"rifle"},true)
	return result

static func from_state(state, appearance = null, demo_mode := false) -> Dictionary:
	var inventory = state.inventory
	var gun = inventory.weapon() if state.equipped() else null
	var pockets: Array = []
	var pack: Array = []
	var backpack = inventory.backpack()
	for item in inventory.items.values():
		if item.location.kind == &"pocket": pockets.append(record(item,inventory))
		elif item.location.kind == &"pack" and backpack != null and item.location.owner_id == backpack.id: pack.append(record(item,inventory))
	return {
		"demo":demo_mode,"runtime":state,"character_name":"Your character","appearance":appearance,
		"rifle":state.definition.display_name.capitalize() if state.equipped() else "No equipped rifle",
		"magazine_id":str(gun.inserted_magazine_id) if gun != null else "","magazine_knowledge":inventory.knowledge(gun.inserted_magazine_id) if gun != null and gun.inserted_magazine_id!=&"" else "No magazine",
		"chamber":gun!=null and gun.chambered_round!=null,"equipped":state.equipped(),"loose":state.loose_rounds,
		"cleanliness":roundi(state.cleanliness*100),"jammed":state.jammed,
		"outfit":{},"pack_items":pack,"pocket_items":pockets,
		"backpack_id":str(backpack.id) if backpack != null else "","backpack":backpack.label if backpack != null else "",
	}

static func from_training(player: Node) -> Dictionary:
	return from_state(player.weapon.state,player.get_node_or_null("BodyVisual"))

static func demo() -> Dictionary:
	return from_state(WeaponState.new(),null,true)
