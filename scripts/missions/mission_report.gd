extends RefCounted
## Builds the one summary structure every mission uses, for one participant:
## {title, outcome, personal, headline, sections: [{heading, rows: [[label, value]]}]}.
## Screens render it without knowing which mission it was.
const MissionRun = preload("res://scripts/missions/mission_run.gd")

static func build(run, id: StringName) -> Dictionary:
	var entry: Dictionary = run.participants[id]
	var personal: StringName = entry.state
	var headline := ""
	match personal:
		MissionRun.EXTRACTED: headline = "Mission complete" if run.outcome() == MissionRun.SUCCESS and not run.definition.objectives.is_empty() else "Returned to camp"
		MissionRun.KILLED: headline = "Killed in action"
		MissionRun.TIMED_OUT: headline = "Missing in action: time ran out"
		_: headline = "Mission in progress"
	var sections: Array = []
	# Missions taken on a region outing.
	if not run.definition.missions.is_empty():
		var mission_rows: Array = []
		for mission in run.definition.missions:
			var done: bool = run.definition.mission_done(run, mission)
			var reward: String = mission.reward_text()
			mission_rows.append([mission.title, ("Completed: camp receives " + reward if reward != "" else "Completed") if done else "Not completed"])
		sections.append({"heading":"Missions","rows":mission_rows})
	# Objectives.
	var objective_rows: Array = []
	for index in range(run.definition.objectives.size()):
		var objective = run.definition.objectives[index]
		var status: String = {&"done":"Carried out",&"carried":"Carried by a teammate still out there",&"on_body":"On a fallen body",&"missing":"Not recovered"}[run.objective_state(index)]
		objective_rows.append([objective.label.left(1).to_upper() + objective.label.substr(1) + ("" if objective.required else " (optional)"), status])
	if objective_rows.is_empty():
		objective_rows.append(["Objectives", "None: scavenging"])
	if not run.is_over():
		objective_rows.append(["Mission", "Still running: %d still in the area" % run.active_count()])
	sections.append({"heading":"Objectives","rows":objective_rows})
	# The outing.
	var end_time: float = entry.ended_at if personal != MissionRun.ACTIVE else run.elapsed
	var outing: Array = [["Time in the area", "%d:%02d" % [int(end_time) / 60, int(end_time) % 60]]]
	if personal == MissionRun.EXTRACTED: outing.append(["Left by", entry.exit.get("label", "an exit")])
	for label in run.stats:
		outing.append([label, str(run.stats[label])])
	sections.append({"heading":"Outing","rows":outing})
	# Equipment carried in and out.
	var end: Dictionary = entry.end if not entry.end.is_empty() else MissionRun.tally(entry.inventory)
	var equipment: Array = [
		["Rounds carried", "%d → %d" % [entry.start.rounds, end.rounds]],
		["Medical and food supplies", "%d → %d" % [entry.start.supplies, end.supplies]],
		["Money carried", "%d → %d rubles, %d → %d lats" % [entry.start.get("rubles", 0), end.get("rubles", 0), entry.start.get("lats", 0), end.get("lats", 0)]],
		["Carried gear", "Brought back to camp" if personal == MissionRun.EXTRACTED else ("Left on your body" if personal != MissionRun.ACTIVE else "Still with you")],
	]
	sections.append({"heading":"Equipment","rows":equipment})
	if personal in [MissionRun.EXTRACTED, MissionRun.ACTIVE]:
		sections.append({"heading":"Condition","rows":condition_rows(entry.health)})
	return {"title":run.definition.title,"outcome":run.outcome(),"personal":personal,"headline":headline,"sections":sections}

static func condition_rows(health) -> Array:
	var rows: Array = [["Health", "%d / %d" % [ceili(health.total_health()), int(health.total_max())]]]
	var names := func(list: Array) -> String: return ", ".join(list.map(func(part): return health.LABELS[part].to_lower()))
	if not health.bleeding_parts(true).is_empty(): rows.append(["Heavy bleeding", names.call(health.bleeding_parts(true))])
	if not health.bleeding_parts(false).is_empty(): rows.append(["Light bleeding", names.call(health.bleeding_parts(false))])
	if not health.fractured_parts().is_empty(): rows.append(["Fractures", names.call(health.fractured_parts())])
	var lost: Array = health.ZONES.filter(func(part): return health.destroyed(part))
	if not lost.is_empty(): rows.append(["Destroyed", names.call(lost)])
	if not health.infected_parts().is_empty(): rows.append(["Infected", names.call(health.infected_parts())])
	if rows.size() == 1 and health.total_health() >= health.total_max(): rows.append(["Injuries", "None"])
	return rows
