
## an extra class to add extra stuff to the godot build in Tween
class_name TweenUtils
extends Node


##makes the specified tween usable with the settings given
static func create_usable_tween(node: Node, object: Object, property: NodePath, final_val: Variant, duration: float, wanted_tween: Tween, wanted_ease: Tween.EaseType = Tween.EASE_IN_OUT) -> Tween:
	#kill all current camera tween processes
	if wanted_tween:
		wanted_tween.kill()
	
	#create the usable tween
	wanted_tween = node.create_tween()
	
	#sets the ease to the wanted one
	wanted_tween.set_ease(wanted_ease)
	
	#actually runs the tween
	wanted_tween.tween_property(object, property, final_val, duration)
	
	#returns the Tween
	return wanted_tween
