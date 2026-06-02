@icon("global_spawn_pooled_component.svg")
@tool

## component used to spawn objects from the global pool
class_name global_spawn_pooled_component
extends component


## in what type of way the objects will spawn
enum _spawn_method {
	CODE,
	READY,
	TIMED,
}



## the scene that this component will spawn and use
@export_category("pooling settings")
@export var object_scene: PackedScene
## the ID this object will have in the pool
@export_placeholder("Please enter a name like 'Money' or 'enemy'") var pool_id: String
## amount of objects this will make from the start, so you can access them later
@export_range(0, 25, 1, "or_greater") var initial_object_count: int = 1



## settings for the way the stuff should spawn
@export_category("spawn method settings")
## in what type of way the objects will spawn
## [br][br][br]
## CODE: will only spawn when you ask it to using code (still possible with other methods)
## [br][br]
## READY: spawns once in the ready function
## [br][br]
## TIMED: spawns every x seconds
@export var spawn_method: _spawn_method = _spawn_method.CODE
## the node that should controll the global position
@export var position_node: Node3D
## extra position that is added after the global pos from the pos node
@export var position: Vector3 = Vector3.ZERO 


## the amount that should spawn when the spawn method spawns something (exept for when using CODE)
@export_range(0, 25, 1, "or_greater") var automatic_spawn_amount: int = 1
## time between every spawning when using the TIMED method
@export_range(0.1, 60.0, 0.1, "or_greater") var spawn_interval: float = 5






func _ready() -> void:
	# do not run in editor
	if Engine.is_editor_hint():
		return
	
	# if there is no pooled object give error and return
	if not object_scene:
		push_error(str(self) + " is missing a PackedScene, please give it one else it will not work and maybe give crashes.")
		return
	
	# give error if the global spawn pool does not exist
	if not has_node("/root/GlobalSpawnPool"):
		push_error("the GlobalSpawnPool is not found. make sure it is added as a global script in project settings")
		return
	
	# add the object to the global pool
	GlobalSpawnPool.register_pool(pool_id, object_scene, initial_object_count)
	
	
	# handle the spawn methods
	match spawn_method:
		_spawn_method.READY:
			spawn_multiple(automatic_spawn_amount)
		_spawn_method.TIMED:
			_setup_spawn_timer()



## make a timer gor the TIMED spawning method
func _setup_spawn_timer() -> void:
	# create a new timer
	var timer: Timer = Timer.new()
	# set the wait time and make it autostart
	timer.wait_time = spawn_interval
	timer.autostart = true
	# every time it is finished spawn
	timer.timeout.connect(func(): spawn_multiple(automatic_spawn_amount))
	# add the timer
	add_child(timer)


## spawns a single unused object from the global pool
func spawn() -> Node:
	# do not run in editor
	if Engine.is_editor_hint(): return null
	
	# request one object from the pool from the global pooler
	var objects: Array[Node] = GlobalSpawnPool.request_objects(pool_id, 1)
	
	# if the obj size is 0 (nothing) return null
	if objects.size() == 0:
		return null
	
	# get the first object
	var obj: Node = objects[0]
	
	# set the transform
	_set_object_transform(obj)
	
	# return the object
	return obj
	




## spawns multiple unused objects from the global pool
func spawn_multiple(amount: int) -> Array[Node]:
	# do not run in editor
	if Engine.is_editor_hint(): return []
	
	# get the pooler's requested objects
	var objects: Array[Node] = GlobalSpawnPool.request_objects(pool_id, amount)
	
	# go through every object and set the transform
	for obj in objects:
		_set_object_transform(obj)
	
	
	
	# return the objects
	return objects




## Returns an object back to the global pool
func return_object(node: Node) -> void:
	# do not run in editor
	if Engine.is_editor_hint(): return
	
	# return the given object back to the pooler
	GlobalSpawnPool.return_object(pool_id, node)













## sets the object transform for the given object
func _set_object_transform(object: Node) -> Node:
	# set the global pos to the node if that is given and the obj is a Node3D
	if position_node and object is Node3D:
		# set the global transform
		object.global_position = position_node.global_position
		
		# set the added position
		object.position += position
	
	# return the object
	return object
