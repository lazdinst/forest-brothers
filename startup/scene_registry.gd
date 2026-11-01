extends RefCounted
## UI-owned paths. Training stays at its existing location.
const MENU := "res://ui/main_menu/main_menu.tscn"
const TRAINING := "res://scenes/prototype/camp_test.tscn"

static func resolve_route(arguments: PackedStringArray, environment: String) -> String:
	# Explicit command line wins over the environment. Unknown values fail to menu.
	var route := environment.strip_edges().to_lower()
	for argument in arguments:
		if argument.begins_with("--start="):
			route = argument.trim_prefix("--start=").to_lower()
	return "training" if route == "training" else "menu"
