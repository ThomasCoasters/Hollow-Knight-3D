## a base class made to make the pooling easier for Node3D objects
class_name PoolingNode3D
extends Node3D


## is the disabling code for the particle
func _on_pool_disable() -> void:
	# stop emitting the particle
	visible = false

## is the enabling code for the particle
func _on_pool_enable() -> void:
	pass

## runs when the pool gets the particle
func _on_pool_get() -> void:
	# start emitting the particle
	visible = true

## runs when the particle is returned to the pool
func _on_pool_return() -> void:
	pass
