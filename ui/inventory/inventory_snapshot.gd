extends RefCounted
## Read-only view data. This adapter never spends, transfers, equips or refills items.

static func from_training(player: Node, stock) -> Dictionary:
	var state = player.weapon.state
	return {
		"demo": false, "character_name": "Your character", "appearance": player.get_node_or_null("BodyVisual"),
		"rifle": state.definition.display_name.capitalize(), "loaded": state.magazines[state.loaded_magazine],
		"spare": state.magazines[1 - state.loaded_magazine], "loose": state.loose_rounds,
		"capacity": state.definition.capacity, "cleanliness": roundi(state.cleanliness * 100),
		"jammed": state.jammed, "stock": stock.quantities.duplicate(true),
		"outfit": {}, "pack_items": [],
	}

static func demo() -> Dictionary:
	return {
		"demo": true, "character_name": "Character & equipment", "appearance": null,
		"rifle": "SVT-inspired test rifle", "loaded": 10, "spare": 0, "loose": 30,
		"capacity": 10, "cleanliness": 100, "jammed": false,
		"stock": {&"food": 12, &"water": 8, &"medicine": 3, &"cloth": 6, &"timber": 18, &"parts": 4, &"rounds": 40},
		"outfit": {"head": "Wool cap", "outer": "Field jacket", "legs": "Trousers", "feet": "Boots", "back": "Canvas pack", "belt": "Belt pouches"},
		"pack_items": [
			{"id": "cape", "title": "Folded coat", "quantity": "1", "kind": "cloth", "span": Vector2i(3, 2)},
			{"id": "flask", "title": "Flask", "quantity": "1", "kind": "water", "span": Vector2i(1, 2)},
			{"id": "bread", "title": "Bread", "quantity": "1", "kind": "food", "span": Vector2i(2, 1)},
		],
	}
