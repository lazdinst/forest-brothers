extends SceneTree
## The shared inventory host works outside training: Tab in the combat arena opens the
## player's real carried inventory, suspends only the arena, and closes with Tab or Escape.
var failures := 0

func _initialize() -> void:
	# A script error stops _run without quitting; fail instead of hanging forever.
	create_timer(60.0).timeout.connect(func():
		push_error("Inventory host check timed out")
		quit(1))
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func key_press(key: Key) -> void:
	await create_timer(0.05).timeout
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	root.push_input(event,true)
	event.pressed = false
	root.push_input(event,true)
	await create_timer(0.05).timeout

func _run() -> void:
	var arena = load("res://scenes/combat/combat_arena.tscn").instantiate()
	root.add_child(arena)
	await create_timer(0.3).timeout
	var player = arena.player
	var state = player.weapon.state
	var rounds: int = state.total_rounds()
	var mode: int = arena.process_mode
	await key_press(KEY_TAB)
	check(arena.inventory.is_open and arena.inventory.view != null,"Tab opens the inventory in the combat arena")
	check(arena.process_mode == Node.PROCESS_MODE_DISABLED and not paused,"Only the arena is suspended, never the whole tree")
	check(arena.inventory.view.data.backpack_id != "" and arena.inventory.view.pocket_grid.cards.size() == 2,"Arena inventory shows the player's real kit")
	var spare: StringName = state.inventory.initial_magazine_ids[1]
	arena.inventory.view.selected_id = spare
	arena.inventory.view._inventory_action(&"drop")
	check(player.weapon._ground_items.has(spare) and state.inventory.magazine(spare).location.kind == &"ground","Dropping from the arena inventory puts the item in the world")
	await key_press(KEY_TAB)
	check(not arena.inventory.is_open and arena.process_mode == mode,"Tab closes it and the arena resumes")
	await key_press(KEY_TAB)
	await key_press(KEY_ESCAPE)
	check(not arena.inventory.is_open and arena.process_mode == mode,"Escape also closes it")
	player.weapon._ground_items[spare].interact(player)
	check(state.inventory.carried(state.inventory.magazine(spare)) and state.total_rounds() == rounds,"F recovers the dropped magazine with rounds conserved")
	arena.queue_free()
	await process_frame
	print("Inventory host checks: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
