extends StaticBody3D
## Finite training cartridge crate. Each use moves a handful of loose rounds into carried inventory;
## the player still fills magazines by hand. Rounds leave the crate, so nothing is created from a pool.
@export var rounds: int = 120
@export var handful: int = 10

func get_prompt() -> String:
	if rounds <= 0:
		return "Ammunition crate is empty"
	return "F  Take %d loose cartridges (%d left in crate)" % [mini(handful, rounds), rounds]

func interact(actor: Node) -> void:
	take(actor)

## Returns how many rounds moved; 0 when the crate is empty or the carrier has no room.
func take(actor: Node) -> int:
	if rounds <= 0 or actor == null or not ("weapon" in actor):
		return 0
	var weapon_state = actor.weapon.state
	var amount := mini(handful, rounds)
	if not weapon_state.inventory.can_add_loose(amount):
		return 0
	weapon_state.loose_rounds += amount
	rounds -= amount
	return amount
