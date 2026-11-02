extends RefCounted
## Hands the chosen region and missions from the mission map to the region's world scene and
## the results back, across scene changes, without an autoload. Also remembers the camp scene
## the player left from, so the mission map and every outing lead back to it. Results last for
## this run of the game only; campaign persistence is not built.
const MissionRun = preload("res://scripts/missions/mission_run.gd")
const BOARD_SCENE := "res://scenes/missions/mission_board.tscn"
## The startup scene; it opens the camp when its route is "training" (see startup/scene_registry.gd).
const STARTUP_SCENE := "res://startup/startup.tscn"
## The composed definition a world scene should play next; null when launched directly.
static var pending: Resource
## Mission id -> last outcome for that mission (MissionRun.SUCCESS / RETURNED / FAILED).
static var results := {}
## Mission ids completed at least once; completed missions are no longer offered.
static var completed := {}
## The scene to return to after planning or an outing; empty when nothing was opened from camp.
static var camp_scene := ""

static func deploy(tree: SceneTree, region: Resource, chosen: Array) -> void:
	pending = region.compose(chosen)
	tree.change_scene_to_file(region.scene_path)

## Leaves the camp for another scene (the mission map, the combat arena), remembering the way back.
static func leave_camp(tree: SceneTree, path: String) -> void:
	camp_scene = tree.current_scene.scene_file_path
	tree.change_scene_to_file(path)

## Back to the camp the player left from. Through startup, the camp is its "training" route.
## The camp scene reloads: camp work is session-only and does not survive the trip yet.
static func return_to_camp(tree: SceneTree) -> void:
	if camp_scene == STARTUP_SCENE:
		OS.set_environment("FOREST_BROTHERS_START", "training")
	tree.change_scene_to_file(camp_scene)

## After an outing's summary: back to camp when the outing started there, else the mission map.
static func after_outing(tree: SceneTree) -> void:
	if camp_scene != "":
		return_to_camp(tree)
	else:
		return_to_board(tree)

## Records each mission of a finished outing: completed if its objectives were carried out,
## otherwise returned early (someone got out) or failed. Returns the missions completed for the
## first time, whose rewards the camp receives.
static func record_run(run) -> Array:
	var first_time: Array = []
	var definition: Resource = run.definition
	var missions: Array = definition.missions if not definition.missions.is_empty() else ([definition] if not definition.objectives.is_empty() else [])
	var outcome: StringName = run.outcome()
	for mission in missions:
		var done: bool = definition.mission_done(run, mission) if mission != definition else outcome == MissionRun.SUCCESS
		results[mission.id] = MissionRun.SUCCESS if done else (MissionRun.FAILED if outcome == MissionRun.FAILED else MissionRun.RETURNED)
		if done and not completed.has(mission.id):
			first_time.append(mission)
		if done: completed[mission.id] = true
	return first_time

static func return_to_board(tree: SceneTree) -> void:
	tree.change_scene_to_file(BOARD_SCENE)
