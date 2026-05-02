@tool

## a recource for menu configs
class_name MenuConfigRecource
extends Resource


## if this is only shown in the start screen or also the pause menu
@export var only_start_screen: bool = false


## what mode this is
enum Mode {
	BUTTON,
	TEXT,
	TEXTURE,
	ANIMATED_TEXTURE,
	NONE
}

## set what mode this is
@export var mode: Mode = Mode.BUTTON:
	set(value):
		# set the var
		mode = value
		
		
		# only play the rest in the editor
		if not Engine.is_editor_hint():
			return
		
		
		# set the correct enabled to true
		match value:
			# if this is a button
			Mode.BUTTON:
				# enable text and button settings
				_text_group_enabled = true
				_button_group_enabled = true
				# disable all texture settings
				_texture_group_enabled = false
				_anim_texture_group_enabled = false
			
			# if this is plain text
			Mode.TEXT:
				# enable text settings
				_text_group_enabled = true
				# disable all texture and button settings
				_button_group_enabled = false
				_texture_group_enabled = false
				_anim_texture_group_enabled = false
			
			# if this is a texture
			Mode.TEXTURE:
				# enable texture settings
				_texture_group_enabled = true
				# disable text, button and animated texture settings
				_text_group_enabled = false
				_button_group_enabled = false
				_anim_texture_group_enabled = false
			
			# if this is an animated texture
			Mode.ANIMATED_TEXTURE:
				# enable all texture settings
				_anim_texture_group_enabled = true
				_texture_group_enabled = true
				# disable text and button settings
				_text_group_enabled = false
				_button_group_enabled = false
			
			# if it is just empty
			Mode.NONE:
				# disable all settings
				_texture_group_enabled = false
				_text_group_enabled = false
				_button_group_enabled = false
				_anim_texture_group_enabled = false





## settings only for texts
@export_group("text settings")
## if this group is enabled
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var _text_group_enabled: bool = true

## the text this will display
@export var text: String = ""
## the color the text will be in
@export var text_color: Color = Color(229, 229, 229)
## the font this will use
@export var font: FontFile = preload("res://Game/fonts/TrajanPro-Bold.otf")
## the font size
@export var font_size: int = 32




## settings only for the button
@export_group("button settings")
## if this group is enabled IGNORE THIS VAR
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var _button_group_enabled: bool = true

## the menu this will open when pressed
@export var send_to: NodePath
## a lambda function that will run when the button is pressed
@export_multiline var pressed_function: String = ""




## settings only for the texture
@export_group("texture settings")
## if this group is enabled IGNORE THIS VAR
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var _texture_group_enabled: bool = false

## the texture this will display
@export var texture: Texture2D
## the scale of the texture
@export var texture_scale: Vector2 = Vector2(1.0, 1.0)


## settings only for the animated texture
@export_group("animated texture settings")
## if this group is enabled IGNORE THIS VAR
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var _anim_texture_group_enabled: bool = false
## the animation frames this texture will use
@export var anim_frames: Array[Texture2D]
## the FPS this animation will play at
@export var fps: float = 20.0
## if this animation should loop
@export var loop: bool = false



## settings only for the spacer
@export_group("spacer settings")
## if this visual should add a spacer
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var should_add_spacer: bool = true
## the size of the spacer
@export var spacer_size: float = 40
