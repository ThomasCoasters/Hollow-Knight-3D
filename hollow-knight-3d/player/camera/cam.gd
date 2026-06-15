class_name Camera
extends Camera3D

##the node the camera want to be at
@export var wanted_position: Marker3D

##the power of the lerp (how fast the camera gets to that position)
##for the position only
@export var position_lerp_power: float = 2.0

## speed screenshake will decay at
@export var shake_decay: float = 20
## internal for how strong the screenshake currently is
var shake_strength: float = 0.0
# internal offset of the screenshake
var shake_offset: Vector3 = Vector3.ZERO
## a noise texture for the screenshake
var noise: FastNoiseLite = FastNoiseLite.new()
## the current screen shake time 
var shake_time: float = 0.0
## the current rotation of the screenshake
var shake_rotation: Vector2 = Vector2.ZERO


func _ready():
	# set the noise seed to a random value
	noise.seed = randi()

## adds screenshake
func add_shake(amount: float) -> void:
	# increase the screen shake strength
	shake_strength += amount


func _process(delta: float) -> void:
	# get the actual delta time
	var real_delta: float = delta / Engine.time_scale
	
	#smoothly go to a new position
	if wanted_position:
		#lerp to the new position
		global_position = lerp(
			global_position,
			wanted_position.global_position,
			delta * position_lerp_power
		)

	
	
	# increase the screen shake time
	shake_time += real_delta
	
	# if the screen has a shake strength
	if shake_strength > 0:
		# decrease the strength
		shake_strength = move_toward(
			shake_strength,
			0.0,
			shake_decay * real_delta
		)
		
		# get the shake value we want to go to
		var target_shake: Vector2 = Vector2(
			noise.get_noise_1d(shake_time * 80.0),
			noise.get_noise_1d((shake_time + 1000.0) * 80.0)
		) * shake_strength
		
		# lerp smoothly to the wanted rotation
		shake_rotation = shake_rotation.lerp(
			target_shake,
			real_delta * 20.0
		)
		
		# set the rotation
		rotation_degrees.x = shake_rotation.x
		rotation_degrees.y = shake_rotation.y
