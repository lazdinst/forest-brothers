extends StaticBody3D
## Presentation-only selection relative to this viewport's active camera.
## The character faces local +Z. A foot-anchored visual faces the camera plane; the body stays upright.

@export var front_texture: Texture2D
@export var side_texture: Texture2D
@export var back_texture: Texture2D
@export_range(0.0, 15.0, 0.5) var direction_hysteresis_degrees: float = 5.0

@onready var visual_pivot: Node3D = $FacingVisual
@onready var sprite: Sprite3D = $FacingVisual/IdleSprite
var _sector: int = -1


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	# Align the entire visual around its feet, not the centered sprite. Keeping
	# all pixels in the camera plane prevents head/feet perspective taper when
	# looking down at close range. This runs even when the view sector is stable.
	visual_pivot.global_basis = camera.global_basis.orthonormalized().scaled(global_basis.get_scale())
	var local_viewer := global_basis.inverse() * (camera.global_position - global_position)
	if Vector2(local_viewer.x, local_viewer.z).length_squared() < 0.0001:
		return
	var angle := atan2(local_viewer.x, local_viewer.z)
	if _sector >= 0:
		var center := float(_sector) * PI / 2.0
		var distance := absf(wrapf(angle - center, -PI, PI))
		if distance <= PI / 4.0 + deg_to_rad(direction_hysteresis_degrees):
			return
	var next_sector := posmod(roundi(angle / (PI / 2.0)), 4)
	_sector = next_sector
	sprite.flip_h = next_sector == 3
	match next_sector:
		0:
			sprite.texture = front_texture
		1, 3:
			sprite.texture = side_texture
		2:
			sprite.texture = back_texture
