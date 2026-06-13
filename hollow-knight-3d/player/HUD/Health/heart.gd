## a singualar heart in the player's HUD
class_name player_HUD_heart
extends Control

## the heart animated sprite
@onready var hearth: AnimatedSprite2D = $hearth

## if this heart is filled visually
var full: bool = true


## set if the heart is filled or not
func set_full(value: bool):
	# if the new value is filled
	if value:
		# if already full do nothing
		if full:
			return
		
		# if not set it to filled and play the anim
		full = true
		hearth.play("full")
	
	# if if will be emptied
	else:
		# if already emptied do nothing
		if !full:
			return
		
		# set it to empty and play the animation
		full = false
		hearth.play("empty")



## runs every time the animation is finished
func _on_hearth_animation_finished() -> void:
	# if the heart is currently filled
	if full:
		# play the shine animation
		hearth.play("shine")
