extends RefCounted
## Local rules: animation resources describe timing but rendering cannot award ammo.
const DEFAULT_DEFINITION = preload("res://weapons/svt_inspired_training.tres")
var definition: Resource
var magazines: Array[int] = []
var loaded_magazine: int = 0
var loose_rounds: int = 0
var cleanliness: float = 1.0
var jammed: bool = false
var busy: StringName = &""
var time_left: float = 0.0
var action_duration: float = 1.0
var cooldown: float = 0.0
var message: String = "Ready"
var _action_committed: bool = false
var _clip: Resource

func _init(content: Resource = DEFAULT_DEFINITION) -> void:
	definition = content
	assert(definition.validation_error() == "", definition.validation_error())
	magazines.assign([definition.initial_loaded, definition.initial_spare])
	loose_rounds = definition.initial_loose

func total_rounds() -> int:
	return loose_rounds + magazines[0] + magazines[1]

func jam_probability() -> float:
	return 0.002 + pow(1.0 - cleanliness, 2.0) * 0.3

func start_action(action: StringName) -> bool:
	if busy != &"":
		return false
	var clip = definition.get_clip(action)
	if clip == null:
		return false
	if action == &"pack" and (loose_rounds <= 0 or magazines[1 - loaded_magazine] >= definition.capacity):
		return false
	if action == &"clear" and not jammed:
		return false
	_clip = clip
	action_duration = clip.duration
	busy = action
	time_left = action_duration
	_action_committed = false
	message = String(action).capitalize()
	return true

func action_progress() -> float:
	return clampf(1.0 - time_left / action_duration, 0.0, 1.0)

func cancel_action() -> void:
	# Before commit, contents stay unchanged. After commit, keep the real transfer.
	busy = &""
	time_left = 0.0
	_clip = null
	message = "Action stopped"

func cancel_packing() -> void:
	if busy == &"pack":
		cancel_action()

func advance(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if busy == &"":
		return
	time_left = maxf(0.0, time_left - delta)
	if not _action_committed and action_progress() + 0.00001 >= _clip.commit_at:
		_commit_action()
		_action_committed = true
	if time_left > 0.0:
		return
	busy = &""
	_clip = null
	message = "JAMMED - J to clear" if jammed else "Ready"

func _commit_action() -> void:
	match busy:
		&"pack":
			var spare := 1 - loaded_magazine
			if loose_rounds > 0 and magazines[spare] < definition.capacity:
				loose_rounds -= 1
				magazines[spare] += 1
		&"reload": loaded_magazine = 1 - loaded_magazine
		&"clear": jammed = false
		&"clean": cleanliness = 1.0

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
	cooldown = definition.fire_interval
	message = "Fired"
	return true
