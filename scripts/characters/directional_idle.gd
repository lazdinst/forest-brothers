extends CharacterBody3D
## Local presentation/animation test. Only the marked demo actor patrols.
# TODO(sprite-closeup): replace the temporary yaw-only sprite + 1.2 m player
# clearance compromise with a reviewed near-field solution. Validate up/down
# looking, aiming/hitboxes, animation and elevated views; never reintroduce
# camera-pitch-driven sprite scaling/rotation. Owner deferred this issue.

@export var front_texture: Texture2D
@export var side_texture: Texture2D
@export var back_texture: Texture2D
@export var walk_front: Texture2D
@export var walk_side: Texture2D
@export var walk_back: Texture2D
@export_range(0.0, 15.0, 0.5) var direction_hysteresis_degrees: float = 5.0
@export var patrol_enabled: bool = false

@onready var visual_pivot: Node3D = $FacingVisual
@onready var sprite: Sprite3D = $FacingVisual/IdleSprite
var _sector: int = -1
var _origin: Vector3
var _travel_direction: float = 1.0
var _pause: float = 0.0
var _animation_time: float = 0.0
var _moving: bool = false
var _walk_frames: Array = []


func _ready() -> void:
	_origin = global_position
	for atlas in [walk_front, walk_side, walk_back]:
		var frames: Array[AtlasTexture] = []
		if atlas != null:
			var cell := Vector2(atlas.get_width() / 2.0, atlas.get_height() / 2.0)
			for frame in range(4):
				var texture := AtlasTexture.new()
				texture.atlas = atlas
				texture.region = Rect2(Vector2(frame % 2, frame / 2) * cell, cell)
				frames.append(texture)
		_walk_frames.append(frames)


func _physics_process(delta: float) -> void:
	if not patrol_enabled:
		return
	if _pause > 0.0:
		_pause -= delta
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var target := _origin + Vector3(0, 0, _travel_direction * 2.0)
		var to_target := target - global_position
		to_target.y = 0.0
		if to_target.length() < 0.12:
			_travel_direction *= -1.0
			_pause = 1.0
		else:
			var direction := to_target.normalized()
			rotation.y = atan2(direction.x, direction.z)
			velocity.x = direction.x * 0.8
			velocity.z = direction.z * 0.8
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	move_and_slide()
	_moving = Vector2(get_real_velocity().x, get_real_velocity().z).length() > 0.05


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var to_viewer := camera.global_position - global_position
	to_viewer.y = 0.0
	if to_viewer.length_squared() < 0.0001:
		return
	visual_pivot.global_basis = Basis.looking_at(-to_viewer, Vector3.UP).scaled(global_basis.get_scale())
	var local_viewer := global_basis.inverse() * to_viewer
	var angle := atan2(local_viewer.x, local_viewer.z)
	var keep_sector := false
	if _sector >= 0:
		var distance := absf(wrapf(angle - float(_sector) * PI / 2.0, -PI, PI))
		keep_sector = distance <= PI / 4.0 + deg_to_rad(direction_hysteresis_degrees)
	if not keep_sector:
		_sector = posmod(roundi(angle / (PI / 2.0)), 4)
	sprite.flip_h = _sector == 3
	var view_index := 0 if _sector == 0 else (2 if _sector == 2 else 1)
	if _moving and _walk_frames[view_index].size() == 4:
		_animation_time += delta * 6.0
		sprite.texture = _walk_frames[view_index][int(_animation_time) % 4]
		sprite.pixel_size = 0.0024
	else:
		_animation_time = 0.0
		sprite.texture = [front_texture, side_texture, back_texture][view_index]
		sprite.pixel_size = 0.0012
