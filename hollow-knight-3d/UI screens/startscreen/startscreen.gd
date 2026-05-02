@tool

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


func _ready() -> void:
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
