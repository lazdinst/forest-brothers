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
