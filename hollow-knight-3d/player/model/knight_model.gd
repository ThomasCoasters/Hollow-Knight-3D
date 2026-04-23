class_name Player_Model
extends Node3D




##the component for the animations
@export var animation_comp: animation_component

##the component for the transparancy changing
@export var transparancy_comp: transparancy_component



##starts the animation at a certain time and set variables to the correct time
##play_if_current_anim only plays the set if the current anim is that string AND play_if_current_anim is not null
func set_animation_segment(anim_name: String, one_time: bool = false, play_if_current_anim: String = "null") -> void:
	animation_comp.set_animation_segment(anim_name, one_time, play_if_current_anim)



##changes the opacity
func change_player_opacity(to: float = 0.0, time: float = 0.5):
	transparancy_comp.change_opacity(to, time)
