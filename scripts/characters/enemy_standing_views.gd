extends RefCounted
## Presentation only. Atlas order is the character turning right on screen.
const ATLAS = preload("res://assets/characters/training_guard/standing_v1/standing_8way_v1.png")
const RifleArt = preload("res://scripts/characters/enemy_rifle_pose_art.gd")
const WalkArt = preload("res://scripts/characters/enemy_walk_art.gd")
# Measured opaque silhouettes, with four pixels of alpha padding for edge coverage.
const REGIONS = [
	Rect2(148, 5, 189, 495), Rect2(499, 4, 182, 496),
	Rect2(877, 5, 131, 495), Rect2(1212, 5, 165, 495),
	Rect2(141, 512, 194, 493), Rect2(494, 512, 179, 494),
	Rect2(870, 512, 130, 497), Rect2(1208, 512, 185, 498),
]
const STEP := TAU / 8.0
const HYSTERESIS := deg_to_rad(3.0)
# Cosmetic exposure time only, not weapon cadence/balance.
const SHOT_SECONDS := 0.075
var shot_left: float = 0.0
var sector: int = -1
var frames: Array[AtlasTexture] = []
var pose: StringName = &"unarmed"
var pose_frames: Dictionary = {}
var walk_frames: Array = []
var walking: bool = false
var walk_distance: float = 0.0
var walk_frame: int = 0
# Cosmetic distance per complete two-step loop, provisional presentation tuning.
const WALK_CYCLE_METERS := 1.4

func advance_walk(displacement: Vector3) -> void:
	var distance := Vector2(displacement.x, displacement.z).length()
	walking = distance > 0.0001
	if walking:
		walk_distance = fposmod(walk_distance + distance, WALK_CYCLE_METERS)
		walk_frame = mini(3, int(walk_distance / WALK_CYCLE_METERS * 4.0))
	else:
		walk_distance = 0.0
		walk_frame = 0

func stop_walk(sprite: Sprite3D, height: float) -> void:
	advance_walk(Vector3.ZERO)
	if pose == &"walking":
		_apply_pose(sprite, height, &"holding")

func _init() -> void:
	frames = _frames(ATLAS, REGIONS)
	pose_frames[&"unarmed"] = frames
	pose_frames[&"holding"] = _frames(RifleArt.HOLD_ATLAS, RifleArt.HOLD_REGIONS)
	pose_frames[&"aiming"] = _frames(RifleArt.AIM_ATLAS, RifleArt.AIM_REGIONS)
	pose_frames[&"firing"] = _frames(RifleArt.FIRE_ATLAS, RifleArt.FIRE_REGIONS)
	for direction in range(8):
		walk_frames.append(_frames(WalkArt.ATLASES[direction], WalkArt.REGIONS[direction]))

func trigger_shot() -> void:
	shot_left = SHOT_SECONDS

func tick(delta: float) -> void:
	shot_left = maxf(0.0, shot_left - delta)

func stop_shot(sprite: Sprite3D, height: float) -> void:
	shot_left = 0.0
	if pose == &"firing":
		_apply_pose(sprite, height, &"aiming")

func _frames(atlas: Texture2D, regions: Array) -> Array[AtlasTexture]:
	var result: Array[AtlasTexture] = []
	for region in regions:
		var frame := AtlasTexture.new()
		frame.atlas = atlas
		frame.region = region
		frame.filter_clip = true
		result.append(frame)
	return result

func update(actor: Node3D, camera: Camera3D, sprite: Sprite3D, height: float, requested_pose: StringName = &"unarmed") -> void:
	var toward := camera.global_position - actor.global_position
	toward.y = 0.0
	if toward.length_squared() < 0.0001:
		return
	var local := actor.global_basis.inverse() * toward
	# Seen from the actor's +X side, its +Z nose points screen-left (atlas cell 6).
	var angle := atan2(-local.x, local.z)
	if sector < 0 or absf(wrapf(angle - sector * STEP, -PI, PI)) > STEP / 2.0 + HYSTERESIS:
		sector = posmod(roundi(angle / STEP), 8)
	var display_pose := requested_pose
	if requested_pose == &"aiming" and shot_left > 0.0:
		display_pose = &"firing"
	_apply_pose(sprite, height, display_pose)

func _apply_pose(sprite: Sprite3D, height: float, requested_pose: StringName) -> void:
	pose = requested_pose
	sprite.texture = walk_frames[sector][walk_frame] if pose == &"walking" else pose_frames[pose][sector]
	sprite.flip_h = false
	var region: Rect2 = sprite.texture.region
	# Normalize the painted cap-to-sole height, not the unequal source-cell margins.
	sprite.pixel_size = height / (region.size.y - 8.0)
	sprite.position.y = height / 2.0 - sprite.get_parent().position.y
	var center := region.get_center().x
	if pose == &"holding":
		center = RifleArt.HOLD_CENTERS[sector]
	elif pose == &"aiming" or pose == &"firing":
		center = RifleArt.AIM_CENTERS[sector]
	elif pose == &"walking":
		center = WalkArt.CENTERS[sector][walk_frame]
	sprite.position.x = (region.get_center().x - center) * sprite.pixel_size

func muzzle_position(sprite: Sprite3D) -> Vector3:
	var region: Rect2 = sprite.texture.region
	var pixel: Vector2 = RifleArt.AIM_MUZZLES[sector] - region.get_center()
	return sprite.global_transform * Vector3(pixel.x * sprite.pixel_size, -pixel.y * sprite.pixel_size, 0.01)
