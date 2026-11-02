extends SceneTree
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
const State = preload("res://scripts/weapons/prototype_weapon_state.gd")
const Definition = preload("res://weapons/svt_inspired_training.tres")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func set_rounds(mag, count: int, ammo_id: StringName) -> void:
	mag.rounds.clear()
	for index in range(count): mag.rounds.append(Inventory.MagazineRound.new(ammo_id))

func stack(inv, quantity: int, ammo_id: StringName = &""):
	var item := Inventory.AmmoStack.new()
	item.id = Inventory.new_id("fixture_stack")
	item.ammo_type_id = inv.primary_ammo_id if ammo_id == &"" else ammo_id
	item.quantity = quantity
	item.location = inv.empty_location()
	inv.items[item.id] = item
	return item

func _initialize() -> void:
	var state = State.new()
	var inv = state.inventory
	check(inv.items.size() == 4 and inv.initial_magazine_ids.size() == 2, "Exactly one rifle, two magazines and one loose stack")
	check(inv.initial_magazine_ids[0] != inv.initial_magazine_ids[1], "Distinct physical magazine identities")
	check(state.magazines == [10,10] and state.loose_rounds == 32 and state.total_rounds() == 52, "Preserve ten-round rifle, two full magazines and 32 loose; no extra chamber round")
	check(inv.weapon().chambered_round == null and inv.magazine(inv.initial_magazine_ids[0]).location.kind == &"magwell", "Inserted magazine does not chamber a round or occupy a pocket")
	check(not state.try_fire(1.0), "Empty chamber cannot fire")
	check(inv.chamber() and state.total_rounds() == 52 and state.magazines[0] == 9, "Manual chambering transfers a round without creating one")
	check(state.try_fire(1.0) and state.total_rounds() == 51 and inv.weapon().chambered_round != null, "Shot consumes chamber and cycles next round")
	state.advance(1)
	check(not state.try_fire(0.0) and state.jammed and state.total_rounds() == 51, "Jam never destroys a round")
	state.jammed = false
	var chamber = inv.weapon().chambered_round
	check(inv.remove_magazine() and inv.weapon().chambered_round == chamber, "Removing magazine preserves chambered round")
	check(state.try_fire(1.0) and inv.weapon().chambered_round == null and state.total_rounds() == 50, "Rifle fires its remaining chambered round without a magazine")
	var a: StringName = inv.initial_magazine_ids[0]
	var b: StringName = inv.initial_magazine_ids[1]
	check(inv.insert_magazine(b) and inv.weapon().chambered_round == null, "Inserting another magazine does not auto-chamber")
	var total: int = state.total_rounds()
	check(state.request_action(&"reload",a), "Timed reload begins")
	state.advance(0.2)
	state.cancel_action()
	check(inv.weapon().inserted_magazine_id == b and state.total_rounds() == total, "Cancelled pre-commit reload preserves identity and rounds")
	state.request_action(&"reload",a)
	state.advance(1.1)
	state.cancel_action()
	check(inv.weapon().inserted_magazine_id == a and state.total_rounds() == total, "Cancelled post-commit reload retains exactly one swap")
	state.advance(9)
	check(inv.weapon().inserted_magazine_id == a, "Repeated large updates do not double swap")
	check(inv.knowledge(a).begins_with("Unknown"), "Initial magazine knowledge is hidden")
	check(state.request_action(&"inspect",a), "Inspection uses existing timed action")
	state.advance(0.1)
	check(inv.knowledge(a).begins_with("Unknown"), "No early inspection information")
	state.advance(10)
	check(inv.knowledge(a) == "More than half", "Inspection reveals category, not exact count")
	var alternate = Definition.duplicate(true)
	alternate.capacity = 30
	alternate.initial_loaded = 30
	alternate.initial_spare = 30
	alternate.initial_loose = 32
	var thirty = State.new(alternate)
	check(thirty.total_rounds() == 92 and thirty.magazines == [30,30], "Configurable thirty-round fixture starts at exactly 92")
	var mag = thirty.inventory.magazine(thirty.inventory.initial_magazine_ids[0])
	for example in [[30,"Almost full"],[27,"Almost full"],[26,"More than half"],[15,"More than half"],[14,"Less than half"],[9,"Less than half"],[8,"Almost empty"],[1,"Almost empty"],[0,"Empty"]]:
		set_rounds(mag,example[0],thirty.inventory.primary_ammo_id)
		thirty.inventory.inspect_magazine(mag.id)
		check(thirty.inventory.knowledge(mag.id) == example[1], "Inspection threshold at %d rounds" % example[0])
	# Independent stack arithmetic fixtures, including overflow and failed transactions.
	for example in [[32,8,32,8],[12,15,27,0],[20,20,32,8]]:
		var bag = Inventory.new(&"svt_inspired_training",10,0,0,0)
		var target = stack(bag,example[0])
		var source = stack(bag,example[1])
		var before: int = bag.total_rounds()
		bag.merge_stacks(source.id,target.id)
		check(target.quantity == example[2] and (source.quantity == example[3]) and bag.total_rounds() == before, "Stack merge conserves overflow: %d + %d" % [example[0],example[1]])
		check((example[3] != 0) == bag.items.has(source.id), "Empty source stacks are removed")
	var bag = Inventory.new(&"svt_inspired_training",10,0,0,0)
	var source = stack(bag,32)
	var split_id: StringName = bag.split_stack(source.id,10)
	check(split_id != &"" and source.quantity == 22 and bag.items[split_id].quantity == 10 and bag.total_rounds() == 32, "Split 32 into 10 and 22 with a new ID")
	var variant := Inventory.AmmoDefinition.new()
	variant.id = &"training_variant"
	variant.caliber = bag.ammo_definitions[bag.primary_ammo_id].caliber
	variant.compatible_weapon_ids.assign([bag.weapon_type_id])
	bag.ammo_definitions[variant.id] = variant
	bag.magazine_definitions[bag.magazine_type_id].compatible_ammo_ids.append(variant.id)
	var variant_stack = stack(bag,2,variant.id)
	check(not bag.merge_stacks(source.id,variant_stack.id), "Different ammunition variants cannot merge")
	var spare = bag.magazine(bag.initial_magazine_ids[1])
	check(bag.load_round(spare.id,source.id) and bag.load_round(spare.id,variant_stack.id), "One magazine supports mixed compatible variants")
	check(spare.rounds[0].ammo_type_id != spare.rounds[1].ammo_type_id, "Magazine preserves round order and type")
	bag.inspect_magazine(spare.id)
	check(bag.unload_round(spare.id) and bag.knowledge(spare.id).begins_with("Unknown"), "Unloading returns typed cartridges and invalidates knowledge")
	var mixed_save: Dictionary = JSON.parse_string(JSON.stringify(bag.encode()))
	check(bag.restore(mixed_save), "Registered compatible variants survive JSON restoration")
	spare = bag.magazine(bag.initial_magazine_ids[1])
	source = bag.items.get(source.id)
	var incompatible := Inventory.AmmoDefinition.new()
	incompatible.id = &"wrong_caliber"
	incompatible.caliber = &"other"
	bag.ammo_definitions[incompatible.id] = incompatible
	var wrong = stack(bag,1,incompatible.id)
	check(not bag.load_round(spare.id,wrong.id) and wrong.quantity == 1, "Wrong ammunition is rejected without spending")
	set_rounds(spare,spare.capacity,bag.primary_ammo_id)
	check(not bag.load_round(spare.id,source.id), "Magazine capacity is enforced")
	# Round-trip stable IDs, mixed contents, ground locations and chamber state.
	var persisted = State.new()
	persisted.inventory.chamber()
	persisted.inventory.inspect_magazine(persisted.inventory.initial_magazine_ids[0])
	persisted.inventory.drop_item(persisted.inventory.initial_magazine_ids[1],Vector3(1,2,3))
	var encoded: Dictionary = JSON.parse_string(JSON.stringify(persisted.encode()))
	var restored = State.new()
	check(restored.restore(encoded), "Equipment can deserialize through actual JSON")
	check(restored.inventory.active_weapon_id == persisted.inventory.active_weapon_id and restored.inventory.initial_magazine_ids == persisted.inventory.initial_magazine_ids and restored.total_rounds() == 52, "Save round-trip preserves identities, chamber and all rounds")
	check(restored.inventory.knowledge(restored.inventory.initial_magazine_ids[0]) == "Almost full", "Earned magazine knowledge survives a valid save/load")
	check(persisted.save_equipment("res://.godot/equipment_roundtrip_test.json") and restored.load_equipment("res://.godot/equipment_roundtrip_test.json"), "Actual file save/load uses validated equipment snapshots")
	var before_restore := JSON.stringify(restored.encode())
	var bad: Dictionary = encoded.duplicate(true)
	bad.inventory.items.append(bad.inventory.items[0].duplicate(true))
	check(not restored.restore(bad) and JSON.stringify(restored.encode()) == before_restore, "Duplicate saved IDs reject atomically")
	bad = encoded.duplicate(true)
	for record in bad.inventory.items:
		if record.kind == "ammo_stack": record.quantity = 32.5
	check(not restored.restore(bad), "Fractional stack quantities reject")
	var ground_mag: StringName = restored.inventory.initial_magazine_ids[1]
	check(restored.inventory.pickup(ground_mag) and not restored.inventory.pickup(ground_mag), "Ground recovery preserves ID and rejects duplicate pickup")
	var full = Inventory.new(&"svt_inspired_training",10,0,0,0)
	while full.empty_location() != null: stack(full,32)
	var full_total: int = full.total_rounds()
	check(not full.add_loose(1) and full.total_rounds() == full_total, "Full pockets/pack reject extra stacks without loss")
	var giver = State.new()
	var receiver = State.new()
	giver.inventory.chamber()
	giver.jammed = true
	var rifle_id: StringName = giver.inventory.active_weapon_id
	var inserted_id: StringName = giver.inventory.weapon().inserted_magazine_id
	giver.inventory.drop_item(rifle_id,Vector3.ZERO)
	check(giver.inventory.transfer_ground_item_to(rifle_id,receiver.inventory), "Another local carrier can recover communal dropped equipment")
	check(not giver.inventory.items.has(rifle_id) and not giver.inventory.items.has(inserted_id) and receiver.inventory.items.has(inserted_id), "Custody transfer moves the complete weapon subtree without copying IDs")
	check(receiver.inventory.equip_weapon(rifle_id) and receiver.jammed and receiver.inventory.weapon().chambered_round != null, "Recovered weapon retains chamber and jam state on equip")
	check(giver.total_rounds()+receiver.total_rounds()==104 and not giver.equipped(), "Two-carrier transfer conserves all physical rounds")
	var unarmed = State.new()
	check(unarmed.restore(JSON.parse_string(JSON.stringify(giver.encode()))) and not unarmed.equipped(), "A carrier without a rifle can still save/load equipment")
	var camp = preload("res://scripts/camp/camp_runtime.gd").new()
	camp.stock.add(&"rounds",20)
	var saturated = State.new()
	while saturated.inventory.empty_location() != null: stack(saturated.inventory,32)
	check(not camp.withdraw_ammo(saturated,10) and camp.stock.count(&"rounds") == 20, "A full carried inventory cannot spend communal ammunition")
	camp.stock.add(&"parts",2)
	var serviced = State.new()
	check(camp.start_job(&"repair",&"bench","physical_repair",serviced), "Existing service binds to a physical equipped rifle")
	serviced.inventory.drop_item(serviced.inventory.active_weapon_id,Vector3.ZERO)
	camp.advance(0.1)
	check(not camp.jobs.has(&"bench") and camp.stock.count(&"parts") == 2, "Losing the serviced rifle cancels and refunds rather than repairing another object")
	print("Ammunition inventory checks: ","PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
