## a base class made to make the pooling easier for Node3D objects
class_name GlobalPoolingNode3D
extends Node3D

## the ID this object will have in the pool
@export var pool_ID: String


## is the disabling code for the node
func _on_pool_disable() -> void:
	# make the node invis
	visible = false

## is the enabling code for the node
func _on_pool_enable() -> void:
	# make the node visible
	visible = true

## runs when the pool gets the node
func _on_pool_get() -> void:
	pass

## runs when the node is returned to the pool
func _on_pool_return() -> void:
	pass


## returns the node to the pool
func return_to_pool() -> void:
	# return this object to the pool
	GlobalSpawnPool.return_object(pool_ID, self)
