extends RefCounted
## Rules-only condition of one player, modelled on Escape from Tarkov: seven body parts with
## their own health, light and heavy bleeding, fractures, pain, shock, suppression, energy and
## hydration, tourniquets, field surgery, wound infection, and timed treatment with physical
## supplies, on oneself or on a teammate, and revival of a downed teammate. No scene nodes: the player adapter
## feeds hits and time, presentation reads effects(). Every number is a placeholder, not
## approved balance. Confirmed rules kept: head at zero kills, thorax (torso) at zero downs,
## any hit on a downed body kills. Enemies keep the simpler BodyHealth.
const SupplyCatalog = preload("res://scripts/health/supply_catalog.gd")
signal changed

# Outcomes shared with BodyHealth so callers treat players and enemies alike.
const NONE := &"none"
const LIMB_DISABLED := &"limb_disabled"
const DOWNED := &"downed"
const KILLED := &"killed"
const OUTCOME_RANK := {NONE:0,LIMB_DISABLED:1,DOWNED:2,KILLED:3}
## Which supply to reach for first when several would help: the plainest that does the job.
const CARE_PREFERENCE: Array[StringName] = [&"cloth_bandage", &"field_dressing", &"tourniquet", &"splint", &"sulfa_powder", &"medical_satchel", &"surgical_kit"]

const HEAD := &"head"
const THORAX := &"thorax"
const STOMACH := &"stomach"
const LEFT_ARM := &"left_arm"
const RIGHT_ARM := &"right_arm"
const LEFT_LEG := &"left_leg"
const RIGHT_LEG := &"right_leg"
const ZONES: Array[StringName] = [HEAD, THORAX, STOMACH, LEFT_ARM, RIGHT_ARM, LEFT_LEG, RIGHT_LEG]
const ARMS: Array[StringName] = [LEFT_ARM, RIGHT_ARM]
const LEGS: Array[StringName] = [LEFT_LEG, RIGHT_LEG]
const LABELS := {HEAD:"Head",THORAX:"Thorax",STOMACH:"Stomach",LEFT_ARM:"Left arm",RIGHT_ARM:"Right arm",LEFT_LEG:"Left leg",RIGHT_LEG:"Right leg"}
## Tarkov's part pools (440 in total).
const PLACEHOLDER_MAX := {HEAD:35.0,THORAX:85.0,STOMACH:70.0,LEFT_ARM:60.0,RIGHT_ARM:60.0,LEFT_LEG:65.0,RIGHT_LEG:65.0}

# Placeholder tuning.
var light_bleed_chance := 0.35
var heavy_bleed_chance := 0.12
var fracture_chance := 0.2
var light_bleed_rate := 0.4 # health per second from the bleeding part
var heavy_bleed_rate := 1.4
var destroyed_spread := 0.7 # damage to a destroyed part spreads to the others at this fraction
var energy_drain := 1.0 / 36.0 # per second: about an hour from full
var hydration_drain := 1.0 / 24.0
var sprint_drain_factor := 2.0
var starvation_damage := 0.12 # per second to thorax and stomach while energy or water is empty
var pain_after_hit := 25.0 # seconds of pain after a heavy hit
var shock_after_hit := 6.0
var suppression_decay := 0.35
var tourniquet_drain := 0.3 # health per second lost by a limb under a tourniquet
var wound_threshold := 8.0 # a hit at least this hard leaves an open wound
var infection_onset := 480.0 # seconds an untreated wound waits before it may turn infected
var infection_chance := 0.5
var infection_drain := 0.05 # health per second from an infected limb or stomach
var fever_drain_factor := 1.5 # energy and water drain faster with any infection
var surgery_restore := 0.3 # fraction of the shrunken maximum a destroyed part returns to
var surgery_max_loss := 0.2 # fraction of the part's maximum lost for good by each surgery
var bleed_out_seconds := 60.0 # how long a downed body waits for revival
var revive_seconds := 8.0
var revive_thorax := 20.0 # thorax health after revival
var revived_weakness := 300.0 # seconds of reduced capability after revival

var state: StringName = &"alive"
var max_health := {}
var health := {}
var light_bleeding := {}
var heavy_bleeding := {}
var fractured := {}
var tourniquet := {}
## Seconds until an open wound may turn infected; negative when there is no open wound.
var wound_left := {}
var infected := {}
var energy := 100.0
var hydration := 100.0
var painkiller_left := 0.0
var pain_left := 0.0
var shock_left := 0.0
var suppression := 0.0
## Seconds left before a downed body bleeds out.
var downed_left := 0.0
## Seconds of reduced capability left after a revival; injuries are kept.
var revived_left := 0.0
var rng := RandomNumberGenerator.new()
## In-progress treatment, or empty: {item_id, supply_id, part, duration, left, revive}. It
## belongs to the one giving it; the patient may be this body or a teammate's.
var treatment := {}
var _treatment_inventory
var _treatment_patient

func _init(max_values: Dictionary = PLACEHOLDER_MAX) -> void:
	for part in ZONES:
		max_health[part] = float(max_values.get(part,PLACEHOLDER_MAX[part]))
		health[part] = max_health[part]
		light_bleeding[part] = false
		heavy_bleeding[part] = false
		fractured[part] = false
		tourniquet[part] = false
		wound_left[part] = -1.0
		infected[part] = false
	rng.randomize()

func is_alive() -> bool: return state == &"alive"
func is_downed() -> bool: return state == &"downed"
func is_dead() -> bool: return state == &"dead"
func destroyed(part: StringName) -> bool: return health[part] <= 0.0
func total_health() -> float:
	var sum := 0.0
	for part in ZONES: sum += health[part]
	return sum
func total_max() -> float:
	var sum := 0.0
	for part in ZONES: sum += max_health[part]
	return sum

## Hit-zone names from the shared combat zones map onto parts; side and height pick the exact part.
static func part_for(zone: StringName, right_side := true, upper := true) -> StringName:
	match zone:
		&"head": return HEAD
		&"torso": return THORAX if upper else STOMACH
		&"arms": return RIGHT_ARM if right_side else LEFT_ARM
		&"legs": return RIGHT_LEG if right_side else LEFT_LEG
	return zone if PLACEHOLDER_MAX.has(zone) else THORAX

func apply_damage(part: StringName, amount: float, roll_injuries := true) -> StringName:
	if not health.has(part): part = part_for(part)
	if state == &"dead" or amount <= 0.0: return NONE
	if state == &"downed":
		state = &"dead"
		changed.emit()
		return KILLED
	var outcome := _damage(part,amount)
	if state == &"alive" and roll_injuries: _roll_injuries(part,amount)
	if state == &"alive" and amount >= wound_threshold and not infected[part] and wound_left[part] < 0.0: wound_left[part] = infection_onset
	if amount >= 20.0: pain_left = maxf(pain_left,pain_after_hit)
	if amount >= 30.0: shock_left = maxf(shock_left,shock_after_hit)
	if outcome != NONE: cancel_treatment()
	changed.emit()
	return outcome

func bleed_out() -> StringName:
	if state != &"downed": return NONE
	state = &"dead"
	changed.emit()
	return KILLED

## A near miss: drives the suppression effect, not damage.
func suppress(amount := 0.35) -> void:
	suppression = minf(1.0,suppression+amount)

func _damage(part: StringName, amount: float) -> StringName:
	# Like Tarkov, damage to a destroyed limb or stomach spreads to every part still standing.
	if destroyed(part) and part != HEAD and part != THORAX:
		var others := ZONES.filter(func(other): return other != part and not destroyed(other))
		if others.is_empty(): return NONE
		var worst := NONE
		for other in others: worst = _worse(worst,_hit(other,amount*destroyed_spread/others.size()))
		return worst
	return _hit(part,amount)

func _hit(part: StringName, amount: float) -> StringName:
	if state != &"alive": return NONE
	health[part] = maxf(0.0,health[part]-amount)
	if health[part] > 0.0: return NONE
	if part == HEAD:
		state = &"dead"
		return KILLED
	if part == THORAX:
		state = &"downed"
		downed_left = bleed_out_seconds
		return DOWNED
	return LIMB_DISABLED

static func _worse(a: StringName, b: StringName) -> StringName:
	return a if OUTCOME_RANK[a] >= OUTCOME_RANK[b] else b

func _roll_injuries(part: StringName, amount: float) -> void:
	var scale := clampf(amount/35.0,0.3,1.5)
	if rng.randf() < heavy_bleed_chance*scale: heavy_bleeding[part] = true
	elif rng.randf() < light_bleed_chance*scale: light_bleeding[part] = true
	if part in ARMS+LEGS and rng.randf() < fracture_chance*scale: fractured[part] = true

## Time passes: bleeding, hunger, thirst, effect timers and treatment. Returns the worst outcome.
func advance(delta: float, sprinting := false) -> StringName:
	if state == &"dead" or delta <= 0.0: return NONE
	var outcome := NONE
	var flags_before := _flag_signature()
	if state == &"downed":
		downed_left -= delta
		if downed_left <= 0.0: outcome = bleed_out()
	if state == &"alive":
		for part in ZONES:
			var rate := (heavy_bleed_rate if heavy_bleeding[part] else 0.0) + (light_bleed_rate if light_bleeding[part] else 0.0)
			if rate > 0.0: outcome = _worse(outcome,_damage(part,rate*delta))
		for part in ZONES:
			if tourniquet[part] and not destroyed(part): outcome = _worse(outcome,_hit(part,tourniquet_drain*delta))
			if infected[part] and part != HEAD and part != THORAX: outcome = _worse(outcome,_damage(part,infection_drain*delta))
			if wound_left[part] >= 0.0:
				wound_left[part] -= delta
				if wound_left[part] < 0.0 and rng.randf() < infection_chance: infected[part] = true
		var factor := (sprint_drain_factor if sprinting else 1.0) * (fever_drain_factor if has_fever() else 1.0)
		energy = maxf(0.0,energy-energy_drain*factor*delta)
		hydration = maxf(0.0,hydration-hydration_drain*factor*delta)
		if energy <= 0.0 or hydration <= 0.0:
			for part in [THORAX,STOMACH]: outcome = _worse(outcome,_damage(part,starvation_damage*delta))
	painkiller_left = maxf(0.0,painkiller_left-delta)
	pain_left = maxf(0.0,pain_left-delta)
	shock_left = maxf(0.0,shock_left-delta)
	suppression = maxf(0.0,suppression-suppression_decay*delta)
	revived_left = maxf(0.0,revived_left-delta)
	if not treatment.is_empty():
		var patient = _treatment_patient
		if state != &"alive" or patient.is_dead() or patient.is_downed() != treatment.revive: cancel_treatment()
		else:
			treatment.left -= delta
			if treatment.left <= 0.0: _finish_treatment()
	if outcome != NONE or _flag_signature() != flags_before: changed.emit()
	return outcome

func _flag_signature() -> String:
	return str([state,light_bleeding.values(),heavy_bleeding.values(),fractured.values(),tourniquet.values(),infected.values(),in_pain(),in_shock(),hungry(),dehydrated(),painkiller_left > 0.0,revived_left > 0.0,treatment.get("item_id","")])

# --- Effects read by presentation (HUD, inventory) -------------------------------------------

func bleeding_parts(heavy: bool) -> Array[StringName]:
	var source := heavy_bleeding if heavy else light_bleeding
	var parts: Array[StringName] = []
	for part in ZONES:
		if source[part]: parts.append(part)
	return parts

func fractured_parts() -> Array[StringName]: return _parts_where(fractured)
func tourniquet_parts() -> Array[StringName]: return _parts_where(tourniquet)
func infected_parts() -> Array[StringName]: return _parts_where(infected)
func open_wound_parts() -> Array[StringName]:
	var parts: Array[StringName] = []
	for part in ZONES:
		if wound_left[part] >= 0.0: parts.append(part)
	return parts

func _parts_where(flags: Dictionary) -> Array[StringName]:
	var parts: Array[StringName] = []
	for part in ZONES:
		if flags[part]: parts.append(part)
	return parts

## Any infection brings fever: faster hunger and thirst and a less steady aim.
func has_fever() -> bool: return state == &"alive" and not infected_parts().is_empty()

func in_pain() -> bool:
	if painkiller_left > 0.0 or state != &"alive": return false
	if pain_left > 0.0 or not fractured_parts().is_empty() or not tourniquet_parts().is_empty(): return true
	for part in ZONES:
		if part != HEAD and part != THORAX and destroyed(part): return true
	return false

## Tunnel vision after a heavy hit or with heavy blood loss.
func in_shock() -> bool:
	return state == &"alive" and (shock_left > 0.0 or total_health() < total_max()*0.3)
func hungry() -> bool: return energy < 20.0
func dehydrated() -> bool: return hydration < 20.0

## Snapshot for HUD effects and other presentation. Read-only; changing it changes nothing.
func effects() -> Dictionary:
	return {
		"state":state,"light_bleeding":bleeding_parts(false),"heavy_bleeding":bleeding_parts(true),
		"fractures":fractured_parts(),"tourniquets":tourniquet_parts(),"infections":infected_parts(),
		"open_wounds":open_wound_parts(),"fever":has_fever(),"pain":in_pain(),"painkiller_seconds":painkiller_left,
		"shock":in_shock(),"suppression":suppression,"energy":energy,"hydration":hydration,
		"hungry":hungry(),"dehydrated":dehydrated(),"health":total_health(),"max_health":total_max(),
		"treating":treatment.get("supply_id",&""),"treatment_progress":treatment_progress(),
		"reviving":treatment.get("revive",false),"bleed_out_seconds":downed_left if state == &"downed" else 0.0,
		"revived_seconds":revived_left,
	}

# --- Movement and handling limits ------------------------------------------------------------

func _leg_impaired() -> bool:
	for part in LEGS:
		if fractured[part] or tourniquet[part] or destroyed(part): return true
	return false

func can_sprint() -> bool:
	return state == &"alive" and hydration > 0.0 and revived_left <= 0.0 and (painkiller_left > 0.0 or not _leg_impaired())

func speed_multiplier() -> float:
	var multiplier := 1.0
	if _leg_impaired() and painkiller_left <= 0.0: multiplier *= 0.7
	if energy <= 0.0 or hydration <= 0.0: multiplier *= 0.85
	if revived_left > 0.0: multiplier *= 0.8
	return multiplier

## For weapon presentation: broken or destroyed arms and pain make aim less steady.
func aim_sway_multiplier() -> float:
	var multiplier := 1.0
	for part in ARMS:
		if (fractured[part] or tourniquet[part] or destroyed(part)) and painkiller_left <= 0.0: multiplier *= 1.4
	if in_pain(): multiplier *= 1.2
	if has_fever(): multiplier *= 1.15
	if revived_left > 0.0: multiplier *= 1.2
	return multiplier

# --- Treatment ------------------------------------------------------------------------------

## Why a supply cannot be used on a part right now; empty when it can.
func treatment_problem(def: Dictionary, part: StringName, uses: int) -> String:
	if def.is_empty(): return "Not a usable supply"
	if state != &"alive": return "Cannot treat while incapacitated"
	if not def.get("targets_part",false):
		if def.has("painkiller"): return ""
		if def.get("energy",0.0) > 0.0 and energy >= 100.0: return "Not hungry"
		if def.get("hydration",0.0) > 0.0 and hydration >= 100.0: return "Not thirsty"
		return ""
	if not health.has(part): return "Choose a body part"
	if def.get("fixes_fracture",false): return "" if fractured[part] else "Nothing broken there"
	if def.get("applies_tourniquet",false):
		if part not in ARMS+LEGS: return "Only on an arm or leg"
		return "" if heavy_bleeding[part] else "No heavy bleeding there"
	if def.get("surgery",false):
		if part == HEAD or part == THORAX: return "Only for an arm, leg or stomach"
		return "" if destroyed(part) else "Only for a destroyed part"
	if def.get("disinfects",false):
		return "" if infected[part] or wound_left[part] >= 0.0 else "No open wound there"
	if def.get("heals",false):
		if destroyed(part) and part != THORAX: return "A destroyed part needs surgery"
		if heavy_bleeding[part] and uses >= int(def.heavy_cost): return ""
		if (light_bleeding[part] or tourniquet[part]) and uses >= int(def.light_cost): return ""
		if heavy_bleeding[part] or light_bleeding[part] or tourniquet[part]: return "Not enough supply left"
		return "" if health[part] < max_health[part] else "Already healthy"
	if def.get("stops_heavy",false) and (heavy_bleeding[part] or tourniquet[part]): return ""
	if def.get("stops_light",false) and light_bleeding[part]: return ""
	if tourniquet[part]: return "Needs a field dressing to replace the tourniquet"
	return "No bleeding there"

## The most urgent part this supply can help: heavy bleed, light bleed, fracture, then most hurt.
func best_part_for(def: Dictionary, uses: int) -> StringName:
	if not def.get("targets_part",false): return &""
	var candidates := ZONES.filter(func(part): return treatment_problem(def,part,uses) == "")
	if candidates.is_empty(): return &""
	candidates.sort_custom(func(a, b): return _urgency(a) > _urgency(b))
	return candidates[0]

## The carried supply and part that best treat this body's most urgent injury, as
## {item_id, part}, or empty when nothing carried helps. Used for quick teammate care.
func best_supply_in(inventory) -> Dictionary:
	var best := {}
	var best_score := -INF
	for item in inventory.items.values():
		if item.kind != &"supply" or not inventory.carried(item): continue
		var part := best_part_for(SupplyCatalog.get_def(item.supply_id),item.uses)
		if part == &"": continue
		var rank := CARE_PREFERENCE.find(item.supply_id)
		var score := _urgency(part) - (rank if rank >= 0 else CARE_PREFERENCE.size())
		if score > best_score:
			best_score = score
			best = {"item_id":item.id,"part":part}
	return best

## A carried supply that can revive a downed body, plainest first, or empty.
static func revive_supply_in(inventory) -> StringName:
	var best: StringName = &""
	var best_rank := INF
	for item in inventory.items.values():
		if item.kind != &"supply" or not inventory.carried(item) or not SupplyCatalog.get_def(item.supply_id).get("revives",false): continue
		var rank := CARE_PREFERENCE.find(item.supply_id)
		if rank < best_rank:
			best_rank = rank
			best = item.id
	return best

func _urgency(part: StringName) -> float:
	return (300.0 if heavy_bleeding[part] else 0.0) + (200.0 if light_bleeding[part] else 0.0) + (150.0 if tourniquet[part] else 0.0) + (120.0 if infected[part] else 0.0) + (100.0 if fractured[part] else 0.0) + (60.0 if wound_left[part] >= 0.0 else 0.0) + (1.0 - health[part]/max_health[part]) * 50.0

## Starts a timed treatment with a supply this body carries. The patient is this body unless a
## teammate's condition is given; the treatment stays with the giver. An empty part picks the
## most urgent one. Range and line of sight are the adapters' business.
func start_treatment(inventory, item_id: StringName, part: StringName = &"", patient = null) -> String:
	if patient == null: patient = self
	if not treatment.is_empty(): return "Already treating"
	if patient != self and state != &"alive": return "Cannot treat while incapacitated"
	var item = inventory.items.get(item_id)
	if item == null or item.kind != &"supply" or not inventory.carried(item): return "Not a carried supply"
	var def := SupplyCatalog.get_def(item.supply_id)
	if def.get("targets_part",false) and part == &"": part = patient.best_part_for(def,item.uses)
	var problem: String = patient.treatment_problem(def,part,item.uses)
	if problem != "": return problem
	_begin(inventory,item,part,float(def.seconds),patient,false)
	return ""

## Starts reviving a downed teammate with a carried bandage or dressing.
func start_revival(inventory, item_id: StringName, patient) -> String:
	if not treatment.is_empty(): return "Already treating"
	if state != &"alive": return "Cannot revive while incapacitated"
	if patient == null or patient == self or not patient.is_downed(): return "Nobody to revive"
	var item = inventory.items.get(item_id)
	if item == null or item.kind != &"supply" or not inventory.carried(item): return "Not a carried supply"
	if not SupplyCatalog.get_def(item.supply_id).get("revives",false): return "Needs a bandage or dressing"
	_begin(inventory,item,THORAX,revive_seconds,patient,true)
	return ""

func _begin(inventory, item, part: StringName, seconds: float, patient, revive: bool) -> void:
	treatment = {"item_id":item.id,"supply_id":item.supply_id,"part":part,"duration":seconds,"left":seconds,"revive":revive}
	_treatment_inventory = inventory
	_treatment_patient = patient
	changed.emit()

## The condition being treated, or null.
func treatment_patient():
	return null if treatment.is_empty() else _treatment_patient

func treatment_progress() -> float:
	return -1.0 if treatment.is_empty() else clampf(1.0-treatment.left/treatment.duration,0.0,1.0)

func cancel_treatment() -> void:
	if treatment.is_empty(): return
	treatment = {}
	_treatment_inventory = null
	_treatment_patient = null
	changed.emit()

func _finish_treatment() -> void:
	var inventory = _treatment_inventory
	var patient = _treatment_patient
	var record := treatment
	treatment = {}
	_treatment_inventory = null
	_treatment_patient = null
	var item = inventory.items.get(record.item_id) if inventory != null else null
	# The supply must still be on the giver when the treatment completes.
	if item == null or not inventory.carried(item): return
	var cost: int = patient.revive() if record.revive else patient.apply_supply(SupplyCatalog.get_def(record.supply_id),record.part,item.uses)
	if cost > 0: inventory.consume_supply(record.item_id,cost)
	changed.emit()

## Applies a completed treatment to this body. Returns the uses spent, or 0 when it no longer
## applies (the supply is then kept).
func apply_supply(def: Dictionary, part: StringName, uses: int) -> int:
	if treatment_problem(def,part,uses) != "": return 0
	var cost := 1
	if def.get("fixes_fracture",false): fractured[part] = false
	elif def.get("applies_tourniquet",false):
		heavy_bleeding[part] = false
		light_bleeding[part] = false
		tourniquet[part] = true
	elif def.get("surgery",false):
		max_health[part] *= 1.0 - surgery_max_loss
		health[part] = max_health[part] * surgery_restore
		heavy_bleeding[part] = false
		light_bleeding[part] = false
		tourniquet[part] = false
	elif def.get("disinfects",false):
		infected[part] = false
		wound_left[part] = -1.0
	elif def.has("painkiller"): painkiller_left = float(def.painkiller)
	elif SupplyCatalog.is_food(def):
		energy = clampf(energy+float(def.get("energy",0.0)),0.0,100.0)
		hydration = clampf(hydration+float(def.get("hydration",0.0)),0.0,100.0)
	elif def.get("heals",false):
		if heavy_bleeding[part]:
			heavy_bleeding[part] = false
			cost = int(def.heavy_cost)
		elif light_bleeding[part]:
			light_bleeding[part] = false
			cost = int(def.light_cost)
		elif tourniquet[part]:
			tourniquet[part] = false
			cost = int(def.light_cost)
		else:
			cost = mini(uses,ceili(max_health[part]-health[part]))
			health[part] = minf(max_health[part],health[part]+cost)
	else:
		if heavy_bleeding[part] and def.get("stops_heavy",false): heavy_bleeding[part] = false
		elif light_bleeding[part]: light_bleeding[part] = false
		else: tourniquet[part] = false
	changed.emit()
	return cost

## Brings a downed body back: the thorax wound is dressed and holds a little health, every
## other injury stays, and capability stays reduced for a while. Returns the uses spent.
func revive() -> int:
	if state != &"downed": return 0
	state = &"alive"
	downed_left = 0.0
	health[THORAX] = maxf(health[THORAX],revive_thorax)
	heavy_bleeding[THORAX] = false
	light_bleeding[THORAX] = false
	revived_left = revived_weakness
	pain_left = maxf(pain_left,pain_after_hit)
	changed.emit()
	return 1
