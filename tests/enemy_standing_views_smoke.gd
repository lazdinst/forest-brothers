extends SceneTree
const Enemy = preload("res://scripts/combat/enemy_actor.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var enemy = Enemy.new()
	world.add_child(enemy)
	enemy.set_physics_process(false)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.make_current()
	var image: Image = enemy.standing_views.ATLAS.get_image()
	check(image.get_pixel(80, 100).a == 0.0, "Atlas background has genuine transparent alpha")
	var textures: Array = []
	for sector in range(8):
		var angle := -sector * TAU / 8.0
		camera.position = Vector3(sin(angle) * 5.0, 1.6, cos(angle) * 5.0)
		enemy._physics_process(0.0)
		check(enemy.standing_views.sector == sector, "Correct camera-relative standing sector %d" % sector)
		check(not enemy.sprite.flip_h, "Directions use their own artwork rather than mirrored cells")
		textures.append(enemy.sprite.texture)
		var region: Rect2 = enemy.sprite.texture.region
		check(region.position.x >= 0 and region.end.x <= image.get_width() and region.end.y <= image.get_height(), "Atlas region lies within source")
		check(is_equal_approx((region.size.y - 8.0) * enemy.sprite.pixel_size, enemy.FIGURE_HEIGHT), "Consistent painted height")
		var sole: float = enemy.visual.position.y + enemy.sprite.position.y - (region.size.y / 2.0 - 4.0) * enemy.sprite.pixel_size
		check(absf(sole) < 0.0001, "Feet remain at ground level")
	check(textures.size() == 8 and textures[2] != textures[6], "Eight distinct textures, independent side views")
	# Rotating the actor changes art even with a stationary viewer.
	camera.position = Vector3(0, 1.6, 5)
	enemy.rotation.y = PI
	enemy._physics_process(0.0)
	check(enemy.standing_views.sector == 4, "Actor turning away shows the back")
	enemy.rotation.y = 0.0
	enemy._physics_process(0.0)
	for degrees in [22.0, 24.0, 22.0]:
		var angle := deg_to_rad(-degrees)
		camera.position = Vector3(sin(angle) * 5, 1.6, cos(angle) * 5)
		enemy._physics_process(0.0)
		check(enemy.standing_views.sector == 0, "Hysteresis prevents boundary flicker")
	camera.position = Vector3(sin(deg_to_rad(-27.0)) * 5, 1.6, cos(deg_to_rad(-27.0)) * 5)
	enemy._physics_process(0.0)
	check(enemy.standing_views.sector == 1, "Crossing the margin changes the view")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: eight standing views, actual actor facing, real alpha, independent profiles, normalized height/feet, boundary hysteresis")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
