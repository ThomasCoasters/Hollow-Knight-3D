
## the node that holds broken objects
class_name BrokenOBJHolder
extends Node3D


## time the rigid bodies will exist for
@export_range(1.0, 100.0) var lifetime: float = 10

## the range this fade will be at (lifetime - this to lifetime + this)
@export_range(0.0, 10) var lifetime_range: float = 1.0

## time the rigid bodies will fade out for
@export_range(0.0, 20.0) var fade_time: float = 0.8

## time the rigid bodies will be animated for before changing to static bodies
@export_range(0.0, 100.0) var activated_time: float = 2.5
## range of time the rigid bodies will be animated for before changing to static bodies
@export_range(0.0, 100.0) var activated_time_range: float = 0.5
## applies a random value between - and + of the given value
@export var random_starting_force: Vector3 = Vector3(100, 0, 100)


## refrence to all the rigid bodies
var rigid_bodies: Array[Node] = []


## (optional) transparancy component to make all the meshes fade out
@export var transparancy_comp: transparancy_component

func _ready() -> void:
	# get all rigid bodies
	_get_all_rigid_bodies()
	
	
	GlobalSpawnPool.register_pool("Geo", preload("uid://bvrpkvlt1oahp"), 10)
	var a = GlobalSpawnPool.request_objects("Geo", 50)
	
	for i in a:
		i.global_position = global_position + Vector3(0, 1, 0)
	
	# add a random velocity to all rigid bodies
	for rigid: RigidBody3D in rigid_bodies:
		if rigid is RigidBody3D:
			# apply a random force
			rigid.apply_central_impulse(
				Vector3(
					randf_range(-random_starting_force.x, random_starting_force.x),
					randf_range(-random_starting_force.y, random_starting_force.y),
					randf_range(-random_starting_force.z, random_starting_force.z),
				)
			)
			# wait one frame for staggering these things
			await get_tree().process_frame
			
	
	
	# if there is a transparancy component add all the meshes to it
	if transparancy_comp:
		# get all meshes
		var meshes = find_children("*", "MeshInstance3D", true, false)
		# go through them all
		for mesh in meshes:
			# if it is a MeshInstance3D add to the transparancy_comps meshes var
			if mesh is MeshInstance3D: transparancy_comp.meshes.append(mesh)
	
	# wait untill the activated time is expired
	var actual_activated_time: float = randf_range(activated_time - activated_time_range, activated_time + activated_time_range)
	await get_tree().create_timer(actual_activated_time).timeout
	# freeze all rigid bodies
	for rigid in rigid_bodies:
		if rigid is RigidBody3D:
			rigid.freeze = true
	
	
	# wait until the lifetime is exipired
	var actual_lifetime: float = randf_range(lifetime - lifetime_range, lifetime + lifetime_range) - activated_time
	await get_tree().create_timer(actual_lifetime).timeout
	
	# fade if there is a transparancy_comp
	if transparancy_comp:
		transparancy_comp.change_opacity(0.0, fade_time)
		await get_tree().create_timer(fade_time * 1.5).timeout
	
	
	queue_free()




## gets all the rigid bodies this node has
func _get_all_rigid_bodies() -> Array[Node]:
	# go through every child of the given node
	rigid_bodies = find_children("*", "RigidBody3D", true, false)
	
	# return it
	return rigid_bodies
