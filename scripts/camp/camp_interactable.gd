extends StaticBody3D
## Something in the camp the player can use with F: shows a prompt and calls an action with the
## player who used it. Collision comes from the node's own shapes.
var prompt := ""
## (actor: Node) -> void
var action: Callable

func get_prompt() -> String:
	return prompt

func interact(actor: Node) -> void:
	if action.is_valid():
		action.call(actor)
