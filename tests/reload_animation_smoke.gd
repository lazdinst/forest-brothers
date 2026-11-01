extends SceneTree
const State = preload("res://scripts/weapons/prototype_weapon_state.gd")
const DEFAULT = preload("res://weapons/svt_inspired_training.tres")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)

func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame

func _run() -> void:
	var rules = State.new()
	rules.magazines.assign([3, 7])
	rules.start_action(&"reload")
	rules.advance(0.8)
	_check(rules.loaded_magazine == 0 and rules.total_rounds() == 40, "Removing/retaining the old magazine must not award or swap ammo early")
	rules.cancel_action()
	_check(rules.loaded_magazine == 0 and rules.magazines == [3, 7], "Cancel before insertion preserves magazine contents")
	rules.start_action(&"reload")
	rules.advance(1.1)
	_check(rules.loaded_magazine == 1 and rules.busy == &"reload", "Magazine insertion commits once before the ready phase")
	_check(not rules.try_fire(1.0), "Seating the magazine does not permit early firing")
	rules.cancel_action()
	_check(rules.loaded_magazine == 1 and rules.total_rounds() == 40, "Cancel after insertion retains the completed transfer")
	rules.start_action(&"reload")
	rules.advance(5.0)
	rules.advance(5.0)
	_check(rules.loaded_magazine == 0 and rules.total_rounds() == 40, "Large time steps and repeated updates must not double swap")
	_check(not rules.start_action(&"unsupported"), "Missing actions reject without changing state")
	# A test-only second weapon shares the controller but owns different content.
	var alternate = DEFAULT.duplicate(true)
	alternate.weapon_id = &"test_only_six_round_rifle"
	alternate.display_name = "TEST FIXTURE"
	alternate.capacity = 6
	alternate.initial_loaded = 6
	alternate.initial_spare = 2
	alternate.initial_loose = 9
	alternate.fire_interval = 0.6
	var alternate_reload = alternate.get_clip(&"reload")
	alternate_reload.duration = 2.0
	alternate_reload.commit_at = 0.5
	_check(DEFAULT.get_clip(&"reload").duration == 1.4, "Changing another weapon's clip must not change the original")
	var other_rules = State.new(alternate)
	other_rules.start_action(&"reload")
	other_rules.advance(0.9)
	_check(other_rules.loaded_magazine == 0, "Second definition keeps its own insertion time")
	other_rules.advance(0.2)
	_check(other_rules.loaded_magazine == 1 and other_rules.busy == &"reload", "Second definition commits at its own marker")
	other_rules.advance(1.0)
	_check(other_rules.try_fire(1.0) and other_rules.total_rounds() == 16, "Second weapon uses its own capacity and retains physical rounds")
	other_rules.advance(0.3)
	_check(not other_rules.try_fire(1.0), "Second weapon uses its own fire interval")
	var packed = load("res://scenes/prototype/camp_test.tscn")
	var world = packed.instantiate()
	root.add_child(world)
	await _frames(10)
	var weapon = world.get_node("Player/Weapon")
	weapon.command(&"reload")
	await _frames(20)
	_check(weapon._magazine.visible and weapon._magazine.position.distance_to(weapon._hands.position) > 15.0, "Reload visibly moves the magazine separately from the rifle")
	_check(weapon.action_phase != "" and weapon.state.busy == &"reload", "The selected clip drives a readable reload phase")
	weapon.command(&"fire")
	await _frames(3)
	_check(weapon.shots == 0, "Presentation cannot bypass the reload firing lock")
	await _frames(80)
	_check(not weapon._magazine.visible and weapon.state.loaded_magazine == 1, "Complete reload returns to an assembled gun")
	world.queue_free()
	await process_frame
	world = packed.instantiate()
	world.get_node("Player/Weapon").definition = alternate
	root.add_child(world)
	await _frames(5)
	weapon = world.get_node("Player/Weapon")
	weapon.command(&"reload")
	_check(weapon.state.action_duration == 2.0 and weapon.state.magazines == [6, 2], "Same presentation controller accepts a different definition at spawn")
	world.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: insertion commit, cancellation before/after commit, no double swap, busy fire lock, animated magazine, two independent weapon definitions")
	quit(0 if failures.is_empty() else 1)
