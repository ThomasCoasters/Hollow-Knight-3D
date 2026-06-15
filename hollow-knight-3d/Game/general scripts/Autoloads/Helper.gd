## helper class with all sorts of functions
class_name helper_class
extends Node



## runs the game at the given speed scale for a given duration (usefull for freezeframes) 
func set_time_scale(time_scale: float, duration: float) -> void:
	# set the new speed scale (time_scale)
	# do make sure it will never be less than 0 because stuff can break
	Engine.time_scale = max(0.001, time_scale)
	
	# create a non timescale affected timer
	await Helper.wait_real_time(duration)
	
	# resets the timescale
	Engine.time_scale = 1
	




## waits a given duration that ignores timescale
func wait_real_time(duration: float) -> void:
	await get_tree().create_timer(duration, true, false, true).timeout

## waits a given duration that does not ignore timescale
func wait(duration: float) -> void:
	await get_tree().create_timer(duration).timeout
