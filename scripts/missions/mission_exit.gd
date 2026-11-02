extends Node3D
## A way out of a mission area, placed on a map. Standing inside it for the mission's exit time
## leaves the area. Draws four posts and a sign; no collision, so it never blocks the way out.
const GROUP := &"mission_exits"
@export var id: StringName = &"exit"
@export var label: String = "Exit"
## Half-extents of the exit area on x and z, in the marker's own frame (not rotated).
@export var half_size: Vector2 = Vector2(2.0, 3.0)

func _ready() -> void:
	add_to_group(GROUP)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.32, 0.27, 0.18)
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var post := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.12, 1.4, 0.12)
		box.material = material
		post.mesh = box
		post.position = Vector3(corner.x * half_size.x, 0.7, corner.y * half_size.y)
		add_child(post)
	var sign := Label3D.new()
	sign.text = "EXIT · %s\nstand here to leave" % label
	sign.font_size = 48
	sign.pixel_size = 0.006
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.position.y = 2.0
	add_child(sign)

## The exit as rules data.
func area() -> Dictionary:
	return {"id":id,"label":label,"center":global_position,"half_size":half_size}
