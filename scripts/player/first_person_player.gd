extends CharacterBody3D
## Local input and movement only. Shared resources belong to the session scene.

@export var walk_speed: float = 3.3
@export var sprint_speed: float = 5.2
@export var jump_speed: float = 4.2
@export var mouse_sensitivity: float = 0.002

@onready var camera: Camera3D = $Camera3D
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay

var interaction_target: Node = null
var gravity: float = 20.0


func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * mouse_sensitivity, -1.45, 1.45)
	elif event.is_action_pressed("interact") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		try_interact()


func _physics_process(delta: float) -> void:
	var controls_active := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or DisplayServer.get_name() == "headless"
	var axes := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if controls_active else Vector2.ZERO
	var direction := global_basis * Vector3(axes.x, 0.0, axes.y)
	var speed := sprint_speed if controls_active and Input.is_action_pressed("sprint") else walk_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif controls_active and Input.is_action_just_pressed("jump"):
		velocity.y = jump_speed
	move_and_slide()
	refresh_interaction_target()


func refresh_interaction_target() -> void:
	interaction_ray.force_raycast_update()
	interaction_target = null
	if interaction_ray.is_colliding():
		var candidate := interaction_ray.get_collider() as Node
		if is_instance_valid(candidate) and candidate.has_method("interact") and candidate.has_method("get_prompt"):
			interaction_target = candidate


func try_interact() -> void:
	refresh_interaction_target()
	if is_instance_valid(interaction_target):
		interaction_target.interact(self)


func get_interaction_prompt() -> String:
	if not is_instance_valid(interaction_target):
		return ""
	return interaction_target.get_prompt()
