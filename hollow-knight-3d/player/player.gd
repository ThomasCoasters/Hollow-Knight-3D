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
	#when you 
	set(value):
		#sets the var to the new value
		can_input = value
		#dissables or enables the inputs
		set_process_input(can_input)
		
		#stop the player from moving
		velocity.x = 0
		velocity.z = 0
		
		#set the moving state chart to the non moving state
		state_chart.send_event(&"stop_moving")


##settings for the movement
@export_group("movement")
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
##how fast the player will fall
@export var GRAVITY: float = 0.1
##multiplier for the gravity
var gravity_multiplier: float = 1.0
##ways of gravity and their gravity multiplier
@export var gravity_mult_per_state: Dictionary[String, float] = {
	"falling": 1.0,
	"jumping": 0.3,
}
##max speed you can fall at
@export var max_fall_speed: float = -50

##settings for jumping
@export_subgroup("jumping")
##amount of jumps you have before you need to reset it
@export var max_jumps_amount: int = 1
##amount of jumps you have left
var jumps_amount: int = max_jumps_amount
##the speed you jump at
@export var jump_speed: float = 20
##timer for how long you can hold the jump button
@onready var max_jump_time_timer: Timer = $max_jump_time
##the time you can hold the jump button for max
@export var max_jump_time: float = 0.3
##is true when the player is mid jump
var is_jumping: bool = false
##is true when the timer makes the player stop jumping
var jump_max_held: bool = false





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

#endregion


#region loops
func _input(_event: InputEvent) -> void:
	### ----- state chart stuff ----- ###
	
	#when not moving
	if idle_moving_state.active:
		#check if moving starts
		if Input.is_action_pressed(&"MoveBackward") || Input.is_action_pressed(&"MoveForward") ||  Input.is_action_pressed(&"MoveLeft") || Input.is_action_pressed(&"MoveRight"):
			#set the state chart to the moving state
			state_chart.send_event(&"start_moving")
	
	#when you are moving
	elif moving_state.active:
		#check if you stop moving
		if velocity == Vector3.ZERO:
			#check if the player does not want to keep moving 
			if !(Input.is_action_pressed(&"MoveBackward") || Input.is_action_pressed(&"MoveForward") ||  Input.is_action_pressed(&"MoveLeft") || Input.is_action_pressed(&"MoveRight")):
				#set the state chart to the non moving state
				state_chart.send_event(&"stop_moving")
	
	
	#when the player currently is jumping
	if jumping_state.active:
		#check if the player released the jumping button
		if Input.is_action_just_released(&"Jump"):
			#make the player go to the falling state
			state_chart.send_event(&"start_falling")
	
	
	#when you are not already having a positive velocity (jumping)
	if velocity.y <= 0:
		#check if you can jump
		if jumps_amount > 0:
			#check if you just pressed the jump button
			if Input.is_action_just_pressed(&"Jump"):
				jumps_amount -= 1
				#set the state chart to the jumping state
				state_chart.send_event(&"start_jumping")



func _physics_process(delta: float) -> void:
	
	### ----- state chart stuff ----- ###
	
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
	
	
	
	
	
	### ----- physics stuff ----- ###
	
	
	#add gravity to the player
	add_gravity() 
	
	
	#add movement velocity and rotation when you are moving only
	if moving_state.active:
		#rotate the player to the looking direction and get the new velocity
		rotate_and_velocity(delta)
	
	
	
	#move the player
	move_and_slide()
#endregion




#region moving
##handles the moving direction and acceleration/deceleration
func rotate_and_velocity(delta: float) -> void:
	#Get the movement input direction and handle the movement/deceleration
	var input_dir: Vector2 = Input.get_vector(&"MoveLeft", &"MoveRight", &"MoveForward", &"MoveBackward")
	var direction: Vector3 = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	#rotates movement towards the camera
	direction = direction.rotated(Vector3.UP, camera.global_rotation.y)
	
	#if you held move in an direction
	if direction:
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
		#decelerate the player
		velocity.x = move_toward(velocity.x, 0, delta * acceleration)
		velocity.z = move_toward(velocity.z, 0, delta * acceleration)






### ----- jumping / falling ----- ###

##runs when the player is on the floor (idle)
func _on_idle_state_entered() -> void:
	#reset the jumps amount
	jumps_amount = max_jumps_amount


##adds gravity to the velocity
func add_gravity() -> void:
	#only add gravity when you are in the air
	if !is_on_floor():
		#add the gravity to the velocity
		velocity.y -= GRAVITY * gravity_multiplier
	
	#have a max falling speed
	velocity.y = max(velocity.y, max_fall_speed)



##runs when you start falling
func _on_falling_state_entered() -> void:
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
	print("entur")
	
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
			change_player_opacity(0.0, 0.2)
		#if not in 1st person mode not fully invis
		else:
			#makes the player slightly see through
			change_player_opacity(0.4, 0.2)

##runs when the camera leaves the camera detector
func _on_camera_detector_area_exited(area: Area3D) -> void:
	if !area.is_in_group("camera_area"):
		return
	
	#makes the player visible again
	change_player_opacity(1.0, 0.2)
#endregion


#region better feel
##changes the opacity of the player
func change_player_opacity(to: float = 0.0, time: float = 0.5) -> void:
	#only change the player model opacity if it is the player model
	if knight is Player_Model:
		#change every mesh of the player
		for mesh: MeshInstance3D in knight.meshes:
			#the ending opacity
			var ending_opacity: float = to
			
			#make the body mesh always invis instead of see through (otherwise really ugly)
			if mesh.name == "Body":
				#check if it would be see through
				if to < 1.0:
					#make to always 0.0 (invis)
					ending_opacity = 0.0
			
			#get the mesh material
			var mat = mesh.get_active_material(0)
			
			
			# Enable transparency
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			
			#make the opacity tween to the correct value nicely
			var tween := create_tween()
			tween.tween_property(mat, "albedo_color:a", ending_opacity, time)
			#when finished make the material transparant if needed else make it normal
			tween.finished.connect(func():
				if to < 1.0:
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				else:
					mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				)
#endregion
