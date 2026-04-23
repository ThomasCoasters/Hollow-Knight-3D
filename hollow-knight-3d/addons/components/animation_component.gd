@icon("animation_component.svg")
@tool

##component used to apply made animations to 3D models
class_name animation_component
extends component


##the animation player that contains all the animations
@export var animation_player: AnimationPlayer



##all animations and their timings
##fist the name and then the array
##first in array is the start time (float), after the end time (also float)
@export var animation_to_times: Dictionary[String, Vector2]

##all the animations with their priority
@export var animation_priority: Dictionary[String, int]



##time segment for the animation
var current_segment: Vector2 = Vector2.ZERO
##saved segment
var saved_segment: Vector2 = Vector2.ZERO

##the current running animation name
var current_anim: String = ""





## called when the (single time) animation finishes.
## Also gives the name of the finished animation.
signal animation_finished(name: String)

## called when an animation is looped
signal animation_looped

## called when an new animation is started.
## Also gives the name of the started animation.
signal animation_started(name: String)


func _process(_delta):
	#do not let the @tool make this run
	if Engine.is_editor_hint():
		return
	
	#do not run when no animation is playing
	if current_anim == "":
		return
	
	#if the animation has been playing to long reset it to the starting time
	if animation_player.current_animation_position >= current_segment.y:
		#if this is not the animation that is saved set that as the correct segment
		if current_segment != saved_segment:
			#emit the animation finished signal
			animation_finished.emit(current_anim)
			
			#set the animation back to the looping one
			current_segment = saved_segment
			
			#sets the current anim to the new animation
			current_anim = animation_to_times.find_key(saved_segment) if not null else "null"
		
		#call the anim loop signal if the animation that is finished is an looping anim
		else:
			#emit the animation looped signal
			animation_looped.emit()
		
		
		#go to the starting point of the animation
		animation_player.seek(current_segment.x, true)






##starts the animation at a certain time and set variables to the correct time
##play_if_current_anim only plays the set if the current anim is that string AND play_if_current_anim is not null
func set_animation_segment(anim_name: String, one_time: bool = false, play_if_current_anim: String = "null"):
	#throws an error instead of randomly breaking if the animation name does not exist
	if !animation_to_times.has(anim_name) || !animation_priority.has(anim_name):
		push_error("Animation does not exist: " + anim_name)
		return
	
	# check if the current animation is the correct one to be overrided
	if play_if_current_anim != "null": # only check this when it is set
		
		# do not play when this is not the wanted anim to override
		if current_anim != play_if_current_anim:
			
			#check if the saved animation needs to be reset
			var saved_anim = animation_to_times.find_key(saved_segment) if not null else "null"
			
			if saved_anim == play_if_current_anim: # check if the saved anim needs to be overridden
				saved_segment = Vector2.ZERO
			
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
		if animation_priority[current_anim] >= animation_priority[anim_name]:
			# do not play the animation
			if current_anim != "RESET": # still play it when the last animation was the reset
				
				# DO change the saved segment if this is not a one_time and the old one IS a one time
				if !one_time: # check if this is not a one time animation
					if saved_segment != current_segment: # check if the current animation is not a one time
						#get the current saved animation
						var saved_anim = animation_to_times.find_key(saved_segment) if not null else "null"
						
						print(saved_anim)
						
						if animation_priority[saved_anim] < animation_priority[anim_name] || saved_anim == "RESET" || saved_anim == "null": # change the saved segment when the saved anim is a lower priority
							saved_segment = segment # set the saved segment to the new one
				
				#stop the animation from playing
				return
	
	#set the segment to the new segment
	current_segment = segment
	
	#save the saved segment if this is not a one time animation
	if !one_time:
		saved_segment = segment
	
	
	#set the running animation to the new animation
	current_anim = anim_name
	
	#stop the anim is it is reset
	animation_player.stop()
	
	#start the animation if not started already
	if !animation_player.is_playing() && current_anim != "RESET":
		animation_player.play("player_animation")
	
	
	#emit the started signal
	animation_started.emit(anim_name)
	
	
	#run the animation from the starting time
	animation_player.seek(segment.x, true)
