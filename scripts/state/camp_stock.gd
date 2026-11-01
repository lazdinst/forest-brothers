extends RefCounted
## A session-owned stock ledger. No global player or persistent save is assumed.

signal changed

var quantities: Dictionary = {&"food": 0, &"water": 0, &"medicine": 0}


func add(item_id: StringName, amount: int) -> void:
	if amount <= 0 or not quantities.has(item_id):
		push_error("Invalid prototype supply: %s / %d" % [item_id, amount])
		return
	quantities[item_id] += amount
	changed.emit()


func count(item_id: StringName) -> int:
	return quantities.get(item_id, 0)
