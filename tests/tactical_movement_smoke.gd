extends SceneTree
const Rules = preload("res://scripts/player/tactical_movement.gd")
const PlayerScene = preload("res://scenes/player/first_person_player.tscn")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, detail: String) -> void:
	if not ok: failures.append(detail)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func key(player, code: Key, pressed: bool, echo := false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	if code == KEY_C:
		if pressed: Input.action_press("stance_adjust")
		else: Input.action_release("stance_adjust")
	player._unhandled_input(event)
func wheel(player, up: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN
	event.pressed = true
	player._unhandled_input(event)
func block(world: Node3D, at: Vector3, dimensions: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions
	collider.shape = box
	body.add_child(collider)
	world.add_child(body)
	body.position = at
	return body
func _run() -> void:
	var rules = Rules.new()
	check(is_equal_approx(rules.walking_speed(1.8,false),3.3), "Default maximum pace")
	rules.adjust_speed(-5)
	rules.toggle_slow()
	check(rules.speed_setting == 1, "Caps selects minimum")
	rules.toggle_slow()
	check(rules.speed_setting == 5, "Caps restores previous selection")
	for i in range(10):
		rules.speed_setting = i + 1
		check(is_equal_approx(rules.walking_speed(1.8,false), 3.3 * (i+1) / 10.0), "Ten evenly spaced walking increments")
	rules.advance(10.0,true,true,false,4.0)
	check(rules.legs == 0.0 and rules.arms == 100.0 and rules.exhausted, "Sprint empties only legs and latches exhaustion")
	rules.advance(1.2,false,false,false,4.0)
	check(rules.legs < 0.01, "Recovery delay prevents instant regeneration")
	rules.advance(1.0,false,false,false,4.0)
	check(not rules.can_sprint(), "Sprint remains locked below reactivation threshold")
	rules.advance(1.0,false,false,false,4.0)
	check(rules.can_sprint(), "Sprint unlocks after 25 points")
	rules.legs = 100.0
	rules.advance(5.0,false,false,true,4.0)
	check(rules.legs == 100.0 and rules.arms == 75.0, "ADS drains arms independently")
	rules.advance(0.6,false,false,false,4.0)
	check(rules.arms == 75.0, "Arm regeneration delay")
	rules.advance(1.0,false,false,false,4.0)
	check(rules.arms == 87.0, "Arm regeneration")
	rules.speed_setting = 10
	var unloaded: float = rules.walking_speed(1.8,false)
	rules.carried_weight = 35.0
	check(rules.walking_speed(1.8,false) < unloaded and rules.load_drain() > 1.0, "Equipment load reduces speed and increases exertion")
	var world := Node3D.new()
	root.add_child(world)
	block(world,Vector3(0,-0.5,0),Vector3(100,1,100))
	var player = PlayerScene.instantiate()
	world.add_child(player)
	player.position = Vector3(0,0.02,0)
	await frames(10)
	var crouch_press := InputEventKey.new()
	crouch_press.physical_keycode = KEY_CAPSLOCK
	check(crouch_press.is_action("slow_walk"), "Caps Lock mapping matches engine enum")
	key(player,KEY_C,true)
	wheel(player,false)
	key(player,KEY_C,true,true)
	key(player,KEY_C,false)
	check(player.locomotion.stance_level == 6 and player.locomotion.speed_setting == 10, "C scroll takes priority, echo and release do not toggle")
	await frames(15)
	check(is_equal_approx(player.body_shape.shape.height,1.68), "Partial stance reaches physical target")
	key(player,KEY_C,true)
	key(player,KEY_C,false)
	await frames(20)
	check(player.locomotion.stance_level == 7 and not player.is_crouching, "Tap C restores full standing")
	key(player,KEY_C,true)
	key(player,KEY_C,false)
	await frames(20)
	check(player.is_crouching and is_equal_approx(player.body_shape.shape.height,1.1), "Tap C selects lowest crouch")
	var roof := block(world,Vector3(0,1.5,0),Vector3(4,0.3,4))
	await frames(3)
	player.locomotion.stance_level = 7
	Input.action_press("sprint")
	Input.action_press("move_forward")
	await frames(8)
	Input.action_release("sprint")
	Input.action_release("move_forward")
	check(player.body_shape.shape.height < 1.35 and player.camera.position.y < 1.2 and not player.is_sprinting, "Blocked expansion stops capsule and eye; sprint cannot bypass roof")
	await frames(10)
	roof.queue_free()
	await frames(30)
	check(not player.is_crouching, "Requested height resumes when clearance opens")
	player.locomotion.stance_level = 4
	await frames(20)
	player.toggle_prone()
	await frames(25)
	check(player.is_prone and is_equal_approx(player.body_shape.shape.height,0.6), "Separate prone capsule")
	player.toggle_prone()
	await frames(25)
	check(not player.is_prone and player.locomotion.stance_level == 4, "Prone restores intermediate stance")
	player.locomotion.stance_level = 7
	player.position = Vector3.ZERO
	player.velocity = Vector3.ZERO
	await frames(25)
	Input.action_press("move_forward")
	await frames(2)
	check(absf(player.velocity.z) < 1.0 and player.velocity.z < 0.0, "Movement accelerates instead of snapping")
	await frames(30)
	var forward_speed: float = Vector2(player.velocity.x,player.velocity.z).length()
	Input.action_press("move_right")
	await frames(30)
	check(Vector2(player.velocity.x,player.velocity.z).length() <= forward_speed + 0.01, "Normalized diagonal cannot exceed straight speed")
	Input.action_release("move_right")
	Input.action_release("move_forward")
	await frames(30)
	Input.action_press("move_back")
	await frames(30)
	check(player.velocity.z < forward_speed and player.velocity.z > 0.0, "Backward speed restriction")
	Input.action_release("move_back")
	await frames(30)
	var selected: int = player.locomotion.speed_setting
	wheel(player,false)
	await frames(20)
	check(player.locomotion.speed_setting == selected-1, "Pace persists while stationary")
	var before_weight: float = player.locomotion.carried_weight
	player.weapon.state.inventory.drop_item(player.weapon.state.inventory.initial_magazine_ids[1],Vector3(5,0,0))
	await frames(3)
	check(player.locomotion.carried_weight < before_weight, "Dropped equipment is excluded from carried weight")
	# Actual sprint overrides, then restores, selected walking pace.
	player.locomotion.speed_setting = 5
	player.locomotion.legs = 100.0
	player.locomotion.exhausted = false
	Input.action_press("sprint")
	Input.action_press("move_forward")
	await frames(60)
	check(player.is_sprinting and player.locomotion.legs < 100.0 and absf(player.velocity.z) > 4.5, "Actual sprint consumes legs and overrides slow pace")
	Input.action_release("sprint")
	await frames(40)
	check(not player.is_sprinting and player.locomotion.speed_setting == 5 and absf(player.velocity.z) < 1.8, "Releasing sprint returns to selected pace")
	Input.action_release("move_forward")
	await frames(30)
	# Pace-dependent sound comes from actual physical steps, including outside annex.
	var sounds := []
	player.movement_noise.connect(func(at: Vector3, loudness: float): sounds.append([at,loudness]))
	player.locomotion.speed_setting = 10
	Input.action_press("move_forward")
	await frames(70)
	var loud: float = player.movement_loudness()
	check(not sounds.is_empty(), "Physical travel publishes movement noise events")
	player.locomotion.speed_setting = 1
	await frames(30)
	check(player.movement_loudness() < loud * 0.2, "Minimum pace produces much quieter steps")
	Input.action_release("move_forward")
	await frames(30)
	var emitted := sounds.size()
	await frames(60)
	check(sounds.size() == emitted, "Stationary character emits no footsteps")
	# Aiming keeps the same collision/camera and muzzle architecture at every level.
	Input.action_press("aim")
	for level in range(1,8):
		player.locomotion.stance_level = level
		await frames(20)
		check(player.is_aiming and absf(player.camera.position.y - (player.body_shape.shape.height - 0.2)) < 0.01, "ADS follows collision-safe stance %d" % level)
	var arms_before: float = player.locomotion.arms
	await frames(60)
	check(player.locomotion.arms < arms_before and player._sway.length() > 0.0, "ADS arm fatigue drives honest camera/aim sway")
	Input.action_release("aim")
	await frames(30)
	player.locomotion.legs = 0.0
	player.locomotion.exhausted = true
	Input.action_press("jump")
	await frames(2)
	check(player.velocity.y <= 0.0, "Exhausted jump cannot launch")
	Input.action_release("jump")
	for failure in failures: push_error(failure)
	if failures.is_empty(): print("PASS: tactical movement rules, input, collision, prone, inertia, load and stamina")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
