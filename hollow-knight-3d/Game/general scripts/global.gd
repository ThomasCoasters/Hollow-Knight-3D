extends Node

##the camera used
var camera: Player_Camera

##the player
var player: Player











##makes the specified tween usable with the settings given
func create_usable_tween(object: Object, property: NodePath, final_val: Variant, duration: float, wanted_tween: Tween, wanted_ease: Tween.EaseType = Tween.EASE_IN_OUT):
	#kill all current camera tween processes
	if wanted_tween:
		wanted_tween.kill()
	
	#create the usable tween
	wanted_tween = create_tween()
	
	#sets the ease to the wanted one
	wanted_tween.set_ease(wanted_ease)
	
	#actually runs the tween
	wanted_tween.tween_property(object, property, final_val, duration)
