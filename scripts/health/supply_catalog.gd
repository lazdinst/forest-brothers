extends RefCounted
## Immutable definitions for medical and food supplies (definitions, not runtime state).
## Effects are fictional game abstractions modelled on Escape from Tarkov, not real treatment
## guidance. Names follow the period candidates in MISSIONS_AND_MEDICINE.md; every number is a
## placeholder pending owner balance. "uses" is a count, or a resource pool for the satchel.
const SUPPLIES := {
	&"cloth_bandage": {"name":"Cloth bandage","icon":"medicine","size":Vector2i(1,1),"uses":1,"seconds":4.0,"targets_part":true,
		"stops_light":true,"description":"Stops light bleeding on one body part."},
	&"field_dressing": {"name":"Field dressing","icon":"medicine","size":Vector2i(1,1),"uses":1,"seconds":5.0,"targets_part":true,
		"stops_light":true,"stops_heavy":true,"description":"Stops heavy or light bleeding on one body part."},
	&"splint": {"name":"Splint","icon":"medicine","size":Vector2i(1,2),"uses":1,"seconds":6.0,"targets_part":true,
		"fixes_fracture":true,"description":"Sets a broken arm or leg. Does not restore lost health."},
	&"morphine": {"name":"Morphine","icon":"medicine","size":Vector2i(1,1),"uses":1,"seconds":3.0,"targets_part":false,
		"painkiller":300.0,"description":"Removes pain and its limits for a while. Cures nothing."},
	&"medical_satchel": {"name":"Medical satchel","icon":"medicine","size":Vector2i(2,2),"uses":300,"seconds":3.0,"targets_part":true,
		"heals":true,"light_cost":40,"heavy_cost":120,"description":"Stops bleeding and restores health from its supply. Cannot save a destroyed part."},
	&"canteen": {"name":"Water canteen","icon":"water","size":Vector2i(1,2),"uses":3,"seconds":3.0,"targets_part":false,
		"hydration":30.0,"description":"Three drinks of water."},
	&"rye_bread": {"name":"Rye bread","icon":"food","size":Vector2i(1,1),"uses":1,"seconds":4.0,"targets_part":false,
		"energy":40.0,"hydration":-5.0,"description":"A dense loaf. Restores energy."},
	&"tinned_meat": {"name":"Tinned meat","icon":"food","size":Vector2i(1,1),"uses":1,"seconds":5.0,"targets_part":false,
		"energy":60.0,"hydration":-10.0,"description":"Restores a lot of energy; makes you thirsty."},
}

static func has(id: StringName) -> bool:
	return SUPPLIES.has(id)

static func get_def(id: StringName) -> Dictionary:
	return SUPPLIES.get(id,{})

static func is_food(def: Dictionary) -> bool:
	return def.has("energy") or def.has("hydration")

## Verb shown on the item's menu.
static func verb(def: Dictionary) -> String:
	if def.get("icon","") == "water": return "Drink"
	if is_food(def): return "Eat"
	return "Use"
