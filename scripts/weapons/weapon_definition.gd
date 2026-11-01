extends Resource
## Immutable content for one weapon. Runtime ammunition never lives here.
@export var weapon_id: StringName = &"svt_inspired_training"
@export var display_name: String = "SVT-INSPIRED TEST RIFLE"
@export var loading_rule: StringName = &"detachable_magazine"
@export_range(1, 100) var capacity: int = 10
@export var initial_loaded: int = 10
@export var initial_spare: int = 0
@export var initial_loose: int = 30
@export var fire_interval: float = 0.22
@export var hip_texture: Texture2D
@export var ads_texture: Texture2D
@export var flash_texture: Texture2D
@export var hip_offset := Vector2(-230.0, -480.0)
@export var hip_size: float = 570.0
@export var ads_size: float = 700.0
@export var hip_muzzle := Vector2(0.42, 0.24)
@export var ads_muzzle := Vector2(0.5, 0.43)
@export var sight_anchor := Vector2(0.5, 0.418)
@export var muzzle_depth: float = 0.85
# Convex UV polygon isolating this artwork's detachable magazine at runtime.
@export var magazine_uv := PackedVector2Array([Vector2(0.568, 0.552), Vector2(0.606, 0.602), Vector2(0.651, 0.696), Vector2(0.638, 0.718), Vector2(0.590, 0.718), Vector2(0.556, 0.653)])
@export var action_clips: Array[Resource] = []

func get_clip(action: StringName) -> Resource:
	for clip in action_clips:
		if clip.action == action:
			return clip
	return null

func validation_error() -> String:
	if weapon_id == &"" or loading_rule != &"detachable_magazine":
		return "This prototype supports detachable magazines only"
	if capacity < 1 or initial_loaded < 0 or initial_loaded > capacity or initial_spare < 0 or initial_spare > capacity or initial_loose < 0 or fire_interval <= 0.0:
		return "Invalid ammunition configuration"
	if hip_texture == null or ads_texture == null or flash_texture == null or magazine_uv.size() < 3 or magazine_uv.size() > 8:
		return "Missing visual assets or magazine mask"
	var actions: Array[StringName] = []
	for clip in action_clips:
		if clip == null or clip.validation_error() != "" or clip.action in actions:
			return "Invalid or duplicate action clip"
		actions.append(clip.action)
	for required in [&"reload", &"pack", &"clear", &"clean", &"inspect"]:
		if required not in actions:
			return "Missing required action: %s" % required
	return ""
