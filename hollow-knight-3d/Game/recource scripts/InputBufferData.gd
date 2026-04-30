class_name InputBufferData
extends Resource

##amount of frames the input buffer has left.
##DO NOT EDIT THIS!
var frames_left: int = 0

##amount of (physics) frames you get for input buffering
@export var max_input_buffer_frames: int = 6

##the transition that is used by this input
##if that is not aplicable keep it empty
@export_node_path("Transition")
var transition_path: NodePath

##runtime refrence for the transition
var transition: Transition = null
