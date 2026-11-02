extends SceneTree
## Characters and worlds persist, Valheim-style: Play creates a character and a world and joins
## it through startup; the camp and the character's equipment are saved when the camp is left and
## restored on return; the character brings its equipment into a second world whose camp starts
## fresh; an outing keeps gear on extraction (objective items handed in) and loses it on death;
## mission results persist with the world; Training stays a sandbox that saves nothing.
const SaveStore = preload("res://scripts/state/save_store.gd")
const GameSession = preload("res://scripts/state/game_session.gd")
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
const CAMP := "res://scenes/prototype/camp_test.tscn"
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

func _carries(player, supply_id: StringName) -> bool:
	var inventory = player.weapon.state.inventory
	return inventory.items.values().any(func(item): return item.kind == &"supply" and item.supply_id == supply_id and inventory.carried(item))

func _give(player, supply_id: StringName) -> void:
	var inventory = player.weapon.state.inventory
	inventory.create_supply(supply_id, inventory.empty_location(&"", Vector2i.ONE))

func _clean(folder: String) -> void:
	for kind in ["characters", "worlds"]:
		var path := folder.path_join(kind)
		if DirAccess.dir_exists_absolute(path):
			for file in DirAccess.get_files_at(path):
				DirAccess.remove_absolute(path.path_join(file))
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(folder)

func _run() -> void:
	SaveStore.root = "user://test_saves_session"
	_clean(SaveStore.root)
	GameSession.end()
	# Play through startup: create a character and a world, then join it.
	var startup = load("res://startup/startup.tscn").instantiate()
	root.add_child(startup)
	await _frames(2)
	startup.show_menu()
	await _frames(1)
	startup.content.play_button.pressed.emit()
	await _frames(2)
	var play = startup.content
	_check(play.page == &"characters" and play.continue_button.disabled, "Play opens character selection with nothing chosen")
	play.name_edit.text = "Jānis"
	_check(play.create(), "A character is created from a name")
	_check(play.selected_character != "" and SaveStore.list("characters").size() == 1, "The character is saved and chosen")
	play.continue_button.pressed.emit()
	_check(play.page == &"worlds" and play.heading.text.contains("Jānis"), "Then world selection for that character")
	play.name_edit.text = "Birch camp"
	play.create()
	var character_id: String = play.selected_character
	var first_world: String = play.selected_world
	play.continue_button.pressed.emit()
	await _frames(14)
	_check(GameSession.active() and startup.training_active and startup.content.scene_file_path == CAMP, "Joining the world opens its camp")
	startup.open_navigation()
	_check(startup.navigation_panel.heading.text == "Paused" and startup.navigation_panel.message.text.contains("Birch camp"), "The pause menu names the character and world")
	startup.close_navigation()
	# Change the camp and the character, then leave to the menu: both are saved.
	var camp = startup.content
	var annex = camp.get_node("SystemsAnnex")
	var timber: int = camp.stock.count(&"timber")
	camp.stock.add(&"timber", 7)
	annex.runtime.place_plan(&"rack_saved", Vector2(-10, 4))
	annex.runtime.shelter_tier = 1
	_give(camp.get_node("Player"), &"cloth_bandage")
	startup.show_menu()
	await _frames(3)
	_check(not GameSession.active(), "Returning to the menu ends the session")
	var saved_world := SaveStore.read("worlds", first_world)
	_check(int(saved_world.camp.stores.timber) == timber + 7 and saved_world.camp.plans.has("rack_saved") and int(saved_world.camp.shelter_tier) == 1, "Leaving saved the camp")
	_check(SaveStore.read("characters", character_id).equipment.inventory.items.any(func(record): return record.get("supply_id", "") == "cloth_bandage"), "Leaving saved the character's equipment")
	# Join again: everything is back.
	GameSession.begin(character_id, first_world)
	startup.launch_training()
	await _frames(14)
	camp = startup.content
	annex = camp.get_node("SystemsAnnex")
	_check(camp.stock.count(&"timber") == timber + 7 and annex.runtime.plans.has(&"rack_saved") and annex.runtime.shelter_tier == 1, "The camp is restored from the world")
	_check(_carries(camp.get_node("Player"), &"cloth_bandage"), "The character carries what it saved")
	startup.show_menu()
	await _frames(3)
	# A second world: the character brings its gear; the camp starts with the starting stores.
	var second := SaveStore.create_world("Bog camp")
	GameSession.begin(character_id, second.id)
	startup.launch_training()
	await _frames(14)
	camp = startup.content
	_check(_carries(camp.get_node("Player"), &"cloth_bandage") and camp.stock.count(&"timber") == timber and not camp.get_node("SystemsAnnex").runtime.plans.has(&"rack_saved"), "In another world the character keeps its gear and the camp is that world's own")
	# Outings: extraction keeps gear minus objective items; death loses it. Results persist.
	var player = camp.get_node("Player")
	_give(player, &"sealed_dispatch")
	MissionLaunch.completed[&"courier_dispatch"] = true
	MissionLaunch.results[&"courier_dispatch"] = &"success"
	GameSession.outing_ended(player, true)
	var record := SaveStore.read("characters", character_id)
	_check(record.equipment.inventory.items.any(func(item): return item.get("supply_id", "") == "cloth_bandage") and not record.equipment.inventory.items.any(func(item): return item.get("supply_id", "") == "sealed_dispatch"), "Extraction keeps gear and hands in the objective item")
	_check(SaveStore.read("worlds", second.id).missions.completed.has("courier_dispatch"), "Mission results are saved with the world")
	GameSession.outing_ended(player, false)
	_check(SaveStore.read("characters", character_id).equipment.is_empty(), "Death leaves the gear on the body: the character returns with the standard kit")
	startup.show_menu()
	await _frames(3)
	GameSession.begin(character_id, second.id)
	_check(MissionLaunch.completed.has(&"courier_dispatch") and not GameSession.world.is_empty(), "Joining the world again restores its mission progress")
	GameSession.begin(character_id, first_world)
	_check(not MissionLaunch.completed.has(&"courier_dispatch"), "Mission progress belongs to its world")
	GameSession.end()
	# Training saves nothing.
	var before := FileAccess.get_file_as_string(SaveStore.root.path_join("worlds").path_join(first_world + ".json"))
	startup.content.training_button.pressed.emit()
	await _frames(14)
	_check(startup.training_active and not GameSession.active(), "Training runs without a session")
	startup.content.stock.add(&"timber", 5)
	startup.show_menu()
	await _frames(3)
	_check(FileAccess.get_file_as_string(SaveStore.root.path_join("worlds").path_join(first_world + ".json")) == before, "Training changed no save")
	startup.queue_free()
	await _frames(2)
	_clean(SaveStore.root)
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: Play creates and joins character and world; camp and equipment saved on leaving and restored; gear travels between worlds; extraction keeps gear, death loses it; mission progress per world; Training saves nothing")
	quit(0 if failures.is_empty() else 1)
