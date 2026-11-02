extends Marker3D
## A place on a map where a mission may post an enemy, facing the marker's forward (-Z turned
## by its rotation). Missions ask for a number of enemies per tag; spots are drawn at random.
const GROUP := &"enemy_spawns"
@export var tag: StringName

func _ready() -> void:
	add_to_group(GROUP)
