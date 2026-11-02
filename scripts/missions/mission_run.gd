extends RefCounted
## Runtime rules of one deployment of a MissionDefinition, for every participant (up to four).
## Each participant ends on their own: extracted (stood in an exit for exit_seconds), killed, or
## timed out (still in the area when the time limit runs out: mission death). The run is over
## when nobody is active. A carry_out objective is done when a participant extracts carrying its
## item. No scene nodes: the controller feeds time and positions; MissionReport reads the result.
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
const ACTIVE := &"active"
const EXTRACTED := &"extracted"
const KILLED := &"killed"
const TIMED_OUT := &"timed_out"
## Whole-mission outcomes.
const SUCCESS := &"success" # every required objective carried out
const RETURNED := &"returned" # someone got out, required objectives not all done
const FAILED := &"failed" # nobody got out

var definition: Resource
var exits: Array[Dictionary] = []
var elapsed := 0.0
## id -> {name, inventory, health, state, exit_left, exit, start, end, ended_at, carried_out}
var participants := {}
## Objective index -> true once carried out.
var objective_done := {}
## Counters shown in the summary, label -> number (e.g. "Enemies killed").
var stats := {}

func _init(mission: Resource, exit_areas: Array) -> void:
	definition = mission
	exits.assign(exit_areas)

func add_participant(id: StringName, display_name: String, inventory, health) -> void:
	participants[id] = {"name":display_name,"inventory":inventory,"health":health,"state":ACTIVE,
		"exit_left":-1.0,"exit":{},"start":tally(inventory),"end":{},"ended_at":0.0,"carried_out":[]}

func count(label: String, amount := 1) -> void:
	stats[label] = stats.get(label, 0) + amount

func state_of(id: StringName) -> StringName:
	return participants[id].state if participants.has(id) else &""

func is_over() -> bool:
	return participants.values().all(func(entry): return entry.state != ACTIVE)

func active_count() -> int:
	return participants.values().filter(func(entry): return entry.state == ACTIVE).size()

func outcome() -> StringName:
	if not participants.values().any(func(entry): return entry.state == EXTRACTED): return FAILED
	return SUCCESS if _required_done() else RETURNED

func time_left() -> float:
	return maxf(0.0, definition.time_limit_seconds - elapsed) if definition.time_limit_seconds > 0.0 else INF

## Time passes. positions: participant id -> where they stand (only for those still able to
## move; a downed or missing id simply does not count down an exit).
func advance(delta: float, positions: Dictionary) -> void:
	if is_over(): return
	elapsed += delta
	for id in participants:
		var entry: Dictionary = participants[id]
		if entry.state != ACTIVE: continue
		var exit := exit_at(positions[id]) if positions.has(id) else {}
		if exit.is_empty():
			entry.exit_left = -1.0
			continue
		if entry.exit_left < 0.0: entry.exit_left = definition.exit_seconds
		entry.exit_left -= delta
		if entry.exit_left <= 0.0: _end(id, EXTRACTED, exit)
	if definition.time_limit_seconds > 0.0 and elapsed >= definition.time_limit_seconds:
		for id in participants:
			if participants[id].state == ACTIVE: _end(id, TIMED_OUT)

func participant_killed(id: StringName) -> void:
	if participants.has(id) and participants[id].state == ACTIVE: _end(id, KILLED)

func exit_at(at: Vector3) -> Dictionary:
	for exit in exits:
		if absf(at.x - exit.center.x) <= exit.half_size.x and absf(at.z - exit.center.z) <= exit.half_size.y: return exit
	return {}

func _end(id: StringName, state: StringName, exit := {}) -> void:
	var entry: Dictionary = participants[id]
	entry.state = state
	entry.exit = exit
	entry.exit_left = -1.0
	entry.ended_at = elapsed
	entry.end = tally(entry.inventory)
	if state != EXTRACTED: return
	for index in range(definition.objectives.size()):
		var objective = definition.objectives[index]
		if objective.kind == &"carry_out" and carries(entry.inventory, objective.item_id):
			objective_done[index] = true
			entry.carried_out.append(objective.item_id)

func _required_done() -> bool:
	for index in range(definition.objectives.size()):
		if definition.objectives[index].required and not objective_done.get(index, false): return false
	return true

## Where an objective stands for the HUD and summary: &"done", &"carried" (by a participant
## still in the area), &"on_body" (a killed or timed-out participant had it) or &"missing".
func objective_state(index: int) -> StringName:
	if objective_done.get(index, false): return &"done"
	var item_id: StringName = definition.objectives[index].item_id
	for entry in participants.values():
		if not carries(entry.inventory, item_id): continue
		if entry.state == ACTIVE: return &"carried"
		if entry.state in [KILLED, TIMED_OUT]: return &"on_body"
	return &"missing"

## Objective lines for one participant's HUD, including their exit countdown and the time left.
func hud_lines(id: StringName) -> Array[String]:
	var lines: Array[String] = []
	if not participants.has(id) or participants[id].state != ACTIVE: return lines
	var entry: Dictionary = participants[id]
	if definition.objectives.is_empty():
		lines.append("Scavenging: take what you can and leave by an exit")
	for index in range(definition.objectives.size()):
		var objective = definition.objectives[index]
		match objective_state(index):
			&"done": lines.append("Done: %s carried out" % objective.label)
			&"carried":
				lines.append("Take %s to an exit" % objective.label if carries(entry.inventory, objective.item_id) else "A teammate carries %s" % objective.label)
			&"on_body": lines.append("Recover %s from a fallen teammate" % objective.label)
			_: lines.append("Find %s" % objective.label)
	if entry.exit_left >= 0.0:
		lines.append("Leaving in %.1f s%s" % [entry.exit_left, "" if _required_done() or _carries_required(entry.inventory) else " (objectives incomplete)"])
	if definition.time_limit_seconds > 0.0 and time_left() < 300.0:
		lines.append("Time left %d:%02d" % [int(time_left()) / 60, int(time_left()) % 60])
	return lines

func _carries_required(inventory) -> bool:
	for index in range(definition.objectives.size()):
		var objective = definition.objectives[index]
		if objective.required and not objective_done.get(index, false) and not carries(inventory, objective.item_id): return false
	return true

static func carries(inventory, item_id: StringName) -> bool:
	for item in inventory.items.values():
		if item.kind == &"supply" and item.supply_id == item_id and inventory.carried(item): return true
	return false

## Carried rounds (loose, in magazines, chambered), carried supply items (objective items and
## money excluded) and carried money.
static func tally(inventory) -> Dictionary:
	var rounds := 0
	var supplies := 0
	var money := {}
	for item in inventory.items.values():
		if not inventory.carried(item): continue
		match item.kind:
			&"ammo_stack": rounds += item.quantity
			&"magazine": rounds += item.rounds.size()
			&"weapon": rounds += 1 if item.chambered_round != null else 0
			&"supply":
				if SupplyCatalog.is_money(item.supply_id): money[item.supply_id] = money.get(item.supply_id, 0) + item.uses
				elif not SupplyCatalog.is_objective(item.supply_id): supplies += 1
	return {"rounds":rounds,"supplies":supplies,"rubles":money.get(&"rubles", 0),"lats":money.get(&"lats", 0)}
