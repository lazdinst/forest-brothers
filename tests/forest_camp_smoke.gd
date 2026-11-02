extends SceneTree
## The world's camp: a clearing in the woods with the fire in the middle, the old man, a small
## tent, a cash chest, a goods chest and a map barrel. The barrel opens the mission map (which
## leads back here), the old man trades from the treasury, the goods chest takes carried goods
## but not money, and the cash chest takes money. Pause and Tab inventory work through startup.
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
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

func _run() -> void:
	var startup = load("res://startup/startup.tscn").instantiate()
	root.add_child(startup)
	# As when the game runs: startup is the current scene the camp leaves from.
	current_scene = startup
	await _frames(2)
	startup.launch_camp()
	await _frames(10)
	var camp = startup.content
	_check(startup.training_active and camp.scene_file_path == "res://scenes/camp/forest_camp.tscn", "Startup opens the camp")
	var fire: Node3D = camp.get_node("Fire")
	_check(fire.position.length() < 0.01 and camp.fire_light.light_energy > 0.0, "The fire burns in the middle")
	for node in [camp.old_man, camp.tent, camp.cash_chest, camp.goods_chest, camp.map_barrel]:
		var distance: float = Vector2(node.position.x, node.position.z).length()
		_check(distance > 1.5 and distance < 10.0, "%s stands around the fire (%.1f m)" % [node.name, distance])
	var trees: int = camp.get_children().filter(func(node): return node.scene_file_path.contains("forest_")).size()
	_check(trees > 100, "Woods surround the clearing (%d trees)" % trees)
	var player = camp.player
	# The old man trades.
	var reach = camp.old_man.get_node("PlayerClearance")
	_check(reach.get_prompt().contains("old man"), "The old man can be talked to")
	var medicine: int = camp.stock.count(&"medicine")
	var rubles: int = camp.stock.count(&"rubles")
	reach.interact(player)
	await _frames(1)
	_check(camp.trade_panel.visible and camp.trade_panel.actions.get_child_count() > 2, "He offers trades")
	camp.trade_panel.action_selected.emit(&"medicine:rubles")
	_check(camp.stock.count(&"medicine") == medicine + 1 and camp.stock.count(&"rubles") == rubles - int(camp.Runtime.PRICES.medicine.rubles), "Buying from him spends the treasury")
	camp.trade_panel.action_selected.emit(&"close")
	_check(not camp.trade_panel.visible, "Leave closes the trade")
	# The goods chest takes goods, not money.
	var inventory = player.weapon.state.inventory
	var dressing = inventory.create_supply(&"field_dressing", inventory.empty_location(&"", Vector2i.ONE))
	var money = inventory.create_supply(&"rubles", inventory.empty_location(&"", Vector2i.ONE), 10)
	camp.goods_chest.interact(player)
	await _frames(2)
	var view = startup.inventory_host.view
	_check(startup.inventory_open and view.loot == camp.goods_chest and view.loot_heading.text.contains("GOODS CHEST"), "F opens the goods chest beside the inventory")
	_check(not view._can_store(money.id, 0, &"", false, false), "Money does not go in the goods chest")
	view._quick({"id":str(dressing.id)}, &"move")
	await _frames(1)
	_check(camp.goods_chest.inventory.items.has(dressing.id) and not inventory.items.has(dressing.id), "A field dressing goes in")
	startup.close_inventory()
	camp.cash_chest.interact(player)
	await _frames(2)
	view = startup.inventory_host.view
	view._quick({"id":str(money.id)}, &"move")
	await _frames(1)
	_check(camp.stock.count(&"rubles") == rubles - int(camp.Runtime.PRICES.medicine.rubles) + 10, "Money goes in the cash chest and the treasury")
	startup.close_inventory()
	await _frames(1)
	# The barrel opens the mission map, which leads back to the camp.
	_check(camp.map_barrel.get_prompt().contains("mission map"), "The map barrel says what it is")
	camp.map_barrel.interact(player)
	await _frames(8)
	_check(current_scene != null and current_scene.scene_file_path == MissionLaunch.BOARD_SCENE and MissionLaunch.camp_scene == MissionLaunch.STARTUP_SCENE and current_scene.back_button.visible, "The barrel opens the mission map with a way back")
	MissionLaunch.camp_scene = ""
	OS.set_environment("FOREST_BROTHERS_START", "")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: camp in the woods with fire, old man (trades), tent, cash and goods chests, map barrel to the mission map")
	quit(0 if failures.is_empty() else 1)
