#region vars
extends CharacterBody3D
class_name Player

##exported nodes
@export_group("nodes")
##player model
@export var knight: Player_Model
##player camera
@export var camera: Player_Camera


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
##amount of (physics) frames you get for input buffering
@export var max_input_buffer_frames: int = 5
##input buffer frames left for the input
@export var inputs_to_buffer: Dictionary[StringName, int] = {
	&"Jump": 0,
	&"Attack": 0,
	&"Dash": 0,
}

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

#dashing
@onready var dash: CompoundState = $StateChart/ParallelState/Dash
@onready var idle_dashing_state: AtomicState = $StateChart/ParallelState/Dash/Idle
@onready var dashing_state: AtomicState = $StateChart/ParallelState/Dash/Dashing


#endregion

#region setup
func _ready() -> void:
	### ----- setup ----- ###
	#sets the global player to the player
	Global.player = self
	
	#time for the max jump time
	max_jump_time_timer.wait_time = max_jump_time
	
	#set the coyote time
	from_idle_to_falling_state.delay_in_seconds = str(max_coyote_frames/60)
	
	#dissables or enables the inputs depending on the starting state of can_input
	set_process_input(can_input)

#endregion


#region loops
func _input(event: InputEvent) -> void:
	### ----- input buffering ----- ###
	_press_input_buffering(event)


func _process(_delta: float) -> void:
	### ----- state chart stuff ----- ###
	_input_state_chart()
	
	print(inputs_to_buffer)


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
			inputs_to_buffer[action] = 0
		
		#set the frame time to the max time if the action is just pressed
		elif Input.is_action_just_pressed(action):
			inputs_to_buffer[action] = max_input_buffer_frames


##reduces all the input buffer timers
func _reduce_input_buffer():
	#goes through the list of actions
	for action in inputs_to_buffer.keys():
		#check if the input is currently buffered
		if inputs_to_buffer[action] > 0:
			#reduce the buffer time by 1
			inputs_to_buffer[action] -= 1


##gets if the input asked is buffered
func is_action_buffered(action: StringName) -> bool:
	#only check if the action is buffered if it even exists
	if inputs_to_buffer.has(action):
		#if the buffer frames are higher then 0 the input is buffered
		if inputs_to_buffer[action] > 0:
			#reset the input buffer time to 0 for no accidental double presses
			inputs_to_buffer[action] = 0
			
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
	
	#check if you are not already attacking
	if !attacking_state.active:
		#check if you just pressed the attack button
		if is_action_buffered(&"Attack"):
			#start the attacking state
			state_chart.send_event(&"start_attack")
			
			#start the attack animation
			knight.set_animation_segment("Attack", true)
	
	
	#check if the player is not already dashing
	if !dashing_state.active:
		#check if the input is the dash input
		if is_action_buffered(&"Dash"):
			#start the dashing state
			state_chart.send_event(&"start_dash")



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


##sets the velocity stuff for dashing
func _set_dashing_velocity() -> void:
	#stop falling
	velocity.y = 0
	
	#get the direction of the camera 
	var dir := -camera.global_transform.basis.z
	
	#do not change when changing the y value
	dir.y = 0
	dir = dir.normalized()
	
	#set the moving velocity
	velocity.x = dir.x * DASH_SPEED
	velocity.z = dir.z * DASH_SPEED
	
	#make the player look at that direction
	var look_position: Vector3 = global_position - dir
	knight.look_at(look_position, Vector3.UP)


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
#endregion



#region camera stuff
##runs when the camera enters the camera detector
func _on_camera_detector_area_entered(area: Area3D) -> void:
	if !area.is_in_group("camera_area"):
		return
	
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
	
	#makes the player visible again
	knight.change_player_opacity(1.0, 0.2)
#endregion
