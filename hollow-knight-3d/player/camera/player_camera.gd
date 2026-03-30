@tool
extends SpringArm3D

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


##the current camera mode (also used for what exported variables are shown)
@export_enum("3rd_person", "1st_person", "side_view", "free", "locked") var camera_mode: String = "3rd_person":
	set(value):
		camera_mode = value
		notify_property_list_changed()

#settings for the camera
##the speed the mouse turns the camera
@export var mouse_sensibility: float = 0.005
## the location the camera is locked or the offset depending on the mode
@export var location: Vector3 = Vector3.ZERO
##the speed the mouse moves around with the moving buttons
@export var speed: float = 50




func _ready() -> void:
	#not make the editor play this 
	if Engine.is_editor_hint():
		return
	
	#put all states in an array
	camera_states = [_3rd_person_state, _1st_person_state, side_view_state, free_state, locked_state]
	
	#sets the state of the correct current mode to true
	set_camera_mode_state(camera_mode)


#region state chart
#setter for the camera mode state chart
func set_camera_mode_state(mode_name: String):
	#wait one frame else breaks
	await get_tree().process_frame
	
	#send the event to the state chart
	state_chart.send_event(mode_name)
#endregion

#region editor experience enhancer
#make the export vars only visible to the current selected mode
func _validate_property(property: Dictionary) -> void:
	# Always show camera_mode
	if property.name == "camera_mode":
		return
	
	#list of vars shown per mode
	var allowed := {
		"3rd_person": ["mouse_sensibility"],
		"1st_person": ["mouse_sensibility"],
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
