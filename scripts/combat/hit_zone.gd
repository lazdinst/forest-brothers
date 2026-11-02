extends Area3D
## One invisible body-part volume. Shots read its zone and owner; it never blocks movement or sight.
const LAYER := 8
var zone: StringName = &""
var owner_actor: Node3D

func _init(zone_name: StringName = &"", actor: Node3D = null) -> void:
	zone = zone_name
	owner_actor = actor
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false
