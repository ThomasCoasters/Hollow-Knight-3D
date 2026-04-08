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
var current_segment: Vector2 = Vector2.ZERO
##saved segment
var saved_segment: Vector2 = Vector2.ZERO

##the current running animation name
var current_anim: String = ""

##all the animations with their priority
@export var animation_priority: Dictionary[String, int]


func _process(_delta):
	
	#do not run when no animation is playing
	if current_anim == "":
		return
	
	#if the animation has been playing to long reset it to the starting time
	if animation_player.current_animation_position >= current_segment.y:
		#if this is not the animation that is saved set that as the correct segment
		if current_segment != saved_segment:
			current_segment = saved_segment
		
		#go to the starting point of the animation
		animation_player.seek(current_segment.x, true)



##starts the animation at a certaint time and set variables to the correct time
func set_animation_segment(anim_name: String, one_time: bool = false):
	#throws an error instead of randomly breaking if the animation name does not exist
	if !animation_to_times.has(anim_name) || !animation_priority.has(anim_name):
		push_error("Animation does not exist: " + anim_name)
		return
	
	#get the time segment
	var segment: Vector2 = animation_to_times[anim_name]
	
	#if the time is not a correct time throw an error
	if segment.x > segment.y:
		push_error("Invalid segment for: " + anim_name)
		return
	
	
	#only check if this anim has higher priority if the previous anim is in the dictionairy
	if animation_priority.has(current_anim):
		#if the new animation has a lower priority than the current do not play it
		if animation_priority[current_anim] < animation_priority[anim_name]:
			#check if the running animation is a looping animation
			if saved_segment != current_segment:
				return
	
	#set the segment to the new segment
	current_segment = segment
	
	#save the saved segment if this is not a one time animation
	if !one_time:
		saved_segment = segment
	
	
	#set the running animation to the new animation
	current_anim = anim_name
	
	#start the animation if not started already
	if !animation_player.is_playing():
		animation_player.play("player_animation")
	
	
	#run the animation from the starting time
	animation_player.seek(segment.x, true)
