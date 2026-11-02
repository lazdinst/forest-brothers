extends "res://scripts/characters/directional_idle.gd"
## The starting civilian as the camp's old man: the same idle sprite, and F on his body opens
## whatever the camp gives him to do (his trade window). The interaction ray finds his body;
## the larger player-clearance shape sits on a layer the ray does not check.
var prompt := ""
## (actor: Node) -> void
var action: Callable

func get_prompt() -> String:
	return prompt

func interact(actor: Node) -> void:
	if action.is_valid():
		action.call(actor)
