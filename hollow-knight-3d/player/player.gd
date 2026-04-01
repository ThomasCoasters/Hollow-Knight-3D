#region vars
extends CharacterBody3D
class_name Player

##exported nodes
@export_group("nodes")
##player model
@export var knight: Player_Model
##player camera
@export var camera: Player_Camera

##settings for the movement
@export_group("movement")
##maximum walking speed
@export var max_speed: float = 2.5
##walking acceleration
##6× higher than max_speed is 10 frames until max speed
##12× higher is 5 frames etc.
@export var acceleration: float = 30


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




#region loops
func _input(_event: InputEvent) -> void:
	#when not moving
	if idle_moving_state.active:
		#check if moving starts
		if Input.is_action_pressed(&"MoveBackward") || Input.is_action_pressed(&"MoveForward") ||  Input.is_action_pressed(&"MoveLeft") || Input.is_action_pressed(&"MoveRight"):
			#set the state chart to the moving state
			state_chart.send_event("start_moving")
	
	#when you are moving
	elif moving_state.active:
		#check if you stop moving
		if velocity == Vector3.ZERO:
			#set the state chart to non moving state
			print("no movin")
			state_chart.send_event("stop_moving")

#endregion




#region moving
##handles moving state every physics frame
func _on_moving_state_physics_processing(delta: float) -> void:
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
	
	move_and_slide()





#endregion



#region camera stuff
##runs when the camera enters the camera detector
func _on_camera_detector_area_entered(area: Area3D) -> void:
	if !area.is_in_group("camera_area"):
		return
	
	#makes the player see through
	change_player_opacity(0.0, 0.2)

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
			#get the mesh material
			var mat = mesh.get_active_material(0)
			
			
			# Enable transparency
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			
			#make the opacity tween to the correct value nicely
			var tween := create_tween()
			tween.tween_property(mat, "albedo_color:a", to, time)
			#when finished make the material transparant if needed else make it normal
			tween.finished.connect(func():
				if to < 1.0:
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				else:
					mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				)
#endregion
