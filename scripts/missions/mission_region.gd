extends Resource
## A region of the mission map as content: a world scene with its own time limit, exits and
## standing enemy population, and the missions that take place there. Players pick a region and
## any of its open missions; compose() turns that choice into the one MissionDefinition the
## world scene plays, so the run, HUD and summary stay the same for any combination. Numbers are
## placeholders; names are fictional unless researched.
const MissionDefinition = preload("res://scripts/missions/mission_definition.gd")
@export var id: StringName
@export var title: String
@export_multiline var description: String
## The world scene for this region; it reads the composed definition through MissionLaunch.
@export_file("*.tscn") var scene_path: String
## Participants still in the region when time runs out die (mission death). 0 means no limit.
@export var time_limit_seconds: float = 3600.0
## Seconds a participant stands in an exit to leave the region.
@export var exit_seconds: float = 5.0
## Enemies present on every outing, by EnemySpawn tag: tag -> how many. Missions add their own.
@export var enemy_groups: Dictionary = {}
## Exit names for the briefing (the world scene places the actual MissionExit markers).
@export var exit_names: PackedStringArray = []
## Where the region sits on the mission map, as fractions of the map's width and height.
@export var board_position: Vector2 = Vector2(0.5, 0.5)
## MissionDefinition resources that take place in this region.
@export var missions: Array[Resource] = []

func find(mission_id: StringName) -> Resource:
	for mission in missions:
		if mission.id == mission_id: return mission
	return null

## One deployment: the region's rules with the chosen missions' objectives and extra enemies.
## No missions chosen is a scavenging outing: no objectives, leave by any exit.
func compose(chosen: Array) -> Resource:
	var outing := MissionDefinition.new()
	outing.id = id
	outing.title = title
	outing.area_name = title
	outing.region = self
	outing.missions.assign(chosen)
	outing.scene_path = scene_path
	outing.time_limit_seconds = time_limit_seconds
	outing.exit_seconds = exit_seconds
	outing.board_position = board_position
	outing.enemy_groups = enemy_groups.duplicate()
	var briefings: Array[String] = []
	for mission in chosen:
		outing.objectives.append_array(mission.objectives)
		briefings.append(mission.briefing)
		for tag in mission.enemy_groups:
			outing.enemy_groups[tag] = int(outing.enemy_groups.get(tag, 0)) + int(mission.enemy_groups[tag])
	outing.briefing = "\n\n".join(briefings) if not briefings.is_empty() else "Scavenging: no mission. Take what you can find and leave by any exit."
	return outing

## How many enemies an outing with these missions posts in total.
func enemy_count(chosen: Array) -> int:
	var total := 0
	for groups in [enemy_groups] + chosen.map(func(mission): return mission.enemy_groups):
		for tag in groups:
			total += int(groups[tag])
	return total
