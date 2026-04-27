## a attack visual for the player
class_name PlayerAttackVisual
extends PoolingNode3D


## the animation player that has the animation for the slash
@export var animation_player: AnimationPlayer


## the rotation of the visual that will be randomised between
@export var random_rotation_angle: Vector2 = Vector2(15, 35)


## if the rotation will be alternated every time it is summoned
@export var alternate_angle: bool = true

## the class of node the parent you find the "real" parent to be
@export var real_parent_class: StringName = &"CharacterBody3D"
## the "real" parent
var real_parent: Node

## if the angle is alternated or not
var alternated: bool = false

## the offset off off the position
@export var offset: Vector3 = Vector3(0, 0.3, 0)

## called when the animation is done
signal animation_finished()





func _physics_process(_delta: float) -> void:
	#if this is enabled set its position to the real parents position
	if enabled:
		global_position = real_parent.global_position + offset




## is the disabling code for the node.
## overwrite the base code to not make the visual invis
func _on_pool_disable() -> void:
	# enabled var is false now
	enabled = false

func _on_pool_enable() -> void:
	# get the real parent
	real_parent = _get_real_parent(self, real_parent_class)
	
	# set the position correctly
	global_position = real_parent.global_position + offset
	
	# run the base code
	super()


## plays when the pool gets this node
func _on_pool_get() -> void:
	# get a variable for the new rotation random rotation
	var random_rotation: float = deg_to_rad(randf_range(random_rotation_angle.x, random_rotation_angle.y))
	
	# if you want to alternate angle
	# reverse the rotation if alternated is true
	if alternate_angle:
		random_rotation = -random_rotation if alternated else random_rotation
		
		# reverse the alternated
		alternated = not alternated
	
	#wait one frame otherwise the ration would be overwriten
	await get_tree().process_frame
	
	# set the z rotation
	rotation.z = random_rotation
	
	# play the animation for the slash
	animation_player.play(&"slash")


## gets the "real" parent.
##
## the start node is from where to start searching.
## the parent_class_name is the class to search for.
func _get_real_parent(start: Node, parent_class_name: StringName) -> Node:
	# the current node
	var current = start.get_parent()
	
	# keep looping until you find the correct one
	while current:
		# if the current node is the correct class return that node
		if current.is_class(parent_class_name):
			return current
		
		# else get the next parent
		current = current.get_parent()
	
	# if it never found that class return null
	return null


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	animation_finished.emit()
	
	return_to_pool()
