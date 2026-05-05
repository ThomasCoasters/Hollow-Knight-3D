#region vars
class_name Player
extends CharacterBody3D

##exported nodes
@export_group("nodes")
##player model
@export var knight: Player_Model
##player camera
@export var camera: Player_Camera


## settings for QOL
@export_group("QOL settings")
## if stuff like attacks will use the camera position or the player rotation
@export var rotation_use_camera: bool = true


##settings for restricting stuff
@export_group("restrictions")
##chooses whether you can use inputs or not
@export var can_input: bool = true:
	set(value):
		#sets the var to the new value
		can_input = value
		
		#dissables or enables the inputs
		set_process_input(can_input)
		
		#stop the player from moving
		velocity.x = 0
		velocity.z = 0

##if you have / can dash or not
@export var has_dash: bool = true


##settings for the movement
@export_group("movement")
##input buffer frames left for the input[br]
##first the name of the input action[br]
##after that the corresponding transition state that is triggered when using this button or null[br]
@export var inputs_to_buffer: Dictionary[StringName, InputBufferData] = {}

##settings for moving
@export_subgroup("moving")
##maximum walking speed
@export var max_speed: float = 2.5
##walking acceleration
##6× higher than max_speed is 10 frames until max speed
##12× higher is 5 frames etc.
@export var acceleration: float = 30

##settings for falling
@export_subgroup("falling")
##the amount of (physics) frames you get for jumping after walking off off a ledge
@export var max_coyote_frames: float = 5
##how fast the player will fall
@export var GRAVITY: float = 0.13
##multiplier for the gravity
var gravity_multiplier: float = 1.0
##ways of gravity and their gravity multiplier
@export var gravity_mult_per_state: Dictionary[String, float] = {
	"falling": 1.0,
	"jumping": 0.3,
}
##max speed you can fall at
@export var max_fall_speed: float = -15

##settings for jumping
@export_subgroup("jumping")
##amount of jumps you have before you need to reset it
@export var max_jumps_amount: int = 1
##amount of jumps you have left
var jumps_amount: int = max_jumps_amount
##the speed you jump at
@export var jump_speed: float = 3
##timer for how long you can hold the jump button
@onready var max_jump_time_timer: Timer = $max_jump_time
##the time you can hold the jump button for max
@export var max_jump_time: float = 0.3
##is true when the player is mid jump
var is_jumping: bool = false
##is true when the timer makes the player stop jumping
var jump_max_held: bool = false

##settings for dashing
@export_subgroup("dashing")
##speed of the dash
@export var DASH_SPEED: float = 10
##the time the dash takes
@export var DASH_TIME: float = 0.27
##the timer for the dash
var dash_timer: float = 0.0


@export_group("attacking")
##the time the dash takes
@export var ATTACK_TIME: float = 0.33
## the y angle from which the pogo should happen
@export_range(-90, 0.0, 0.1, "radians_as_degrees") var pogo_angle: float = -PI/3
## the minimum angle the player can attack at when on the ground
@export_range(-90, 0.0, 0.1, "radians_as_degrees") var min_floored_attack_angle: float = deg_to_rad(-10)




#state chart stuff

#normal
@onready var state_chart: StateChart = $StateChart
@onready var parallel_state: ParallelState = $StateChart/ParallelState

#moving
@onready var moving: CompoundState = $StateChart/ParallelState/Moving
@onready var idle_moving_state: AtomicState = $StateChart/ParallelState/Moving/Idle
@onready var moving_state: AtomicState = $StateChart/ParallelState/Moving/Moving

#jumping
@onready var jumping_falling: CompoundState = $StateChart/ParallelState/Jumping_Falling
@onready var idle_jumping_falling_state: AtomicState = $StateChart/ParallelState/Jumping_Falling/Idle
@onready var jumping_state: AtomicState = $StateChart/ParallelState/Jumping_Falling/Jumping
@onready var falling_state: AtomicState = $StateChart/ParallelState/Jumping_Falling/Falling
@onready var from_idle_to_falling_state: Transition = $StateChart/ParallelState/Jumping_Falling/Idle/Falling

#attacking
@onready var attack: CompoundState = $StateChart/ParallelState/Attack
@onready var idle_attacking_state: AtomicState = $StateChart/ParallelState/Attack/Idle
@onready var attacking_state: AtomicState = $StateChart/ParallelState/Attack/Attacking
@onready var attack_recharge: AtomicState = $StateChart/ParallelState/Attack/Attack_recharge
@onready var to_attack_recharge: Transition = $StateChart/ParallelState/Attack/Attacking/to_attack_recharge
@onready var to_attacking: Transition = $StateChart/ParallelState/Attack/Idle/to_attacking

#dashing
@onready var dash: CompoundState = $StateChart/ParallelState/Dash
@onready var idle_dashing_state: AtomicState = $StateChart/ParallelState/Dash/Idle
@onready var dashing_state: AtomicState = $StateChart/ParallelState/Dash/Dashing
@onready var dash_recharge: AtomicState = $StateChart/ParallelState/Dash/Dash_recharge
@onready var to_dash_recharge: Transition = $StateChart/ParallelState/Dash/Dashing/To_dash_recharge
@onready var to_dashing: Transition = $StateChart/ParallelState/Dash/Idle/to_dashing


## if the camera detector is currently entered by the camera
var camera_currently_detected: bool = false


## settings for components
@export_group("components")
## the component for the health settings
@export var health_comp: health_component
## the attack pooling component
@export var pooled_attack_comp: spawn_pooled_component
## the component for playing random audios
@export var random_audio_comp: random_audio_component

#endregion

#region setup
func _ready() -> void:
	### ----- setup ----- ###
	#sets the global player to the player
	Global.player = self
	
	#time for the max jump time
	max_jump_time_timer.wait_time = max_jump_time
	
	#dissables or enables the inputs depending on the starting state of can_input
	set_process_input(can_input)
	
	
	#input buffering setup
	for action in inputs_to_buffer.keys():
		#makes not every recource be shared
		inputs_to_buffer[action] = inputs_to_buffer[action].duplicate()
		
		#get the data for this key
		var data := inputs_to_buffer[action]
		
		#set the transition to the correct value
		if data.transition_path != NodePath():
			data.transition = get_node(data.transition_path)
	
	
	
	### ----- state chart delays ----- ###
	#set the coyote time
	from_idle_to_falling_state.delay_in_seconds = str(max_coyote_frames/60)
	
	#sets the attack active time
	to_attack_recharge.delay_in_seconds = str(ATTACK_TIME)
	
	#sets the active dashing time
	to_dash_recharge.delay_in_seconds = str(DASH_TIME)

#endregion


#region loops
func _input(event: InputEvent) -> void:
	### ----- input buffering ----- ###
	_press_input_buffering(event)


func _process(_delta: float) -> void:
	### ----- state chart stuff ----- ###
	_input_state_chart()


func _physics_process(delta: float) -> void:
	### ----- input buffering ----- ###
	_reduce_input_buffer()
	
	### ----- state chart stuff ----- ###
	_state_chart_physics_process(delta)
	
	
	### ----- physics stuff ----- ###
	_handle_physics(delta)
#endregion



#region inputs
##handles the input buffering for pressing
func _press_input_buffering(_event: InputEvent) -> void:
	#goes through the list of actions
	for action in inputs_to_buffer.keys():
		#remove the input if it was released
		if not Input.is_action_pressed(action):
			inputs_to_buffer[action].frames_left = 0
		
		#set the frame time to the max time if the action is just pressed
		elif Input.is_action_just_pressed(action):
			inputs_to_buffer[action].frames_left = inputs_to_buffer[action].max_input_buffer_frames


##reduces all the input buffer timers
func _reduce_input_buffer():
	#goes through the list of actions
	for action in inputs_to_buffer.keys():
		#check if the input is currently buffered
		if inputs_to_buffer[action].frames_left > 0:
			#reduce the buffer time by 1
			inputs_to_buffer[action].frames_left -= 1


##gets if the input asked is buffered
func is_action_buffered(action: StringName) -> bool:
	#only check if the action is buffered if it even exists
	if inputs_to_buffer.has(action):
		#if the buffer frames are higher then 0 the input is buffered
		if inputs_to_buffer[action].frames_left > 0:
			
			#check if the childs transition can be taken safely
			var trans := inputs_to_buffer[action].transition as Transition
			#if not valid transition or just null
			if trans != null:
				#if the gaurd blocks the action
				if not trans.evaluate_guard():
					return false
			
			#reset the input buffer time to 0 for no accidental double presses
			inputs_to_buffer[action].frames_left = 0
			
			#returns true if buffered
			return true
	
	#if the action does not exist
	else:
		push_error("action does not exist: " + action + ". Add it to the 'inputs_to_buffer' variable")
	
	return false


##handles the _input version for the state chart inputs
func _input_state_chart() -> void:
	#when not moving
	if idle_moving_state.active:
		#check if moving starts
		if Input.is_action_pressed(&"MoveBackward") || Input.is_action_pressed(&"MoveForward") ||  Input.is_action_pressed(&"MoveLeft") || Input.is_action_pressed(&"MoveRight"):
			#set the state chart to the moving state
			state_chart.send_event(&"start_moving")
			
			#start the walking anim
			knight.set_animation_segment("Walk")
	
	#when you are moving
	elif moving_state.active:
		#check if the player does not want to keep moving 
		if !(Input.is_action_pressed(&"MoveBackward") || Input.is_action_pressed(&"MoveForward") ||  Input.is_action_pressed(&"MoveLeft") || Input.is_action_pressed(&"MoveRight")):
			#set the state chart to the non moving state
			state_chart.send_event(&"stop_moving")
			
			#stop the walk anim
			knight.set_animation_segment("RESET", false, "Walk")
	
	
	#when the player currently is jumping
	if jumping_state.active:
		#check if the player released the jumping button
		if Input.is_action_just_released(&"Jump"):
			#make the player go to the falling state
			state_chart.send_event(&"start_falling")
	
	
	#when you are not already having a positive velocity (jumping)
	if velocity.y <= 0:
		#check if you can jump (enough jumps + not dashing)
		if jumps_amount > 0 && !dashing_state.active:
			#check if you just pressed the jump button
			if is_action_buffered(&"Jump"):
				#set the state chart to the jumping state
				state_chart.send_event(&"start_jumping")
	
	#check if the player is in the attacking idle state
	if idle_attacking_state.active:
		#check if you just pressed the attack button
		if is_action_buffered(&"Attack"):
			#start the attacking state
			state_chart.send_event(&"start_attack")
			
			#start the attack animation
			knight.set_animation_segment("Attack", true)
	
	
	#check if the player is in the dashing idle state
	if idle_dashing_state.active:
		#check if the input is the dash input
		if is_action_buffered(&"Dash"):
			#start the dashing state
			state_chart.send_event(&"start_dash")
			
			#start the dash animation
			knight.set_animation_segment("Dash", true)



##handles the state chart in physics_process
func _state_chart_physics_process(_delta: float) -> void:
	#when you are falling
	if falling_state.active:
		#check if the player landed
		if is_on_floor():
			#stop falling and go to the idle state
			state_chart.send_event(&"stop_falling")
	
	
	#when you are not jumping nor falling
	if idle_jumping_falling_state.active:
		#check if you left the floor
		if !is_on_floor():
			#set the state chart to the falling state
			state_chart.send_event(&"start_falling")

#endregion


#region moving
##handles the moving direction and acceleration/deceleration
func _rotate_and_velocity(delta: float) -> void:
	#Get the movement input direction and handle the movement/deceleration
	var input_dir: Vector2 = Input.get_vector(&"MoveLeft", &"MoveRight", &"MoveForward", &"MoveBackward")
	var direction: Vector3 = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	#rotates movement towards the camera
	direction = direction.rotated(Vector3.UP, camera.global_rotation.y)
	
	#if you held move in an direction
	if direction.length() > 0.001:
		#make direction usable for movement
		direction *= max_speed
		
		#accelerate the player
		velocity.x = move_toward(velocity.x, direction.x, delta * acceleration)
		velocity.z = move_toward(velocity.z, direction.z, delta * acceleration)
		
		#look in the moving direction
		var look_position: Vector3 = global_position + Vector3(-velocity.x, 0, -velocity.z)
		var target_transform := knight.global_transform.looking_at(look_position, Vector3.UP)
		
		# convert to quaternions
		var current_rot := knight.global_transform.basis.get_rotation_quaternion()
		var target_rot := target_transform.basis.get_rotation_quaternion()
		
		# interpolate rotation
		var new_rot := current_rot.slerp(target_rot, delta * 10.0) # tweak 10.0
		
		# apply back
		knight.global_transform.basis = Basis(new_rot)
	
	else:
		#stop the player movement
		velocity.x = 0
		velocity.z = 0


##handles the physics_process physics (movement)
func _handle_physics(delta: float) -> void:
	#do not give the player option to move or fall while dashing
	if dash_timer == 0.0:
		#add gravity to the player
		_add_gravity() 
		
		#add movement velocity and rotation when can move only
		if can_input:
			#rotate the player to the looking direction and get the new velocity
			_rotate_and_velocity(delta)
	
	#move the player
	move_and_slide()



### ----- jumping / falling ----- ###

##runs when the player is on the floor (idle)
func _on_idle_state_entered() -> void:
	#reset the jumps amount
	jumps_amount = max_jumps_amount


##adds gravity to the velocity
func _add_gravity() -> void:
	#only add gravity when you are in the air
	if !is_on_floor():
		#add the gravity to the velocity
		velocity.y -= GRAVITY * gravity_multiplier
	
	#if you are recharging the dash and touching the ground make it recharge faster
	elif dash_recharge.active:
		#set the player to the non dashing state
		state_chart.send_event(&"stop_dash")
	
	
	#have a max falling speed
	velocity.y = max(velocity.y, max_fall_speed)
	
	



##runs when you start falling
func _on_falling_state_entered() -> void:
	#reduce the jumps amount you have left
	jumps_amount -= 1
	
	#stop the jump timer so this state is not entered multiple times:
	if !max_jump_time_timer.is_stopped():
		max_jump_time_timer.stop()
	
	#if you released the jump button earlier you start falling faster
	if is_jumping && !jump_max_held:
		velocity.y /= 2
	
	#set the gravity multiplier to the one for falling
	gravity_multiplier = gravity_mult_per_state["falling"]



##runs when you start jumping
func _on_jumping_state_entered() -> void:
	#add the jumping velocity
	velocity.y = jump_speed
	
	#set the gravity multiplier to the one for jumping
	gravity_multiplier = gravity_mult_per_state["jumping"]
	
	#start the max jump held timer
	max_jump_time_timer.start()
	
	#set the player to is jumping
	is_jumping = true
	#reset the jump max held variable
	jump_max_held = false
	
	#play the jump audio
	random_audio_comp.play_audio(&"Jump")


##runs when you held the jump button for too long
func _on_max_jump_time_timeout() -> void:
	#player held jump for the max amount of time so jump max held is true
	jump_max_held = true
	
	#make the player go to the falling state
	state_chart.send_event(&"start_falling")



### ----- dashing ----- ###

##runs when the dashing state is entered (dash started)
func _on_dashing_state_entered() -> void:
	#set the dash timer to the correct time
	dash_timer = DASH_TIME
	
	#stop the jump if it is active
	if jumping_state.active:
		#stop the jump
		is_jumping = false
		
		#make the player go to the falling state
		state_chart.send_event(&"start_falling")
	
	#change the velocity stuff
	_set_dashing_velocity()
	
	#play the audio
	random_audio_comp.play_audio(&"Dash")


##sets the velocity stuff for dashing
func _set_dashing_velocity() -> void:
	#stop falling
	velocity.y = 0
	
	# rotate the player to look away from the camera and get the direction
	# only if the rotation_use_camera is true
	var dir: Vector3
	if rotation_use_camera:
		dir = _instant_player_rotation()
	
	# else just get the dir
	else:
		dir = knight.global_basis.z
	
	#set the moving velocity
	velocity.x = dir.x * DASH_SPEED
	velocity.z = dir.z * DASH_SPEED
	
	


##runs every frame while dashing
func _on_dashing_state_processing(delta: float) -> void:
	#reduce the dash timer
	if dash_timer > 0.0: # only reduce if the time should be reduced
		dash_timer = max(0.0, dash_timer - delta)
		
		#when the dash timer reaches 0 reset velocity to stop the dash speed from being preserved when not moving after the dash (bug)
		if dash_timer == 0.0:
			#stop the player movement
			velocity.x = 0
			velocity.z = 0
	
	elif is_on_floor(): # if the timer stoped and the player is on the floor
		#set the player to the non dashing state
		state_chart.send_event(&"stop_dash")




## makes the player look at the camera rotation instantly.[br]
## returns the direction
func _instant_player_rotation() -> Vector3:
	#get the direction of the camera 
	var dir := -camera.global_transform.basis.z
	
	#do not change when changing the y value
	dir.y = 0
	dir = dir.normalized()
	
	#make the player look at that direction
	var look_position: Vector3 = global_position - dir
	knight.look_at(look_position, Vector3.UP)
	
	return dir
#endregion


#region attacking
func _on_attacking_state_entered() -> void:
	# spawns the attack and gets it
	var spawned_attack = pooled_attack_comp.create_unused_object(true)
	
	#get the direction of the camera or the player model depending on settings 
	var dir: Vector3
	if rotation_use_camera:
		# use camera
		dir = -camera.global_transform.basis.z
	
		# rotate the player to look away from the camera
		_instant_player_rotation()
	
	else:
		# use player transform
		dir = knight.global_transform.basis.z
		# do not rotate the player
		
		# still get the y dir from the camera because that is used for attacking up/down
		dir.y = -camera.global_transform.basis.z.y
	
	#normalize the direction
	dir = _clamp_attack_y_dir(dir)
	dir = dir.normalized()
	
	#make the attack look at that direction
	var look_position: Vector3 = global_position - dir
	spawned_attack.look_at(look_position, Vector3.UP)
	
	# play the attacking audio
	random_audio_comp.play_audio(&"Attack")



## makes the attack not go at a crazy angle
func _clamp_attack_y_dir(dir) -> Vector3:
	# if the player is grounded it should not be able to attack downwards really far
	if is_on_floor():
		# make the angle always be higher than the pogo angle
		dir.y = max(min_floored_attack_angle, dir.y)
	
	# returns the direction
	return dir
#endregion


#region camera stuff
##runs when the camera enters the camera detector
func _on_camera_detector_area_entered(area: Area3D) -> void:
	if !area.is_in_group("camera_area"):
		return
	
	# set the camera detected to true
	camera_currently_detected = true
	
	#make the player see though if not in 1st person else fully invis
	if camera:
		#check if the player is in 1st person
		if camera._1st_person_state.active:
			#makes the player invis
			knight.change_player_opacity(0.0, 0.2)
		#if not in 1st person mode not fully invis
		else:
			#makes the player slightly see through
			knight.change_player_opacity(0.4, 0.2)

##runs when the camera leaves the camera detector
func _on_camera_detector_area_exited(area: Area3D) -> void:
	if !area.is_in_group("camera_area"):
		return
	
	# set the camera detected to false
	camera_currently_detected = false
	
	#makes the player visible again
	knight.change_player_opacity(1.0, 0.2)


func _on_player_camera_camera_mode_changed(new_mode: String, old_mode: String) -> void:
	# easily add / change settings without big if elif else loop
	match old_mode:
		"3rd_person":
			# check if you are in the camera_detector
			if camera_currently_detected:
				#check if the new mode is 1st person
				if new_mode == "1st_person":
					#makes the player invis
					knight.change_player_opacity(0.0, 0.2)

#endregion
