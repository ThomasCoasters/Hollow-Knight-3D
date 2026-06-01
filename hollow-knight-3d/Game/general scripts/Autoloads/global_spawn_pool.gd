## a global holder for pooled object spawning
class_name global_spawn_pooler
extends Node

## settings for a pooled object
class pooled_object_settings:
	var node: Node
	var is_used: bool = false

## keeps track of different pooled objects
## formated as: {"pool_id_as_string": Array[pooled_object_settings]}
var _global_pools: Dictionary[String, Array] = {}

## keeps track of the starting size of the pool
var _pool_target_sizes: Dictionary[String, int] = {}

## keeps track of the packed scene for the pool ID
var _pool_scenes: Dictionary[String, PackedScene] = {}

## called when a new object is created
signal new_object_made(node: Node, pool_id: String)
## called when an object is returned
signal object_returned(node: Node, pool_id: String)
## called when an object is fetched
signal got_object(node: Node, pool_id: String)


func _ready() -> void:
	# do not run in editor
	if Engine.is_editor_hint():
		return


## register a new object to the pool
func register_pool(pool_id: String, scene: PackedScene, required_size: int) -> void:
	# if the object does not exist in the pool add it
	if not _global_pools.has(pool_id):
		# add the object to the pool
		_global_pools[pool_id] = []
		# set the target size to 0 temp
		_pool_target_sizes[pool_id] = 0
		# add the scene as the pool scene
		_pool_scenes[pool_id] = scene
	
	
	# check if the new target has a higher pool size than the current one
	var current_target = _pool_target_sizes[pool_id]
	if required_size > current_target:
		# change the size to the new one
		_pool_target_sizes[pool_id] = required_size
		
		# spawn the new amount that is needed
		var items_to_add = required_size - current_target
		for i in range(items_to_add):
			_create_new_pooled_object(pool_id)


## request for objects of the pool
## add new ones to the pool if it ran out
func request_objects(pool_id: String, amount: int) -> Array[Node]:
	# refrence for the nodes that will be given
	var assigned_nodes: Array[Node] = []
	
	# if the ID does not exist in the pool, give an error
	if not _global_pools.has(pool_id):
		push_error("pool ID " + pool_id + " does not exist. Make it first, then request it")
		return assigned_nodes
	
	# add a assigned node to the array for every one that is requested
	for i in range(amount):
		# get or create a new node
		var node = _get_or_create_pool_node(pool_id)
		# if there was a node given
		if node != null:
			# add it to the assigned nodes
			assigned_nodes.append(node)
	
	# return the assigned nodes
	return assigned_nodes


## returns a object back to the pool
func return_object(pool_id: String, node: Node) -> void:
	# if the ID does not exist in the pool, give an error
	if not _global_pools.has(pool_id):
		push_error("pool ID " + pool_id + " does not exist. Make it first, then return it")
		return
	
	# get a temp refrence to the pool
	var pool: Array = _global_pools[pool_id]
	# go through every setting in the pool
	for settings in pool:
		# if the node is the node given
		if settings.node == node:
			# set the used setting to false
			settings.is_used = false
			# dissable the given object
			_disable_object(node)
			
			# if it has a fuction called "_on_pool_return", run it
			if node.has_method("_on_pool_return"):
				node._on_pool_return()
			
			# emit the obj returned signal
			object_returned.emit(node, pool_id)
			return
	
	# if there was no setting that was correct, give an error
	push_error("trying to return a object back to the pool that does not exist in the pool: " + pool_id)


## gets a node from the pool or creates a new one if none is available
func _get_or_create_pool_node(pool_id: String) -> Node:
	# get a temp refrence to the pool
	var pool: Array = _global_pools[pool_id]
	
	# look if there is a available one in the pool
	for settings in pool:
		# get the node this setting has
		var node: Node = settings.node
		# if it is used or not a valid thing check the next one
		if settings.is_used || not is_instance_valid(node):
			continue
		
		# enable the object
		_enable_object(node)
		# set the object to be used
		settings.is_used = true
		
		# if it has the func "_on_pool_get", run that
		if node.has_method("_on_pool_get"):
			node._on_pool_get()
		
		# emit the got obj signal
		got_object.emit(node, pool_id)
		# return the object
		return node
	
	
	# if there was no node free create a new one and add it to the pool
	return _create_new_pooled_object(pool_id, true)


## create a new pooled object
func _create_new_pooled_object(pool_id: String, use_now: bool = false) -> Node:
	# get the scene of the pools ID
	var scene: PackedScene = _pool_scenes[pool_id]
	# instantiate the scene
	var new_pooled_object: Node = scene.instantiate()
	
	# if not imidietly used dissable it, else enable it
	if not use_now:
		_disable_object(new_pooled_object)
	else:
		_enable_object(new_pooled_object)
	
	# create a new pooled obj setting
	var settings = pooled_object_settings.new()
	# set the node to the created one
	settings.node = new_pooled_object
	# set the is used
	settings.is_used = use_now
	
	# add it to the global pool
	_global_pools[pool_id].append(settings)
	# add it to this node
	add_child(new_pooled_object)
	
	# emit the new object made signal
	new_object_made.emit(new_pooled_object, pool_id)
	# return the newly made object
	return new_pooled_object


## disables objects
func _disable_object(node: Node) -> void:
	# if it has the "_on_pool_disable" func run it and return
	if node.has_method("_on_pool_disable"):
		node._on_pool_disable()
		return
	
	# if not set the process and physics process to false
	node.set_process(false)
	node.set_physics_process(false)
	# if it is Node3D or CanvasItem make it invis
	if node is Node3D || node is CanvasItem:
		node.visible = false
	# if collision set it disabled
	if node is CollisionObject2D or node is CollisionObject3D:
		node.set_deferred("disabled", true)


## enables objects
func _enable_object(node: Node) -> void:
	# if it has the "_on_pool_enable" func run it and return
	if node.has_method("_on_pool_enable"):
		node._on_pool_enable()
		return
	
	# if not set the process and physics process to true
	node.set_process(true)
	node.set_physics_process(true)
	# if it is Node3D or CanvasItem make it visible
	if node is Node3D || node is CanvasItem:
		node.visible = true
	# if collision set it enabled
	if node is CollisionObject2D or node is CollisionObject3D:
		node.set_deferred("disabled", false)
