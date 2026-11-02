extends SceneTree
const Enemy = preload("res://scripts/combat/enemy_actor.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.make_current()
	var enemy = Enemy.new()
	world.add_child(enemy)
	enemy.set_physics_process(false)
	var rounds: int = enemy.total_rounds()
	for sector in range(8):
		var angle := -sector * TAU / 8.0
		camera.position = Vector3(sin(angle) * 5, 1.6, cos(angle) * 5)
		for frame in range(4):
			enemy.standing_views.advance_walk(Vector3.ZERO)
			enemy.standing_views.advance_walk(Vector3(frame * 0.35 + 0.01, 0, 0))
			enemy._update_sprite_views()
			var views = enemy.standing_views
			check(views.pose == &"walking" and views.sector == sector and views.walk_frame == frame, "Walk view %d frame %d selected" % [sector, frame])
			check(enemy.sprite.texture == views.walk_frames[sector][frame], "Correct independently painted frame")
			check(not enemy.sprite.flip_h, "Walking art never mirrors the rifle")
			var region: Rect2 = enemy.sprite.texture.region
			var image: Image = enemy.sprite.texture.atlas.get_image()
			check(image.get_pixel(0, 0).a < 0.01 and image.get_pixel(20, 20).a == 0, "Walking atlas has transparent background at sector %d" % sector)
			check(region.position.x >= 0 and region.position.y >= 0 and region.end.x <= image.get_width() and region.end.y <= image.get_height(), "Full walking frame fits atlas")
			var sole: float = enemy.visual.position.y + enemy.sprite.position.y - (region.size.y / 2.0 - 4) * enemy.sprite.pixel_size
			check(absf(sole) < 0.0001, "Supporting sole anchored on ground")
			check(is_equal_approx((region.size.y - 8) * enemy.sprite.pixel_size, enemy.FIGURE_HEIGHT), "Walk height matches standing")
	# Phase depends on distance, including tiny steps and loop wrap, not frame rate.
	enemy.standing_views.advance_walk(Vector3.ZERO)
	for i in range(4):
		enemy.standing_views.advance_walk(Vector3(0.1, 0, 0))
	var phase: int = enemy.standing_views.walk_frame
	enemy.standing_views.advance_walk(Vector3.ZERO)
	enemy.standing_views.advance_walk(Vector3(0.4, 0, 0))
	check(enemy.standing_views.walk_frame == phase, "Equal distance gives equal phase across timestep sizes")
	enemy.standing_views.advance_walk(Vector3(2.8, 0, 0))
	check(enemy.standing_views.walk_frame == phase, "Whole cycles wrap without drift")
	enemy.state = &"engage"
	enemy._update_sprite_views()
	check(enemy.standing_views.pose == &"aiming", "Aiming takes priority over walking")
	enemy.reload_left = 2
	enemy._update_sprite_views()
	check(enemy.standing_views.pose == &"holding", "Reload keeps its lowered placeholder")
	enemy.reload_left = 0
	enemy.state = &"cover"
	enemy.cover_phase = &"move"
	enemy._update_sprite_views()
	check(enemy.standing_views.pose == &"walking", "Cover movement uses distance-driven walk")
	enemy.standing_views.advance_walk(Vector3(0, 0.5, 0))
	enemy._update_sprite_views()
	check(not enemy.standing_views.walking and enemy.standing_views.pose == &"holding", "Vertical motion alone never walks")
	check(enemy.total_rounds() == rounds, "Locomotion presentation cannot affect ammunition")
	# Real collision integration: a walking patrol stops animating against a wall.
	var ground := StaticBody3D.new()
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(20, 1, 20)
	ground_shape.shape = ground_box
	ground_shape.position.y = -0.5
	ground.add_child(ground_shape)
	world.add_child(ground)
	var patrol = Enemy.new()
	patrol.position = Vector3(0, 0.02, -3)
	world.add_child(patrol)
	patrol.active = true
	await frames(50)
	check(patrol.position.x > 0.35 and patrol.standing_views.pose == &"walking" and patrol.standing_views.walk_frame > 0, "Actual patrol displacement advances walking")
	var wall := StaticBody3D.new()
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(0.2, 3, 3)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	wall.position = Vector3(patrol.position.x + 0.7, 1.5, -3)
	world.add_child(wall)
	await frames(110)
	var blocked_at: Vector3 = patrol.position
	await frames(15)
	check(patrol.position.distance_to(blocked_at) < 0.001 and patrol.standing_views.pose == &"holding", "Collision-blocked movement cannot step in place")
	patrol.active = false
	await frames(2)
	check(not patrol.standing_views.walking, "Inactive enemies stop walking")
	patrol.standing_views.advance_walk(Vector3(0.4, 0, 0))
	patrol._update_sprite_views()
	patrol.receive_hit(100, patrol.position, Vector3.UP, enemy, &"torso")
	check(patrol.state == &"downed" and not patrol.standing_views.walking and patrol.standing_views.pose != &"walking", "Incapacitation clears standing locomotion")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: 32 walking frames, all angles/alpha/anchors, distance phase/wrap, pose priorities, real patrol movement, wall stop, inactive/downed cleanup, conserved ammo")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
