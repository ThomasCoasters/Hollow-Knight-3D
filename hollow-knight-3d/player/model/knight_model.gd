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
			
			current_anim = animation_to_times.find_key(saved_segment) if not null else "null"
		
		#go to the starting point of the animation
		animation_player.seek(current_segment.x, true)






##starts the animation at a certaint time and set variables to the correct time
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
	
	
	#run the animation from the starting time
	animation_player.seek(segment.x, true)







##changes the opacity of the player
func change_player_opacity(to: float = 0.0, time: float = 0.5) -> void:
	#change every mesh of the player
	for mesh: MeshInstance3D in meshes:
		#the ending opacity
		var ending_opacity: float = to
		
		#make the body mesh always invis instead of see through (otherwise really ugly)
		if mesh.name == "Body":
			#check if it would be see through
			if to < 1.0:
				#make to always 0.0 (invis)
				ending_opacity = 0.0
		
		
		
		#get the mesh material
		var mat: StandardMaterial3D = mesh.get_active_material(0)
		
		
		# Enable transparency
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		
		
		
		#make the opacity tween to the correct value nicely
		var tween := create_tween()
		tween.tween_property(mat, "albedo_color:a", ending_opacity, time)
		
		
		#check if the outline exists
		if mat and mat.next_pass:
			#store the outline in a var
			var next = mat.next_pass
			
			#make sure the outline is always fully visible or fully invisible
			var end_outline_opacity: float = 1.0 if ending_opacity >= 1.0 else 0.0
			
			#check if it is a shadermaterial
			if next is ShaderMaterial:
				#smooth tween to the opacity chosen
				tween.parallel().tween_property(next, "shader_parameter/alpha", end_outline_opacity, time)
		
		
		#when finished make the material transparant if needed else make it normal
		tween.finished.connect(func():
			if to < 1.0:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			else:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			)
