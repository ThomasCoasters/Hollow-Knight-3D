class_name Camera
extends Camera3D

##the node the camera want to be at
@export var wanted_position: Marker3D

##the power of the lerp (how fast the camera gets to that position)
##for the position only
@export var position_lerp_power: float = 2.0

## speed screenshake will decay at
@export var shake_decay: float = 0.01
## internal for how strong the screenshake currently is
var shake_strength: float = 0.0
# internal offset of the screenshake
var shake_offset: Vector3 = Vector3.ZERO
## a noise texture for the screenshake
var noise: FastNoiseLite = FastNoiseLite.new()
## the current screen shake time 
var shake_time: float = 0.0


func _ready():
	# set the noise seed to a random value
	noise.seed = randi()

## adds screenshake
func add_shake(amount: float) -> void:
	# increase the screen shake strength
	shake_strength += amount
	
	# reset shake time
	shake_time = 0.0


func _process(delta: float) -> void:
	# get the actual delta time
	var real_delta: float = delta / Engine.time_scale
	
	# the target position
	var target_position: Vector3 = Vector3.ZERO
	
	#smoothly go to a new position
	if wanted_position:
		#lerp to the new position
		target_position = lerp(
			global_position,
			wanted_position.global_position,
			delta * position_lerp_power
		)

	
	
	# decrease the screen shake time
	shake_time += real_delta
	
	# if the screen has a shake strength
	if shake_strength > 0:
		# decrease the strength
		shake_strength = move_toward(
			shake_strength,
			0.0,
			shake_decay * real_delta
		)
		
		# get the x and y offset of the screenshake
		var x = noise.get_noise_1d(shake_time * 25.0)
		var y = noise.get_noise_1d((shake_time + 100.0) * 25.0)
		
		# add the shake to the global position
		target_position += Vector3(
			x * shake_strength,
			y * shake_strength,
			0.0
		)
	
	# get the position
	global_position = target_position
