extends RefCounted
## Authored dialogue for one NPC, read from a JSON file: greetings (contextual, by priority),
## the choices offered after a greeting, topic categories, topics and the nodes they lead to,
## visit rules, and goodbyes. This is the authored dialogue provider; a different provider
## (for example a generated one) only needs the same methods. See docs/NPC_DIALOGUE.md.
var greetings: Array = []
var greeting_choices: Array = []
var categories: Array = []
var topics: Array = []
var nodes: Dictionary = {}
var visit_rules: Array = []
var goodbyes: Array = []
var error := ""

static func load_file(path: String):
	var database = new()
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not parsed is Dictionary:
		database.error = "Dialogue file missing or not valid JSON: " + path
		push_error(database.error)
		return database
	database.greetings = parsed.get("greetings", [])
	database.greeting_choices = parsed.get("greeting_choices", [])
	database.categories = parsed.get("categories", [])
	database.topics = parsed.get("topics", [])
	database.nodes = parsed.get("nodes", {})
	database.visit_rules = parsed.get("visit_rules", [])
	database.goodbyes = parsed.get("goodbyes", [])
	database.error = database.validate()
	if database.error != "": push_error("%s: %s" % [path, database.error])
	return database

func node(id: String) -> Dictionary:
	return nodes.get(id, {})

## Every link points at a node that exists; returns the first problem, or "".
func validate() -> String:
	for topic in topics:
		if not nodes.has(topic.get("start", "")): return "Topic %s starts at missing node %s" % [topic.get("id", "?"), topic.get("start", "")]
		if not categories.any(func(category): return category.id == topic.get("category", "")): return "Topic %s has unknown category" % topic.get("id", "?")
	for id in nodes:
		for choice in nodes[id].get("choices", []):
			if choice.has("next") and not nodes.has(choice.next): return "Node %s links to missing node %s" % [id, choice.next]
			if choice.has("topic") and not topics.any(func(topic): return topic.id == choice.topic): return "Node %s links to missing topic %s" % [id, choice.topic]
	for choice in greeting_choices:
		if choice.has("next") and not nodes.has(choice.next): return "A greeting choice links to missing node %s" % choice.next
	return ""

func topic(id: String) -> Dictionary:
	for entry in topics:
		if entry.id == id: return entry
	return {}
