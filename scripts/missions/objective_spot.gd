extends Marker3D
## A place on a map where a mission may put an objective item. Missions pick among the spots
## whose tag matches their objective, so one map can host many missions.
const GROUP := &"objective_spots"
@export var tag: StringName

func _ready() -> void:
	add_to_group(GROUP)
