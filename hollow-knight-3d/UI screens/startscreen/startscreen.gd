## the screen you will see when you start the game
class_name startscreen
extends Control



## the node that renders the backgrounds
@onready var bg_renderer: TextureRect = %"BG_Renderer"

## the node that contains all the bg stuff
@onready var BG: Control = %BG


## all the backgrounds
@export var backgrounds: Dictionary[StringName, PackedScene]

## current bg
@export var current_bg: StringName = &"Classic"

## cursor image
@export var cursor_img: Texture2D = preload("uid://xqsmti4l5pn0")
## the original img of the cursor (internal)
var _og_cursor_img: Image
## the scale of the custom cursor
@export var cursor_scale: float = 0.85




func _ready() -> void:
	# get the cursor img
	_og_cursor_img = cursor_img.get_image()
	# set the cursor img with a new scale
	_set_cursor_scale(cursor_scale)
	
	
	# add all the bg(s) to the bg node
	for bg_key in backgrounds:
		# get the bg
		var bg_packed: PackedScene = backgrounds[bg_key]
		
		# make the bg
		var bg_scene: SubViewport = bg_packed.instantiate()
		BG.add_child(bg_scene)
		
		# if this bg is the current bg set the bg as the texture of the bg_renderer
		if bg_key == current_bg:
			# create the viewport texture
			bg_renderer.texture = bg_scene.get_texture()







## sets the cursor img to one with a new scale
func _set_cursor_scale(new_scale: float):
	# get the image
	var scaled_img = _og_cursor_img.duplicate()
	# get the new size based on scale
	var new_size = Vector2(_og_cursor_img.get_width() * new_scale, _og_cursor_img.get_height() * new_scale)
	# set the size of the img
	scaled_img.resize(new_size.x, new_size.y, Image.INTERPOLATE_BILINEAR)
	# actually set the cursor img
	DisplayServer.cursor_set_custom_image(scaled_img)
