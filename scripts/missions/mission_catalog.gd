extends Resource
## The missions offered on the mission map (content). Order is display order.
@export var missions: Array[Resource] = []

func find(id: StringName) -> Resource:
	for mission in missions:
		if mission.id == id: return mission
	return null
