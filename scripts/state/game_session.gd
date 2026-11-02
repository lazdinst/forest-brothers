extends RefCounted
## The character and world being played, across scene changes, without an autoload. Scenes call
## in at fixed points: the camp applies the world and the character's equipment when it loads and
## saves both when it is left (and on a timer); a mission world applies the equipment on deploy
## and saves the outcome when the local player's outing ends. Saving at deployment and at the
## outing's end means a crash mid-outing leaves both files as they were before deploying.
## No session is active in Training, which stays a sandbox that saves nothing.
const SaveStore = preload("res://scripts/state/save_store.gd")
const MissionLaunch = preload("res://scripts/missions/mission_launch.gd")
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
static var character: Dictionary = {}
static var world: Dictionary = {}

static func active() -> bool:
	return not character.is_empty() and not world.is_empty()

## Starts playing a character in a world: mission results come from the world file.
static func begin(character_id: String, world_id: String) -> bool:
	character = SaveStore.read("characters", character_id)
	world = SaveStore.read("worlds", world_id)
	if not active():
		end()
		return false
	MissionLaunch.results.clear()
	MissionLaunch.completed.clear()
	var missions: Dictionary = world.get("missions", {})
	for id in missions.get("results", {}):
		MissionLaunch.results[StringName(id)] = StringName(missions.results[id])
	for id in missions.get("completed", []):
		MissionLaunch.completed[StringName(id)] = true
	return true

static func end() -> void:
	character = {}
	world = {}
	MissionLaunch.results.clear()
	MissionLaunch.completed.clear()

# --- Character -------------------------------------------------------------------------------

## Gives the player the character's saved equipment; a character without one keeps the standard
## kit the player scene starts with.
static func apply_equipment(player: Node) -> void:
	if not active() or character.get("equipment", {}).is_empty(): return
	if not player.weapon.state.restore(character.equipment):
		push_warning("Saved equipment could not be restored; issuing the standard kit")

## Saves what the player carries and wears: carried items only (anything dropped stays in the
## world it was dropped in) and no mission objective items, which are handed in at camp.
static func save_equipment(player: Node) -> bool:
	if not active(): return false
	character.equipment = carried_snapshot(player.weapon.state)
	return SaveStore.write("characters", character)

## Mission death: carried gear stays on the body, so the character returns with the standard kit.
## The kit is a placeholder until camp issue of weapons and ammunition exists.
static func lose_equipment() -> bool:
	if not active(): return false
	character.equipment = {}
	return SaveStore.write("characters", character)

static func carried_snapshot(weapon_state) -> Dictionary:
	var inventory = weapon_state.inventory
	var snapshot: Dictionary = weapon_state.encode()
	var kept: Array = []
	for record in snapshot.inventory.items:
		var item = inventory.items.get(StringName(record.id))
		if item == null or not inventory.carried(item): continue
		if record.kind == "supply" and SupplyCatalog.is_objective(StringName(record.get("supply_id", ""))): continue
		kept.append(record)
	snapshot.inventory.items = kept
	if not kept.any(func(record): return record.id == snapshot.inventory.active_weapon_id):
		snapshot.inventory.active_weapon_id = ""
	return snapshot

# --- World -----------------------------------------------------------------------------------

## The saved camp, or empty for a new world (the camp then starts with its starting stores).
static func camp_state() -> Dictionary:
	return world.get("camp", {}) if active() else {}

## Saves the camp and the mission results into the world file.
static func save_world(camp: Dictionary = {}) -> bool:
	if not active(): return false
	if not camp.is_empty():
		world.camp = camp
	var results := {}
	for id in MissionLaunch.results:
		results[str(id)] = str(MissionLaunch.results[id])
	world.missions = {"results":results,"completed":MissionLaunch.completed.keys().map(func(id): return str(id))}
	return SaveStore.write("worlds", world)

## Called when the local player's outing ends: mission results always; equipment kept when they
## got out, lost when they died or ran out of time.
static func outing_ended(player: Node, extracted: bool) -> void:
	if not active(): return
	if extracted:
		save_equipment(player)
	else:
		lose_equipment()
	save_world()
