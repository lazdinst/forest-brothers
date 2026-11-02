extends RefCounted
## Read-only view data. This adapter never spends, transfers, equips or refills items.

static func from_training(player: Node) -> Dictionary:
	var state = player.weapon.state
	return {
		"demo": false, "character_name": "Your character", "appearance": player.get_node_or_null("BodyVisual"),
		"rifle": state.definition.display_name.capitalize(), "loaded": state.magazines[state.loaded_magazine],
		"spare": state.magazines[1 - state.loaded_magazine], "loose": state.loose_rounds,
		"capacity": state.definition.capacity, "cleanliness": roundi(state.cleanliness * 100),
		"jammed": state.jammed,
		"outfit": {}, "pack_items": [], "pocket_items": [],
	}

static func demo() -> Dictionary:
	return {
		"demo": true, "character_name": "Character & equipment", "appearance": null,
		"rifle": "SVT-inspired test rifle", "loaded": 10, "spare": 0, "loose": 30,
		"capacity": 10, "cleanliness": 100, "jammed": false,
		"outfit": {"head": "Wool cap", "outer": "Field jacket", "legs": "Trousers", "feet": "Boots", "back": "Canvas pack", "belt": "Belt pouches"},
		"pack_items": [
			{"id": "cape", "title": "Folded coat", "quantity": "1", "kind": "cloth"},
			{"id": "tool", "title": "Tool", "quantity": "1", "kind": "parts"},
		],
		"pocket_items": [
			{"id": "flask", "title": "Flask", "quantity": "1", "kind": "water"},
			{"id": "bread", "title": "Bread", "quantity": "1", "kind": "food"},
		],
	}
