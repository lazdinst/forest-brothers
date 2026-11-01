extends AnimatableBody3D

@export var open_angle_degrees: float = -95.0
var is_open: bool = false
var moving: bool = false


func get_prompt() -> String:
	if moving:
		return ""
	return "F  Close door" if is_open else "F  Open door"


func interact(_actor: Node) -> void:
	if moving:
		return
	moving = true
	is_open = not is_open
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "rotation:y", deg_to_rad(open_angle_degrees) if is_open else 0.0, 0.35)
	tween.finished.connect(func() -> void: moving = false)
