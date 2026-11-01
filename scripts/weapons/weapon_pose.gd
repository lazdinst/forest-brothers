extends Resource
## One authored presentation keyframe. Positions are pixels at a 720px viewport.
@export_range(0.0, 1.0) var time: float = 0.0
@export var phase: StringName = &""
@export var offset := Vector2.ZERO
@export var roll_degrees: float = 0.0
@export var magazine_offset := Vector2.ZERO
@export_range(0.0, 1.0) var magazine_alpha: float = 1.0
# Future drawn hand poses can replace the procedural pose without changing rules.
@export var texture: Texture2D
