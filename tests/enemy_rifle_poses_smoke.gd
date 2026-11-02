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
	var initial_rounds: int = enemy.total_rounds()
	check(not enemy.rifle.get_node("ProxyMesh").visible, "Sprite gun replaces the box proxy")
	for aiming in [false, true]:
		enemy.state = &"engage" if aiming else &"idle"
		for sector in range(8):
			var angle := -sector * TAU / 8.0
			camera.position = Vector3(sin(angle) * 5, 1.6, cos(angle) * 5)
			enemy._physics_process(0.0)
			var views = enemy.standing_views
			check(views.sector == sector, "Correct rifle view at sector %d" % sector)
			check(views.pose == (&"aiming" if aiming else &"holding"), "Pose follows combat state")
			var image: Image = enemy.sprite.texture.atlas.get_image()
			check(image.get_pixel(20, 20).a == 0, "Rifle atlas has real transparency")
			var region: Rect2 = enemy.sprite.texture.region
			check(region.end.x <= image.get_width() and region.end.y <= image.get_height(), "Rifle, feet and head regions fit source")
			check(is_equal_approx((region.size.y - 8.0) * enemy.sprite.pixel_size, enemy.FIGURE_HEIGHT), "Pose keeps physical height")
			var sole: float = enemy.visual.position.y + enemy.sprite.position.y - (region.size.y / 2.0 - 4) * enemy.sprite.pixel_size
			check(absf(sole) < 0.0001, "Pose keeps feet on ground")
			var center: float = views.RifleArt.AIM_CENTERS[sector] if aiming else views.RifleArt.HOLD_CENTERS[sector]
			var foot_x: float = enemy.sprite.position.x + (center - region.get_center().x) * enemy.sprite.pixel_size
			check(absf(foot_x) < 0.0001, "Rifle overhang does not push body off its origin")
			if aiming:
				var muzzle: Vector2 = views.RifleArt.AIM_MUZZLES[sector]
				check(region.has_point(muzzle), "Painted muzzle marker is inside the selected frame")
				check(enemy.muzzle_world_position().is_equal_approx(views.muzzle_position(enemy.sprite)), "Flash uses the painted muzzle")
			check(not enemy.sprite.flip_h, "Neither shoulder nor rifle is mirrored")
	# The engaged pose lowers while reloading or running for cover.
	enemy.reload_left = 2.0
	enemy._physics_process(0.0)
	check(enemy.standing_views.pose == &"holding", "Reload uses lowered holding placeholder")
	enemy.reload_left = 0.0
	enemy.cover_phase = &"move"
	enemy._physics_process(0.0)
	check(enemy.standing_views.pose == &"holding", "Running for cover lowers weapon")
	enemy.cover_phase = &""
	enemy._physics_process(0.0)
	check(enemy.standing_views.pose == &"aiming", "Aim resumes when rifle is ready")
	check(enemy.total_rounds() == initial_rounds, "Cosmetic pose changes cannot create or consume ammunition")
	var frame_before: Texture2D = enemy.sprite.texture
	enemy.state = &"dead"
	enemy._physics_process(0.0)
	check(enemy.sprite.texture == frame_before, "Standing updates stop after death")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: 16 rifle views, hold/aim/reload/cover poses, alpha, height/feet/body anchor, painted muzzle, no duplicate proxy or ammo changes")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
