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
	ROW,
	BUTTON_ROW,
	NONE,
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
				# enable button and text settings
				_text_group_enabled = true
				_button_group_enabled = true
				# dissable all texture and grid settings
				_anim_texture_group_enabled = false
				_texture_group_enabled = false
				_row_group_enabled = false
			
			# if this is plain text
			Mode.TEXT:
				# enable text settings
				_text_group_enabled = true
				# disable all texture, grid and button settings
				_button_group_enabled = false
				_texture_group_enabled = false
				_anim_texture_group_enabled = false
				_row_group_enabled = false
			
			# if this is a texture
			Mode.TEXTURE:
				# enable texture settings
				_texture_group_enabled = true
				# disable text, button, grid and animated texture settings
				_text_group_enabled = false
				_button_group_enabled = false
				_anim_texture_group_enabled = false
				_row_group_enabled = false
			
			# if this is an animated texture
			Mode.ANIMATED_TEXTURE:
				# enable all texture settings
				_anim_texture_group_enabled = true
				_texture_group_enabled = true
				# disable text, grid and button settings
				_text_group_enabled = false
				_button_group_enabled = false
				_row_group_enabled = false
			
			# if this in an row
			Mode.ROW:
				# only enable row settings
				_row_group_enabled = true
				# disable all other settings
				_texture_group_enabled = false
				_text_group_enabled = false
				_button_group_enabled = false
				_anim_texture_group_enabled = false
			
			# if this is an button row
			Mode.BUTTON_ROW:
				# enable row and button settings
				_row_group_enabled = true
				_button_group_enabled = true
				# disable all texture and text settings
				_text_group_enabled = false
				_texture_group_enabled = false
				_anim_texture_group_enabled = false
			
			# if it is just empty
			Mode.NONE:
				# disable all settings
				_texture_group_enabled = false
				_text_group_enabled = false
				_button_group_enabled = false
				_anim_texture_group_enabled = false
				_row_group_enabled = false



## if false this will sit in the previous item in a row if there is an grid in these settings
@export var full_width: bool = true


## settings everything has for fading in/out
@export_group("fading settings")
## time the fade takes when fading in
@export var in_fade_duration: float = 0.17
## time the fade takes when fading out
@export var out_fade_duration: float = 0.17
## time it waits before fading in
@export var in_start_delay: float = 0.0
## time it waits before fading out
@export var out_start_delay: float = 0.0




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
## a lambda function that will run when the button is pressed.
##[br][br]
## ScripRunUtil explanation:[br]
## Executes a multiline string as code.[br]
## code_string: is the raw GDscript code you want to run.[br]
## context: The object the code can interact with (referenced as 'ctx' in the string).[br]
## context is an array so if you only have 1 thing you still use ctx[0][br]
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


## settings only for the row mode
@export_group("row settings")
## if this group is enabled IGNORE THIS VAR
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var _row_group_enabled: bool = false
## The things that are inside this row
@export var sub_configs: Array[MenuConfigRecource] = []
## spacing between visuals in this row
@export var row_spacing: int = 20



## settings only for the vertical spacer
@export_group("vertical spacer settings")
## if this visual should add a vertical spacer
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var should_add_vertical_spacer: bool = true
## the size of the spacer
@export var vertical_spacer_size: float = 40


## settings only for the horizontal spacer
@export_group("horizontal spacer settings")
## if this visual should add a horizontal spacer
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var should_add_horizontal_spacer: bool = false
## the size of the spacer
@export var horizontal_spacer_size: float = 40





## settings for an offset
@export_group("offset")
## if this visual should have an offset
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var should_have_offset: bool = false
## the offset
@export var offset: Vector2 = Vector2.ZERO
