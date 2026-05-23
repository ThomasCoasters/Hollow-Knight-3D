extends CanvasLayer

## called when the transition is finished
signal on_transition_finished

## the color rect that is the visible part of the transition
@onready var color_rect: ColorRect = $ColorRect
## the animation player that determines the visibility of the transition color rect
@onready var animation_player: AnimationPlayer = $AnimationPlayer
## the animated sprite that plays animations for stuff like loading or saving
@onready var textures: AnimatedSprite2D = %textures
## the current animation for the texture
var _current_tex_anim: StringName


## if the animation should fade to normal during after finishing fading in
var fade_in_out: bool = false

## if the anim is currently active
static var fading: bool = false 

## the scale the saving anim should be at
@export var save_scale: float = 0.8
## the scale the loading amin should be at
@export var load_scale: float = 1.0


func _ready() -> void:
	# on start make the color rect invis
	color_rect.visible = false
	# run the animation finished when the animation is finished
	animation_player.animation_finished.connect(_on_animation_finished)
	
	# make the anim invis
	textures.modulate.a = 0



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






## plays the save anim untill the save is saving
func play_save_anim() -> void:
	# make the animation visible
	textures.modulate.a = 1
	# make correct scale
	textures.scale = Vector2(save_scale, save_scale)
	
	# start the save intro animation
	textures.play(&"save_intro")
	_current_tex_anim = &"save_intro"
	
	# wait untill the save is finished
	await SaveLoad.save_exited
	
	# check if the current animation is the saving intro
	if _current_tex_anim == &"save_intro":
		# wait untill the animation is finished
		await textures.animation_finished
	
	# set the current animation to the exit
	textures.play(&"save_exit")
	_current_tex_anim = &"save_exit"


## plays the loading anim until the load is done loading
func play_load_loading_anim() -> void:
	# make a tween for the fade in / fade out
	var tween: Tween = create_tween()
	
	# make the animation start invisible
	textures.modulate.a = 0
	# make correct scale
	textures.scale = Vector2(load_scale, load_scale)
	
	# make it fade to visible
	tween = TweenUtils.create_usable_tween(self, textures, "modulate:a", 1.0, 0.25, tween)
	
	# start the save intro animation
	textures.play(&"loading")
	_current_tex_anim = &"loading"
	
	# wait untill the save is finished
	await SaveLoad.load_exited
	
	# wait untill the tween is done
	if tween and tween.is_running():
		await tween.finished
	
	# make fade to invis
	tween = TweenUtils.create_usable_tween(self, textures, "modulate:a", 0.0, 0.25, tween)


# ran when the animation for stuff like saving or loading is finished
func _on_textures_animation_finished() -> void:
	# check what the finished animation was
	match _current_tex_anim:
		# if it was the save into play the loop
		&"save_intro":
			# start the save looping animation
			textures.play(&"save_pingpong")
			_current_tex_anim = &"save_pingpong"
		# if the finished anim is the exit hide the visual
		&"save_exit":
			# make invis
			textures.modulate.a = 0
