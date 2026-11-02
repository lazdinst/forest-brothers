extends RefCounted
## Runs one conversation with one NPC, for any NPC: picks a contextual greeting, offers the
## topics the relationship and world allow, walks nodes and choices, applies their effects to the
## NPC's state and asks the host for side effects (gifts, opening trade). The window only shows
## `view`, `text` and `choices` and calls back in. Signal-based; no UI here.
const Rules = preload("res://scripts/npc/dialogue_rules.gd")
signal changed
signal ended
## The host should open another interaction (for example "trade").
signal open_requested(action: String)
## The host should hand these supply items to the player.
signal gifts_requested(supply_ids: Array)

var definition
var state
var provider
var context: Dictionary = {}
## &"conversation" (the NPC speaks, choices below) or &"topics" (choose what to ask about).
var view := &"conversation"
var node_id := ""
var text := ""
var choices: Array = []
## True after Goodbye: the last line shows, then the conversation ends.
var closing := false
var _rng := RandomNumberGenerator.new()

func _init(npc_definition, npc_state, dialogue_provider) -> void:
	definition = npc_definition
	state = npc_state
	provider = dialogue_provider
	_rng.randomize()

## Begins a conversation. A new visit (first meeting, or after an outing) clears visit flags and
## runs the visit rules (familiarity per visit, reactions to missions completed since).
func start(world_context: Dictionary) -> void:
	context = world_context.duplicate()
	var outing := int(context.get("outings", 0))
	var missions := int(context.get("missions_completed", 0))
	var new_visit: bool = not state.met() or outing != state.last_visit_outing
	context.outings_since_visit = outing - state.last_visit_outing if state.met() else 0
	context.new_missions_completed = maxi(0, missions - state.seen_missions_completed) if state.met() else 0
	context.new_visit = new_visit
	if new_visit:
		state.visit_flags.clear()
		for rule in provider.visit_rules:
			if Rules.passes(rule.get("conditions", []), state, definition, context):
				_requests(Rules.apply(rule.get("effects", []), state, context))
	closing = false
	_greet()
	state.flags.met = true
	state.last_visit_outing = outing
	state.seen_missions_completed = missions

func stage() -> String:
	return state.stage(definition)

## Topics the NPC will talk about now, by category: [{"id", "title", "topics": [{"id", "title", "new"}]}].
func available_topics() -> Array:
	var grouped: Array = []
	for category in provider.categories:
		var entries: Array = []
		for topic in provider.topics:
			if topic.category != category.id or not Rules.passes(topic.get("conditions", []), state, definition, context): continue
			entries.append({"id": topic.id, "title": topic.title, "new": not state.told.has(topic.start)})
		if not entries.is_empty():
			grouped.append({"id": category.id, "title": category.title, "topics": entries})
	return grouped

func show_topics() -> void:
	if closing:
		ended.emit()
		return
	view = &"topics"
	changed.emit()

func choose_topic(id: String) -> void:
	var topic: Dictionary = provider.topic(id)
	if topic.is_empty() or not Rules.passes(topic.get("conditions", []), state, definition, context): return
	_enter(topic.start)

## Picks one of the current choices by index.
func choose(index: int) -> void:
	if index < 0 or index >= choices.size(): return
	var choice: Dictionary = choices[index]
	var requests := Rules.apply(choice.get("effects", []), state, context)
	_requests(requests)
	if choice.has("open"):
		open_requested.emit(str(choice.open))
		return
	if choice.get("end", false) or requests.end:
		goodbye()
	elif choice.has("next"):
		_enter(choice.next)
	elif choice.has("topic"):
		choose_topic(choice.topic)
	else:
		show_topics()

## Says goodbye: a closing line when the NPC has one, then the conversation ends.
func goodbye() -> void:
	state.conversations_completed += 1
	var lines: Array = provider.goodbyes.filter(func(entry): return not entry is Dictionary or Rules.passes(entry.get("conditions", []), state, definition, context))
	if lines.is_empty():
		ended.emit()
		return
	closing = true
	view = &"conversation"
	node_id = "goodbye"
	text = _pick(lines)
	choices = []
	changed.emit()

func _greet() -> void:
	var best := -INF
	var candidates: Array = []
	for greeting in provider.greetings:
		if not Rules.passes(greeting.get("conditions", []), state, definition, context): continue
		var priority := float(greeting.get("priority", 0))
		if priority > best:
			best = priority
			candidates = []
		if priority == best: candidates.append(greeting)
	view = &"conversation"
	node_id = "greeting"
	var lines: Array = []
	for greeting in candidates:
		lines.append_array(greeting.text if greeting.text is Array else [greeting.text])
	# Vary the greeting: not the same line twice in a row when there is a choice.
	if lines.size() > 1: lines.erase(state.last_greeting)
	text = _pick(lines) if not lines.is_empty() else "..."
	state.last_greeting = text
	choices = provider.greeting_choices.filter(func(choice): return Rules.passes(choice.get("conditions", []), state, definition, context))
	changed.emit()

func _enter(id: String) -> void:
	var entry: Dictionary = provider.node(id)
	if entry.is_empty():
		show_topics()
		return
	var requests := Rules.apply(entry.get("effects", []), state, context)
	_requests(requests)
	state.told[id] = true
	view = &"conversation"
	node_id = id
	text = _pick(entry.text if entry.text is Array else [entry.text])
	choices = entry.get("choices", []).filter(func(choice): return Rules.passes(choice.get("conditions", []), state, definition, context))
	# A node that ends the conversation (he sends you away) shows its line, then closes.
	if requests.end:
		state.conversations_completed += 1
		closing = true
		choices = []
	changed.emit()

## A line from a list: the first conditional entry ({"text", "conditions"}) that passes, else a
## random plain line.
func _pick(lines: Array) -> String:
	var plain: Array = []
	for line in lines:
		if line is Dictionary:
			if Rules.passes(line.get("conditions", []), state, definition, context): return str(line.text)
		else:
			plain.append(line)
	return str(plain[_rng.randi() % plain.size()]) if not plain.is_empty() else ""

func _requests(requests: Dictionary) -> void:
	if not requests.gifts.is_empty(): gifts_requested.emit(requests.gifts)
	if requests.open != "": open_requested.emit(requests.open)
