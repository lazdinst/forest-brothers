extends SceneTree
## Additive, seed-stable placement. Keeps original forest transforms untouched.
const Layout=preload("res://scripts/environment/forest_layout.gd")
var rng:=RandomNumberGenerator.new()
var occupied: Array[Vector2]=[]
var trees: Array[Vector2]=[]
var existing_debris: Array[Vector2]=[]
var records: Array=[]
var debris: Node3D

func _initialize() -> void:
	call_deferred("_run")

func _allowed(p: Vector2,angle: float,half_length: float,width: float) -> bool:
	var axis:=Vector2(cos(angle),sin(angle))
	var side:=Vector2(-axis.y,axis.x)
	for step in range(-12,13):
		for lateral in [-width,0.0,width]:
			var point: Vector2=p+axis*half_length*step/12.0+side*lateral
			if point.x< -47 or point.x>24 or point.y< -45 or point.y>38 or Layout.reserved(point,1.2) or Layout.trench_distance(point)<2.2 or absf(point.x-Layout.trail_x(point.y))<1.9:
				return false
	for tree in trees:
		var delta:=tree-p
		if absf(delta.dot(axis))<half_length+0.7 and absf(delta.dot(side))<0.8:
			return false
	for other in existing_debris:
		if other.distance_to(p)<3.0:
			return false
	for other in occupied:
		if other.distance_to(p)<7.0:
			return false
	return true

func _place(id: String,scene_id: String,anchor: Vector2,half_length: float,width: float) -> bool:
	for attempt in range(1200):
		var p: Vector2=anchor+Vector2(rng.randf_range(-5,5),rng.randf_range(-5,5)) if attempt<160 else Vector2(rng.randf_range(-41,22),rng.randf_range(-39,35))
		var angle:=rng.randf()*TAU
		if not _allowed(p,angle,half_length,width):
			continue
		var direction:=Vector2(cos(angle),sin(angle))
		var a:=p-direction*half_length
		var b:=p+direction*half_length
		var x_axis:=Vector3(direction.x,(Layout.height(b.x,b.y)-Layout.height(a.x,a.y))/(half_length*2.0),direction.y).normalized()
		var z_axis:=x_axis.cross(Vector3.UP).normalized()
		var y_axis:=z_axis.cross(x_axis).normalized()
		var basis:=Basis(x_axis,y_axis,z_axis)
		var base_height:=Layout.height(p.x,p.y)
		# Sample the support line, lifting only enough to avoid burying the log.
		for i in range(-8,9):
			var local_x:=half_length*i/8.0
			var world_point:=Vector3(p.x,base_height,p.y)+basis*Vector3(local_x,0,0)
			base_height=maxf(base_height,Layout.height(world_point.x,world_point.z)-basis.x.y*local_x-0.04)
		var prop=load("res://assets/environment/scenes/"+scene_id+".tscn").instantiate()
		prop.name=id
		prop.transform=Transform3D(basis,Vector3(p.x,base_height,p.y))
		debris.add_child(prop)
		prop.owner=debris
		occupied.append(p)
		records.append({"id":id,"asset":scene_id,"at":[p.x,base_height,p.y],"angle":angle})
		return true
	push_error("Cannot find a safe placement for "+id)
	return false

func _run() -> void:
	rng.seed=194611020
	var original=load("res://assets/environment/scenes/training_forest_generated.tscn").instantiate()
	for child in original.get_children():
		if child.name.begins_with("TreeBody"):
			trees.append(Vector2(child.position.x,child.position.z))
		elif child.name.begins_with("Deadwood"):
			existing_debris.append(Vector2(child.position.x,child.position.z))
	original.free()
	debris=Node3D.new()
	debris.name="PineDebris"
	var success:=true
	for entry in [
		["FallenPine01","pine_fallen_v2",Vector2(15,18),5.2,1.5],
		["RottenPine01","pine_rotten_v2",Vector2(19,30),4.0,0.8],
		["FallenPine02","pine_fallen_v2",Vector2(-27,7),5.2,1.5],
		["RottenPine02","pine_rotten_v2",Vector2(-24,30),4.0,0.8],
		["RottenPine03","pine_rotten_v2",Vector2(-31,-20),4.0,0.8],
		["BrokenSnag01","pine_snag_v2",Vector2(20,-29),0.65,0.65],
		["BrokenSnag02","pine_snag_v2",Vector2(-31,-33),0.65,0.65]
	]:
		success=_place(entry[0],entry[1],entry[2],entry[3],entry[4]) and success
	# Small dead branches are decorative, leaving movement/shot collision alone.
	for i in range(16):
		var p:=Vector2(rng.randf_range(-35,22),rng.randf_range(-34,32))
		if Layout.reserved(p,0.8) or Layout.trench_distance(p)<2.0 or absf(p.x-Layout.trail_x(p.y))<1.5:
			continue
		var scene_id:="pine_branch_dead_v2" if i%2==0 else "pine_branch_broken_v2"
		var prop=load("res://assets/environment/scenes/"+scene_id+".tscn").instantiate()
		prop.name="LooseBranch%02d" % i
		prop.position=Vector3(p.x,Layout.height(p.x,p.y)+0.015,p.y)
		prop.rotation.y=rng.randf()*TAU
		debris.add_child(prop)
		prop.owner=debris
		records.append({"id":str(prop.name),"asset":scene_id,"at":[p.x,prop.position.y,p.y]})
	debris.set_meta("seed",194611020)
	debris.set_meta("placements",records)
	if not success:
		debris.free()
		quit(1)
		return
	var packed:=PackedScene.new()
	assert(packed.pack(debris)==OK)
	assert(ResourceSaver.save(packed,"res://assets/environment/scenes/pine_debris_generated.tscn")==OK)
	print("PINE PLACEMENT PASS ",JSON.stringify(records))
	debris.free()
	quit()
