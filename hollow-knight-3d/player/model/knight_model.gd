class_name Player_Model
extends Node3D




##the component for the animations
@export var animation_comp: animation_component

##the component for the transparancy changing
@export var transparancy_comp: transparancy_component


## a tween for the fade in/out stuff
var in_out_tween: Tween



## the wanted current opacity
var wanted_opacity: float = 1.0



##starts the animation at a certain time and set variables to the correct time
##play_if_current_anim only plays the set if the current anim is that string AND play_if_current_anim is not null
func set_animation_segment(anim_name: String, one_time: bool = false, play_if_current_anim: String = "null") -> void:
	animation_comp.play_animation(anim_name, one_time, play_if_current_anim)


@rpc("authority", "call_local", "reliable")
##changes the opacity
func change_player_opacity(to: float = 0.0, time: float = 0.5, change_wanted_opacity: bool = true):
	transparancy_comp.change_opacity(to, time)
	
	# set the wanted opacity (for the in-out stuff)
	if change_wanted_opacity: wanted_opacity = to



## fades the opacity in and out
func fade_in_out(duration: float = 3, times: int = 10, low_to: float = 0.2, high_to: float = 0.8) -> void:
	# reset the tween
	if in_out_tween:
		in_out_tween.kill()
	
	# create the tween
	in_out_tween = create_tween()
	
	# make tween ignore time scale
	in_out_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	
	# have the tween loop the amount of times this should happen
	in_out_tween.set_loops(times)
	
	# get half of the duration per thing
	var half_duration: float = duration / (times * 2.0)
	
	# fade the player out
	in_out_tween.tween_callback(change_player_opacity.bind(low_to, half_duration, false))
	in_out_tween.tween_interval(half_duration)
	
	# fade back in again
	in_out_tween.tween_callback(change_player_opacity.bind(high_to, half_duration, false))
	in_out_tween.tween_interval(half_duration)
	
	
	## when the tween is finished go back to normal opacity
	in_out_tween.finished.connect(change_player_opacity.bind(wanted_opacity, half_duration))
	
