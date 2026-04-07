extends Node3D
class_name Player_Model

##all the meshes off the model
@export var meshes: Array[MeshInstance3D]

##all animations and their timings
##fist the name and then the array
##first in array is the start time (float), after the end time (also float)
@export var animation_to_times: Dictionary[String, Vector2]


##the animation player
@onready var animation_player: AnimationPlayer = $AnimationPlayer

##time segment for the animation
var current_segment := Vector2.ZERO

##the current running animation name
var current_anim: String = ""



func _process(_delta):
	
	#do not run when no animation is playing
	if current_anim == "":
		return
	
	print(current_segment, animation_player.current_animation_position)
	
	#if the animation has been playing to long reset it to the starting time
	if animation_player.current_animation_position >= current_segment.y:
		animation_player.seek(current_segment.x, true)
		animation_player.advance(0)



##starts the animation at a certaint time and set variables to the correct time
func set_animation_segment(anim_name: String):
	#throws an error instead of randomly breaking if the animation name does not exist
	if not animation_to_times.has(anim_name):
		push_error("Animation does not exist: " + anim_name)
		return
	
	#get the time segment
	var segment: Vector2 = animation_to_times[anim_name]
	
	#if the time is not a correct time throw an error
	if segment.x > segment.y:
		push_error("Invalid segment for: " + anim_name)
		return
	
	
	#set the segment to the new segment
	current_segment = segment
	
	#set the running animation to the new animation
	current_anim = anim_name
	
	
	
	#start the animation if not started already
	if !animation_player.is_playing():
		animation_player.play("player_animation")
	
	
	#run the animation from the starting time
	animation_player.seek(segment.x, true)
