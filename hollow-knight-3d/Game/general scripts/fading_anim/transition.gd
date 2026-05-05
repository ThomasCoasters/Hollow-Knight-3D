extends CanvasLayer

## called when the transition is finished
signal on_transition_finished

## the color rect that is the visible part of the transition
@onready var color_rect: ColorRect = $ColorRect
## the animation player that determines the visibility of the transition color rect
@onready var animation_player: AnimationPlayer = $AnimationPlayer


## if the animation should fade to normal during after finishing fading in
var fade_in_out: bool = false

## if the anim is currently active
var fading: bool = false 


func _ready() -> void:
	# on start make the color rect invis
	color_rect.visible = false
	# run the animation finished when the animation is finished
	animation_player.animation_finished.connect(_on_animation_finished)



## ran when the animation is finished
func _on_animation_finished(anim_name):
	# if this was fading in and you want to fade_in_out fade it out
	if anim_name == "fade_to_black" and fade_in_out:
		# play the out anim
		animation_player.play("fade_to_normal")
	
	# else stop the animation
	else:
		# make the color rect invis only if the anim was fade_to_normal
		color_rect.visible = false if anim_name == "fade_to_normal" else true
		
		# stop the anim internally
		fading = false
	
	# emit the finished signal
	on_transition_finished.emit()



## plays the transition visual.
##[br][br]
## in_and_out will make if play first in and then out (only if fade_in == true)[br]
## if fade_in is true will play the fade in. if false will play the fade out[br]
func play_transition(in_and_out: bool = true, fade_in: bool = true) -> void:
	# if you are currently fading wait until it is finished
	while fading:
		# wait for the on_transition_finished
		await on_transition_finished
	
	
	# start the fading
	fading = true
	
	# make the color rect visible
	color_rect.visible = true
	
	# set the fade in out
	fade_in_out = in_and_out
	
	# get the correct animation for this setting and play it
	var anim: StringName = &"fade_to_black" if fade_in else &"fade_to_normal"
	animation_player.play(anim)
