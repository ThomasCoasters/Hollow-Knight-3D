
## the node that holds broken objects
class_name BrokenOBJHolder
extends Node3D


## time the rigid bodies will exist for
@export_range(1.0, 100.0) var lifetime: float = 10

## the range this fade will be at (lifetime - this to lifetime + this)
@export_range(0.0, 10) var lifetime_range: float = 1.0

## time the rigid bodies will fade out for
@export_range(0.0, 20.0) var fade_time: float = 0.8


## refrence to all the rigid bodies
var rigid_bodies: Array[Node] = []


## (optional) transparancy component to make all the meshes fade out
@export var transparancy_comp: transparancy_component



func _ready() -> void:
	# get all rigid bodies
	_get_all_rigid_bodies()
	
	# if there is a transparancy component add all the meshes to it
	if transparancy_comp:
		# get all meshes
		var meshes = find_children("*", "MeshInstance3D", true, false)
		# go through them all
		for mesh in meshes:
			# if it is a MeshInstance3D add to the transparancy_comps meshes var
			if mesh is MeshInstance3D: transparancy_comp.meshes.append(mesh)
	
	# freeze rigid bodies after 1 second (reduce lag)
	await get_tree().create_timer(min(3.0, lifetime/3)).timeout
	for body in rigid_bodies:
		if body is RigidBody3D:
			body.freeze = true
	
	
	# wait until the lifetime is exipired
	var actual_lifetime: float = randf_range(lifetime - lifetime_range, lifetime + lifetime_range)
	await get_tree().create_timer(actual_lifetime).timeout
	
	# fade if there is a transparancy_comp
	if transparancy_comp: transparancy_comp.change_opacity(0.0, fade_time)
	
	await transparancy_comp.transparancy_changing_finished
	
	queue_free()





func _get_all_rigid_bodies() -> Array[Node]:
	# go through every child of the given node
	rigid_bodies = find_children("*", "RigidBody3D", true, false)
	
	# return it
	return rigid_bodies
