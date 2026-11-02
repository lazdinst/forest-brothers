extends Resource
## A mission as content: title, briefing, objectives, exit and time rules. Maps provide the
## places (MissionExit and ObjectiveSpot markers); MissionController plays any definition the
## same way, with the same HUD and summary screen. Numbers are placeholders.
@export var id: StringName
@export var title: String
@export_multiline var briefing: String
## MissionObjective resources.
@export var objectives: Array[Resource] = []
## Seconds a participant stands in an exit to leave the area.
@export var exit_seconds: float = 5.0
## Participants still in the area when time runs out die (mission death). 0 means no limit.
@export var time_limit_seconds: float = 3600.0
## The world scene that hosts this mission; it reads the definition through MissionLaunch.
@export_file("*.tscn") var scene_path: String
## Enemies to place, by EnemySpawn tag on the map: tag -> how many.
@export var enemy_groups: Dictionary = {}
## Where the mission sits on the mission map, as fractions of the map's width and height.
@export var board_position: Vector2 = Vector2(0.5, 0.5)
## Place name shown on the mission map (fictional unless researched).
@export var area_name: String
