extends "res://scripts/characters/directional_idle.gd"
var annex
var resident_id: StringName = &"resident_01"
var rescuable: bool = false
var departing: bool = false
var departure_tween: Tween

func get_prompt() -> String:
	return "F  Direct civilian to camp" if rescuable else "F  Civilian assignment"

func interact(actor: Node) -> void:
	if rescuable:
		if annex.runtime.rescue(resident_id):
			departing = true
			set_deferred("collision_layer",0)
			for child in get_children():
				if child is StaticBody3D:
					child.set_deferred("collision_layer",0)
			departure_tween = create_tween()
			departure_tween.tween_property(self,"position",position+Vector3(4,0,-1),1.5)
			departure_tween.tween_callback(hide)
			annex.refresh_panel()
	else:
		annex.open_resident(self, actor)

func arrive_at(at: Vector3) -> void:
	if departure_tween != null and departure_tween.is_valid():
		departure_tween.kill()
	rescuable = false
	departing = false
	_moving = false
	global_position = at
	collision_layer = 1
	show()
	for child in get_children():
		if child is StaticBody3D:
			child.collision_layer = 4
		if child is Label3D:
			child.text = "Arrived civilian (test)"

func _physics_process(delta: float) -> void:
	super(delta)
	if departing:
		_moving = true
