extends SceneTree
## Real F5 scene checks: deadwood cover, hollow openings and vault clearance.
const Layout=preload("res://scripts/environment/forest_layout.gd")
var world: Node3D
var player
var failures: Array[String]=[]

func _initialize() -> void:
	call_deferred("_run")

func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func _check(ok: bool,message: String) -> void:
	if not ok:
		failures.append(message)

func _ray(a: Vector3,b: Vector3) -> Dictionary:
	return world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,1,[player.get_rid()]))

func _run() -> void:
	world=load("res://scenes/prototype/camp_test.tscn").instantiate()
	root.add_child(world)
	player=world.get_node("Player")
	await _frames(15)
	var debris=world.get_node("WoodlandProps/PineDebris")
	var fresh=debris.get_node("FallenPine01")
	var rotten=debris.get_node("RottenPine01")
	var fresh_hit:=_ray(fresh.to_global(Vector3(-3.1,0.42,1.2)),fresh.to_global(Vector3(-3.1,0.42,-1.2)))
	_check(not fresh_hit.is_empty() and fresh_hit.collider==fresh.get_node("Body"),"Fallen pine wood blocks world/shot rays")
	var rotten_hit:=_ray(rotten.to_global(Vector3(-3.3,0.32,1.2)),rotten.to_global(Vector3(-3.3,0.32,-1.2)))
	_check(not rotten_hit.is_empty() and rotten_hit.collider==rotten.get_node("Body"),"Rotten log sidewall remains physical cover")
	_check(_ray(rotten.to_global(Vector3(-4.3,0.32,0)),rotten.to_global(Vector3(-3.45,0.32,0))).is_empty(),"Hollow end opening is not filled by an invisible solid box")
	for prop in debris.get_children():
		if prop.name.begins_with("LooseBranch"):
			_check(prop.find_children("*","CollisionObject3D",true,false).is_empty(),"Small decorative branches do not create movement/shot blockers")
	# Approach the branch-free butt section, not through a projecting limb.
	var at: Vector3=fresh.to_global(Vector3(-4.0,0,1.1))
	player.position=Vector3(at.x,Layout.height(at.x,at.z)+0.025,at.z)
	player.velocity=Vector3.ZERO
	var forward: Vector3=-fresh.global_basis.z
	player.rotation=Vector3(0,atan2(-forward.x,-forward.z),0)
	player.camera.rotation=Vector3.ZERO
	await _frames(15)
	_check(player.try_vault(),"Existing controller can vault the thick end of the fallen pine")
	await _frames(50)
	_check(not player.is_vaulting and fresh.to_local(player.global_position).z<0,"Pine vault finishes on a clear opposite-side landing")
	if DisplayServer.get_name()!="headless":
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--evidence="):
				var directory:=arg.trim_prefix("--evidence=")
				DirAccess.make_dir_recursive_absolute(directory)
				player.set_physics_process(false)
				for entry in [[fresh,"fallen_in_forest"],[rotten,"rotten_in_forest"]]:
					var prop: Node3D=entry[0]
					var eye: Vector3=prop.to_global(Vector3(-1.5,0,3.6))
					player.position=Vector3(eye.x,Layout.height(eye.x,eye.z)+0.03,eye.z)
					player.camera.look_at(prop.to_global(Vector3(0,0.4,0)))
					await _frames(15)
					await RenderingServer.frame_post_draw
					_check(root.get_texture().get_image().save_png(directory.path_join(entry[1]+".png"))==OK,"Save actual forest context")
	for failure in failures:
		push_error(failure)
	print("PINE DEBRIS CHECK: ","PASS" if failures.is_empty() else "FAIL")
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
