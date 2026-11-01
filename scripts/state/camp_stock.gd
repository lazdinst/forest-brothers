extends RefCounted
## A session-owned stock ledger. No global player or persistent save is assumed.

signal changed

var quantities: Dictionary = {&"food":0,&"water":0,&"medicine":0,&"meals":0,&"timber":0,&"parts":0,&"cloth":0,&"rounds":0}


func add(item_id: StringName, amount: int) -> void:
	if amount <= 0 or not quantities.has(item_id):
		push_error("Invalid prototype supply: %s / %d" % [item_id, amount])
		return
	quantities[item_id] += amount
	changed.emit()


func count(item_id: StringName) -> int:
	return quantities.get(item_id, 0)


func try_exchange(costs: Dictionary, outputs: Dictionary) -> bool:
	# Validate every entry before any mutation; shortages cannot partially spend.
	for group in [costs, outputs]:
		for id in group:
			if not quantities.has(id) or not group[id] is int or group[id] < 0:
				return false
	for id in costs:
		if quantities[id] < costs[id]:
			return false
	for id in costs:
		quantities[id] -= costs[id]
	for id in outputs:
		quantities[id] += outputs[id]
	changed.emit()
	return true
