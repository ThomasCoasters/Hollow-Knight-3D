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


## settings for the animation when pressing a button
@export var button_press_anim: MenuConfigRecource

## the max amount of columns this node can have
@export var max_columns: int = 1


func _ready() -> void:
	# get a refrence for the current row
	var current_row: HBoxContainer = null
	# get amount of objects in this row
	var object_row_count: int = 1
	
	# go through every visual and build them
	for visual in visuals:
		# get a refrence to the built visual
		var made_visual: Control = _create_visual(visual)
		
		# if this visual is full width
		if visual.full_width:
			# directly add it to the main VBox
			VerticalVisualContainer.add_child(made_visual)
			# reset the current row and obj row count
			current_row = null
			object_row_count = 1
		
		# if it is not full width
		else:
			# increase the object in this row
			object_row_count += 1
			
			# if we currently are not in a row OR the columns 
			if current_row == null or object_row_count > max_columns:
				# create a new HBoxcontainer
				current_row = HBoxContainer.new()
				# set the row to be max size
				
				# make all object try to be in the center
				current_row.alignment = BoxContainer.ALIGNMENT_CENTER
				# add it
				VerticalVisualContainer.add_child(current_row)
				
				# reset object row count
				object_row_count = 1
			
			
			
			
			# if relevant add a horizontal spacer
			if visual.should_add_horizontal_spacer and object_row_count != max_columns:
				# create the spacer
				var spacer: Control = Control.new()
				
				# set the spacer size
				spacer.custom_minimum_size.x = visual.horizontal_spacer_size
				
				# add the spacer to the current_row
				current_row.add_child(spacer)
				# also add it to a spacer group
				spacer.add_to_group(&"spacer")
			
			
			# add the visual to the HBox
			current_row.add_child(made_visual)
		
		
		
		# if relevant add a spacer
		if visual.should_add_vertical_spacer:
			# create the spacer
			var spacer: Control = Control.new()
			
			# set the spacer size
			spacer.custom_minimum_size.y = visual.vertical_spacer_size
			
			# add the spacer
			VerticalVisualContainer.add_child(spacer)
			# also add it to a spacer group
			spacer.add_to_group(&"spacer")



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
		
		# if the config is an row
		config.Mode.ROW:
			control = _create_row_visual(config)
		
		# if there is a NONE node just make a new control
		config.Mode.NONE:
			control = Control.new()
	
	
	# give a error if there is no (control) node made
	if !control:
		# send an error
		push_error("no control node was made in the menu for config: " + str(config) + ". Please change the mode to NONE if this was intended, else remove it.")
		# just make a temp new control as a substitute
		control = Control.new()
	
	# create a metadata on the control with the config
	control.set_meta(&"config", config)
	
	# return the built node
	return control



## creates the texture for the given menu config
func _create_texture_visual(config: MenuConfigRecource) -> TextureRect:
	# if there is no texture just return an empty texturerect
	if not config.texture:
		return TextureRect.new()
	
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

## creates the animated texture (AnimatedSprite2D wraped in an Control node)
func _create_animated_texture_visual(config: MenuConfigRecource) -> Control:
	# check if the animated texture does not have any frames
	if config.anim_frames.is_empty():
		# we assume this is a normal texture but still send a error
		push_error("given an animated texture visual but given no animation frames for config: " + str(config) + ". Assumed this is a normal texture but please set it as an normal texture.")
		# run the normal texture visual and return the made texture
		return _create_texture_visual(config)
	
	# create a control as the wrapper for the AnimatedSprite2D
	var wraper: Control = Control.new()
	
	# create the AnimatedSprite2D
	var sprite: AnimatedSprite2D= AnimatedSprite2D.new()
	# set the sprite frames to the made spriteframes
	sprite.sprite_frames = _build_sprite_frames(config)
	# set the animation to the made animation
	sprite.animation = "default"
	# play the animation
	sprite.play()
	
	# apply the scale based off off the first frame 
	wraper.custom_minimum_size = config.anim_frames[0].get_size() * config.texture_scale
	
	# the sprite inside the wraper
	sprite.position = wraper.custom_minimum_size / 2.0
	# set the scale of the sprite
	sprite.scale = config.texture_scale
	
	# add the spite to the wraper
	wraper.add_child(sprite)
	
	# return the wraper
	return wraper


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
		node.add_theme_color_override(&"font_disabled_color", config.text_color)
	else:
		# Standard Label override
		node.add_theme_color_override(&"font_color", config.text_color)
	
	# set the font
	node.add_theme_font_override(&"font", config.font)
	
	
	
	
	# set the font size
	node.add_theme_font_size_override(&"font_size", config.font_size)
	
	
	#return the node
	return node


## builds the animated texture
func _build_sprite_frames(config: MenuConfigRecource) -> SpriteFrames:
	# create a new spriteframes
	var frames := SpriteFrames.new()
	
	# check if there are any sprites
	if config.anim_frames.is_empty():
		# if not give an error and return the empty spriteframes
		push_error("No frames for animation: " + str(config))
		return frames
	
	# set the FPS but it can't go beneath 1
	var anim_fps: float = max(config.fps, 1.0)
	# set the fps off the animation
	frames.set_animation_speed("default", anim_fps)
	
	# add every texture to the animation
	for tex in config.anim_frames:
		# add it as an frame
		frames.add_frame("default", tex)
	
	# set if it should loop
	frames.set_animation_loop("default", config.loop)
	
	# return the spriteframes
	return frames




## creates the button for the given menu config
func _create_button_visual(config: MenuConfigRecource) -> Button:
	# create a button
	var button: Button = Button.new()
	
	# make the text visuals
	_build_text_visual(button, config)
	
	
	# create the empty stylebox
	var empty_stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
	
	# set the size to be the smallest possible (not full width of the screen)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# set all the styles to empty
	button.add_theme_stylebox_override(&"normal", empty_stylebox)
	button.add_theme_stylebox_override(&"hover", empty_stylebox)
	button.add_theme_stylebox_override(&"focus", empty_stylebox)
	button.add_theme_stylebox_override(&"disabled", empty_stylebox)
	button.add_theme_stylebox_override(&"pressed", empty_stylebox)
	
	
	# create a new anim sprite
	var sprite: AnimatedSprite2D = null
	
	# check if the button should have an anim on pressed
	if not button_press_anim.anim_frames.is_empty():
		# get the spriteframes
		var frames: SpriteFrames = _build_sprite_frames(button_press_anim)
		
		# set the basic values to the animated sprite
		sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = frames
		sprite.animation = "default"
		# don't autoplay this animation
		sprite.autoplay = ""
		
		# create a wraper so that the layout works
		var wraper := CenterContainer.new()
		
		# set the size flags
		wraper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wraper.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# set the custom minimum size
		wraper.custom_minimum_size = button_press_anim.anim_frames[0].get_size() * button_press_anim.texture_scale
		
		# make the wraper not steal inputs
		wraper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		
		wraper.set_anchors_preset(Control.PRESET_CENTER)
		
		
		# center the sprite
		sprite.centered = true
		sprite.position -= 10 * button_press_anim.texture_scale
		# set the scale of the sprite
		sprite.scale = button_press_anim.texture_scale
		# add the sprite to the wraper
		wraper.add_child(sprite)
		# add the wraper to the button
		button.add_child(wraper)
	
	
	
	# when the button is pressed what should happen
	button.pressed.connect(func():
		# check if there is an send to in the config and emit the signal
		if config.send_to:
			# emit the signal
			menu_button_pressed.emit(config, self)
		
		# play the sprite if it exists
		if sprite:
			# actually play the sprite
			sprite.play()
		
		# call the multiline script running object 
		# add "self" as the context so the script can change this node whatever it will
		# also add this button and the config
		ScriptRunUtil.execute_multiline_code(config.pressed_function, [self, config, button])
	)
	
	
	# return the button
	return button


## creates a horizontal container and populate it with sub-elements
func _create_row_visual(config: MenuConfigRecource) -> HBoxContainer:
	# create the row (HBox)
	var row: HBoxContainer = HBoxContainer.new()
	
	# add the seperation and make the objects exist from the center
	row.add_theme_constant_override(&"separation", config.row_spacing)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# add the sub elements
	for sub_cfg in config.sub_configs:
		# create element
		var element = _create_visual(sub_cfg) # can make more rows inside this row
		# add the element
		row.add_child(element)
	
	# return it
	return row





## dissables or enables all buttons
func toggle_buttons(disable: bool) -> void:
	# gets every child
	for button: Control in VerticalVisualContainer.get_children():
		# if it is not a button go to the next child
		if not button is Button: continue
		
		# if it is a button set the enable to the given value
		button.disabled = disable
