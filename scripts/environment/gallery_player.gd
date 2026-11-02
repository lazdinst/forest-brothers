extends "res://scripts/player/first_person_player.gd"
## Reuse movement/clearance, with an unobstructed unarmed inspection view.
func _ready() -> void:
	super._ready()
	weapon.visible = false
	weapon.process_mode = Node.PROCESS_MODE_DISABLED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event.is_action_pressed("ui_cancel") or event.is_action_pressed("reset_position"):
		super._unhandled_input(event)
	elif event is InputEventMouseButton and not controls_active():
		# Allow capturing the mouse, without passing firing/weapon commands through.
		super._unhandled_input(event)
