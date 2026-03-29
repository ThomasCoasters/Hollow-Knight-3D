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


#the current camera mode
@export_enum("3rd_person", "1st_person", "side_view", "free", "locked") var camera_mode: String = "3rd_person":
	set(value):
		camera_mode = value
		notify_property_list_changed()

#settings for the camera
@export var mouse_sensibility: float = 0.005
@export var location: Vector3 = Vector3.ZERO
@export var speed: float = 50




func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	#put all states in an array
	camera_states = [_3rd_person_state, _1st_person_state, side_view_state, free_state, locked_state]
	
	#sets the state of the correct current mode to true
	set_camera_mode_state(camera_mode)


#region state chart
func set_camera_mode_state(mode_name: String):
	print(mode_name)
	
	state_chart.send_event(mode_name)
	for state: AtomicState in camera_states:
		print(state.name , " " , state.active)

#endregion

#region editor experience enhancer
#make the export vars only visible to the current selected mode
func _validate_property(property: Dictionary) -> void:
	#goes over every exported var
	for current_property in property:
		match property.name:
			"mouse_sensibility":
				#modes 
				if camera_mode not in ["3rd_person", "1st_person", "free"]:
					property.usage = PROPERTY_USAGE_NO_EDITOR
			"location":
				if camera_mode not in ["side_view", "locked"]:
					property.usage = PROPERTY_USAGE_NO_EDITOR
			"speed":
				if camera_mode not in ["free"]:
					property.usage = PROPERTY_USAGE_NO_EDITOR
#endregion
