extends RefCounted
## Hands the chosen mission from the mission map to its world scene and the result back,
## across scene changes, without an autoload. Results last for this run of the game only;
## campaign persistence is not built.
const BOARD_SCENE := "res://scenes/missions/mission_board.tscn"
## The definition a world scene should play next; null when launched directly.
static var pending: Resource
## Mission id -> last whole-mission outcome (MissionRun.SUCCESS / RETURNED / FAILED).
static var results := {}

static func deploy(tree: SceneTree, definition: Resource) -> void:
	pending = definition
	tree.change_scene_to_file(definition.scene_path)

static func record(definition: Resource, outcome: StringName) -> void:
	results[definition.id] = outcome

static func return_to_board(tree: SceneTree) -> void:
	tree.change_scene_to_file(BOARD_SCENE)
