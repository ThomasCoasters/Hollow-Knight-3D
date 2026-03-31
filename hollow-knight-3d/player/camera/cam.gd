extends Camera3D
class_name Camera

##the node the camera want to be at
@export var wanted_position: Marker3D
##the power of the lerp (how fast the camera gets to that position)
##for the position only
@export var position_lerp_power: float = 2.0



func _process(delta: float) -> void:
	#failsafe (only move if you have a node to move to)
	if wanted_position:
		#lerp to the new position
		position = lerp(position, wanted_position.position, delta*position_lerp_power)
