extends Resource
## A mission as content: title, briefing, objectives, and the extra enemies it brings to its
## region (MissionRegion). A region composes the missions chosen for one outing into a single
## definition with the region's time limit, exits and scene; MissionController plays any
## definition the same way, with the same HUD and summary screen. A map can also play a
## standalone definition directly (the combat arena). Numbers are placeholders.
@export var id: StringName
@export var title: String
@export_multiline var briefing: String
## MissionObjective resources.
@export var objectives: Array[Resource] = []
## Seconds a participant stands in an exit to leave the area.
@export var exit_seconds: float = 5.0
## Participants still in the area when time runs out die (mission death). 0 means no limit.
## A composed outing takes the region's limit.
@export var time_limit_seconds: float = 3600.0
## The world scene that hosts this mission; it reads the definition through MissionLaunch.
## A composed outing takes the region's scene.
@export_file("*.tscn") var scene_path: String
## Enemies this mission adds, by EnemySpawn tag on the map: tag -> how many.
@export var enemy_groups: Dictionary = {}
## Where the mission sits on a map, as fractions of the map's width and height.
@export var board_position: Vector2 = Vector2(0.5, 0.5)
## Place within the region shown in the briefing (fictional unless researched).
@export var area_name: String
## Paid into the camp stores the first time the mission is completed: stock id -> amount
## (food, water, medicine, meals, timber, parts, cloth, rounds). Placeholder amounts.
@export var rewards: Dictionary = {}

## The rewards as text, e.g. "4 timber, 2 parts"; empty when there are none.
func reward_text() -> String:
	var parts: Array[String] = []
	for id in rewards:
		parts.append("%d %s" % [int(rewards[id]), str(id)])
	return ", ".join(parts)
## Set on a composed outing: the region it plays in and the missions it combines.
var region: Resource
var missions: Array[Resource] = []

## Whether a mission's required objectives were all carried out in this run (composed outings).
func mission_done(run, mission: Resource) -> bool:
	var any := false
	for index in range(objectives.size()):
		if not mission.objectives.has(objectives[index]): continue
		any = true
		if objectives[index].required and not run.objective_done.get(index, false): return false
	return any
