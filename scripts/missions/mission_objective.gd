extends Resource
## One objective of a mission definition (content, not runtime state).
## Kind &"carry_out": the item must leave the area with a participant who gets out. The item is
## placed at one of the map's ObjectiveSpot markers carrying spot_tag. Further kinds (reach a
## place, rescue a civilian) slot in beside it.
@export var kind: StringName = &"carry_out"
## Item catalog id of the objective item (SupplyCatalog entry marked "objective").
@export var item_id: StringName
## How the objective names the item, e.g. "the sealed dispatch".
@export var label: String
@export var spot_tag: StringName
## Optional objectives do not decide whether the mission succeeded.
@export var required: bool = true
