extends SceneTree
## Quick-use keys: 1 is the rifle; a carried bandage bound to 4 shows on the bar, does nothing
## with no wound, and treats a bleeding arm when pressed (then the key empties); a magazine on 2
## reloads; hovering over an item in the inventory and pressing a number binds it (badge shown),
## pressing it again unbinds; money cannot be bound; bindings survive a save as JSON.
const Hotkeys = preload("res://scripts/player/hotkeys.gd")
const PlayerHealth = preload("res://scripts/health/player_health.gd")
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
func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	return event

func _run() -> void:
	var camp = load("res://scenes/camp/forest_camp.tscn").instantiate()
	root.add_child(camp)
	current_scene = camp
	await _frames(8)
	var player = camp.player
	var hud = player.hotkey_hud
	var inventory = player.weapon.state.inventory
	_check(Hotkeys.slot_for_key(KEY_1) == 1 and Hotkeys.slot_for_key(KEY_0) == 10 and Hotkeys.slot_for_key(KEY_A) == 0, "Keys 1 to 0 are the quick-use slots")
	_check(hud.slot_view(1).get("kind", "") == "rifle" and hud.cells.size() == 10, "The bar shows ten keys with the rifle on 1")
	var bandage = inventory.create_supply(&"cloth_bandage", inventory.empty_location(&"", Vector2i.ONE))
	_check(player.hotkeys.bind(4, bandage.id, inventory) and hud.slot_view(4).get("title", "") == "Cloth bandage", "A bandage bound to 4 shows on the bar")
	var money = inventory.create_supply(&"rubles", inventory.empty_location(&"", Vector2i.ONE), 10)
	_check(not player.hotkeys.bind(5, money.id, inventory) and not player.hotkeys.bind(1, bandage.id, inventory), "Money cannot be bound, and 1 stays the rifle")
	# No wound: nothing to treat.
	player._unhandled_input(_key(KEY_4))
	_check(player.body.treatment.is_empty() and player.weapon.state.message.contains("Nothing for"), "With no wound the bandage stays: " + player.weapon.state.message)
	# A bleeding arm: pressing 4 treats it.
	player.body.light_bleeding[PlayerHealth.LEFT_ARM] = true
	player._unhandled_input(_key(KEY_4))
	_check(not player.body.treatment.is_empty() and player.body.treatment.get("part") == PlayerHealth.LEFT_ARM, "Bleeding, 4 bandages the bleeding arm (%s)" % player.body.treatment)
	for i in range(60 * 6):
		await physics_frame
		player.advance_condition(1.0 / 60.0)
		if player.body.treatment.is_empty(): break
	await _frames(2)
	_check(not player.body.light_bleeding[PlayerHealth.LEFT_ARM] and not inventory.items.has(bandage.id) and hud.slot_view(4).is_empty(), "The bleeding stops, the bandage is used up and 4 is empty")
	# A magazine on 2 reloads.
	var spare: StringName = inventory.initial_magazine_ids[1]
	player.hotkeys.bind(2, spare, inventory)
	player.use_hotkey(2)
	_check(player.weapon.state.busy == &"reload", "A magazine on 2 reloads the rifle (%s)" % player.weapon.state.busy)
	player.weapon.state.cancel_action()
	# Binding in the inventory by hovering and pressing a number.
	var dressing = inventory.create_supply(&"field_dressing", inventory.empty_location(&"", Vector2i.ONE))
	camp.inventory.open()
	await _frames(3)
	var view = camp.inventory.view
	var card = view.pocket_grid.cards.filter(func(entry): return entry.item_id == dressing.id)
	if card.is_empty(): card = view.pack_grid.cards.filter(func(entry): return entry.item_id == dressing.id)
	_check(not card.is_empty(), "The dressing has a card in the inventory")
	if not card.is_empty():
		# Headless runs have no pointer, so the hover point is passed in.
		var over: Vector2 = card[0].get_global_rect().get_center()
		_check(view.hovered_item(over) == dressing.id and view.hovered_item(Vector2(-50, -50)) == &"", "The inventory finds the item under the pointer")
		view.bind_hovered(7, over)
		await _frames(1)
		_check(player.hotkeys.slot_of(dressing.id) == 7, "Hovering and pressing 7 binds the dressing to 7")
		# Binding redraws the cards; find the dressing's card again.
		var fresh: Array = (view.pocket_grid.cards + view.pack_grid.cards).filter(func(entry): return is_instance_valid(entry) and entry.item_id == dressing.id)
		var badge = fresh[0].get_node_or_null("HotkeyBadge") if not fresh.is_empty() else null
		_check(badge != null and badge.text.strip_edges() == "7", "Its card shows the key")
		view.bind_hovered(7, over)
		await _frames(1)
		_check(player.hotkeys.slot_of(dressing.id) == 0, "Pressing 7 again takes it off")
		view.bind_hovered(7, over)
	camp.inventory.close()
	# Saved with the character.
	var copy := Hotkeys.new()
	copy.restore(JSON.parse_string(JSON.stringify(player.hotkeys.encode())))
	_check(copy.slots.get(7) == dressing.id and copy.slots.get(2) == spare, "Bindings survive a save")
	camp.queue_free()
	await _frames(2)
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: quick-use keys: rifle on 1, bandage on 4 treats bleeding, magazine on 2 reloads, hover-and-press binding with badge, no money, saved")
	quit(0 if failures.is_empty() else 1)
