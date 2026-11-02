extends SceneTree
## Mission rules without a scene, for two participants: individual endings, the objective done
## only when carried out, a fallen carrier leaving it on the body, a teammate still in the area,
## the time limit as mission death, and one report shape for every outcome.
const MissionRun = preload("res://scripts/missions/mission_run.gd")
const MissionReport = preload("res://scripts/missions/mission_report.gd")
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
const PlayerHealth = preload("res://scripts/health/player_health.gd")
const DEFINITION = preload("res://missions/arena_dispatch.tres")
var failures: Array[String] = []

func _initialize() -> void:
	_run()
	for failure in failures:
		push_error(failure)
	print("Mission run checks: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func carry(inventory, supply_id: StringName):
	var probe = Inventory.SupplyInstance.new()
	probe.supply_id = supply_id
	return inventory.create_supply(supply_id, inventory.empty_location(&"", inventory.footprint(probe)))

func fresh() -> MissionRun:
	var run := MissionRun.new(DEFINITION, [{"id":&"west","label":"forest path","center":Vector3(-32, 0, -4),"half_size":Vector2(2, 3)}])
	run.add_participant(&"anna", "Anna", Inventory.new(), PlayerHealth.new())
	run.add_participant(&"jānis", "Jānis", Inventory.new(), PlayerHealth.new())
	return run

func _run() -> void:
	check(DEFINITION.objectives.size() == 1 and DEFINITION.objectives[0].item_id == &"sealed_dispatch", "The arena mission loads from its definition file")
	var exit := Vector3(-32, 0, -4)
	var away := Vector3(0, 0, 20)
	# Anna carries the dispatch and dies; Jānis is still out there.
	var run := fresh()
	carry(run.participants[&"anna"].inventory, &"sealed_dispatch")
	run.participant_killed(&"anna")
	check(run.state_of(&"anna") == MissionRun.KILLED and not run.is_over() and run.objective_state(0) == &"on_body", "One death ends only that participant; the dispatch is on the body")
	var report := MissionReport.build(run, &"anna")
	check(report.headline == "Killed in action" and report.sections[0].rows.any(func(row): return row[0] == "Mission" and str(row[1]).contains("1 still")), "Her summary says the mission is still running")
	check(run.hud_lines(&"jānis")[0].contains("Recover the sealed dispatch"), "The teammate's HUD says to recover it from the body")
	# Jānis recovers it (here: a new copy stands in for taking it off the body) and gets out.
	carry(run.participants[&"jānis"].inventory, &"sealed_dispatch")
	for step in range(60):
		run.advance(0.1, {&"jānis": exit})
	check(run.state_of(&"jānis") == MissionRun.EXTRACTED and run.is_over() and run.outcome() == MissionRun.SUCCESS, "Carrying it out completes the mission for the group")
	check(MissionReport.build(run, &"jānis").headline == "Mission complete", "The carrier's summary: mission complete")
	# Getting out without it is an early return.
	run = fresh()
	run.participant_killed(&"anna")
	for step in range(60):
		run.advance(0.1, {&"jānis": exit})
	check(run.outcome() == MissionRun.RETURNED and MissionReport.build(run, &"jānis").headline == "Returned to camp", "Leaving without the objective is an early return")
	# Nobody gets out: failed.
	run = fresh()
	run.participant_killed(&"anna")
	run.participant_killed(&"jānis")
	check(run.is_over() and run.outcome() == MissionRun.FAILED, "Everyone killed: the mission failed")
	# The time limit is mission death for anyone still in the area.
	run = fresh()
	run.definition = DEFINITION.duplicate()
	run.definition.time_limit_seconds = 10.0
	for step in range(50):
		run.advance(0.1, {&"anna": away, &"jānis": away})
	check(run.hud_lines(&"anna").any(func(line): return line.begins_with("Time left")), "The HUD shows the time left near the limit")
	for step in range(60):
		run.advance(0.1, {&"anna": away, &"jānis": away})
	check(run.state_of(&"anna") == MissionRun.TIMED_OUT and run.state_of(&"jānis") == MissionRun.TIMED_OUT, "Time running out is mission death for those still in the area")
	check(MissionReport.build(run, &"anna").headline.begins_with("Missing in action"), "Their summary: missing in action")
	# Every report has the same shape.
	var shape := MissionReport.build(run, &"jānis")
	check(shape.has("title") and shape.has("headline") and shape.sections.map(func(section): return section.heading) == ["Objectives", "Outing", "Equipment"], "Reports share one shape (no condition section after death)")
	run.count("Enemies killed", 2)
	check(MissionReport.build(run, &"anna").sections[1].rows.any(func(row): return row == ["Enemies killed", "2"]), "Mission counters appear in the summary")
