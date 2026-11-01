extends RefCounted
## Local range rules, separate from input, art, and hit detection.

const CAPACITY: int = 10
var magazines: Array[int] = [10, 0]
var loaded_magazine: int = 0
var loose_rounds: int = 30
var cleanliness: float = 1.0
var jammed: bool = false
var busy: StringName = &""
var time_left: float = 0.0
var action_duration: float = 1.0
var cooldown: float = 0.0
var message: String = "Ready"


func total_rounds() -> int:
	return loose_rounds + magazines[0] + magazines[1]


func jam_probability() -> float:
	return 0.002 + pow(1.0 - cleanliness, 2.0) * 0.3


func start_action(action: StringName) -> bool:
	if busy != &"":
		return false
	match action:
		&"pack":
			if loose_rounds <= 0 or magazines[1 - loaded_magazine] >= CAPACITY:
				return false
			action_duration = 0.32
		&"reload": action_duration = 1.4
		&"clear":
			if not jammed:
				return false
			action_duration = 0.9
		&"clean": action_duration = 2.2
		&"inspect": action_duration = 0.8
		_: return false
	busy = action
	time_left = action_duration
	message = String(action).capitalize()
	return true


func cancel_packing() -> void:
	if busy == &"pack":
		busy = &""
		time_left = 0.0
		message = "Packing stopped"


func advance(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if busy == &"":
		return
	time_left -= delta
	if time_left > 0.0:
		return
	match busy:
		&"pack":
			var spare := 1 - loaded_magazine
			if loose_rounds > 0 and magazines[spare] < CAPACITY:
				loose_rounds -= 1
				magazines[spare] += 1
		&"reload": loaded_magazine = 1 - loaded_magazine
		&"clear": jammed = false
		&"clean": cleanliness = 1.0
	busy = &""
	time_left = 0.0
	message = "JAMMED - J to clear" if jammed else "Ready"


func try_fire(roll: float) -> bool:
	if busy != &"" or cooldown > 0.0:
		return false
	if jammed:
		message = "JAMMED - J to clear"
		return false
	if magazines[loaded_magazine] <= 0:
		message = "Empty - hold T to pack spare, R to swap"
		return false
	if roll < jam_probability():
		jammed = true
		message = "JAMMED - J to clear"
		return false
	magazines[loaded_magazine] -= 1
	cleanliness = maxf(0.0, cleanliness - 0.008)
	cooldown = 0.22
	message = "Fired"
	return true
