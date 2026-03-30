extends Camera3D
class_name Camera

##the node the camera want to be at
@export var spring_arm: Marker3D
##the power of the lerp (how fast the camera gets to that position)
@export var lerp_power: float = 2.0


func _process(delta: float) -> void:
	position = lerp(position, spring_arm.position, delta*lerp_power)
