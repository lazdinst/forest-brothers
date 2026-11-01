extends SceneTree
const State = preload("res://scripts/weapons/prototype_weapon_state.gd")
var failures: Array[String] = []

func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)

func _initialize() -> void:
	var state = State.new()
	state.start_action(&"pack")
	state.advance(0.1)
	state.cancel_packing()
	_check(state.total_rounds() == 40 and state.magazines[1] == 0, "Cancel packing without duplicating or losing rounds")
	for index in range(4):
		state.start_action(&"pack")
		_check(not state.start_action(&"reload"), "Cannot reload during cartridge transfer")
		state.advance(0.33)
	_check(state.loose_rounds == 26 and state.magazines[1] == 4 and state.total_rounds() == 40, "Packing moves physical cartridges into the spare")
	state.start_action(&"reload")
	_check(not state.try_fire(1.0), "Cannot fire mid-reload")
	state.advance(1.41)
	_check(state.loaded_magazine == 1 and state.magazines[0] == 10, "Reload retains the other magazine and its contents")
	_check(state.try_fire(1.0) and state.total_rounds() == 39, "Fire consumes exactly one round")
	_check(not state.try_fire(1.0) and state.total_rounds() == 39, "Cooldown does not consume ammunition")
	state.advance(1.0)
	var clean_risk: float = state.jam_probability()
	state.cleanliness = 0.05
	_check(state.jam_probability() > clean_risk, "Dirt increases jam risk")
	_check(not state.try_fire(0.0) and state.jammed and state.total_rounds() == 39, "A jam blocks firing without destroying a cartridge")
	state.start_action(&"clean")
	state.advance(2.3)
	_check(state.jammed and state.cleanliness == 1.0, "Cleaning is separate from clearing a jam")
	state.start_action(&"clear")
	state.advance(1.0)
	_check(not state.jammed and state.total_rounds() == 39, "Clear the jam without replenishing ammunition")
	for index in range(3):
		_check(state.try_fire(1.0), "Fire remaining loaded rounds")
		state.advance(1.0)
	_check(not state.try_fire(1.0) and state.magazines[1] == 0 and state.total_rounds() == 36, "Empty magazine must not draw directly from loose rounds")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: physical-round conservation, partial magazines, interrupted packing, busy/cooldown gating, empty magazine, dirt/jam/clear/clean")
	quit(0 if failures.is_empty() else 1)
