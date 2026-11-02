extends RefCounted
## Rules-only zone health shared by players and enemies. No scene nodes.
## Confirmed: head at zero kills, torso at zero downs, any hit on a downed body kills.
## Placeholder numbers only; zone values and limb effects remain open owner questions.
const HEAD := &"head"
const TORSO := &"torso"
const ARMS := &"arms"
const LEGS := &"legs"
const ZONES: Array[StringName] = [HEAD, TORSO, ARMS, LEGS]
const PLACEHOLDER_MAX := {HEAD: 35.0, TORSO: 80.0, ARMS: 60.0, LEGS: 65.0}

# Outcome of one apply_damage call.
const NONE := &"none"
const LIMB_DISABLED := &"limb_disabled"
const DOWNED := &"downed"
const KILLED := &"killed"

var state: StringName = &"alive"
var max_health := {}
var multiplier := {}
var health := {}
var disabled := {}

func _init(max_values: Dictionary = PLACEHOLDER_MAX, multipliers: Dictionary = {}) -> void:
	for zone in ZONES:
		max_health[zone] = float(max_values.get(zone, PLACEHOLDER_MAX[zone]))
		multiplier[zone] = float(multipliers.get(zone, 1.0))
		health[zone] = max_health[zone]
		disabled[zone] = false

func is_alive() -> bool:
	return state == &"alive"

func is_downed() -> bool:
	return state == &"downed"

func is_dead() -> bool:
	return state == &"dead"

func apply_damage(zone: StringName, amount: float) -> StringName:
	if state == &"dead" or amount <= 0.0 or not health.has(zone):
		return NONE
	if state == &"downed":
		state = &"dead"
		return KILLED
	health[zone] = maxf(0.0, health[zone] - amount * multiplier[zone])
	if health[zone] > 0.0:
		return NONE
	if zone == HEAD:
		state = &"dead"
		return KILLED
	if zone == TORSO:
		state = &"downed"
		return DOWNED
	# Overflow into an already disabled limb is unresolved; it is ignored for now.
	if disabled[zone]:
		return NONE
	disabled[zone] = true
	return LIMB_DISABLED

func bleed_out() -> StringName:
	if state != &"downed":
		return NONE
	state = &"dead"
	return KILLED
