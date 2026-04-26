@icon("transparancy_component.svg")
@tool

##component used to spawn objects and pool them for future use
class_name spawn_pooled_component
extends component


##the object this spawns and uses
@export var object: PackedScene

##amount of objects it spawns at the start (can still create more when needed)
@export var initial_object_count: int = 1 


class pooled_object_settings:
	var node: Node
	var is_used: bool = false


## the objects that are currently pooled
var _pooled_objects: Array[pooled_object_settings] = []




## called when a new object is created
signal new_object_made(node: Node)

## called when a object is returned
signal object_returned(node: Node)

## called when a object is got
signal got_object(node: Node)


func _ready() -> void:
	#do not play in the editor
	if Engine.is_editor_hint():
		return
	
	## creates the amount of initial objects as needed
	for i in range(initial_object_count):
		_create_new_pooled_object()



## returns the object to the pool (gets unused)
func return_object(node: Node) -> void:
	# goes through every node in the pool
	for settings in _pooled_objects:
		# checks if the node is an actual node in the pool
		if settings.node == node:
			# set the used to false
			settings.is_used = false
			# and dissable the node
			_dissable_object(node)
			
			# run the pool_return function
			if node.has_method("_on_pool_return"):
				node._on_pool_return()
			
			# emit the returned object signal
			object_returned.emit(node)
			
			return
	
	push_error("Trying to return object not in pool")



## gets a unused object, if not possible creates a new one if overflow is enabled.
## a new one always gets the use settings auto enabled
func get_unused_object(create_overflow: bool, auto_set_use_settings: bool = true) -> Node:
	#goes through every pooled object
	for settings: pooled_object_settings in _pooled_objects:
		# the node
		var node: Node = settings.node
		
		#checks if the object is used or does not exist
		if settings.is_used || not is_instance_valid(node):
			continue
		
		
		# if the object is not used
		
		# if the auto_set_use_settings is enabled set the settings to use it
		if auto_set_use_settings:
			_set_used_settings(settings)
		
		# runs the pool_get function
		if node.has_method("_on_pool_get"):
			node._on_pool_get()
		
		# emit the got signal
		got_object.emit(node)
		
		#return it
		return node
	
	# if there is no object found create a new one when create_overflow is true
	if create_overflow:
		var node: Node = _create_new_pooled_object(true)
		
		# runs the pool_get function
		if node.has_method("_on_pool_get"):
			node._on_pool_get()
		
		# emit the got signal
		got_object.emit(node)
		
		return node
	
	# if you can not make overflow give an error and null
	push_error("Was not able to return an unused node. Current pooled objects: "  + str(_pooled_objects))
	return




## set the settings for being used
func _set_used_settings(settings: pooled_object_settings):
	#enable the object
	_enable_object(settings.node)
	
	#set the used setting to true
	settings.is_used = true



## creates a new version of the object.
## Returns the instance id
func _create_new_pooled_object(use_now: bool = false) -> Node:
	# create the object
	var new_pooled_object: Node = object.instantiate()
	
	# dissable everything if the object is not used
	if not use_now:
		_dissable_object(new_pooled_object)
	
	# creates the settings for the new object
	var settings: pooled_object_settings = pooled_object_settings.new()
	# sets the object
	settings.node = new_pooled_object
	# sets the used setting 
	settings.is_used = use_now
	
	
	# append the new node to the pooled objects
	_pooled_objects.append(settings)
	
	
	# create the node
	add_child(new_pooled_object)
	
	# emit the new object made signal
	new_object_made.emit(new_pooled_object) 
	
	# return the node made
	return new_pooled_object



 
## dissable everything to pool the object
func _dissable_object(node: Node) -> void:
	#if the object has a specific function for dissabling use that
	if node.has_method("_on_pool_disable"):
		node._on_pool_disable()
		
		return
	
	
	
	### ----- backup for no custom function ----- ###
	
	# dissable the processing of the object
	node.set_process(false)
	node.set_physics_process(false)
	node.set_process_input(false)
	node.set_process_unhandled_input(false)
	
	# visibility
	if node is Node3D || node is CanvasItem:
		node.visible = false
	
	# collision
	if node is CollisionObject2D or node is CollisionObject3D:
		node.set_deferred("disabled", true)
	
	# timers
	if node is Timer:
		node.stop()
	
	# animations
	if node is AnimationPlayer:
		node.stop()
	
	# particles
	if node is GPUParticles2D or node is GPUParticles3D:
		node.emitting = false



## enable everything to use the pooled object
func _enable_object(node: Node) -> void:
	#if the object has a specific function for enabling use that
	if node.has_method("_on_pool_enable"):
		node._on_pool_enable()
		
		return
	
	
	
	### ----- backup for no custom function ----- ###
	
	# dissable the processing of the object
	node.set_process(true)
	node.set_physics_process(true)
	node.set_process_input(true)
	node.set_process_unhandled_input(true)
	
	# visibility
	if node is Node3D || node is CanvasItem:
		node.visible = true
	
	# collision
	if node is CollisionObject2D or node is CollisionObject3D:
		node.set_deferred("disabled", false)
	
	# timers
	if node is Timer:
		node.start()
	
	# animations
	if node is AnimationPlayer:
		node.start()
	
	# particles
	if node is GPUParticles2D or node is GPUParticles3D:
		node.emitting = true
