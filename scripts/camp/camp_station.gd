extends StaticBody3D
var annex
var station_id: StringName
var title: String
var kind: StringName

func get_prompt() -> String:
	return "F  " + title

func interact(actor: Node) -> void:
	annex.open_station(self, actor)
