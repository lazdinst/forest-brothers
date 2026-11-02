extends RefCounted
## Conditions and effects for authored dialogue, shared by every NPC. A condition list passes
## when every entry passes; an effect list changes the NPC's state or asks the host for something
## (a gift, opening trade). Context is a plain dictionary the scene supplies (time of day,
## season, player condition, missions completed ...); missing keys read as false / 0.
##
## Conditions: {"stage_at_least": s} {"stage_below": s} {"flag": f} {"not_flag": f}
##   {"visit_flag": f} {"not_visit_flag": f} {"told": node} {"not_told": node}
##   {"first_meeting": true|false} {"context": key} {"not_context": key}
##   {"context_at_least": {key: n}} {"context_equals": {key: value}}
## Effects: {"familiarity"|"trust"|"respect"|"suspicion": n} {"flag": f} {"clear_flag": f}
##   {"visit_flag": f} {"event": text} {"gift": supply_id} {"open": action} {"end": true}
##   Any effect may carry "once": key, so it applies a single time in this world.

static func passes(conditions: Array, state, definition, context: Dictionary) -> bool:
	for condition in conditions:
		if not _one(condition, state, definition, context): return false
	return true

static func _one(condition: Dictionary, state, definition, context: Dictionary) -> bool:
	for key in condition:
		var value = condition[key]
		match key:
			"stage_at_least": if state.stage_index(definition, state.stage(definition)) < state.stage_index(definition, value): return false
			"stage_below": if state.stage_index(definition, state.stage(definition)) >= state.stage_index(definition, value): return false
			"flag": if not state.flags.get(value, false): return false
			"not_flag": if state.flags.get(value, false): return false
			"visit_flag": if not state.visit_flags.get(value, false): return false
			"not_visit_flag": if state.visit_flags.get(value, false): return false
			"told": if not state.told.has(value): return false
			"not_told": if state.told.has(value): return false
			"first_meeting": if (not state.met()) != bool(value): return false
			"context": if not context.get(value, false): return false
			"not_context": if context.get(value, false): return false
			"context_at_least":
				for name in value:
					if float(context.get(name, 0)) < float(value[name]): return false
			"context_equals":
				for name in value:
					if str(context.get(name, "")) != str(value[name]): return false
			_:
				push_warning("Unknown dialogue condition: " + str(key))
				return false
	return true

## Applies effects; returns requests for the host: {"gifts": [...], "open": action or "", "end": bool}.
static func apply(effects: Array, state, context: Dictionary) -> Dictionary:
	var requests := {"gifts": [], "open": "", "end": false}
	for effect in effects:
		var key: String = str(effect.get("once", ""))
		if key != "":
			if state.once.has(key): continue
			state.once[key] = true
		for name in effect:
			var value = effect[name]
			match name:
				"familiarity", "trust", "respect", "suspicion": state.set(name, maxi(0, int(state.get(name)) + int(value)))
				"flag": state.flags[value] = true
				"clear_flag": state.flags.erase(value)
				"visit_flag": state.visit_flags[value] = true
				"event": state.remember(int(context.get("outings", 0)), str(value))
				"gift": requests.gifts.append(StringName(value))
				"open": requests.open = str(value)
				"end": requests.end = bool(value)
				"once": pass
				_: push_warning("Unknown dialogue effect: " + str(name))
	return requests
