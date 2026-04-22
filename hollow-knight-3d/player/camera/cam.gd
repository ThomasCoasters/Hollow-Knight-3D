class_name Camera
extends Camera3D

##the node the camera want to be at
@export var wanted_position: Marker3D

##the power of the lerp (how fast the camera gets to that position)
##for the position only
@export var position_lerp_power: float = 2.0



func _process(delta: float) -> void:
	#smoothly go to a new position
	if wanted_position:
		#lerp to the new position
		global_position = lerp(global_position, wanted_position.global_position, delta*position_lerp_power)
