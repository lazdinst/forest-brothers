extends RefCounted
## Scene-owned physical item rules. No UI, animation, save-file or network authority.
signal changed

class AmmoDefinition extends RefCounted:
	var id: StringName
	var display_name := "Rifle cartridges"
	var caliber: StringName
	var compatible_weapon_ids: Array[StringName] = []
	var icon_asset_id := "rounds"
	var max_stack_size := 32

class MagazineDefinition extends RefCounted:
	var id: StringName
	var caliber: StringName
	var capacity := 10
	var compatible_ammo_ids: Array[StringName] = []
	var compatible_weapon_ids: Array[StringName] = []

class Location extends RefCounted:
	var kind: StringName
	var owner_id: StringName
	var slot := -1
	var position := Vector3.ZERO
	func _init(type: StringName = &"pocket", owner: StringName = &"", index := -1) -> void:
		kind = type
		owner_id = owner
		slot = index
	func encode() -> Dictionary:
		return {"kind":str(kind),"owner_id":str(owner_id),"slot":slot,"position":[position.x,position.y,position.z]}

class MagazineRound extends RefCounted:
	var ammo_type_id: StringName
	func _init(ammo_id: StringName = &"") -> void: ammo_type_id = ammo_id

class Item extends RefCounted:
	var id: StringName
	var kind: StringName
	var location: Location

class AmmoStack extends Item:
	var ammo_type_id: StringName
	var quantity := 0
	func _init() -> void: kind = &"ammo_stack"

class MagazineInstance extends Item:
	var magazine_type_id: StringName
	var capacity := 10
	var rounds: Array[MagazineRound] = []
	var condition := 1.0
	var inspected := false
	var estimate := "Unknown"
	var label := "Magazine"
	func _init() -> void: kind = &"magazine"

class WeaponInstance extends Item:
	var weapon_type_id: StringName
	var inserted_magazine_id: StringName = &""
	var chambered_round: MagazineRound
	var condition := 1.0
	var jammed := false
	func _init() -> void: kind = &"weapon"

const POCKET_CAPACITY := 4
var pack_capacity := 36 # Existing reversible layout, not approved final balance.
var owner_id: StringName
var items: Dictionary[StringName, Item] = {}
var ammo_definitions: Dictionary[StringName, AmmoDefinition] = {}
var magazine_definitions: Dictionary[StringName, MagazineDefinition] = {}
var active_weapon_id: StringName
var weapon_type_id: StringName
var primary_ammo_id: StringName = &"training_rifle_ball"
var magazine_type_id: StringName = &"training_rifle_magazine"
var initial_magazine_ids: Array[StringName] = []
var estimate_thresholds := [0.9,0.5,0.3]
var error := ""

func _init(weapon_id: StringName = &"svt_inspired_training", capacity := 10, first := 10, second := 10, loose := 32, owner: StringName = &"", ammo_id: StringName = &"training_rifle_ball", caliber_id: StringName = &"7.62x54", mag_type: StringName = &"training_rifle_magazine", ammo_label := "7.62 rifle rounds") -> void:
	assert(capacity > 0 and first >= 0 and first <= capacity and second >= 0 and second <= capacity and loose >= 0, "Invalid initial equipment configuration")
	owner_id = owner if owner != &"" else new_id("carrier")
	weapon_type_id = weapon_id
	primary_ammo_id = ammo_id
	magazine_type_id = mag_type
	var ammo := AmmoDefinition.new()
	ammo.id = primary_ammo_id
	ammo.caliber = caliber_id
	ammo.display_name = ammo_label
	ammo.compatible_weapon_ids.assign([weapon_id])
	ammo_definitions[ammo.id] = ammo
	var mag_def := MagazineDefinition.new()
	mag_def.id = magazine_type_id
	mag_def.caliber = ammo.caliber
	mag_def.capacity = capacity
	mag_def.compatible_ammo_ids.assign([ammo.id])
	mag_def.compatible_weapon_ids.assign([weapon_id])
	magazine_definitions[mag_def.id] = mag_def
	var gun := WeaponInstance.new()
	gun.id = new_id("rifle")
	gun.weapon_type_id = weapon_id
	gun.location = Location.new(&"equipped", owner_id, 0)
	items[gun.id] = gun
	active_weapon_id = gun.id
	for index in range(2):
		var magazine := MagazineInstance.new()
		magazine.id = new_id("magazine")
		magazine.magazine_type_id = mag_def.id
		magazine.capacity = capacity
		magazine.label = "Magazine A" if index == 0 else "Magazine B"
		magazine.location = Location.new(&"magwell",gun.id) if index == 0 else Location.new(&"pocket",owner_id,0)
		for count in range(first if index == 0 else second): magazine.rounds.append(MagazineRound.new(ammo.id))
		items[magazine.id] = magazine
		initial_magazine_ids.append(magazine.id)
	gun.inserted_magazine_id = initial_magazine_ids[0]
	var added := add_loose(loose)
	assert(added, "Initial cartridges require valid stack space")

static func new_id(prefix: String) -> StringName:
	return StringName(prefix + "_" + Crypto.new().generate_random_bytes(16).hex_encode())

func weapon() -> WeaponInstance: return items.get(active_weapon_id) as WeaponInstance
func magazine(id: StringName) -> MagazineInstance: return items.get(id) as MagazineInstance
func equipped() -> bool: return weapon() != null and weapon().location.kind == &"equipped"

func carried(item: Item) -> bool:
	if item.location.kind in [&"pocket",&"pack",&"equipped"]: return item.location.owner_id == owner_id
	if item.location.kind == &"magwell":
		var gun := items.get(item.location.owner_id) as WeaponInstance
		return gun != null and carried(gun)
	return false

func loose_count(ammo_id: StringName = &"") -> int:
	var count := 0
	for item in items.values():
		if item is AmmoStack and carried(item) and (ammo_id == &"" or item.ammo_type_id == ammo_id): count += item.quantity
	return count

func total_rounds() -> int:
	var count := 0
	for item in items.values():
		if item is AmmoStack: count += item.quantity
		elif item is MagazineInstance: count += item.rounds.size()
		elif item is WeaponInstance and item.chambered_round != null: count += 1
	return count

func empty_location(excluding: StringName = &"") -> Location:
	for kind in [&"pocket",&"pack"]:
		for index in range(POCKET_CAPACITY if kind == &"pocket" else pack_capacity):
			var location := Location.new(kind,owner_id,index)
			if occupant(location,excluding) == null: return location
	return null

func occupant(location: Location, excluding: StringName = &"") -> Item:
	for item in items.values():
		if item.id != excluding and item.location.kind == location.kind and item.location.owner_id == location.owner_id and item.location.slot == location.slot: return item
	return null

func valid_slot(location: Location) -> bool:
	return location != null and location.owner_id == owner_id and location.kind in [&"pocket",&"pack"] and location.slot >= 0 and location.slot < (POCKET_CAPACITY if location.kind == &"pocket" else pack_capacity)

## Side-effect-free checks so a view can preview whether a drop would be accepted.
## The mutating commands below still validate on their own.
func can_move_item(id: StringName, destination: Location) -> bool:
	var item: Item = items.get(id)
	return item != null and carried(item) and item.location.kind != &"magwell" and valid_slot(destination) and occupant(destination,id) == null

func can_merge_stacks(source_id: StringName, target_id: StringName) -> bool:
	var source := items.get(source_id) as AmmoStack
	var target := items.get(target_id) as AmmoStack
	return source != null and target != null and source != target and carried(source) and carried(target) and source.ammo_type_id == target.ammo_type_id and target.quantity < 32

func can_load_round(magazine_id: StringName, stack_id: StringName) -> bool:
	var mag := magazine(magazine_id)
	var stack := items.get(stack_id) as AmmoStack
	return mag != null and stack != null and carried(mag) and mag.location.kind != &"magwell" and carried(stack) and compatible(mag,stack.ammo_type_id) and mag.rounds.size() < mag.capacity

func move_item(id: StringName, destination: Location) -> bool:
	var item: Item = items.get(id)
	if item == null or not carried(item) or item.location.kind == &"magwell": return fail("Remove the inserted magazine first")
	if not can_move_item(id,destination): return fail("That slot is unavailable")
	item.location = destination
	_notify_changed()
	return true

func compatible(mag: MagazineInstance, ammo_id: StringName) -> bool:
	if mag == null or not ammo_definitions.has(ammo_id) or not magazine_definitions.has(mag.magazine_type_id): return false
	var definition := magazine_definitions[mag.magazine_type_id]
	return ammo_definitions[ammo_id].caliber == definition.caliber and ammo_id in definition.compatible_ammo_ids

func can_add_loose(amount: int, ammo_id: StringName = &"") -> bool:
	if ammo_id == &"": ammo_id = primary_ammo_id
	if amount < 0 or not ammo_definitions.has(ammo_id): return false
	var available := 0
	for item in items.values():
		if item is AmmoStack and carried(item) and item.ammo_type_id == ammo_id: available += 32 - item.quantity
	for kind in [&"pocket",&"pack"]:
		for index in range(4 if kind == &"pocket" else pack_capacity):
			if occupant(Location.new(kind,owner_id,index)) == null: available += 32
	return amount <= available

func add_loose(amount: int, ammo_id: StringName = &"") -> bool:
	if ammo_id == &"": ammo_id = primary_ammo_id
	if not can_add_loose(amount,ammo_id): return fail("No room for cartridges")
	var remaining := amount
	for item in items.values():
		if item is AmmoStack and carried(item) and item.ammo_type_id == ammo_id:
			var transfer := mini(32-item.quantity,remaining)
			item.quantity += transfer
			remaining -= transfer
	while remaining > 0:
		var stack := AmmoStack.new()
		stack.id = new_id("cartridges")
		stack.ammo_type_id = ammo_id
		stack.quantity = mini(32,remaining)
		stack.location = empty_location()
		items[stack.id] = stack
		remaining -= stack.quantity
	_notify_changed()
	return true

func remove_loose(amount: int, ammo_id: StringName = &"") -> bool:
	if ammo_id == &"": ammo_id = primary_ammo_id
	if amount < 0 or amount > loose_count(ammo_id): return false
	for item in items.values():
		if amount == 0: break
		if item is AmmoStack and carried(item) and item.ammo_type_id == ammo_id:
			var transfer := mini(amount,item.quantity)
			item.quantity -= transfer
			amount -= transfer
			if item.quantity == 0: items.erase(item.id)
	_notify_changed()
	return true

func split_stack(id: StringName, amount: int) -> StringName:
	var source := items.get(id) as AmmoStack
	var destination := empty_location()
	if source == null or not carried(source) or amount <= 0 or amount >= source.quantity or destination == null:
		fail("Split needs a partial amount and a free slot")
		return &""
	var stack := AmmoStack.new()
	stack.id = new_id("cartridges")
	stack.ammo_type_id = source.ammo_type_id
	stack.quantity = amount
	stack.location = destination
	source.quantity -= amount
	items[stack.id] = stack
	_notify_changed()
	return stack.id

func merge_stacks(source_id: StringName, target_id: StringName) -> bool:
	var source := items.get(source_id) as AmmoStack
	var target := items.get(target_id) as AmmoStack
	if source == null or target == null or source == target or not carried(source) or not carried(target) or source.ammo_type_id != target.ammo_type_id: return fail("Only matching carried cartridges can merge")
	var amount := mini(source.quantity,32-target.quantity)
	if amount == 0: return fail("Stack is already full")
	target.quantity += amount
	source.quantity -= amount
	if source.quantity == 0: items.erase(source.id)
	_notify_changed()
	return true

func load_round(magazine_id: StringName, stack_id: StringName) -> bool:
	if not can_load_round(magazine_id,stack_id): return fail("Remove the magazine and use compatible cartridges")
	var mag := magazine(magazine_id)
	var stack := items.get(stack_id) as AmmoStack
	mag.rounds.append(MagazineRound.new(stack.ammo_type_id))
	stack.quantity -= 1
	if stack.quantity == 0: items.erase(stack.id)
	invalidate(mag)
	_notify_changed()
	return true

func unload_round(magazine_id: StringName) -> bool:
	var mag := magazine(magazine_id)
	if mag == null or not carried(mag) or mag.location.kind == &"magwell" or mag.rounds.is_empty(): return fail("Remove a loaded magazine first")
	var round: MagazineRound = mag.rounds.back()
	if not can_add_loose(1,round.ammo_type_id): return fail("No room for unloaded cartridges")
	mag.rounds.pop_back()
	add_loose(1,round.ammo_type_id)
	invalidate(mag)
	_notify_changed()
	return true

func insert_magazine(id: StringName) -> bool:
	var mag := magazine(id)
	var gun := weapon()
	if not equipped() or mag == null or not carried(mag) or mag.location.kind == &"magwell" or gun.weapon_type_id not in magazine_definitions[mag.magazine_type_id].compatible_weapon_ids: return fail("Magazine is not compatible or accessible")
	var old := magazine(gun.inserted_magazine_id)
	var previous_location := mag.location
	mag.location = Location.new(&"magwell",gun.id)
	gun.inserted_magazine_id = mag.id
	if old != null: old.location = previous_location
	_notify_changed()
	return true

func remove_magazine() -> bool:
	var gun := weapon()
	var destination := empty_location()
	if not equipped() or gun.inserted_magazine_id == &"" or destination == null: return fail("No magazine or no free slot")
	magazine(gun.inserted_magazine_id).location = destination
	gun.inserted_magazine_id = &""
	_notify_changed()
	return true

func chamber() -> bool:
	if not equipped() or weapon().chambered_round != null: return fail("Chamber is already loaded or no weapon equipped")
	var mag := magazine(weapon().inserted_magazine_id)
	if mag == null or mag.rounds.is_empty(): return fail("No round available to chamber")
	var next_round: MagazineRound = mag.rounds.back()
	if not ammo_definitions[next_round.ammo_type_id].compatible_weapon_ids.is_empty() and weapon().weapon_type_id not in ammo_definitions[next_round.ammo_type_id].compatible_weapon_ids: return fail("Cartridge incompatible with this weapon")
	weapon().chambered_round = mag.rounds.pop_back()
	invalidate(mag)
	_notify_changed()
	return true

func eject_chamber() -> bool:
	if not equipped() or weapon().chambered_round == null: return fail("Chamber is empty")
	var round := weapon().chambered_round
	if not can_add_loose(1,round.ammo_type_id): return fail("No room for the ejected cartridge")
	weapon().chambered_round = null
	add_loose(1,round.ammo_type_id)
	return true

func consume_shot() -> bool:
	if not equipped() or weapon().chambered_round == null: return false
	weapon().chambered_round = null
	chamber() # Cycling feeds the next round if present; no magazine is also valid.
	_notify_changed()
	return true

func inspect_magazine(id: StringName) -> bool:
	var mag := magazine(id)
	if mag == null or not carried(mag): return false
	mag.estimate = describe_fill(mag)
	mag.inspected = true
	_notify_changed()
	return true

func describe_fill(mag: MagazineInstance) -> String:
	var fraction := float(mag.rounds.size()) / mag.capacity
	return "Empty" if mag.rounds.is_empty() else ("Almost full" if fraction >= estimate_thresholds[0] else ("More than half" if fraction >= estimate_thresholds[1] else ("Less than half" if fraction >= estimate_thresholds[2] else "Almost empty")))

func knowledge(id: StringName) -> String:
	var mag := magazine(id)
	return mag.estimate if mag != null and mag.inspected else "Unknown · inspect"

func invalidate(mag: MagazineInstance) -> void:
	mag.inspected = false
	mag.estimate = "Unknown"

func drop_item(id: StringName, at: Vector3) -> bool:
	var item: Item = items.get(id)
	if item == null or not carried(item) or item.location.kind == &"magwell": return fail("Remove the inserted magazine before dropping it")
	item.location = Location.new(&"ground",&"world")
	item.location.position = at
	_notify_changed()
	return true

func pickup(id: StringName) -> bool:
	var item: Item = items.get(id)
	if item == null or item.location.kind != &"ground": return false
	var destination := empty_location()
	if item is WeaponInstance and not equipped(): destination = Location.new(&"equipped",owner_id,0)
	if destination == null: return fail("Inventory is full")
	item.location = destination
	if destination.kind == &"equipped": active_weapon_id = item.id
	_notify_changed()
	return true

func transfer_ground_item_to(id: StringName, recipient) -> bool:
	# Communal equipment can change custody. Preflight the complete weapon subtree
	# before removing anything from the source; no ID or chamber round is copied.
	var item: Item = items.get(id)
	if recipient == self: return pickup(id)
	if item == null or item.location.kind != &"ground" or recipient.weapon_type_id != weapon_type_id: return fail("Equipment cannot be recovered by this inventory")
	var destination: Location = recipient.empty_location()
	if item is WeaponInstance and not recipient.equipped(): destination = Location.new(&"equipped",recipient.owner_id,0)
	if destination == null: return fail("Recipient inventory is full")
	var subtree: Array[Item] = [item]
	if item is WeaponInstance and item.inserted_magazine_id != &"": subtree.append(magazine(item.inserted_magazine_id))
	for member in subtree:
		if member == null or recipient.items.has(member.id): return fail("Duplicate equipment ID")
	for definition_id in magazine_definitions:
		if recipient.magazine_definitions.has(definition_id) and recipient.magazine_definitions[definition_id].capacity != magazine_definitions[definition_id].capacity: return fail("Magazine definitions do not match")
	for definition_id in ammo_definitions:
		if recipient.ammo_definitions.has(definition_id) and recipient.ammo_definitions[definition_id].caliber != ammo_definitions[definition_id].caliber: return fail("Ammunition definitions do not match")
	for definition_id in ammo_definitions: recipient.ammo_definitions[definition_id] = ammo_definitions[definition_id]
	for definition_id in magazine_definitions: recipient.magazine_definitions[definition_id] = magazine_definitions[definition_id]
	for member in subtree:
		items.erase(member.id)
		recipient.items[member.id] = member
		if member is MagazineInstance: invalidate(member)
	item.location = destination
	if active_weapon_id == item.id: active_weapon_id = &""
	if destination.kind == &"equipped": recipient.active_weapon_id = item.id
	_notify_changed()
	recipient._notify_changed()
	return true

func equip_weapon(id: StringName) -> bool:
	var gun := items.get(id) as WeaponInstance
	if gun == null or not carried(gun) or gun.weapon_type_id != weapon_type_id: return false
	if equipped() and gun != weapon():
		var destination := gun.location
		weapon().location = destination
	gun.location = Location.new(&"equipped",owner_id,0)
	active_weapon_id = gun.id
	_notify_changed()
	return true

func fail(text: String) -> bool:
	error = text
	return false

func encode() -> Dictionary:
	var records: Array = []
	for item in items.values():
		var record := {"id":str(item.id),"kind":str(item.kind),"location":item.location.encode()}
		if item is AmmoStack: record.merge({"ammo_type_id":str(item.ammo_type_id),"quantity":item.quantity})
		elif item is MagazineInstance:
			var rounds: Array = []
			for round in item.rounds: rounds.append(str(round.ammo_type_id))
			record.merge({"magazine_type_id":str(item.magazine_type_id),"capacity":item.capacity,"rounds":rounds,"condition":item.condition,"label":item.label,"inspected":item.inspected,"estimate":item.estimate})
		elif item is WeaponInstance: record.merge({"weapon_type_id":str(item.weapon_type_id),"inserted_magazine_id":str(item.inserted_magazine_id),"chambered_round":str(item.chambered_round.ammo_type_id) if item.chambered_round != null else "","condition":item.condition,"jammed":item.jammed})
		records.append(record)
	return {"version":1,"owner_id":str(owner_id),"active_weapon_id":str(active_weapon_id),"pack_capacity":pack_capacity,"initial_magazine_ids":initial_magazine_ids.duplicate(),"items":records}

func restore(snapshot: Dictionary) -> bool:
	# Parse into a temporary inventory; rejection leaves every current item untouched.
	if snapshot.get("version") != 1 or not snapshot.get("items") is Array or not snapshot.get("owner_id") is String or not integral(snapshot.get("pack_capacity")) or int(snapshot.pack_capacity) != pack_capacity: return fail("Invalid equipment snapshot")
	var candidate = get_script().new(weapon_type_id,magazine_definitions[magazine_type_id].capacity,0,0,0,StringName(snapshot.owner_id),primary_ammo_id,ammo_definitions[primary_ammo_id].caliber,magazine_type_id,ammo_definitions[primary_ammo_id].display_name)
	candidate.items.clear()
	candidate.ammo_definitions = ammo_definitions
	candidate.magazine_definitions = magazine_definitions
	for record in snapshot.items:
		if not record is Dictionary or not record.get("location") is Dictionary or not record.get("id") is String or record.id.is_empty() or candidate.items.has(StringName(record.id)): return fail("Invalid or duplicate item ID")
		var item: Item
		match record.get("kind",""):
			"ammo_stack":
				var stack := AmmoStack.new()
				if not record.get("ammo_type_id") is String: return fail("Invalid ammunition definition ID")
				stack.ammo_type_id = StringName(record.get("ammo_type_id",""))
				if not integral(record.get("quantity")): return fail("Invalid stack quantity")
				stack.quantity = int(record.quantity)
				if not ammo_definitions.has(stack.ammo_type_id) or stack.quantity < 1 or stack.quantity > 32: return fail("Invalid cartridge stack")
				item = stack
			"magazine":
				var mag := MagazineInstance.new()
				if not record.get("magazine_type_id") is String: return fail("Invalid magazine definition ID")
				mag.magazine_type_id = StringName(record.get("magazine_type_id",""))
				if not magazine_definitions.has(mag.magazine_type_id) or not record.get("rounds") is Array: return fail("Invalid magazine definition")
				if not integral(record.get("capacity")): return fail("Invalid magazine capacity")
				mag.capacity = int(record.capacity)
				if mag.capacity != magazine_definitions[mag.magazine_type_id].capacity or record.rounds.size() > mag.capacity: return fail("Magazine capacity exceeded")
				for ammo in record.rounds:
					if not ammo is String or not compatible(mag,StringName(ammo)): return fail("Incompatible magazine round")
					mag.rounds.append(MagazineRound.new(StringName(ammo)))
				if not (record.get("condition") is int or record.get("condition") is float): return fail("Invalid magazine condition")
				mag.condition = float(record.condition)
				if not is_finite(mag.condition) or mag.condition < 0 or mag.condition > 1: return fail("Invalid magazine condition")
				mag.label = str(record.get("label","Magazine"))
				# Retain earned knowledge, but never trust an arbitrary saved label/count.
				if not record.get("inspected",false) is bool: return fail("Invalid magazine knowledge")
				mag.inspected = record.get("inspected",false)
				mag.estimate = describe_fill(mag) if mag.inspected else "Unknown"
				item = mag
			"weapon":
				var gun := WeaponInstance.new()
				if not record.get("weapon_type_id") is String or not record.get("inserted_magazine_id") is String or not record.get("chambered_round") is String: return fail("Invalid weapon content IDs")
				gun.weapon_type_id = StringName(record.get("weapon_type_id",""))
				if gun.weapon_type_id != weapon_type_id: return fail("Unknown weapon definition")
				gun.inserted_magazine_id = StringName(record.get("inserted_magazine_id",""))
				var chamber_id := StringName(record.get("chambered_round",""))
				if chamber_id != &"":
					if not ammo_definitions.has(chamber_id) or gun.weapon_type_id not in ammo_definitions[chamber_id].compatible_weapon_ids: return fail("Invalid chamber round")
					gun.chambered_round = MagazineRound.new(chamber_id)
				if not (record.get("condition") is int or record.get("condition") is float): return fail("Invalid weapon condition")
				gun.condition = float(record.condition)
				if not record.get("jammed",false) is bool: return fail("Invalid weapon jam state")
				gun.jammed = record.get("jammed",false)
				if not is_finite(gun.condition) or gun.condition < 0 or gun.condition > 1: return fail("Invalid weapon condition")
				item = gun
			_: return fail("Unknown item kind")
		item.id = StringName(record.id)
		var location: Dictionary = record.location
		if not location.get("kind") is String or not location.get("owner_id") is String: return fail("Invalid location identity")
		var position = location.get("position",[0,0,0])
		if not position is Array or position.size() != 3: return fail("Invalid world location")
		for coordinate in position:
			if not (coordinate is int or coordinate is float): return fail("Invalid world coordinate")
		if not integral(location.get("slot")): return fail("Invalid location index")
		item.location = Location.new(StringName(location.get("kind","")),StringName(location.get("owner_id","")),int(location.get("slot",-1)))
		item.location.position = Vector3(float(position[0]),float(position[1]),float(position[2]))
		if not item.location.position.is_finite(): return fail("Invalid world coordinates")
		candidate.items[item.id] = item
	candidate.active_weapon_id = StringName(snapshot.get("active_weapon_id",""))
	if candidate.active_weapon_id != &"" and candidate.weapon() == null: return fail("Missing active weapon")
	for item in candidate.items.values():
		var at: Location = item.location
		if at.kind in [&"pocket",&"pack"]:
			if not candidate.valid_slot(at) or candidate.occupant(at,item.id) != null: return fail("Duplicate or invalid slot")
		elif at.kind == &"equipped":
			if not item is WeaponInstance or item.id != candidate.active_weapon_id or at.owner_id != candidate.owner_id or at.slot != 0 or candidate.occupant(at,item.id) != null: return fail("Invalid equipped weapon")
		elif at.kind == &"magwell":
			var gun := candidate.items.get(at.owner_id) as WeaponInstance
			if not item is MagazineInstance or gun == null or gun.inserted_magazine_id != item.id or at.slot != -1: return fail("Invalid magazine ownership")
		elif at.kind != &"ground" or at.owner_id != &"world" or at.slot != -1: return fail("Unknown item location")
		if item is WeaponInstance and item.inserted_magazine_id != &"":
			var mag: MagazineInstance = candidate.magazine(item.inserted_magazine_id)
			if mag == null or mag.location.kind != &"magwell" or mag.location.owner_id != item.id or item.weapon_type_id not in magazine_definitions[mag.magazine_type_id].compatible_weapon_ids: return fail("Broken inserted-magazine link")
	var initial_ids = snapshot.get("initial_magazine_ids",[])
	if not initial_ids is Array or initial_ids.size() != 2: return fail("Invalid magazine identities")
	if initial_ids[0] == initial_ids[1]: return fail("Magazine identities must be distinct")
	for id in initial_ids:
		if not id is String and not id is StringName: return fail("Invalid magazine identity")
		if str(id).is_empty(): return fail("Empty magazine identity")
	owner_id = candidate.owner_id
	items = candidate.items
	active_weapon_id = candidate.active_weapon_id
	initial_magazine_ids.assign(initial_ids)
	_notify_changed()
	return true

static func integral(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value))

func _notify_changed() -> void:
	error = ""
	changed.emit()
