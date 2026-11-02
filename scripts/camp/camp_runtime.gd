extends RefCounted
## Session-local training rules. No renderer, singleton player, cash or save file.
signal changed
var can_complete: Callable
var can_player_work: Callable
const Stock = preload("res://scripts/state/camp_stock.gd")
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
## The contact's fixed prices per lot, in rubles or in lats. Lats buy more: they are scarce
## pre-war savings the contact values highly. Placeholder amounts, not balance.
const PRICES = {
	&"medicine": {"label":"Medicine","amount":1,"rubles":40,"lats":2},
	&"rounds": {"label":"Cartridges","amount":20,"rubles":30,"lats":1},
	&"parts": {"label":"Weapon parts","amount":1,"rubles":25,"lats":1},
	&"cloth": {"label":"Cloth","amount":2,"rubles":10,"lats":1},
	&"food": {"label":"Food","amount":3,"rubles":15,"lats":1},
}
## What the trader pays for a full supply item, in rubles; partly used items pay in proportion.
## Placeholder amounts, kept well under buying prices.
const SELL_SUPPLIES = {&"cloth_bandage":3,&"field_dressing":5,&"tourniquet":6,&"splint":5,&"morphine":15,
	&"medical_satchel":20,&"sulfa_powder":8,&"surgical_kit":25,&"canteen":4,&"rye_bread":2,&"tinned_meat":4}
const SELL_WEAPON := 60
const SELL_MAGAZINE := 5
const RECIPES = {
	&"water": {"label":"Draw water", "cost":{}, "output":{&"water":2}, "seconds":2.0, "role":&""},
	&"cook": {"label":"Cook communal meal", "cost":{&"food":1,&"water":1}, "output":{&"meals":1}, "seconds":4.0, "role":&"cook"},
	&"repair": {"label":"Service carried rifle", "cost":{&"parts":1}, "output":{}, "seconds":3.0, "role":&"", "effect":&"repair"},
	&"bandage": {"label":"Bandage test patient's bleeding", "cost":{&"cloth":1}, "output":{}, "seconds":2.0, "role":&"", "effect":&"bandage"},
	&"splint": {"label":"Splint test patient's fracture", "cost":{&"cloth":1,&"timber":1}, "output":{}, "seconds":3.0, "role":&"", "effect":&"splint"},
	&"recover": {"label":"Medical recovery (test patient)", "cost":{&"medicine":1}, "output":{}, "seconds":4.0, "role":&"", "effect":&"recover"},
	&"upgrade": {"label":"Upgrade shelter", "cost":{&"timber":4,&"parts":1}, "output":{}, "seconds":7.0, "role":&"builder", "effect":&"upgrade"},
	&"rack": {"label":"Build planned supply rack", "cost":{&"timber":2}, "output":{}, "seconds":6.0, "role":&"builder", "effect":&"rack"},
	&"dig": {"label":"Dig marked trench", "cost":{}, "output":{}, "seconds":4.0, "role":&"", "effect":&"dig"}
}
var stock
var residents: Dictionary = {&"resident_01":{"role":&"unassigned","busy":"","fed":false}}
var jobs: Dictionary = {}
var plans: Dictionary = {}
var shelter_tier: int = 0
var trench_complete: bool = false
var patient: Dictionary = {"bleeding":true,"fracture":true,"recovery":30.0}
var cache_claimed: bool = false
var message: String = "Training stores are stocked. Extra supplies are available at the quartermaster."
var _requests: Dictionary = {}
var _sequence: int = 0
var pending_recruits: Array[StringName] = []
var exercise_active: bool = false
var exercise_objective: bool = false
var quests_completed: int = 0

func _init(ledger = null) -> void:
	stock = ledger if ledger != null else Stock.new()

func request_id() -> String:
	_sequence += 1
	return "local_%d" % _sequence

func claim_cache() -> bool:
	if cache_claimed:
		return _fail("Training cache already claimed; resources are communal.")
	cache_claimed = true
	stock.try_exchange({}, {&"food":8,&"water":6,&"medicine":4,&"timber":12,&"parts":5,&"cloth":6,&"rounds":40})
	message = "Training cache received once. No currency or private stock."
	changed.emit()
	return true

func assign_role(resident_id: StringName, role: StringName) -> bool:
	if not residents.has(resident_id) or role not in [&"cook",&"builder",&"unassigned"]:
		return _fail("Unknown resident or role")
	if residents[resident_id].busy != "":
		return _fail("Finish or cancel this resident's current job first")
	residents[resident_id].role = role
	message = "Resident assigned: %s" % role
	changed.emit()
	return true

func start_job(recipe_id: StringName, station_id: StringName, token: String, weapon_state = null, player_id: StringName = &"") -> bool:
	if _requests.has(token):
		return _fail("Duplicate request ignored")
	_requests[token] = true
	if not RECIPES.has(recipe_id) or jobs.has(station_id):
		return _fail("Unknown recipe or station already busy")
	var recipe: Dictionary = RECIPES[recipe_id]
	if recipe_id == &"upgrade" and shelter_tier >= 1:
		return _fail("Training upgrade already complete")
	if recipe_id == &"dig" and trench_complete:
		return _fail("Marked trench already dug")
	if recipe_id == &"rack" and (not plans.has(station_id) or plans[station_id].status != &"planned"):
		return _fail("Place a valid rack plan first")
	if recipe_id == &"repair" and (weapon_state == null or not weapon_state.equipped()):
		return _fail("Bring the carried rifle to this workbench")
	if recipe_id == &"bandage" and not patient.bleeding:
		return _fail("Patient is not bleeding")
	if recipe_id == &"splint" and not patient.fracture:
		return _fail("Patient has no fracture")
	if recipe_id == &"recover" and patient.recovery <= 0:
		return _fail("Test patient has already recovered")
	if recipe_id == &"recover" and (patient.bleeding or patient.fracture):
		return _fail("Treat the bleeding and fracture before recovery")
	var worker: StringName = &""
	if player_id != &"":
		for job in jobs.values():
			if job.player == player_id:
				return _fail("Finish or cancel your current task first")
		if not can_player_work.is_valid() or not can_player_work.call(player_id,station_id):
			return _fail("Stay at the station to do this work yourself")
	elif recipe.role != &"":
		for id in residents:
			if residents[id].role == recipe.role and residents[id].busy == "":
				worker = id
				break
		if worker == &"":
			return _fail("Assign an available civilian as %s" % recipe.role)
	if not stock.try_exchange(recipe.cost, {}):
		return _fail("Insufficient communal supplies; costs are shown on the station")
	jobs[station_id] = {"recipe":recipe_id,"left":recipe.seconds,"worker":worker,"player":player_id,"cost":recipe.cost.duplicate(),"assisted":false,"weapon":weapon_state}
	jobs[station_id]["weapon_item_id"] = weapon_state.inventory.active_weapon_id if weapon_state != null else &""
	if worker != &"":
		residents[worker].busy = String(station_id)
	if recipe_id == &"rack":
		plans[station_id].status = &"building"
	message = "%s started; supplies reserved once" % recipe.label
	changed.emit()
	return true

func advance(delta: float) -> void:
	if not patient.bleeding and not patient.fracture:
		patient.recovery = maxf(0.0, patient.recovery - delta)
	for id in jobs.keys():
		if not jobs.has(id):
			continue
		if jobs[id].player != &"" and (not can_player_work.is_valid() or not can_player_work.call(jobs[id].player,id)):
			cancel_job(id)
			continue
		if jobs[id].recipe == &"repair" and (not jobs[id].weapon.equipped() or jobs[id].weapon.inventory.active_weapon_id != jobs[id].weapon_item_id):
			cancel_job(id)
			continue
		jobs[id].left -= delta
		if jobs[id].left <= 0.0:
			if can_complete.is_valid() and not can_complete.call(jobs[id].recipe,id):
				jobs[id].left = 0.25
				if message != "Construction waiting: clear the marked footprint":
					message = "Construction waiting: clear the marked footprint"
					changed.emit()
				continue
			_finish_job(id)

func _finish_job(id: StringName) -> void:
	var job: Dictionary = jobs[id]
	jobs.erase(id) # Remove first; changed callbacks cannot complete it twice.
	if job.worker != &"":
		residents[job.worker].busy = ""
	var recipe: Dictionary = RECIPES[job.recipe]
	stock.try_exchange({}, recipe.output)
	match recipe.get("effect", &""):
		&"repair": job.weapon.inventory.items[job.weapon_item_id].condition = 1.0 # Clearing a jam is separate.
		&"bandage": patient.bleeding = false
		&"splint": patient.fracture = false
		&"recover": patient.recovery = 0.0
		&"upgrade": shelter_tier = 1
		&"rack": plans[id].status = &"complete"
		&"dig": trench_complete = true
	message = "%s complete" % recipe.label
	changed.emit()

func cancel_job(id: StringName) -> bool:
	if not jobs.has(id):
		return false
	var job: Dictionary = jobs[id]
	jobs.erase(id)
	if job.worker != &"":
		residents[job.worker].busy = ""
	if plans.has(id):
		plans[id].status = &"planned"
	stock.try_exchange({}, job.cost)
	message = "Job cancelled; reserved supplies refunded once"
	changed.emit()
	return true

func cancel_player_jobs(player_id: StringName) -> void:
	for id in jobs.keys():
		if jobs[id].player == player_id:
			cancel_job(id)

func assist(id: StringName) -> bool:
	if not jobs.has(id) or jobs[id].worker == &"" or jobs[id].assisted:
		return _fail("Assistance applies once to an active civilian job")
	jobs[id].assisted = true
	jobs[id].left = maxf(0.1, jobs[id].left - 2.0)
	message = "Foreman assistance: two seconds of test work completed"
	changed.emit()
	return true

func withdraw_ammo(weapon_state, amount: int = 10) -> bool:
	if weapon_state != null and not weapon_state.inventory.can_add_loose(amount):
		return _fail("No room for cartridge stacks; communal stock unchanged")
	if weapon_state == null or amount <= 0 or not stock.try_exchange({&"rounds":amount}, {}):
		return _fail("Not enough communal cartridges")
	weapon_state.loose_rounds += amount
	message = "%d cartridges moved to carried loose rounds" % amount
	changed.emit()
	return true

func deposit_ammo(weapon_state, amount: int = 10) -> bool:
	if weapon_state == null or amount <= 0 or weapon_state.loose_rounds < amount:
		return _fail("Not enough carried loose cartridges")
	weapon_state.loose_rounds -= amount
	stock.try_exchange({}, {&"rounds":amount})
	message = "Cartridges returned to communal storage"
	changed.emit()
	return true

## Moves every carried rubles and lats item into the camp treasury.
func deposit_money(weapon_state) -> bool:
	if weapon_state == null:
		return _fail("Nothing carried to deposit")
	var inventory = weapon_state.inventory
	var amounts := {}
	for item in inventory.items.values().duplicate():
		if item.kind == &"supply" and SupplyCatalog.is_money(item.supply_id) and inventory.carried(item):
			amounts[item.supply_id] = amounts.get(item.supply_id, 0) + item.uses
			inventory.items.erase(item.id)
	if amounts.is_empty():
		return _fail("You carry no rubles or lats")
	inventory._notify_changed()
	stock.try_exchange({}, amounts)
	message = "Deposited %d rubles and %d lats into the camp treasury" % [amounts.get(&"rubles", 0), amounts.get(&"lats", 0)]
	changed.emit()
	return true

## Buys one lot of a good from the contact, paying from the treasury in rubles or lats.
func buy(good: StringName, currency: StringName) -> bool:
	if not PRICES.has(good) or not currency in [&"rubles", &"lats"]:
		return _fail("The contact does not sell that")
	var offer: Dictionary = PRICES[good]
	if not stock.try_exchange({currency: int(offer[currency])}, {good: int(offer.amount)}):
		return _fail("The treasury is short of %s" % currency)
	message = "Bought %d %s for %d %s" % [offer.amount, good, offer[currency], currency]
	changed.emit()
	return true

## What the trader pays, in rubles, for an item with everything inside it (a rifle with its
## magazine, a magazine with its rounds). Cheap: well under what buying costs. 0 means he will
## not take it (money, mission items, a worn backpack, the equipped rifle).
func sell_value(inventory, item) -> int:
	if item == null or not inventory.carried(item): return 0
	if item.kind == &"backpack" or item.location.kind in [&"equipped", &"worn"]: return 0
	var total := 0
	for member in inventory.contents_tree(item):
		match member.kind:
			&"weapon": total += SELL_WEAPON
			&"magazine": total += SELL_MAGAZINE + int(member.rounds.size() / 2.0)
			&"ammo_stack": total += maxi(1, int(member.quantity / 2.0))
			&"supply":
				if SupplyCatalog.is_money(member.supply_id) or SupplyCatalog.is_objective(member.supply_id): return 0
				var full := int(SupplyCatalog.get_def(member.supply_id).uses)
				total += maxi(1, int(float(SELL_SUPPLIES.get(member.supply_id, 2)) * member.uses / maxi(1, full)))
	return total

## Sells an item (with everything inside it) to the trader; the rubles go to the treasury.
func sell(inventory, id: StringName) -> bool:
	var item = inventory.items.get(id)
	var value := sell_value(inventory, item)
	if value <= 0:
		return _fail("The old man will not take that")
	for member in inventory.contents_tree(item):
		inventory.items.erase(member.id)
		if inventory.active_weapon_id == member.id: inventory.active_weapon_id = &""
	inventory._notify_changed()
	stock.try_exchange({}, {&"rubles": value})
	message = "Sold for %d rubles" % value
	changed.emit()
	return true

func place_plan(id: StringName, at: Vector2) -> bool:
	if plans.has(id) or at.x < -13.2 or at.x > -5.8 or at.y < -1.6 or at.y > 9.6:
		return _fail("Place racks in the marked west planning plot")
	for plan in plans.values():
		if plan.at.distance_to(at) < 2.0:
			return _fail("Plan footprints overlap")
	plans[id] = {"at":at,"status":&"planned"}
	message = "Rack plan placed; it consumes nothing until construction starts"
	changed.emit()
	return true

func begin_exercise() -> bool:
	if exercise_active:
		return _fail("A rescue exercise is already active")
	exercise_active = true
	exercise_objective = false
	pending_recruits.clear()
	message = "Training outing started: rescue the marked civilian and defeat the practice enemy"
	changed.emit()
	return true

func rescue(id: StringName) -> bool:
	if not exercise_active or id in pending_recruits or residents.has(id):
		return _fail("No active exercise, or this civilian is already secured/pending")
	pending_recruits.append(id)
	message = "Civilian departing; still pending until a safe return"
	changed.emit()
	return true

func resolve_exercise(safe: bool) -> bool:
	if not exercise_active:
		return false
	exercise_active = false
	if safe:
		for id in pending_recruits:
			residents[id] = {"role":&"unassigned","busy":"","fed":false}
		if exercise_objective:
			quests_completed += 1
			stock.try_exchange({}, {&"timber":3})
		message = "Safe return: recruits secured. " + ("Objective reward: 3 timber." if exercise_objective else "Objective incomplete; no quest reward.")
	else:
		message = "Group-death exercise: pending recruits lost; established residents remain"
	pending_recruits.clear()
	changed.emit()
	return true

func _fail(reason: String) -> bool:
	message = reason
	changed.emit()
	return false

func feed_resident(id: StringName) -> bool:
	if not residents.has(id) or residents[id].fed:
		return _fail("This test resident is absent or already provisioned")
	if not stock.try_exchange({&"meals":1,&"water":1}, {}):
		return _fail("Serve requires one communal meal and water")
	residents[id].fed = true
	message = "Resident provisioned from communal food storage"
	changed.emit()
	return true

## Persistent camp state for a world save (JSON-safe). Jobs in progress are not saved: their
## reserved supplies count back into the stores and their workers are free again on load.
func encode() -> Dictionary:
	var stores := {}
	for id in stock.quantities:
		stores[str(id)] = stock.quantities[id]
	for job in jobs.values():
		for id in job.cost:
			stores[str(id)] = stores.get(str(id), 0) + int(job.cost[id])
	var people := {}
	for id in residents:
		people[str(id)] = {"role":str(residents[id].role),"fed":residents[id].fed}
	var plan_records := {}
	for id in plans:
		var status: StringName = plans[id].status
		plan_records[str(id)] = {"at":[plans[id].at.x, plans[id].at.y],"status":str(&"planned" if status == &"building" else status)}
	return {"stores":stores,"residents":people,"plans":plan_records,"shelter_tier":shelter_tier,"trench_complete":trench_complete,
		"patient":patient.duplicate(),"cache_claimed":cache_claimed,"quests_completed":quests_completed}

## Replaces the camp with a saved state; unknown store entries are ignored.
func restore(state: Dictionary) -> void:
	jobs.clear()
	for id in stock.quantities.keys():
		stock.quantities[id] = int(state.get("stores", {}).get(str(id), 0))
	residents.clear()
	for id in state.get("residents", {}):
		var record: Dictionary = state.residents[id]
		residents[StringName(id)] = {"role":StringName(record.get("role", "unassigned")),"busy":"","fed":bool(record.get("fed", false))}
	plans.clear()
	for id in state.get("plans", {}):
		var record: Dictionary = state.plans[id]
		plans[StringName(id)] = {"at":Vector2(record.at[0], record.at[1]),"status":StringName(record.status)}
	shelter_tier = int(state.get("shelter_tier", 0))
	trench_complete = bool(state.get("trench_complete", false))
	if state.get("patient") is Dictionary:
		patient = {"bleeding":bool(state.patient.bleeding),"fracture":bool(state.patient.fracture),"recovery":float(state.patient.recovery)}
	cache_claimed = bool(state.get("cache_claimed", false))
	quests_completed = int(state.get("quests_completed", 0))
	pending_recruits.clear()
	exercise_active = false
	message = "Camp restored from the world save."
	stock.changed.emit()
	changed.emit()
