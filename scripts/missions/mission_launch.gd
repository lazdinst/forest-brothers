extends RefCounted
## Hands the chosen region and missions from the mission map to the region's world scene and
## the results back, across scene changes, without an autoload. Results last for this run of
## the game only; campaign persistence is not built.
const MissionRun = preload("res://scripts/missions/mission_run.gd")
const BOARD_SCENE := "res://scenes/missions/mission_board.tscn"
## The composed definition a world scene should play next; null when launched directly.
static var pending: Resource
## Mission id -> last outcome for that mission (MissionRun.SUCCESS / RETURNED / FAILED).
static var results := {}
## Mission ids completed at least once; completed missions are no longer offered.
static var completed := {}

static func deploy(tree: SceneTree, region: Resource, chosen: Array) -> void:
	pending = region.compose(chosen)
	tree.change_scene_to_file(region.scene_path)

## Records each mission of a finished outing: completed if its objectives were carried out,
## otherwise returned early (someone got out) or failed.
static func record_run(run) -> void:
	var definition: Resource = run.definition
	var missions: Array = definition.missions if not definition.missions.is_empty() else ([definition] if not definition.objectives.is_empty() else [])
	var outcome: StringName = run.outcome()
	for mission in missions:
		var done: bool = definition.mission_done(run, mission) if mission != definition else outcome == MissionRun.SUCCESS
		results[mission.id] = MissionRun.SUCCESS if done else (MissionRun.FAILED if outcome == MissionRun.FAILED else MissionRun.RETURNED)
		if done: completed[mission.id] = true

static func return_to_board(tree: SceneTree) -> void:
	tree.change_scene_to_file(BOARD_SCENE)
