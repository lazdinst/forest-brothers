extends Resource
## The regions offered on the mission map (content), each with its own missions. Order is
## display order.
@export var regions: Array[Resource] = []

func find_region(id: StringName) -> Resource:
	for region in regions:
		if region.id == id: return region
	return null

## The region a mission belongs to, or null.
func region_of(mission_id: StringName) -> Resource:
	for region in regions:
		if region.find(mission_id) != null: return region
	return null
