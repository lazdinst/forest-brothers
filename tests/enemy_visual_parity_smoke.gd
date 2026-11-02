extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func check(ok: bool, text: String) -> void:
	if not ok:
		failures.append(text)
func snapshot(enemy, counters: Dictionary) -> Dictionary:
	return {"health":enemy.body.health.duplicate(),"body":enemy.body.state,"state":enemy.state,"recognition":snappedf(enemy.recognition,0.001),"search":snappedf(enemy.search_left,0.001),"position":enemy.global_position.snapped(Vector3.ONE*0.001),"facing":snappedf(enemy.rotation.y,0.001),"velocity":enemy.velocity.snapped(Vector3.ONE*0.001),"shots":counters.shots,"hits":counters.hits,"defeats":counters.defeats,"layer":enemy.collision_layer,"body_disabled":enemy.get_node("Body").disabled}
func exercise(use_mesh: bool) -> Array:
	var world = load("res://scenes/prototype/camp_test.tscn").instantiate()
	root.add_child(world)
	await frames(12)
	var annex = world.get_node("SystemsAnnex")
	var player = world.get_node("Player")
	annex.use_mpfb_enemy = use_mesh
	annex.reset_enemies()
	var enemy = annex.enemies[0]
	var counters := {"shots":0,"hits":0,"defeats":0}
	enemy.fired.connect(func(_e,_t,hit): counters.shots+=1; counters.hits+=1 if hit else 0)
	enemy.defeated.connect(func(_e): counters.defeats+=1)
	player.global_position = annex.global_position+Vector3(-4,0.02,-8)
	player.velocity = Vector3.ZERO
	await frames(4)
	check(enemy.can_see(player),"Parity fixture starts with a visible player")
	enemy.active = true
	var trace: Array = []
	for i in range(4):
		await frames(30)
		trace.append(snapshot(enemy,counters))
	check(counters.shots>0 and counters.hits>0,"Both variants recognize and fire through clear LOS")
	player.global_position = annex.global_position+Vector3(-4,0.02,-2)
	player.velocity = Vector3.ZERO
	await frames(3)
	check(not enemy.can_see(player),"Same physical cover blocks both variants")
	enemy.hear_noise(player.global_position)
	for i in range(7):
		await frames(60)
		trace.append(snapshot(enemy,counters))
	enemy.receive_hit(40,enemy.global_position+Vector3.UP,Vector3.FORWARD,player)
	trace.append(snapshot(enemy,counters))
	check(enemy.body.health[&"torso"]==40,"Visual choice does not change nonlethal damage")
	enemy.receive_hit(80,enemy.global_position+Vector3.UP,Vector3.FORWARD,player)
	await frames(3)
	trace.append(snapshot(enemy,counters))
	enemy.receive_hit(40,enemy.global_position+Vector3.UP,Vector3.FORWARD,player)
	await frames(75)
	trace.append(snapshot(enemy,counters))
	check(enemy.body.is_dead() and counters.defeats==1 and enemy.get_node("Body").disabled,"Death resolves once and disables the same collider")
	var stock_before: int = world.stock.count(&"food")
	var ammo_before: int = player.weapon.state.total_rounds()
	annex._toggle_enemy_comparison()
	await frames(3)
	check(annex.use_mpfb_enemy != use_mesh and annex.enemies[0].body.is_alive(),"Comparison toggle resets the bout with the other visual")
	check(player.weapon.state.total_rounds()==ammo_before and world.stock.count(&"food")==stock_before,"Visual comparison does not change supplies or ammunition")
	world.queue_free()
	await frames(3)
	return trace
func _run() -> void:
	var sprite_trace: Array = await exercise(false)
	var mesh_trace: Array = await exercise(true)
	check(sprite_trace.size()==14 and mesh_trace.size()==14,"Both gameplay traces completed")
	check(sprite_trace==mesh_trace,"Sprite and MPFB yield identical AI/facing/movement/fire/health/death traces")
	if sprite_trace!=mesh_trace:
		for i in range(mini(sprite_trace.size(),mesh_trace.size())):
			if sprite_trace[i]!=mesh_trace[i]:
				print("Parity difference at ",i,": ",sprite_trace[i]," / ",mesh_trace[i])
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("PASS: sprite/MPFB identical recognition, cover, movement/facing, search, firing, health, one-time death/collider, comparison reset and conserved supplies")
	quit(0 if failures.is_empty() else 1)
