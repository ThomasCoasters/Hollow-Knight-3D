#region vars
@tool
extends Node3D
class_name Player_Camera

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
##the speed the mouse moves around with the moving buttons
@export var speed: float = 50

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
##the speed the mouse turns the camera
@export var mouse_sensibility: float = 0.005
##minimal vertical angle for the camera
@export_range(-90, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = -PI/2.5
##maximal vertical angle for the camera
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var max_vertical_angle: float = PI/4


##zooming variables
@export_group("zoom")
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
#endregion




#just the starting game stuff

#region setup
func _ready() -> void:
	#not make the editor play this 
	if Engine.is_editor_hint():
		return
	
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
		"free": ["mouse_sensibility", "speed", "rotation_lerp_power"],
		"side_view": ["side_view_distance", "side_view_rotation_x", "side_view_rotation_y", "rotation_lerp_power"],
		"locked": ["location"]
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
	move_camera_by_mouse(event)
	
	#zooming
	zoom_camera_by_input(event)
#endregion

#region 1st person camera
##starting settings for 1st person camera
func _on_st_person_state_entered() -> void:
	#make the camera start in the player
	spring_arm_3d.spring_length = 0

##camera movement for 1st person
func _on_st_person_state_input(event: InputEvent) -> void:
	#moving the camera
	move_camera_by_mouse(event)
#endregion

#region side view camera
##starting settings for 3rd person camera
func _on_side_view_state_entered() -> void:
	#set the spring length to the starting distance
	spring_arm_3d.spring_length = side_view_distance
	
	#sets the correct rotation
	wanted_rotation.x = side_view_rotation_x
	wanted_rotation.y = side_view_rotation_y
#endregion




#functions on the way the camera should move

#region camera movement functions
##used for rotating the camera by moving the mouse
func move_camera_by_mouse(event: InputEvent) -> void:
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


##used for zooming the camera in/out by user inputs
func zoom_camera_by_input(event: InputEvent) -> void:
	#zooming in
	if event.is_action_pressed("ZoomIn"):
		spring_arm_3d.spring_length = clamp(spring_arm_3d.spring_length - zoom_speed, min_distance, max_distance)
	
	#zooming out
	if event.is_action_pressed("ZoomOut"):
		spring_arm_3d.spring_length = clamp(spring_arm_3d.spring_length + zoom_speed, min_distance, max_distance)
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
