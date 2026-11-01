extends StaticBody3D
const Character = preload("res://scripts/characters/polygon_character.gd")
const STATES: Array[StringName] = [&"idle",&"walk",&"run",&"crouch",&"aim",&"reload",&"interact",&"die"]
var character
var state_index: int = 0
var label: Label3D
func _ready() -> void:
	character = Character.new()
	character.name = "PolygonCharacter"
	add_child(character)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.28
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	label = Label3D.new()
	label.position.y = 2.1
	label.font_size = 30
	label.pixel_size = 0.002
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	_update_label()
func get_prompt() -> String:
	return "F  Polygon rig: %s → %s" % [STATES[state_index],STATES[(state_index+1)%STATES.size()]]
func interact(_actor) -> void:
	state_index = (state_index+1)%STATES.size()
	character.play(STATES[state_index])
	_update_label()
func _update_label() -> void:
	label.text = "REJECTED ART / rig test only / F next pose\n"+String(STATES[state_index])
