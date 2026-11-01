extends StaticBody3D

var hit_count: int = 0
var _reset_time: float = 0.0


func take_hit() -> void:
	hit_count += 1
	_reset_time = 0.3
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.5, 0.12)
	$Mesh.material_override = material


func _process(delta: float) -> void:
	if _reset_time <= 0.0:
		return
	_reset_time -= delta
	if _reset_time <= 0.0:
		$Mesh.material_override = null
