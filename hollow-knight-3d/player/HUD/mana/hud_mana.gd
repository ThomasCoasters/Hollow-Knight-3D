## the mana ball in the UI
class_name mana_ball
extends Control

##the node that changes scale to change this' scale
@export var scale_parent: Control

## the mana where you can select the color
@onready var color_mana: ColorRect = %ColorMana

## the static full mana visual
@onready var texture_mana: ColorRect = %TextureMana

## the circle that will show a short flash when you gain soul
@onready var flash_circle: ManaFlashCircle = %Flash_circle

## the thing that spawns the orb particles thing
@onready var orb_particle_spawner: spawn_pooled_component = %Orb_spawn

## the shine that plays when you fill your mana bar
@onready var mana_fill_shine: AnimatedSprite2D = %soul_fill_shine

## which percentage the visuals should be what color or texture
@export var percentage_visual: Array[ManaVisualSettings]



## the current amount of mana
@export var current_mana: int = 0:
	set(value):
		# flash the flash circle when you gain mana
		if current_mana < value && flash_circle:
			flash_circle.time_alive = 0.0
		
		# play the mana fill shine if value is max_mana and current mana not
		if value == max_mana && current_mana != max_mana:
			mana_fill_shine.play(&"shine")
		
		#set the value correct
		current_mana = clamp(value, 0, max_mana)
		
		#update the visuals
		_update_mana_visuals(value)


## the max amount of mana
@export var max_mana: int = 99


## the current visual setting
var current_visual_setting: ManaVisualSettings

## the current control node that has the visual
var current_visual: Control

## called when a new visual setting is selected
signal setting_changed(old_setting: ManaVisualSettings, new_setting: ManaVisualSettings)

## called when a new visual is selected for current_visual
signal visual_changed(old_visual: Control, new_visual: Control)


## updates the mana visual
func _update_mana_visuals(new_value: int) -> void:
	# get the ManaVisualSetting that is in the range of the current value
	var new_setting: ManaVisualSettings = _get_setting_for_value(new_value)
	
	# when the new setting is not the same as the current one
	if current_visual_setting != new_setting:
		# emit the setting changed signal
		setting_changed.emit(current_visual_setting, new_setting)
		
		# change the current visual setting to the new one
		current_visual_setting = new_setting
	
	
	# if there is no setting for this value return with an error
	if !current_visual_setting:
		push_error("there is no setting for the current mana value: " + str(new_value))
		return
	
	# get the visual that should change
	var change_visual: Control = _get_change_setting(current_visual_setting)
	
	# when the new visual is not the same as the current one
	if current_visual != change_visual:
		# emit the visual changed signal
		visual_changed.emit(current_visual, change_visual)
		
		# change the current visual to the new one
		current_visual = change_visual
	
	
	# if there is no control for this setting return and give a error
	if !change_visual:
		push_error("there is not a valid given color or texture for: " + str(new_value) + " mana." )
		return
	
	# actually change the visuals
	_change_control_visuals(change_visual, current_visual_setting, new_value)



## gets the correct ManaVisualSettings for the given value.
## returns null if there is no setting correct
func _get_setting_for_value(value) -> ManaVisualSettings:
	# go through every setting
	for setting: ManaVisualSettings in percentage_visual:
		# check if the current value is equal or above min_value
		# and below (and not equal) to max_value
		if setting.min_mana_amount <= value && setting.max_mana_amount > value:
			return setting
	
	# if there is no setting correct return null
	return null


## gets if the given setting should change texture or color.
## returns the texture_mana or color_mana.
## if none is viable in for this setting returns null
func _get_change_setting(setting: ManaVisualSettings) -> Control:
	# gets the given color and texture
	var color: Color = setting.color
	var tex: Texture2D = setting.texture
	
	# gets if the given color is not the default color (0, 0, 0, 0)
	if color != Color(0, 0, 0, 0):
		# returns the color mana visual
		return color_mana
	
	# gets if there is a given texture
	if tex:
		# returns the texture mana visual
		return texture_mana
	
	# if none of these are correct return null
	return null



## changes the visual for the given control.
func _change_control_visuals(visual: Control, setting: ManaVisualSettings, value: int) -> void:
	# make both the mana visuals invis
	color_mana.visible = false
	texture_mana.visible = false
	
	# make the chosen visual visible
	visual.visible = true
	
	# changes the value to a 0 to 1.0 value
	var fill_ratio: float = float(value) / max_mana
	
	# set the fill param
	visual.material.set_shader_parameter("fill_ratio", fill_ratio)
	
	
	# if the setting is a color change
	if setting.color != Color(0, 0, 0, 0):
		# set the fill color param to the color
		visual.material.set_shader_parameter("fill_color", setting.color)
	
	
	# if the setting is a texture
	elif setting.texture:
		# set the texture to the new one
		visual.material.set_shader_parameter("fill_tex", setting.texture)
	
	
	# set the dissable_lights to the value in the settings
	visual.material.set_shader_parameter("pulsing_lights", setting.pulsing_lighting)


## when the current setting changes
func _on_setting_changed(old_setting: ManaVisualSettings, new_setting: ManaVisualSettings) -> void:
	#only play the animation if you are entering the second state (1 in array)
	if old_setting != percentage_visual[0] || new_setting != percentage_visual[1]:
		return
	
	
	
	# spawn the orb something particles IDK =/
	var new_orb: PoolingGPUParticles2D = orb_particle_spawner.create_unused_object(true)
	
	# set the scale correctly
	if scale_parent:
		new_orb.scale = scale_parent.scale
	
	# set the position to the correct one
	# first the simple one
	new_orb.global_position = global_position
	# then add the extra position
	new_orb.global_position += 110 * new_orb.scale
