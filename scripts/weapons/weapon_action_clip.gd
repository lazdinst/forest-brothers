extends Resource
## Shared action timeline; gameplay reads timing, presentation samples poses.
@export var action: StringName = &"reload"
@export_range(0.01, 30.0) var duration: float = 1.4
@export_range(0.0, 1.0) var commit_at: float = 1.0
@export var animate_magazine: bool = false
@export var poses: Array[Resource] = []

func sample(progress: float) -> Dictionary:
	if poses.is_empty():
		return {"offset": Vector2.ZERO, "roll": 0.0, "magazine_offset": Vector2.ZERO, "magazine_alpha": 1.0, "phase": String(action), "texture": null}
	var left = poses[0]
	var right = left
	for pose in poses:
		if pose.time <= progress:
			left = pose
		else:
			right = pose
			break
		right = left
	var weight: float = clampf((progress - left.time) / maxf(right.time - left.time, 0.00001), 0.0, 1.0)
	weight = smoothstep(0.0, 1.0, weight)
	return {"offset": left.offset.lerp(right.offset, weight), "roll": lerpf(left.roll_degrees, right.roll_degrees, weight), "magazine_offset": left.magazine_offset.lerp(right.magazine_offset, weight), "magazine_alpha": lerpf(left.magazine_alpha, right.magazine_alpha, weight), "phase": String(left.phase), "texture": left.texture}

func validation_error() -> String:
	if action == &"" or duration <= 0.0 or commit_at < 0.0 or commit_at > 1.0:
		return "Invalid action or timing"
	var previous := -1.0
	for pose in poses:
		if pose == null or pose.time < 0.0 or pose.time > 1.0 or pose.time <= previous:
			return "Pose times must increase within 0..1"
		previous = pose.time
	return ""
