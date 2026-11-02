extends SceneTree
## Two local players: aiming at a teammate, reviving a downed one with a carried bandage,
## treating a standing one, stopping when out of reach, and group incapacitation as mission death.
const PlayerScene = preload("res://scenes/player/first_person_player.tscn")
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)

func _give(player, supply_id: StringName):
	var inventory = player.weapon.state.inventory
	var probe = Inventory.SupplyInstance.new()
	probe.supply_id = supply_id
	return inventory.create_supply(supply_id, inventory.empty_location(&"", inventory.footprint(probe)))

func _quiet(player) -> void:
	player.body.light_bleed_chance = 0.0
	player.body.heavy_bleed_chance = 0.0
	player.body.fracture_chance = 0.0
	player.body.infection_chance = 0.0

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	shape.shape = box
	shape.position.y = -0.5
	ground.add_child(shape)
	world.add_child(ground)
	var medic = PlayerScene.instantiate()
	var patient = PlayerScene.instantiate()
	world.add_child(medic)
	world.add_child(patient)
	medic.position = Vector3(0, 0.02, 0)
	patient.position = Vector3(0, 0.02, -1.5)
	_quiet(medic)
	_quiet(patient)
	var events: Array = []
	medic.casualty.connect(func(_p, outcome): events.append([&"medic", outcome]))
	patient.casualty.connect(func(_p, outcome): events.append([&"patient", outcome]))
	var revivals: Array = []
	patient.revived.connect(func(p): revivals.append(p))
	await _frames(20)
	medic.refresh_interaction_target()
	_check(medic.interaction_target == patient and medic.get_interaction_prompt().contains("Treat teammate"), "Looking at a teammate offers to treat them")
	# A standing teammate keeps a downed player in the mission.
	patient.receive_hit(90, patient.global_position + Vector3.UP * 1.4, Vector3.FORWARD, null, &"torso")
	_check(patient.body.is_downed() and events == [[&"patient", &"downed"]], "With a teammate standing, thorax at zero downs instead of killing")
	_check(is_equal_approx(patient.body.downed_left, patient.bleed_out_seconds) and patient.get_prompt().contains("Revive"), "A downed teammate shows the bleed-out time and a revive prompt")
	_check(medic.care_for(patient) == "Needs a bandage or dressing", "Reviving needs a carried bandage or dressing")
	var bandage = _give(medic, &"cloth_bandage")
	var dressing = _give(medic, &"field_dressing")
	medic.body.revive_seconds = 0.5
	_check(medic.care_for(patient) == "" and medic.body.treatment.revive and medic.body.treatment.item_id == bandage.id, "Revival starts with the plainest carried supply, the bandage")
	await _frames(45)
	_check(patient.body.is_alive() and revivals.size() == 1 and patient.hit_zones.layout == &"standing", "The downed teammate is revived and stands back up")
	_check(not medic.weapon.state.inventory.items.has(bandage.id), "Revival uses up the bandage")
	_check(patient.body.revived_left > 0.0 and not patient.body.can_sprint() and patient.body.speed_multiplier() < 1.0, "A revived player keeps reduced capability for a while")
	_check(patient.body.health[&"thorax"] > 0.0 and patient.body.health[&"thorax"] < 40.0, "A revived player comes back with low thorax health")
	# Treating a standing teammate; walking out of reach stops it and keeps the supply.
	patient.body.light_bleeding[&"left_arm"] = true
	_check(medic.care_for(patient) == "" and medic.body.treatment.part == &"left_arm", "Treating a teammate goes to their most urgent injury")
	medic.position = Vector3(0, 0.02, 5)
	await _frames(2)
	_check(medic.body.treatment.is_empty() and medic.care_patient == null and medic.weapon.state.inventory.items.has(dressing.id), "Moving out of reach stops the treatment and spends nothing")
	medic.position = Vector3(0, 0.02, 0)
	await _frames(2)
	_check(medic.care_for(patient) == "", "Treatment restarts back in reach")
	medic.body.treatment.left = 0.05
	await _frames(6)
	_check(not patient.body.light_bleeding[&"left_arm"] and not medic.weapon.state.inventory.items.has(dressing.id), "The medic's dressing stops the teammate's bleeding")
	_check(medic.body.light_bleeding.values().all(func(flag): return not flag), "Treatment changes the patient, not the medic")
	# Everyone down: mission death for all.
	events.clear()
	patient.receive_hit(90, patient.global_position + Vector3.UP * 1.4, Vector3.FORWARD, null, &"torso")
	_check(patient.body.is_downed(), "The teammate goes down again")
	medic.receive_hit(90, medic.global_position + Vector3.UP * 1.4, Vector3.FORWARD, null, &"torso")
	_check(medic.body.is_dead() and patient.body.is_dead(), "When the last standing player goes down, everyone downed dies")
	_check(events == [[&"patient", &"downed"], [&"medic", &"killed"], [&"patient", &"killed"]], "Casualties resolve in order: %s" % [events])
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: teammate targeting, downed with a teammate, revival with a bandage, reduced capability, treating a teammate, reach, group incapacitation")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
