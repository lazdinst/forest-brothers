extends SceneTree
## Rules check for the Tarkov-style player condition: parts, damage spread, bleeds, fractures,
## pain, energy and water, and timed treatment with physical supplies.
const PlayerHealth = preload("res://scripts/health/player_health.gd")
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
var failures: Array[String] = []

func _initialize() -> void:
	_run()
	for failure in failures:
		push_error(failure)
	print("Player health checks: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func quiet() -> PlayerHealth:
	var health := PlayerHealth.new()
	health.light_bleed_chance = 0.0
	health.heavy_bleed_chance = 0.0
	health.fracture_chance = 0.0
	return health

func carried_supply(inventory, supply_id: StringName):
	var spot = inventory.empty_location(&"",inventory.footprint(_probe(supply_id)))
	return inventory.create_supply(supply_id,spot)

func _probe(supply_id: StringName):
	var probe = Inventory.SupplyInstance.new()
	probe.supply_id = supply_id
	return probe

## Runs a treatment to completion in small steps, as the game clock would.
func treat(health, inventory, item_id: StringName, part: StringName = &"") -> String:
	var problem: String = health.start_treatment(inventory,item_id,part)
	if problem != "": return problem
	for step in range(200):
		if health.treatment.is_empty(): break
		health.advance(0.1)
	return ""

func _run() -> void:
	var health := quiet()
	check(health.ZONES.size() == 7 and is_equal_approx(health.total_max(),440.0),"Seven body parts totalling 440, as in Tarkov")
	check(health.apply_damage(&"head",40) == PlayerHealth.KILLED and health.is_dead(),"Head at zero kills")
	health = quiet()
	check(health.apply_damage(&"torso",90) == PlayerHealth.DOWNED and health.is_downed(),"Thorax at zero downs (old torso zone maps to thorax)")
	check(health.apply_damage(&"left_leg",1) == PlayerHealth.KILLED,"Any hit on a downed body kills")
	# Destroyed parts spread further damage to everything still standing.
	health = quiet()
	check(health.apply_damage(&"left_leg",70) == PlayerHealth.LIMB_DISABLED and health.destroyed(&"left_leg") and health.is_alive(),"A limb at zero is destroyed, not fatal")
	var before := health.total_health()
	health.apply_damage(&"left_leg",30)
	check(is_equal_approx(before - health.total_health(),21.0) and health.health[&"head"] < 35.0,"Damage to a destroyed limb spreads to the rest at 70%")
	check(health.in_pain() and not health.can_sprint() and is_equal_approx(health.speed_multiplier(),0.7),"A destroyed leg hurts, slows and stops sprinting")
	# Bleeding drains the bleeding part over time and can down the player.
	health = quiet()
	health.light_bleeding[&"left_arm"] = true
	health.advance(10.0)
	check(is_equal_approx(health.health[&"left_arm"],56.0),"Light bleeding drains its part slowly")
	health.heavy_bleeding[&"thorax"] = true
	var outcome := PlayerHealth.NONE
	for step in range(80):
		outcome = PlayerHealth._worse(outcome,health.advance(1.0))
	check(outcome == PlayerHealth.DOWNED and health.is_downed(),"Untreated heavy thorax bleeding downs the player")
	# Injury rolls happen on hits.
	health = PlayerHealth.new()
	health.rng.seed = 7
	health.heavy_bleed_chance = 1.0
	health.fracture_chance = 1.0
	health.apply_damage(&"right_leg",30)
	check(health.heavy_bleeding[&"right_leg"] and health.fractured[&"right_leg"] and health.in_pain(),"Hits can cause heavy bleeding and fractures, which hurt")
	# Treatment with real supplies.
	var inventory = Inventory.new()
	health = quiet()
	health.light_bleeding[&"left_arm"] = true
	health.heavy_bleeding[&"right_leg"] = true
	health.fractured[&"right_leg"] = true
	var bandage = carried_supply(inventory,&"cloth_bandage")
	check(health.treatment_problem(SupplyCatalog.get_def(&"cloth_bandage"),&"right_leg",1) != "","A bandage cannot stop heavy bleeding")
	check(treat(health,inventory,bandage.id) == "" and not health.light_bleeding[&"left_arm"] and not inventory.items.has(bandage.id),"A bandage finds and stops the light bleed, and is used up")
	var dressing = carried_supply(inventory,&"field_dressing")
	check(treat(health,inventory,dressing.id) == "" and not health.heavy_bleeding[&"right_leg"],"A field dressing stops heavy bleeding")
	check(not health.can_sprint() and is_equal_approx(health.speed_multiplier(),0.7),"A broken leg still slows and stops sprinting")
	var morphine = carried_supply(inventory,&"morphine")
	check(treat(health,inventory,morphine.id) == "" and not health.in_pain() and health.can_sprint() and health.painkiller_left > 200.0,"Morphine removes pain and its limits for a while")
	check(health.fractured[&"right_leg"],"Morphine does not mend a fracture")
	var splint = carried_supply(inventory,&"splint")
	check(not inventory.can_move_item(splint.id,inventory.slot_location(&"pocket",3)),"A 1 x 2 splint does not fit a pocket")
	check(treat(health,inventory,splint.id) == "" and not health.fractured[&"right_leg"],"A splint sets the fracture")
	# The satchel spends supply points: bleeds cost a fixed amount, healing costs what it restores.
	var satchel = carried_supply(inventory,&"medical_satchel")
	health.heavy_bleeding[&"stomach"] = true
	health.health[&"left_arm"] = 30.0
	check(treat(health,inventory,satchel.id,&"stomach") == "" and not health.heavy_bleeding[&"stomach"] and satchel.uses == 180,"The satchel stops a heavy bleed for 120 points")
	check(treat(health,inventory,satchel.id,&"left_arm") == "" and is_equal_approx(health.health[&"left_arm"],60.0) and satchel.uses == 150,"The satchel heals exactly what is missing")
	health.health[&"left_leg"] = 0.0
	check(health.treatment_problem(SupplyCatalog.get_def(&"medical_satchel"),&"left_leg",satchel.uses).contains("surgery"),"A destroyed part cannot be healed by the satchel")
	# Interrupted treatment consumes nothing.
	health.light_bleeding[&"head"] = true
	var spare = carried_supply(inventory,&"cloth_bandage")
	check(health.start_treatment(inventory,spare.id) == "","Treatment starts")
	health.advance(1.0)
	inventory.drop_item(spare.id,Vector3.ZERO)
	health.advance(5.0)
	check(health.light_bleeding[&"head"] and inventory.items.has(spare.id),"Dropping the supply mid-treatment fails it and spends nothing")
	# Energy and water.
	health = quiet()
	health.energy = 50.0
	health.hydration = 50.0
	var bread = carried_supply(inventory,&"rye_bread")
	check(treat(health,inventory,bread.id) == "" and health.energy > 89.0 and health.hydration < 46.0,"Bread restores energy and costs a little water")
	var canteen = carried_supply(inventory,&"canteen")
	check(treat(health,inventory,canteen.id) == "" and canteen.uses == 2 and health.hydration > 70.0,"A canteen gives three drinks")
	health.energy = 0.0
	var thorax: float = health.health[&"thorax"]
	health.advance(10.0)
	check(health.health[&"thorax"] < thorax and health.hungry() and health.speed_multiplier() < 1.0,"Empty energy slowly damages the thorax and stomach")
	health = quiet()
	health.advance(600.0, true)
	check(health.energy < 70.0 and health.hydration < 55.0,"Energy and water drain over time, faster when sprinting")
	health.suppress()
	var effects := health.effects()
	check(effects.suppression > 0.0 and effects.has("pain") and effects.has("shock") and effects.has("heavy_bleeding") and effects.has("treatment_progress"),"Effects snapshot carries everything the HUD needs")
	# Supplies are saved and validated like other items.
	var saved = JSON.parse_string(JSON.stringify(inventory.encode()))
	check(inventory.restore(saved) and inventory.items[canteen.id].uses == 2,"Supplies and their remaining uses survive a save")
	for record in saved.items:
		if record.id == str(canteen.id): record.uses = 9
	check(not inventory.restore(saved),"A save claiming more uses than the supply holds is rejected")
