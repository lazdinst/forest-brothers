extends SceneTree
## Regression: a pitched close camera must not taper the sprite toward its feet.

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var civilian = load("res://scenes/characters/starting_civilian.tscn").instantiate()
	root.add_child(civilian)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.make_current()
	camera.fov = 60.0
	for distance in [0.65, 1.0, 3.0]:
		for offset in [Vector3(0, 1.6, distance), Vector3(distance, 1.6, 0), Vector3(0, 1.6, -distance)]:
			camera.position = offset
			camera.look_at(civilian.position + Vector3(0, 0.9, 0))
			await process_frame
			await process_frame
			var sprite: Sprite3D = civilian.get_node("FacingVisual/IdleSprite")
			var upper_width := camera.unproject_position(sprite.to_global(Vector3(0.2, 0.7, 0))).distance_to(camera.unproject_position(sprite.to_global(Vector3(-0.2, 0.7, 0))))
			var lower_width := camera.unproject_position(sprite.to_global(Vector3(0.2, -0.7, 0))).distance_to(camera.unproject_position(sprite.to_global(Vector3(-0.2, -0.7, 0))))
			_check(upper_width > 0.0 and absf(upper_width / lower_width - 1.0) < 0.01, "Sprite projection must preserve width between head and feet at distance %.2f" % distance)
			_check(civilian.get_node("FacingVisual").global_position.distance_to(civilian.global_position) < 0.001, "Visual foot anchor must stay at the body origin")
			_check(civilian.global_basis.is_equal_approx(Basis.IDENTITY), "Camera pitch must not rotate the physical body")
	if failures.is_empty():
		print("PASS: close/medium/far tilted views preserve sprite proportions and foot anchor; collider stays upright")
	else:
		for failure in failures:
			push_error(failure)
	civilian.queue_free()
	camera.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
