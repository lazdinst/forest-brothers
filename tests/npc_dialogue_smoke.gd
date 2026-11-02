extends SceneTree
## The shared NPC system: Ģirts's authored dialogue loads and links up (60+ nodes); a first
## meeting greets differently from later visits and greetings vary; topics open with the
## relationship (stranger, acquaintance, trusted); follow-ups branch; context (bleeding) takes
## priority; a threat is remembered; state survives a JSON save; limited trade stock sells out
## and restocks; a second NPC runs on the same code; and in the camp, Talk opens the dialogue
## window, Escape steps back and Goodbye closes, with the state saved into the camp.
const Database = preload("res://scripts/npc/dialogue_database.gd")
const Controller = preload("res://scripts/npc/dialogue_controller.gd")
const State = preload("res://scripts/npc/npc_state.gd")
const Trade = preload("res://scripts/npc/npc_trade.gd")
const Runtime = preload("res://scripts/camp/camp_runtime.gd")
const Inventory = preload("res://scripts/inventory/ammunition_inventory.gd")
const GIRTS = preload("res://npcs/girts.tres")
const ARVIDS = preload("res://npcs/arvids.tres")
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures.append(detail)

func _topic_ids(controller) -> Array:
	var ids: Array = []
	for group in controller.available_topics():
		for topic in group.topics: ids.append(topic.id)
	return ids

func _choose_text(controller, text: String) -> bool:
	for index in range(controller.choices.size()):
		if controller.choices[index].text == text:
			controller.choose(index)
			return true
	failures.append("No choice '%s' at %s" % [text, controller.node_id])
	return false

func _run() -> void:
	var girts = Database.load_file(GIRTS.dialogue_path)
	_check(girts.error == "", "Ģirts's dialogue is valid: " + girts.error)
	_check(girts.nodes.size() >= 60, "At least 60 authored nodes (%d)" % girts.nodes.size())
	_check(girts.categories.size() == 7, "Seven topic categories")
	# First meeting, then varied greetings on later talks.
	var state := State.new()
	var talk := Controller.new(GIRTS, state, girts)
	talk.start({"outings": 0})
	_check(talk.text.begins_with("So. You're the one"), "A first meeting has its own greeting: " + talk.text)
	_check(talk.choices.any(func(choice): return choice.text == "How are you?") and talk.choices.any(func(choice): return choice.text == "Goodbye."), "The greeting offers replies")
	var seen := {}
	var last := ""
	for index in range(6):
		talk.start({"outings": 0})
		_check(talk.text != last, "Greetings do not repeat back to back")
		last = talk.text
		seen[talk.text] = true
	_check(seen.size() >= 3, "Repeated visits use varied greetings (%d different)" % seen.size())
	# A stranger: small talk only; his soldiering is refused.
	var ids := _topic_ids(talk)
	_check(ids.has("age") and ids.has("soldier_refused") and not ids.has("riflemen") and not ids.has("childhood"), "As a stranger he keeps his past to himself")
	talk.choose_topic("age")
	_check(talk.node_id == "st_age" and talk.choices.size() == 3, "A topic opens with follow-ups")
	_choose_text(talk, "You've seen a lot.")
	_check(talk.node_id == "st_seen", "A follow-up leads on")
	# Over visits and completed missions, he comes to trust the player.
	talk.start({"outings": 1, "missions_completed": 0})
	_check(talk.stage() == "acquaintance" and _topic_ids(talk).has("childhood"), "A second visit makes an acquaintance; his childhood opens")
	talk.start({"outings": 2, "missions_completed": 2})
	_check(talk.text.contains("Soldiers at every door"), "News of the group's work comes first: " + talk.text)
	talk.choose_topic("old_age")
	talk.choose_topic("too_old")
	_choose_text(talk, "You help us enough.")
	talk.start({"outings": 3, "missions_completed": 3})
	_check(talk.stage() == "trusted", "Missions and kindness earn his trust (stage %s, trust %d)" % [talk.stage(), state.trust])
	ids = _topic_ids(talk)
	_check(ids.has("riflemen") and not ids.has("soldier_refused") and not ids.has("son"), "Trusted, he talks about the Riflemen but not yet about his son")
	talk.choose_topic("riflemen")
	_choose_text(talk, "Tell me about the fighting.")
	_choose_text(talk, "What happened then?")
	_choose_text(talk, "So you joined the Reds?")
	_check(talk.text == "Aye. I did." and state.flags.get("asked_military", false), "He admits fighting for the Reds, and remembers being asked")
	_choose_text(talk, "Why?")
	_check(talk.node_id == "p_reds_why" and talk.choices.size() == 3, "Why branches three ways")
	# Context: bleeding comes before any other greeting.
	talk.start({"outings": 3, "player_bleeding": true, "player_injured": true})
	_check(talk.text.contains("bleeding on my ground") and talk.choices.any(func(choice): return choice.text == "I'm hurt. Can you help?"), "Bleeding, he notices first and offers help")
	# A threat is remembered.
	var wary := State.new()
	var rude := Controller.new(GIRTS, wary, girts)
	var ended := {"count": 0}
	rude.ended.connect(func(): ended.count += 1)
	rude.start({"outings": 0})
	rude.choose_topic("informants_refused")
	_choose_text(rude, "Tell me, or I'll make you.")
	_check(wary.flags.get("threatened", false) and wary.suspicion >= 2, "A threat raises suspicion and is remembered")
	_check(rude.closing, "He ends the conversation")
	rude.start({"outings": 1})
	_check(rude.text.contains("Keep your hands where I can see them"), "Next time he greets the threat: " + rude.text)
	# State survives a save as JSON.
	var copy := State.new()
	copy.restore(JSON.parse_string(JSON.stringify(state.encode())))
	_check(copy.stage(GIRTS) == "trusted" and copy.told.has("p_reds_why") and copy.flags.get("asked_military", false) and copy.trust == state.trust, "Relationship and memory survive saving")
	# Limited trade stock.
	var runtime := Runtime.new()
	runtime.stock.add(&"rubles", 200)
	var pack := Inventory.new()
	var trade := Trade.new(GIRTS, copy, runtime)
	trade.destinations = [pack]
	trade.restock(0)
	var bought := 0
	while trade.buy("bread", &"rubles"): bought += 1
	_check(bought == 3 and not trade.can_buy("bread", &"rubles") and pack.items.values().filter(func(item): return item.kind == &"supply" and item.supply_id == &"rye_bread").size() == 3, "He has three loaves, then none")
	trade.restock(2)
	_check(trade.offers().filter(func(offer): return offer.id == "bread")[0].left == 2, "Two outings later two loaves are back")
	# A second NPC on the same code.
	var arvids = Database.load_file(ARVIDS.dialogue_path)
	var lookout := Controller.new(ARVIDS, State.new(), arvids)
	lookout.start({"outings": 0})
	_check(arvids.error == "" and lookout.text.contains("Arvīds") and _topic_ids(lookout).has("watch"), "A second NPC runs on the same system")
	# In the camp: F, Talk, topics, Escape, Goodbye; the state goes into the camp save.
	var startup = load("res://startup/startup.tscn").instantiate()
	root.add_child(startup)
	current_scene = startup
	await _frames(2)
	startup.launch_camp()
	await _frames(10)
	var camp = startup.content
	camp.old_man.interact(camp.player)
	await _frames(1)
	camp.npcs.menu.action_chosen.emit(&"talk")
	await _frames(2)
	var window = camp.npcs.dialogue
	_check(window.visible and window.name_label.text == "Ģirts Ozoliņš" and window.speech.text.length() > 10 and window.replies.get_child_count() > 2, "Talk opens his dialogue window with a greeting and replies")
	camp.npcs.controller.show_topics()
	await _frames(1)
	_check(window.topics_box.visible and window.categories.get_child_count() >= 1 and window.topic_list.get_child_count() >= 1, "The topic view lists categories and topics")
	camp.npcs.controller.choose_topic("weather")
	await _frames(1)
	_check(window.conversation_box.visible and camp.npcs.controller.node_id == "st_weather", "Choosing a topic shows his answer")
	var escape := InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	Input.parse_input_event(escape)
	await _frames(2)
	_check(window.topics_box.visible, "Escape goes back to the topics")
	camp.npcs.controller.goodbye()
	await _frames(1)
	_check(camp.npcs.controller.closing and window.continue_button.visible, "Goodbye shows his parting line")
	window.continue_button.emit_signal("pressed")
	await _frames(1)
	_check(not camp.npcs.is_open() and camp.player.process_mode == Node.PROCESS_MODE_INHERIT, "Then the window closes and the player has control")
	var saved: Dictionary = camp.camp_state()
	_check(saved.npcs.has("girts") and saved.npcs.girts.flags.get("met", false) and saved.npcs.girts.told.has("st_weather") and saved.npcs.has("arvids"), "Both NPCs' state goes into the camp save")
	startup.queue_free()
	await _frames(2)
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: NPC dialogue: 60+ valid nodes, first/varied/contextual greetings, relationship-gated topics and branches, remembered threat, saved state, limited trade, second NPC, camp window flow")
	quit(0 if failures.is_empty() else 1)
