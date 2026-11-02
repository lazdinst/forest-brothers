extends SceneTree
## Birch-only replacement: keep existing forest placement and other species.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	load("res://scripts/environment/birch_recipe.gd").new().bake()
	quit()
