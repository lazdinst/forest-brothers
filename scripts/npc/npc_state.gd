extends RefCounted
## One NPC's relationship and memory in one world: hidden relationship values, structured memory
## flags (met, told stories, helped, threatened ...), a short list of important events, flags
## that only last for the current visit, and its trade stock. Saved with the world's camp. No
## free-form dialogue history: memory is bounded by the authored content.
const MAX_EVENTS := 20
var familiarity := 0
var trust := 0
var respect := 0
var suspicion := 0
var conversations_completed := 0
## Outing count (GameSession world "outings") at the last visit; -1 before the first meeting.
var last_visit_outing := -1
## Missions completed the last time this NPC took notice (for "new missions" reactions).
var seen_missions_completed := 0
## Node ids already told: stories are not repeated as if new.
var told := {}
## Lasting memory flags: met, asked_military, threatened, promised_salt ...
var flags := {}
## Flags for the current visit only (cleared when a new visit begins).
var visit_flags := {}
## Effects marked "once" that have already applied.
var once := {}
## The most recent important events, newest last: [{"outing": n, "text": "..."}].
var events: Array = []
## The last greeting variant used, so greetings vary.
var last_greeting := ""
## Trade lots left per stock id, and the outing they were last restocked.
var stock_left := {}
var restocked_outing := -1

func met() -> bool:
	return flags.get("met", false)

## The highest stage whose minimums are all met; suspicion caps it at the second stage.
func stage(definition) -> String:
	var reached: String = definition.stages[0].stage if not definition.stages.is_empty() else "stranger"
	for index in range(definition.stages.size()):
		var rule: Dictionary = definition.stages[index]
		if index >= 2 and suspicion >= definition.suspicion_cap: break
		var ok := true
		for key in ["familiarity", "trust", "respect"]:
			if int(get(key)) < int(rule.get(key, 0)): ok = false
		if ok: reached = rule.stage
	return reached

func stage_index(definition, stage_name: String) -> int:
	for index in range(definition.stages.size()):
		if definition.stages[index].stage == stage_name: return index
	return -1

func remember(outing: int, text: String) -> void:
	events.append({"outing": outing, "text": text})
	while events.size() > MAX_EVENTS: events.pop_front()

func encode() -> Dictionary:
	return {"familiarity":familiarity,"trust":trust,"respect":respect,"suspicion":suspicion,
		"conversations_completed":conversations_completed,"last_visit_outing":last_visit_outing,
		"seen_missions_completed":seen_missions_completed,"told":told.keys(),"flags":flags.duplicate(),
		"visit_flags":visit_flags.duplicate(),"once":once.keys(),"events":events.duplicate(true),
		"last_greeting":last_greeting,"stock_left":stock_left.duplicate(),"restocked_outing":restocked_outing}

func restore(data: Dictionary) -> void:
	for key in ["familiarity","trust","respect","suspicion","conversations_completed","last_visit_outing","seen_missions_completed","restocked_outing"]:
		if data.has(key): set(key, int(data[key]))
	told = {}
	for id in data.get("told", []): told[str(id)] = true
	once = {}
	for id in data.get("once", []): once[str(id)] = true
	flags = data.get("flags", {}).duplicate()
	visit_flags = data.get("visit_flags", {}).duplicate()
	events = data.get("events", []).duplicate(true)
	last_greeting = str(data.get("last_greeting", ""))
	stock_left = {}
	var saved: Dictionary = data.get("stock_left", {})
	for id in saved: stock_left[str(id)] = int(saved[id])
