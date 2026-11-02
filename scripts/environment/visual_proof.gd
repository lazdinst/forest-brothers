extends Node3D
## Local proof HUD only. Reuses the existing player/weapon without changing them.

@onready var player = $Player

func _process(_delta: float) -> void:
	$HUD/State.text = player.movement_state + " | " + player.weapon.status_text()
	$HUD/Crosshair.visible = not player.is_aiming and player.weapon.aim_fraction < 0.05
