extends SceneTree
## Species-only asset update. Ordinary mesh resources may be baked headless.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var source=load("res://scripts/environment/pine_recipe.gd").new()
	source.bake()
	source.bake_branch(false)
	source.bake_branch(true)
	source.bake_snag()
	source.bake_fallen()
	source.bake_rotten()
	print("PINE ASSETS PASS: living tree, dead branch, broken branch, snag, fallen pine, rotten mossy pine")
	quit()
