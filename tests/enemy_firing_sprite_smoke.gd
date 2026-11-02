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
	var target := Node3D.new()
	world.add_child(target)
	target.position = Vector3(0, 0, 8)
	var shots := [0]
	enemy.fired.connect(func(_e, _t, _h): shots[0] += 1)
	var rounds: int = enemy.total_rounds()
	var fire_image: Image = enemy.standing_views.RifleArt.FIRE_ATLAS.get_image()
	check(fire_image.get_pixel(20, 20).a == 0, "Firing atlas has real alpha")
	for sector in range(8):
		var angle := -sector * TAU / 8.0
		camera.position = Vector3(sin(angle) * 5, 1.6, cos(angle) * 5)
		enemy.state = &"engage"
		enemy._physics_process(0.0)
		var aimed_muzzle: Vector3 = enemy.muzzle_world_position()
		var aimed_scale: float = enemy.sprite.pixel_size
		enemy._shoot(target)
		check(enemy.standing_views.pose == &"firing" and enemy.standing_views.sector == sector, "Shot immediately displays matching firing sector %d" % sector)
		check(is_equal_approx(enemy.sprite.pixel_size, aimed_scale), "Firing exposure does not change figure scale")
		check(enemy.muzzle_world_position().distance_to(aimed_muzzle) < 0.001, "Painted firing muzzle remains aligned")
		var region: Rect2 = enemy.sprite.texture.region
		check(region.end.x <= fire_image.get_width() and region.end.y <= fire_image.get_height(), "Firing art fits atlas")
		if sector != 4:
			var point: Vector2 = enemy.standing_views.RifleArt.AIM_MUZZLES[sector]
			var bright := false
			for y in range(int(point.y) - 8, int(point.y) + 9):
				for x in range(maxi(0, int(point.x) - 16), mini(fire_image.get_width(), int(point.x) + 17)):
					var color := fire_image.get_pixel(x, y)
					bright = bright or (color.a > 0.5 and color.r > 0.9 and color.g > 0.65)
			check(bright, "Visible muzzle has a small warm painted flash")
		for child in enemy.get_children():
			check(not (child is MeshInstance3D and child.mesh is SphereMesh), "No duplicate sphere flash")
		enemy._physics_process(0.03)
		check(enemy.standing_views.pose == &"firing", "Exposure survives its first 30 ms")
		enemy._physics_process(0.05)
		check(enemy.standing_views.pose == &"aiming", "Exposure ends and returns to aiming")
	check(shots[0] == 8 and enemy.total_rounds() == rounds - 8, "Eight actual shots consume exactly eight rounds")
	# Consecutive shots restart the exposure; reload/death never retain lit frames.
	enemy._shoot(target)
	enemy._physics_process(0.06)
	enemy._shoot(target)
	enemy._physics_process(0.03)
	check(enemy.standing_views.pose == &"firing", "A new shot restarts the exposure")
	check(enemy.start_reload(), "Reload starts after emptying magazine")
	check(enemy.standing_views.pose == &"holding" and enemy.standing_views.shot_left == 0, "Reload clears firing frame immediately")
	enemy.reload_left = 0
	enemy.rounds_in_magazine = 2
	enemy._shoot(target)
	enemy.receive_hit(100, enemy.position, Vector3.UP, target, &"torso")
	check(enemy.state == &"downed" and enemy.standing_views.pose != &"firing" and enemy.standing_views.shot_left == 0, "Incapacitation clears illuminated pose")
	enemy.receive_hit(1, enemy.position, Vector3.UP, target, &"torso")
	check(enemy.state == &"dead" and enemy.standing_views.pose != &"firing", "Corpse retains no firing light")
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: eight illuminated shot views, actual shot/ammo sync, muzzle alignment, brief exposure/reset, no duplicate flash, reload/down/death cleanup")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
