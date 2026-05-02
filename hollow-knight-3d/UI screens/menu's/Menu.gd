@tool

## a menu that is displayed in the startscreen or pausescreen
class_name Menu
extends Control


## the buttons / textures that should appear
@export var visuals: Array[MenuConfigRecource]


## the container for all the visuals
@onready var VerticalVisualContainer: VBoxContainer = %"VerticalVisualContainer"


## called when a menu button is clicked
signal menu_button_pressed(config: MenuConfigRecource, menu: Menu)



func _ready() -> void:
	# go through every visual and build them
	for visual in visuals:
		# get a refrence to the built visual
		var made_visual: Control = _create_visual(visual)
		
		# add the made visual as a child of the vbox
		VerticalVisualContainer.add_child(made_visual)
		
		# if relevant add a spacer
		if visual.should_add_spacer:
			# create the spacer
			var spacer: Control = Control.new()
			
			# set the spacer size
			spacer.custom_minimum_size.y = visual.spacer_size
			
			# add the spacer
			VerticalVisualContainer.add_child(spacer)



## creates the visuals for the given menu config
func _create_visual(config: MenuConfigRecource) -> Control:
	# the new built node
	var control: Control
	
	
	match config.mode:
		# if the mode is a button
		config.Mode.BUTTON:
			control = _create_button_visual(config)
		
		# if the mode is plain text
		config.Mode.TEXT:
			control = _create_text_visual(config)
		
		# if the config is a texture
		config.Mode.TEXTURE:
			control = _create_texture_visual(config)
		
		# if the config is an animated texture
		config.Mode.ANIMATED_TEXTURE:
			control = _create_animated_texture_visual(config)
		
		# if there is a NONE node just make a new control
		config.Mode.NONE:
			control = Control.new()
	
	
	
	# return the built node
	return control



## creates the texture for the given menu config
func _create_texture_visual(config: MenuConfigRecource) -> TextureRect:
	# create the texture node
	var tex: TextureRect = TextureRect.new()
	
	# set the texture
	tex.texture = config.texture
	
	# dissable expand mode
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# apply the scale
	tex.custom_minimum_size = config.texture.get_size() * config.texture_scale
	
	# return it
	return tex


func _create_animated_texture_visual(config: MenuConfigRecource) -> TextureRect:
	# create the texture node
	var tex: TextureRect = TextureRect.new()
	
	# dissable expand mode
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# create the animated texture
	var anim_tex: AnimatedTexture = AnimatedTexture.new()
	
	# set basic vars in the anim tex
	anim_tex.frames = config.anim_frames.size()
	anim_tex.fps = config.fps
	anim_tex.one_shot = !config.loop
	
	# add each frame from the array
	for i in range(config.animation_frames.size()):
		anim_tex.set_frame_texture(i, config.animation_frames[i])
	
	# set the texture
	tex.texture = anim_tex
	
	
	# apply the scale based off off the first frame
	tex.custom_minimum_size = config.animation_frames[0].get_size() * config.texture_scale
	
	# return it
	return tex


## creates the text for the given menu config
func _create_text_visual(config: MenuConfigRecource) -> Label:
	# create a new label
	var label: Label = Label.new()
	
	# make the text visuals
	_build_text_visual(label, config)
	
	# set the horizontal alignment to middle
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# return the label
	return label


## builds text based off off the given menu config
func _build_text_visual(node: Control, config: MenuConfigRecource) -> Control:
	#set the text to the selected text
	node.text = config.text
	
	# set the color
	# Check if the node is a Button to apply the color to all the states
	if node is Button:
		node.add_theme_color_override(&"font_color", config.text_color)
		node.add_theme_color_override(&"font_hover_color", config.text_color)
		node.add_theme_color_override(&"font_pressed_color", config.text_color)
		node.add_theme_color_override(&"font_focus_color", config.text_color)
	else:
		# Standard Label override
		node.add_theme_color_override(&"font_color", config.text_color)
	
	# set the font
	node.add_theme_font_override(&"font", config.font)
	
	# set the font size
	node.add_theme_font_size_override(&"font_size", config.font_size)
	
	
	#return the node
	return node


## creates the button for the given menu config
func _create_button_visual(config: MenuConfigRecource) -> Button:
	# create a button
	var button: Button = Button.new()
	
	# make the text visuals
	_build_text_visual(button, config)
	
	
	# create the empty stylebox
	var empty_stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
	
	# set all the styles to empty
	button.add_theme_stylebox_override(&"normal", empty_stylebox)
	button.add_theme_stylebox_override(&"hover", empty_stylebox)
	button.add_theme_stylebox_override(&"pressed", empty_stylebox)
	button.add_theme_stylebox_override(&"focus", empty_stylebox)
	
	
	# when the button is pressed what should happen
	button.pressed.connect(func():
		# emit the signal
		menu_button_pressed.emit.bind(config, self)
		
		# call the multiline script running object 
		# add "self" as the context so the script can change this node whatever it will
		ScriptRunUtil.execute_multiline_code(config.pressed_function, self)
	)
	
	
	# return the button
	return button
