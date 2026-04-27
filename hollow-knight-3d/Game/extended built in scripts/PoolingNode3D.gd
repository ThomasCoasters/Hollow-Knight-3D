## a base class made to make the pooling easier for Node3D objects
class_name PoolingNode3D
extends Node3D

## if the node is enabled or dissabled
var enabled: bool = false


## is the disabling code for the node
func _on_pool_disable() -> void:
	# make the node invis
	visible = false
	
	# enabled var is false now
	enabled = false

## is the enabling code for the node
func _on_pool_enable() -> void:
	# enabled var is true now
	enabled = true

## runs when the pool gets the node
func _on_pool_get() -> void:
	# make the node visible
	visible = true

## runs when the node is returned to the pool
func _on_pool_return() -> void:
	pass


## returns the node to the pool
func return_to_pool() -> void:
	# get the parent
	var parent: spawn_pooled_component = get_parent() as spawn_pooled_component
	
	# the parent should be an spawn_pooled_component else something is wrong
	if !parent:
		push_error("parent is not an spawn_pooled_component but it is an: " + str(get_parent().get_class()) + ". But it should only be inside a spawn_pooled_component.")
		return
	
	# return this object to the pool
	parent.return_object(self)
