#region vars
@tool
class_name Player_Camera
extends Node3D

#springarm
@onready var spring_arm_3d: SpringArm3D = $SpringArm3D

#statechart
@onready var state_chart: StateChart = $StateChart
#camera type states
@onready var camera_mode_state_machine: CompoundState = $StateChart/Camera_mode
@onready var _3rd_person_state: AtomicState = $"StateChart/Camera_mode/3rd_person"
@onready var _1st_person_state: AtomicState = $"StateChart/Camera_mode/1st_person"
@onready var side_view_state: AtomicState = $StateChart/Camera_mode/side_view
@onready var free_state: AtomicState = $StateChart/Camera_mode/free
@onready var locked_state: AtomicState = $StateChart/Camera_mode/locked
var camera_states: Array[AtomicState]

#all the camera states typed as strings
var state_to_mode: Dictionary[AtomicState, String] = {}


##all the camera modes in a array for easeier camera state cycles
@export var CAMERA_MODES: Array[String] = ["3rd_person", "1st_person", "side_view", "free", "locked"]

##the current camera mode (also used for what exported variables are shown)
@export_enum("3rd_person", "1st_person", "side_view", "free", "locked") var camera_mode: String = "3rd_person":
	set(value):
		camera_mode = value
		notify_property_list_changed()



#settings for the camera

##camera location for stuff like the locked camera
@export var location: Vector3 = Vector3.ZERO

##place to store the postion of the camera
var old_camera_position: Vector3 = Vector3.ZERO

##time to return to the old camera position nicely from modes like the locked mode
@export var cam_move_tween_time: float = 0.5

##camera rotating
@export_group("camera rotation")
##wanted rotation (for smoothly lerping)
var wanted_rotation: Vector3 = Vector3.ZERO

##the correct lerp value per camera mode
@export var camera_mode_to_lerp: Dictionary[String, int] = {
	"3rd_person": 12,
	"1st_person": 12,
	"side_view": 2,
	"free": 15,
	"locked": 2
}


##the power of the lerp (how fast the camera gets to that rotation)
##for the rotation only
@export var rotation_lerp_power: float = 7.0

## the rotation of the camera in side view (X)
@export_range(-180.0, 180.0, 0.1, "radians_as_degrees") var side_view_rotation_x: float = -deg_to_rad(10)
## the rotation of the camera in side view (Y)
@export_range(-180.0, 180.0, 0.1, "radians_as_degrees") var side_view_rotation_y: float = -deg_to_rad(90)

## the rotation of the camera in locked mode (X)
@export_range(-180.0, 180.0, 0.1, "radians_as_degrees") var locked_rotation_x: float = -deg_to_rad(10)
## the rotation of the camera in locked mode (Y)
@export_range(-180.0, 180.0, 0.1, "radians_as_degrees") var locked_rotation_y: float = -deg_to_rad(90)

##the speed the mouse turns the camera
@export var mouse_sensibility: float = 0.005
##minimal vertical angle for the camera
@export_range(-90, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = -PI/2.5
##maximal vertical angle for the camera
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var max_vertical_angle: float = PI/4


##variables that require the scrollwheel or looks like it does
@export_group("scrolling")

##zooming variables
@export_subgroup("zoom")
## the distance the camera is from the player
@export var side_view_distance: float = 4.0
##max distance from player
@export var max_distance: float = 4.0
##min distance from player
@export var min_distance: float = 0.5
##starting distance from player
@export var starting_distance: float = 2.5
##speed that you zoom at
@export var zoom_speed: float = 0.2

##freecam speed variables
@export_subgroup("freecam_speed")
##the speed the mouse moves around with the moving buttons
@export var speed: float = 5.0
##max speed
@export var max_speed: float = 15.0
##min speed
@export var min_speed: float = 1.0
##speed that scrolling changes the speed
@export var scroll_speed: float = 1.0



##tween used for moving the camera
var cam_moving_tween: Tween


## called when the cameramode changes
signal camera_mode_changed(new_mode: String, old_mode: String)

#endregion



#just the starting game stuff

#region setup
func _ready() -> void:
	#not make the editor play this 
	if Engine.is_editor_hint():
		return
	
	#sets this as the Global camera
	Global.camera = self
	
	#makes the mouse invis
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	#initialize the arrays and dictionary that use @onready variables
	#the camera states
	camera_states = [_3rd_person_state, _1st_person_state, side_view_state, free_state, locked_state]
	#states to a string
	state_to_mode = {
		_3rd_person_state: "3rd_person",
		_1st_person_state: "1st_person",
		side_view_state: "side_view",
		free_state: "free",
		locked_state: "locked",
	}
	
	
	#create the reset point for the camera
	old_camera_position = position
	
	#wait one frame else the setter breaks
	await get_tree().process_frame
	
	#sets the state of the correct current mode to true
	set_camera_mode_state(camera_mode)
	
	await get_tree().process_frame





#endregion






#region loops/checks
##runs when an input is made
func _input(_event: InputEvent) -> void:
	#toggle the next camera state if that is the input
	toggle_camera_in_loop()

##runs every frame
func _process(delta: float) -> void:
	#not make the editor play this 
	if Engine.is_editor_hint():
		return
	
	
	#lerp the camera rotation
	global_rotation.x = lerp_angle(global_rotation.x, wanted_rotation.x, delta*rotation_lerp_power)
	global_rotation.y = lerp_angle(global_rotation.y, wanted_rotation.y, delta*rotation_lerp_power)
	global_rotation.z = lerp_angle(global_rotation.z, wanted_rotation.z, delta*rotation_lerp_power)
#endregion


#region setting/getting
##setter for the camera mode state chart
func set_camera_mode_state(mode_name: String) -> void:
	# emit the mode changed signal
	camera_mode_changed.emit(mode_name, get_camera_mode_state())
	
	
	for state: AtomicState in camera_states:
		#stop all states that do not need to be on
		if state.active:
			state._state_exit()
		
		#activate the correct state
		if state_to_mode[state] == mode_name:
			state._state_enter(null)
	

##getter for the current camera state
##returns an string of the name
##returns "null" if no state is active
func get_camera_mode_state() -> String:
	for state: AtomicState in camera_states:
		if state.active:
			return state_to_mode[state]
	
	return "null"

##getter for the next camera mode in the queue
func get_next_camera_mode(current_mode: String) -> String:
	#fail safe for no current mode
	if current_mode == "null":
		return "null"
	
	#finds the current index for the current mode
	var index = CAMERA_MODES.find(current_mode)
	#increases the index to find the next one
	index = (index + 1) % CAMERA_MODES.size()
	#returns the new mode
	return CAMERA_MODES[index]
#endregion

#region editor experience enhancer
##make the export vars only visible to the current selected mode
func _validate_property(property: Dictionary) -> void:
	# Only affect (my) script variables
	if not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
		return
	
	# Always show camera_mode
	if property.name == "camera_mode" || property.name == "CAMERA_MODES" || property.name == "camera_mode_to_lerp":
		return
	
	#list of vars shown per mode
	var allowed := {
		"3rd_person": ["mouse_sensibility", "min_vertical_angle", "max_vertical_angle", "max_distance", "min_distance", "starting_distance", "zoom_speed", "rotation_lerp_power"],
		"1st_person": ["mouse_sensibility", "min_vertical_angle", "max_vertical_angle", "rotation_lerp_power"],
		"free": ["mouse_sensibility", "speed", "rotation_lerp_power", "max_speed", "min_speed", "scroll_speed"],
		"side_view": ["side_view_distance", "side_view_rotation_x", "side_view_rotation_y", "rotation_lerp_power"],
		"locked": ["location", "locked_rotation_x", "locked_rotation_y", "cam_move_tween_time"]
	}
	
	#not remove the correct vars
	if camera_mode in allowed and property.name in allowed[camera_mode]:
		return
	
	#not make the incorrect vars be shown
	property.usage = PROPERTY_USAGE_NO_EDITOR
#endregion




#function for the camera states

#region all camera states
##starting settings for all camera states
func _on_camera_mode_child_state_entered() -> void:
	#set the lerp power to the correct value per mode
	rotation_lerp_power = camera_mode_to_lerp[get_camera_mode_state()]
#endregion


#region 3rd person camera
##starting settings for 3rd person camera
func _on_rd_person_state_entered() -> void:
	#set the spring length to the starting distance
	spring_arm_3d.spring_length = starting_distance


##camera movement for 3rd person
func _on_rd_person_state_input(event: InputEvent) -> void:
	#moving the camera
	_rotate_camera_by_mouse(event)
	
	#zooming
	_zoom_camera_by_input(event)
#endregion

#region 1st person camera
##starting settings for 1st person camera
func _on_st_person_state_entered() -> void:
	#make the camera start in the player
	spring_arm_3d.spring_length = 0

##camera movement for 1st person
func _on_st_person_state_input(event: InputEvent) -> void:
	#moving the camera
	_rotate_camera_by_mouse(event)
#endregion

#region side view camera
##starting settings for side view camera
func _on_side_view_state_entered() -> void:
	#set the spring length to the starting distance
	spring_arm_3d.spring_length = side_view_distance
	
	#sets the correct rotation
	wanted_rotation.x = side_view_rotation_x
	wanted_rotation.y = side_view_rotation_y
#endregion

#region free camera
##starting settings for the free cam state
func _on_free_state_entered() -> void:
	#make the camera start in the player / rotate in a nicer way
	spring_arm_3d.spring_length = 0
	
	#sets self on top layer so the player does not move the camera
	top_level = true

##camera movement (delta time needed version) for free cam
func _on_free_state_physics_processing(delta: float) -> void:
	#move the camera with the moving buttons
	_move_camera_freely(delta)


##camera movement (input version) for free cam
func _on_free_state_input(event: InputEvent) -> void:
	#moving the camera (rotation)
	_unrestricted_rotate_camera_by_mouse(event)
	
	#slow down/speed up
	_change_speed_by_input(event)


##resets some weird settings
func _on_free_state_exited() -> void:
	#reverse setting self on top layer so the player cam move the camera now
	top_level = false
	
	#tween to the correct position
	TweenUtils.create_usable_tween(self, self, "position", old_camera_position, cam_move_tween_time, cam_moving_tween, Tween.EASE_OUT)
#endregion

#region locked camera
##starting settings for locked camera
func _on_locked_state_entered() -> void:
	#make the spring arm not affect the position
	spring_arm_3d.spring_length = 0
	
	#sets self on top layer so the player does not move the camera
	top_level = true
	
	#sets the correct rotation
	wanted_rotation.x = locked_rotation_x
	wanted_rotation.y = locked_rotation_y
	
	
	#tween to the new location
	TweenUtils.create_usable_tween(self, self, "global_position", location, cam_move_tween_time, cam_moving_tween, Tween.EASE_OUT)


##resets changes that might break stuff
func _on_locked_state_exited() -> void:
	#reverse setting self on top layer so the player cam move the camera now
	top_level = false
	
	#tween to the correct position
	TweenUtils.create_usable_tween(self, self, "position", old_camera_position, cam_move_tween_time, cam_moving_tween, Tween.EASE_OUT)
#endregion



#functions on the way the camera should move

#region camera movement functions
##used for rotating the camera by moving the mouse
func _rotate_camera_by_mouse(event: InputEvent) -> void:
	#mouse movement
	if event is InputEventMouseMotion:
		#Y rotation
		wanted_rotation.y -= event.relative.x * mouse_sensibility
		#wrap the Y to circle infinitly
		wanted_rotation.y = wrapf(wanted_rotation.y, 0.0, TAU)
		
		#X camera rotation
		wanted_rotation.x -= event.relative.y * mouse_sensibility
		#not make the camera be able to go too far
		wanted_rotation.x = clamp(wanted_rotation.x, min_vertical_angle, max_vertical_angle)


##used for rotating the camera by moving the mouse without restrictions
func _unrestricted_rotate_camera_by_mouse(event: InputEvent) -> void:
	#mouse movement
	if event is InputEventMouseMotion:
		#Y rotation
		wanted_rotation.y -= event.relative.x * mouse_sensibility
		#wrap the Y to circle infinitly
		wanted_rotation.y = wrapf(wanted_rotation.y, 0.0, TAU)
		
		#X camera rotation
		wanted_rotation.x -= event.relative.y * mouse_sensibility
		#not make the camera be able to go in a circle
		wanted_rotation.x = clamp(wanted_rotation.x, deg_to_rad(-90), deg_to_rad(90))


##used for zooming the camera in/out by user inputs
func _zoom_camera_by_input(event: InputEvent) -> void:
	#zooming in
	if event.is_action_pressed(&"ZoomIn"):
		spring_arm_3d.spring_length = clamp(spring_arm_3d.spring_length - zoom_speed, min_distance, max_distance)
	
	#zooming out
	if event.is_action_pressed(&"ZoomOut"):
		spring_arm_3d.spring_length = clamp(spring_arm_3d.spring_length + zoom_speed, min_distance, max_distance)


##used for changing the speed up/down by user inputs
func _change_speed_by_input(event: InputEvent) -> void:
	#speeding up
	if event.is_action_pressed(&"ZoomIn"):
		speed = clamp(speed + zoom_speed, min_speed, max_speed)
	
	#slowing down
	if event.is_action_pressed(&"ZoomOut"):
		speed = clamp(speed - zoom_speed, min_speed, max_speed)


##used for moving the camera freely
func _move_camera_freely(delta: float) -> void:
	#gets the direction of the inputs
	var input_dir: Vector2 = Input.get_vector(&"MoveLeft", &"MoveRight", &"MoveForward", &"MoveBackward")
	
	#changes the direction to a Vector3
	var local_direction: Vector3 = Vector3(input_dir.x, 0, input_dir.y)
	
	#does not move when not moving (failsafe for later)
	if local_direction == Vector3.ZERO:
		return
	
	#gets the normalised version of the direction
	local_direction = local_direction.normalized()
	
	#rotates the direction to be correct for the looking direction
	var global_direction: Vector3 = global_transform.basis * local_direction
	
	#moves the camera
	global_position += global_direction * speed * delta
#endregion






#functions for testing
#region testing
##sets the new camera state to the next one in a loop
func toggle_camera_in_loop() -> void:
	if Input.is_action_just_pressed("ChangeCamera"):
		#gets the next mode
		var current_mode: String = get_next_camera_mode(get_camera_mode_state())
		
		#failsave for no next mode
		if current_mode == "null":
			return
		
		#sets the camera mode to the new mode
		set_camera_mode_state(current_mode)
#endregion
