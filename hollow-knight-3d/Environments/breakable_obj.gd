## the node that holds non-broken breakable objects
class_name BreakableOBJHolder
extends Node3D


## the scene this should load when broken
@export var broken_scene: String

## the detector component that will check if the given thing enters this node
@export var detect_comp: detector_component

const GEO_SCENE = preload("uid://bvrpkvlt1oahp")

## if the obj is already broken
var broken: bool = false

func _ready() -> void:
	# load the broken scene
	SceneLoader.request_scene(broken_scene)
	
	# check if there is a detector component given
	if detect_comp:
		# if the broken func is not already connected
		if not detect_comp.detected_collider.is_connected(break_object):
			# switch to the broken obj when the detector comp is entered
			detect_comp.detected_collider.connect(break_object)



## breaks the object
func break_object(_hitbox: hitbox_component) -> void:
	# if it already is broken return
	if broken: return
	
	
	# get the broken scene
	var break_packed_scene: PackedScene = SceneLoader.force_get_scene(broken_scene)
	
	# instantiate the break scene
	var break_scene: BrokenOBJHolder = break_packed_scene.instantiate() as BrokenOBJHolder
	
	# check if it even is a broken obj
	if not break_scene:
		push_error("the scene given is not a valid scene")
		return
	
	# make it broken
	broken = true
	
	# set the location of the broken scene to this one
	break_scene.global_transform = global_transform
	
	# add the break scene to the map
	Global.map_holder.current_map_node.add_child(break_scene)
	
	# remove this one
	queue_free()
	
