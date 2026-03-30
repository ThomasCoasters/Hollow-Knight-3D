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

##the current camera mode (also used for what exported variables are shown)
@export_enum("3rd_person", "1st_person", "side_view", "free", "locked") var camera_mode: String = "3rd_person":
	set(value):
		camera_mode = value
		notify_property_list_changed()



#settings for the camera
## the location the camera is locked or the offset depending on the mode
@export var location: Vector3 = Vector3.ZERO
##the speed the mouse moves around with the moving buttons
@export var speed: float = 50

##camera rotating
@export_group("camera rotation")
##the speed the mouse turns the camera
@export var mouse_sensibility: float = 0.005
##minimal vertical angle for the camera
@export_range(-90, 0.0, 0.1, "radians_as_degrees") var min_vertical_angle: float = -PI/2.5
##maximal vertical angle for the camera
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var max_vertical_angle: float = PI/4


##zooming variables
@export_group("zoom")
##max distance from player
@export var max_distance: float = 4.0
##min distance from player
@export var min_distance: float = 0.5
##starting distance from player
@export var starting_distance: float = 2.5
##speed that you zoom at
@export var zoom_speed: float = 0.2
#endregion



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
	
	
	#set the spring length to the starting distance
	spring_arm_3d.spring_length = starting_distance
	
	#wait one frame else the setter breaks
	await get_tree().process_frame
	
	#sets the state of the correct current mode to true
	set_camera_mode_state(camera_mode)
	
	await get_tree().process_frame
#endregion


#region state chart
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
func get_camera_mode_state() -> String:
	for state: AtomicState in camera_states:
		if state.active:
			return state_to_mode[state]
	
	return "null"
#endregion

#region editor experience enhancer
##make the export vars only visible to the current selected mode
func _validate_property(property: Dictionary) -> void:
	# Only affect (my) script variables
	if not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
		return
	
	# Always show camera_mode
	if property.name == "camera_mode":
		return
	
	#list of vars shown per mode
	var allowed := {
		"3rd_person": ["mouse_sensibility", "min_vertical_angle", "max_vertical_angle", "max_distance", "min_distance", "starting_distance", "zoom_speed"],
		"1st_person": ["mouse_sensibility", "min_vertical_angle", "max_vertical_angle"],
		"free": ["mouse_sensibility", "speed"],
		"side_view": ["location"],
		"locked": ["location"]
	}
	
	#not remove the correct vars
	if camera_mode in allowed and property.name in allowed[camera_mode]:
		return
	
	#not make the incorrect vars be shown
	property.usage = PROPERTY_USAGE_NO_EDITOR
#endregion




#region 3rd person camera
##camera movement for 3rd person
func _on_rd_person_state_input(event: InputEvent) -> void:
	print("input")
	#moving the camera
	move_camera_by_mouse(event)
	
	#zooming
	zoom_camera_by_input(event)
#endregion


#region 1st person camera
##starting settings for 1st person camera
func _on_st_person_state_entered() -> void:
	spring_arm_3d.spring_length = 0

##camera movement for 1st person
func _on_st_person_state_input(event: InputEvent) -> void:
	#moving the camera
	move_camera_by_mouse(event)
#endregion




#region camera movement functions
##used for rotating the camera by moving the mouse
func move_camera_by_mouse(event: InputEvent) -> void:
	#mouse movement
	if event is InputEventMouseMotion:
		#Y rotation
		rotation.y -= event.relative.x * mouse_sensibility
		#wrap the Y to circle infinitly
		rotation.y = wrapf(rotation.y, 0.0, TAU)
		
		#X camera rotation
		rotation.x -= event.relative.y * mouse_sensibility
		#not make the camera be able to go too far
		rotation.x = clamp(rotation.x, min_vertical_angle, max_vertical_angle)


##used for zooming the camera in/out by user inputs
func zoom_camera_by_input(event: InputEvent) -> void:
	#zooming in
	if event.is_action_pressed("ZoomIn"):
		spring_arm_3d.spring_length = clamp(spring_arm_3d.spring_length - zoom_speed, min_distance, max_distance)
	
	#zooming out
	if event.is_action_pressed("ZoomOut"):
		spring_arm_3d.spring_length = clamp(spring_arm_3d.spring_length + zoom_speed, min_distance, max_distance)
#endregion


func _on_rd_person_state_unhandled_input(event: InputEvent) -> void:
	pass # Replace with function body.
