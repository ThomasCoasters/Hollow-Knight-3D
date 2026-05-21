## the screen you will see when you start the game
class_name startscreen
extends Control



## the node that renders the backgrounds in the front
@onready var bg_back: TextureRect = %"BG_Back"
## the node that renders the backgrounds in the back
@onready var bg_front: TextureRect = %"BG_Front"

## the node that contains all the bg stuff
@onready var BG: Control = %BG


## all the backgrounds
@export var backgrounds: Dictionary[StringName, PackedScene]

## current bg
var current_bg: StringName

## cursor image
@export var cursor_img: Texture2D = preload("uid://xqsmti4l5pn0")
## the original img of the cursor (internal)
var _og_cursor_img: Image
## the scale of the custom cursor
@export var cursor_scale: float = 0.85

## tween for the fading bg
var bg_tween: Tween


func _ready() -> void:
	# get the cursor img
	_og_cursor_img = cursor_img.get_image()
	# set the cursor img with a new scale
	_set_cursor_scale(cursor_scale)
	
	
	# set the current bg to the saved value
	current_bg = SaveLoad.general_contents[&"Extras"][&"Background"]
	
	# add all the bg(s) to the bg node
	for bg_key in backgrounds:
		# get the bg
		var bg_packed: PackedScene = backgrounds[bg_key]
		
		# make the bg
		var bg_scene: SubViewport = bg_packed.instantiate()
		BG.add_child(bg_scene)
		# set the name to the key name
		bg_scene.name = bg_key
		
		# if this bg is the current bg set the bg as the texture of the bg_renderer
		if bg_key == current_bg:
			# create the viewport texture
			bg_front.texture = bg_scene.get_texture()
			set_bg_visual(bg_key)


## sets the bg to the given value
func set_bg_visual(BG_name: String) -> void:
	# find the child with the given name in thhe BG node
	var bg: SubViewport = BG.get_node_or_null(BG_name)
	
	# if it does not exist give error and return
	if not bg:
		push_error("BG given does not exist: " + BG_name)
		return
	
	await RenderingServer.frame_post_draw
	
	# move current texture to back
	bg_back.texture = bg_front.texture
	
	# set new texture on front renderer
	bg_front.texture = bg.get_texture()
	
	# start invis
	bg_front.modulate.a = 0.0
	
	# delete tween if running
	if bg_tween:
		bg_tween.kill()
	
	# create tween + setup
	bg_tween = create_tween()
	bg_tween.set_parallel(true)
	
	# tween the front to front and back to back
	bg_tween.tween_property(bg_front, "modulate:a", 1.0, 0.5)
	
	# set the new BG to the current one
	current_bg = BG_name


## gets the current bg visual name
func get_bg_visual() -> StringName:
	# just return the current bg
	return current_bg



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
