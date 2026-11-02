extends RefCounted
## Rules for the arena's one outing: find the sealed dispatch and leave the area carrying it.
## Leaving without it is allowed (an early safe return); death ends the outing and the dispatch,
## like all carried gear, stays on the body. No scene nodes: the arena feeds time and position;
## presentation reads objective_text() and debrief(). Numbers are placeholders.
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
const DOCUMENT := &"sealed_dispatch"
const ACTIVE := &"active"
const COMPLETE := &"complete" # left the area with the dispatch
const LEFT := &"left" # left the area without it
const KILLED := &"killed"

var state: StringName = ACTIVE
var exit_center: Vector3
var exit_half_size := Vector2(2.0, 3.0) # x and z half-extents of the exit area
var exit_seconds := 5.0 # standing in the exit this long leaves the area
## Seconds left while standing in the exit; negative when outside it.
var exit_left := -1.0
var elapsed := 0.0
var enemies_killed := 0
var _start := {}

func _init(exit_at: Vector3) -> void:
	exit_center = exit_at

## Notes what the player set out with, for the debrief.
func begin(inventory) -> void:
	_start = _tally(inventory)

static func carries_document(inventory) -> bool:
	for item in inventory.items.values():
		if item.kind == &"supply" and item.supply_id == DOCUMENT and inventory.carried(item): return true
	return false

func in_exit(at: Vector3) -> bool:
	return absf(at.x - exit_center.x) <= exit_half_size.x and absf(at.z - exit_center.z) <= exit_half_size.y

## Time passes for a living player at a position. Standing in the exit counts down and leaves;
## stepping out resets the count. Returns the mission state.
func advance(delta: float, at: Vector3, inventory) -> StringName:
	if state != ACTIVE: return state
	elapsed += delta
	if not in_exit(at):
		exit_left = -1.0
		return state
	if exit_left < 0.0: exit_left = exit_seconds
	exit_left -= delta
	if exit_left <= 0.0:
		exit_left = -1.0
		state = COMPLETE if carries_document(inventory) else LEFT
	return state

func player_killed() -> void:
	if state == ACTIVE: state = KILLED

func objective_text(inventory) -> String:
	if state != ACTIVE: return ""
	var carrying := carries_document(inventory)
	var text := "Objective: " + ("reach the exit on the west edge with the dispatch" if carrying else "find the sealed dispatch")
	if exit_left >= 0.0:
		text += "\nLeaving in %.1f s%s" % [exit_left, "" if carrying else " (without the dispatch)"]
	return text

## Read-only summary for the debrief screen: {state, headline, lines}.
func debrief(inventory, health, enemies_downed := 0) -> Dictionary:
	var carrying := carries_document(inventory)
	var headline := ""
	var lines: Array[String] = []
	match state:
		COMPLETE:
			headline = "Mission complete: dispatch recovered"
			lines.append("The dispatch reaches camp.")
		LEFT:
			headline = "Left the area without the dispatch"
			lines.append("Carried supplies are safe; the dispatch is still out there.")
		KILLED:
			headline = "Killed in action"
			lines.append("Your carried gear stays on your body%s." % (", including the dispatch" if carrying else ""))
		_:
			headline = "Mission in progress"
	lines.append("Time in the area: %d:%02d" % [int(elapsed) / 60, int(elapsed) % 60])
	lines.append("Enemies killed: %d · downed: %d" % [enemies_killed, enemies_downed])
	var now := _tally(inventory)
	lines.append("Rounds carried: %d → %d" % [_start.get("rounds", 0), now.rounds])
	lines.append("Medical and food supplies carried: %d → %d" % [_start.get("supplies", 0), now.supplies])
	if state != KILLED: lines.append_array(injuries(health))
	return {"state":state,"headline":headline,"lines":lines}

static func injuries(health) -> Array[String]:
	var lines: Array[String] = ["Health %d / %d" % [ceili(health.total_health()), int(health.total_max())]]
	var parts := func(list: Array) -> String: return ", ".join(list.map(func(part): return health.LABELS[part].to_lower()))
	if not health.bleeding_parts(true).is_empty(): lines.append("Heavy bleeding: " + parts.call(health.bleeding_parts(true)))
	if not health.bleeding_parts(false).is_empty(): lines.append("Light bleeding: " + parts.call(health.bleeding_parts(false)))
	if not health.fractured_parts().is_empty(): lines.append("Fractures: " + parts.call(health.fractured_parts()))
	var lost: Array = health.ZONES.filter(func(part): return health.destroyed(part))
	if not lost.is_empty(): lines.append("Destroyed: " + parts.call(lost))
	if not health.infected_parts().is_empty(): lines.append("Infected: " + parts.call(health.infected_parts()))
	if lines.size() == 1 and health.total_health() >= health.total_max(): lines.append("No injuries")
	return lines

## Carried rounds (loose, in magazines, chambered) and carried supply items, the dispatch excluded.
static func _tally(inventory) -> Dictionary:
	var rounds := 0
	var supplies := 0
	for item in inventory.items.values():
		if not inventory.carried(item): continue
		match item.kind:
			&"ammo_stack": rounds += item.quantity
			&"magazine": rounds += item.rounds.size()
			&"weapon": rounds += 1 if item.chambered_round != null else 0
			&"supply": supplies += 0 if SupplyCatalog.is_objective(item.supply_id) else 1
	return {"rounds":rounds,"supplies":supplies}
