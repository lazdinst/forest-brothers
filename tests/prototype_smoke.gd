extends SceneTree
## Integration check using real scene physics and the player's interaction ray.

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://scenes/prototype/camp_test.tscn") as PackedScene
	if scene == null:
		push_error("Could not load the prototype scene")
		quit(1)
		return
	var world = scene.instantiate()
	root.add_child(world)
	var player = world.get_node("Player")
	await _frames(40)
	for id in world.TRAINING_STOCK:
		_check(world.stock.count(id) == world.TRAINING_STOCK[id],"Fresh training receives %s supplies" % id)
	_check(player.is_on_floor(), "Player must land on the floor")
	var start_z: float = player.position.z
	Input.action_press("move_forward")
	await _frames(30)
	Input.action_release("move_forward")
	_check(player.position.z < start_z - 1.0, "Forward input must move the character")
	player.position = Vector3(0, 0.01, -0.7)
	player.velocity = Vector3.ZERO
	await _frames(3)
	player.try_interact()
	await _frames(30)
	_check(world.get_node("Door").is_open, "An aimed in-range interaction must open the door")
	Input.action_press("move_forward")
	await _frames(80) # Allow acceleration and recovery from the swinging door push.
	Input.action_release("move_forward")
	_check(player.position.z < -2.5, "Player must pass through the open doorway: %s" % player.position)
	for entry in [["food", -2.0], ["water", 0.0], ["medicine", 2.0]]:
		var before: int = world.stock.count(StringName(entry[0]))
		player.position = Vector3(entry[1], 0.01, -4.3)
		player.velocity = Vector3.ZERO
		player.camera.rotation.x = -0.34
		await _frames(3)
		player.try_interact()
		player.try_interact()
		await _frames(3)
		_check(world.stock.count(StringName(entry[0])) == before + 1, "%s pickup must be awarded exactly once" % entry[0])
	player.camera.rotation.x = 0.0
	# The old box perimeter is now open woodland. Retain the solid-wall
	# regression against the existing supplies-room partition instead.
	player.position = Vector3(3.4, 0.01, -0.8)
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	await _frames(35)
	Input.action_release("move_forward")
	_check(player.position.z > -1.6, "Solid wall must block movement")
	if failures.is_empty():
		print("PASS: floor, movement, door interaction/traversal, three one-shot pickups, wall collision")
	else:
		for failure in failures:
			push_error(failure)
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
