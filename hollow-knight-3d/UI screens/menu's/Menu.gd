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

## settings for the animation that plays when the button is hovered[br]
## plays on the side with an offset and other side fliped
@export var button_hover_anim: MenuConfigRecource

## the max amount of columns this node can have
@export var max_columns: int = 1

## the input nodes this menu has
var menu_inputs: Array[Array] = []


func _ready() -> void:
	# get a refrence for the current row
	var current_row: HBoxContainer = null
	# get amount of objects in this row
	var object_row_count: int = 1
	
	# add a anitional empty row to start tracking the menu inputs
	menu_inputs.clear()
	
	# go through every visual and build them
	for visual in visuals:
		
		# if this visual is full width
		if visual.full_width:
			# start a new array for the menu inputs
			menu_inputs.append([])
			# reset the current row and obj row count
			current_row = null
			object_row_count = 1
		
		# if it is not full width
		else:
			# increase the object in this row
			object_row_count += 1
			
			# if we currently are not in a row OR the columns 
			if current_row == null or object_row_count > max_columns:
				# start a new array for the menu inputs
				menu_inputs.append([])
				
				# create a new HBoxcontainer
				current_row = HBoxContainer.new()
				
				# make all object try to be in the center
				current_row.alignment = BoxContainer.ALIGNMENT_CENTER
				# add it
				VerticalVisualContainer.add_child(current_row)
				
				# reset object row count
				object_row_count = 1
			
			
		# get a refrence to the built visual
		var made_visual: Control = _create_visual(visual)
		
		# if this visual is full width
		if visual.full_width:
			# directly add it to the main VBox
			VerticalVisualContainer.add_child(made_visual)
		
		# if it is not full width
		else:
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
	
	
	
	# setup the keyboard nav
	_setup_keyboard_navigation()


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
		
		# if the config is an button row
		config.Mode.BUTTON_ROW:
			control = _create_button_row_visual(config)
		
		# if the config is an slider
		config.Mode.SLIDER:
			control = _create_slider_visual(config)
		
		# if there is a NONE node just make a new control
		config.Mode.NONE:
			control = _create_empty_node(config)
	
	
	# give a error if there is no (control) node made
	if !control:
		# send an error
		push_error("no control node was made in the menu for config: " + str(config) + ". Please change the mode to NONE if this was intended, else remove it.")
		# just make a temp new control as a substitute
		control = Control.new()
	
	# create a metadata on the control with the config
	control.set_meta(&"config", config)
	
	# apply offset to the given node
	control = _apply_offset_if_needed(control, config)
	
	# return the built node
	return control





## creates an empty node (with possibility for extra settings)
func _create_empty_node(config: MenuConfigRecource) -> Control:
	# create the empty control
	var control: Control
	
	# check if the row settings are enabled and there are any sub cofigs
	if config._row_group_enabled and config.sub_configs:
		# create a wraper so that the layout works
		var wraper: MarginContainer = MarginContainer.new()
		
		# add the wraper to the wraper group
		wraper.add_to_group(&"wraper")
		
		# set the size flags
		wraper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wraper.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# make the wraper not steal inputs
		wraper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# add sub elements to this control
		wraper = _build_sub_elements(wraper, config)
		
		# set the control to this wraper
		control = wraper
	
	# otherwise make an control
	else: control = Control.new()
	
	
	# return the control
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
	
	# create a control as the wraper for the AnimatedSprite2D
	var wraper: Control = Control.new()
	
	#set the wraper horizontal size flags
	wraper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# add the wraper to the wraper group
	wraper.add_to_group(&"wraper")
	
	
	
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
	
	# make the hover fx
	_build_button_hover_anim(button, config)
	
	# change the button to have an invis bg
	button = _build_invis_button_bg(button)
	
	
	
	# add to the menu input array
	menu_inputs.back().append(button)
	
	# set the size to be the smallest possible (not full width of the screen)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	
	
	# add the animnation when pressing the button.
	# also get the result
	var result = _build_button_press_anim(button)
	
	# get the new button from the result
	button = result[0]
	# also get the sprite
	var sprite: AnimatedSprite2D = result[1]
	
	
	
	# call the multiline script running object 
	# add "self" as the context so the script can change this node whatever it will
	# also add this button and the config
	ScriptRunUtil.execute_multiline_code(config.ready_function, [self, config, button])
	
	
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
	row = _build_sub_elements(row, config)
	
	# return it
	return row





## builds sub elements
func _build_sub_elements(parent: Control, config: MenuConfigRecource) -> Control:
	# go through every sub config
	for i in config.sub_configs.size():
		# get the current sub config
		var sub_cfg: MenuConfigRecource = config.sub_configs[i]
		# create the visual
		var element: Control = _create_visual(sub_cfg)
		# add the visual
		parent.add_child(element)
		
		
		# get if this is the last one
		var is_last: bool = i == config.sub_configs.size() - 1
		
		# if there should be an horizontal spacer and this is not the last visual add it
		if sub_cfg.should_add_horizontal_spacer and not is_last:
			# create the spacer
			var spacer: Control = Control.new()
			
			# set spacer size
			spacer.custom_minimum_size.x = sub_cfg.horizontal_spacer_size
			# add the spacer
			parent.add_child(spacer)
			# add spacer to the spacer group
			spacer.add_to_group(&"spacer")
	
	
	
	# return the parent back
	return parent


## build the visual for the button press anim
func _build_button_press_anim(button: Button):
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
		var wraper: CenterContainer = CenterContainer.new()
		
		# add the wraper to the wraper group
		wraper.add_to_group(&"wraper")
		
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
	
	
	# return the updated button and the sprite
	return [button, sprite]


## builds an empty button background visual
func _build_invis_button_bg(button: Button) -> Button:
	# create the empty stylebox
	var empty_stylebox: StyleBoxEmpty = StyleBoxEmpty.new()
	
	# set all the styles to empty
	button.add_theme_stylebox_override(&"normal", empty_stylebox)
	button.add_theme_stylebox_override(&"hover", empty_stylebox)
	button.add_theme_stylebox_override(&"focus", empty_stylebox)
	button.add_theme_stylebox_override(&"disabled", empty_stylebox)
	button.add_theme_stylebox_override(&"pressed", empty_stylebox)
	
	# return the new button
	return button



## builds the hover animation visuals
func _build_button_hover_anim(button: Button, config: MenuConfigRecource) -> void:
	# check if there is no anim given
	if button_hover_anim.anim_frames.is_empty():
		# build nothing
		return
	
	
	
	# store refrences to the sprites
	var hover_sprites: Array[AnimatedSprite2D] = []
	# also store wrappers
	var hover_wrappers: Array[Control] = []
	
	
	# updates the hover position of the hover wrapers
	var update_hover_positions = func():
		# wait one frame so layout is valid
		await get_tree().process_frame
		
		# get the frame size
		var frame_size := button_hover_anim.anim_frames[0].get_size()
		frame_size *= button_hover_anim.texture_scale
		
		# update all sprites
		for i in hover_sprites.size():
			var sprite := hover_sprites[i]
			
			# LEFT
			if i == 0:
				sprite.position = Vector2(
					config.hover_offset[i].x,
					button.size.y / 2.0 + config.hover_offset[i].y
				)
			
			# RIGHT
			else:
				sprite.position = Vector2(
					button.size.x + config.hover_offset[i].x,
					button.size.y / 2.0 + config.hover_offset[i].y
				)
			
			# center properly
			sprite.position -= frame_size / 2.0
	
	
	
	
	
	# create the hover visuals
	for i in 2:
		# create a wrapper
		var wrapper := Control.new()
		
		# make the wrapper not steal inputs
		wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# make the wraper full rect so positioning is correct
		wrapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		# create the sprite
		var sprite := AnimatedSprite2D.new()
		
		# setup the sprite's frames
		sprite.sprite_frames = _build_sprite_frames(button_hover_anim)
		sprite.animation = "default"
		
		# set the scale
		sprite.scale = button_hover_anim.texture_scale
		
		# flip the right animation
		if i == 1:
			sprite.flip_h = true
		
		# start invis and frame 0
		sprite.frame = 0
		sprite.stop()
		sprite.visible = false
		
		# add the sprite
		wrapper.add_child(sprite)
		
		# add the wrapper
		button.add_child(wrapper)
		
		
		update_hover_positions.call()
		
		# store the sprite
		hover_sprites.append(sprite)
		# also store wrapper
		hover_wrappers.append(wrapper)
	
	
	
	
	# a function for when the hover should be shown
	var show_hover = func():
		# get the sprites
		for sprite in hover_sprites:
			# make visible
			sprite.visible = true
			
			# play anim forward from corrent frame
			sprite.play()
	
	# a function for when the hover visual should be hidden
	var hide_hover = func():
		# get every animation again
		for sprite in hover_sprites:
			# play the anim backwards from the current frame
			sprite.play_backwards()
	
	
	
	# runs when you hover/focus the button
	button.focus_entered.connect(show_hover)
	button.mouse_entered.connect(func():
		# if the button already has focus no need to start all these things
		if button.has_focus(): return
		
		# make this button get the focus
		button.grab_focus()
		# make the visuals appear
		show_hover.call()
	)
	
	
	# runs when you un-hover/un-focus the button
	button.focus_exited.connect(hide_hover)
	button.mouse_exited.connect(func():
		# if not have focus do nothing
		if not button.has_focus(): return
		
		# play the animation
		hide_hover.call()
		# also stop button from having focus
		button.release_focus()
	)
	
	
	# get all the sprites
	for sprite in hover_sprites:
		# runs when the sprite's frame changes
		sprite.frame_changed.connect(func():
			# if the button is currently not hovered (anim is played in reverse)
			if not button.is_hovered() and not button.has_focus():
				# check if the frame is the first one 0
				if sprite.frame == 0:
					# stop the anim
					sprite.stop()
					# make the sprite invis
					sprite.visible = false
		)
	
	# when the button is resized
	button.resized.connect(func():
		# update the hover positions
		update_hover_positions.call()
	)



## creates a container and populate it with sub-elements while having it work like a button
func _create_button_row_visual(config: MenuConfigRecource) -> Button:
	# create the row (button)
	var row_button: Button = Button.new()
	
	# make the text visuals
	_build_text_visual(row_button, config)
	
	# make the hover fx
	_build_button_hover_anim(row_button, config)
	
	# change the button to have an invis bg
	row_button = _build_invis_button_bg(row_button)
	
	# create a layout container
	var hbox: HBoxContainer = HBoxContainer.new()
	
	# lets click go through this container
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# set the ancors correct
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# add the seperation and make the objects exist from the center
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override(&"separation", config.row_spacing)
	# add the sub elements
	hbox = _build_sub_elements(hbox, config)
	
	# add to the menu input array
	menu_inputs.back().append(row_button)
	
	# add the hbox
	row_button.add_child(hbox)
	
	
	
	# add the animnation when pressing the button.
	# also get the result
	var result = _build_button_press_anim(row_button)
	
	# get the new button from the result
	row_button = result[0]
	# also get the sprite
	var sprite: AnimatedSprite2D = result[1]
	
	
	# call the multiline script running object 
	# add "self" as the context so the script can change this node whatever it will
	# also add this button and the config
	ScriptRunUtil.execute_multiline_code(config.ready_function, [self, config, row_button])
	
	
	
	# when the button is pressed what should happen
	row_button.pressed.connect(func():
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
		ScriptRunUtil.execute_multiline_code(config.pressed_function, [self, config, row_button])
	)
	
	
	# idk why this was needed but it broke otherwise
	_set_button_size_to_container(row_button, hbox)
	
	# return it
	return row_button




## creates a slider
func _create_slider_visual(config: MenuConfigRecource) -> Control:
	# a wrapper for the slider contents
	var root: Control = Control.new()
	root.add_to_group(&"wraper")
	# set the wraper size to the given size for the slider
	root.custom_minimum_size = config.slider_size
	
	# create the slider
	var slider: HSlider = HSlider.new()
	
	# set the slider values (min max and staring value)
	slider.min_value = config.slider_min
	slider.max_value = config.slider_max
	slider.value = config.slider_value
	# make the slider full size
	slider.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# make a empty visual for the slider
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	# add the empty visual
	slider.add_theme_stylebox_override("slider", empty)
	slider.add_theme_stylebox_override("grabber_area", empty)
	slider.add_theme_stylebox_override("grabber_area_highlight", empty)
	# also make the grabber invis
	slider.add_theme_icon_override("grabber", ImageTexture.create_from_image(Image.create(1,1,false,Image.FORMAT_RGBA8)))
	slider.add_theme_icon_override("grabber_highlight", ImageTexture.create_from_image(Image.create(1,1,false,Image.FORMAT_RGBA8)))
	
	# add the slider to the wraper
	root.add_child(slider)
	
	# create a line for the bg
	var bg: Panel = Panel.new()
	# create the visual for the bg
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = config.slider_bg_color
	
	# set the rounded corners for the bg
	bg_style.corner_radius_top_left = config.slider_corner_radius
	bg_style.corner_radius_top_right = config.slider_corner_radius
	bg_style.corner_radius_bottom_left = config.slider_corner_radius
	bg_style.corner_radius_bottom_right = config.slider_corner_radius
	
	# add the visuals to the bg
	bg.add_theme_stylebox_override("panel", bg_style)
	# make the bg not take inputs
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# set the size for the bg to be correct
	bg.custom_minimum_size = Vector2(config.slider_size.x, config.slider_bar_height)
	# set the position of the bg to be correct
	bg.position = Vector2(0, (config.slider_size.y - config.slider_bar_height) / 2.0)
	
	# add the bg to the wraper
	root.add_child(bg)
	
	# create the visual for the filled visual
	var fill := Panel.new()
	
	# create the visual for the fill line
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = config.slider_fill_color
	# set the rounded corners
	fill_style.corner_radius_top_left = config.slider_corner_radius
	fill_style.corner_radius_top_right = config.slider_corner_radius
	fill_style.corner_radius_bottom_left = config.slider_corner_radius
	fill_style.corner_radius_bottom_right = config.slider_corner_radius
	# add the visual to the fill
	fill.add_theme_stylebox_override("panel", fill_style)
	# make the fill not take up mouse inputs
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# set the y size of the fill visual 
	fill.custom_minimum_size.y = config.slider_bar_height
	# set the position correct (already calculated before)
	fill.position = bg.position
	# add the fill to the wraper
	root.add_child(fill)
	
	# create the pointer visual
	var pointer := TextureRect.new()
	# set the texture of the pointer visual
	pointer.texture = config.texture
	# set the pointer to be a good UI thing
	pointer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# set the scale of the pointer
	if pointer.texture:
		pointer.custom_minimum_size = (pointer.texture.get_size() * config.texture_scale)
	# rotate the pointer
	pointer.rotation_degrees = config.texture_rotation
	
	# add the pointer to the wraper
	root.add_child(pointer)
	
	
	# func that updates the visuals
	var update_slider_visuals = func():
		# get the ratio of the inputted value
		var ratio: float = (slider.value - slider.min_value) / (slider.max_value - slider.min_value)
		# get the x size value
		var x: float = ratio * config.slider_size.x if ratio > 0 else 0.025 * config.slider_size.x
		
		# set the size for the fill
		fill.size.x = x
		
		# update the texture position
		if pointer.texture:
			# get the size of the pointer
			var tex_size: Vector2 = (pointer.texture.get_size() * config.texture_scale)
			
			# set the position of the pointer
			pointer.position = Vector2(x - tex_size.x / 2.0, bg.position.y - tex_size.y - 8) + config.texture_offset
	
	# update the visuals
	update_slider_visuals.call()
	
	# what happens when the slider value changes
	slider.value_changed.connect(func(value):
		# update the visuals every time the slider value changed
		update_slider_visuals.call()
		
		# run the function inputted in the slider
		ScriptRunUtil.execute_multiline_code(config.slider_changed_function, [self, config, slider, value])
	)
	
	
	# run the ready func
	ScriptRunUtil.execute_multiline_code(config.slider_ready_function, [self, config, slider])
	
	
	# return the wraper
	return root








## only fix ig
func _set_button_size_to_container(button: Button, hbox: HBoxContainer) -> void:
	# wait untill the hbox has any size
	while hbox.size == Vector2.ZERO:
		await get_tree().process_frame
	
	# set the buttons min size to the hbox size
	button.custom_minimum_size = hbox.size



## dissables or enables all buttons
func toggle_buttons(disable: bool) -> void:
	# gets every child
	for button: Control in VerticalVisualContainer.get_children():
		# if it is not a button go to the next child
		if not button is Button: continue
		
		# if it is a button set the enable to the given value
		button.disabled = disable









## setups the keyboard navigation for inputs
func _setup_keyboard_navigation() -> void:
	# remove empty rows
	menu_inputs = menu_inputs.filter(func(row): return not row.is_empty())
	
	# if there are no contents return
	if menu_inputs.is_empty(): return
	
	# go through every row in the menu inputs
	for row in menu_inputs.size():
		# go through every content in the given row
		for content in menu_inputs[row].size():
			# get the current control node
			var current: Control = menu_inputs[row][content]
			# make the current control node focus all things
			current.focus_mode = Control.FOCUS_ALL
			
			
			# find the row above/below the current control
			var up_row_idx = wrapi(row - 1, 0, menu_inputs.size())
			var down_row_idx = wrapi(row + 1, 0, menu_inputs.size())
			
			# only target nodes on the same column above or below this one
			var target_up = menu_inputs[up_row_idx][min(content, menu_inputs[up_row_idx].size() - 1)]
			var target_down = menu_inputs[down_row_idx][min(content, menu_inputs[down_row_idx].size() - 1)]
			
			# set the top and bottom neighbours
			current.focus_neighbor_top = current.get_path_to(target_up)
			current.focus_neighbor_bottom = current.get_path_to(target_down)
			
			
			
			# check if this row has only one control
			if menu_inputs[row].size() == 1:
				# this is a full width button so no side nodes
				# get the current nodes path
				var self_path: NodePath = current.get_path()
				# set the neighbours left and right to itself (so nothing happens)
				current.focus_neighbor_left = self_path
				current.focus_neighbor_right = self_path
			else:
				# this control is in a row
				# get thhe left / right control in this row
				var left_idx = wrapi(content - 1, 0, menu_inputs[row].size())
				var right_idx = wrapi(content + 1, 0, menu_inputs[row].size())
				
				# get the left / right neighbors
				current.focus_neighbor_left = current.get_path_to(menu_inputs[row][left_idx])
				current.focus_neighbor_right = current.get_path_to(menu_inputs[row][right_idx])



## haves thhe first input grab focus
func focus_first_input() -> void:
	# go through every row in the menu inputs
	for row in menu_inputs:
		# also through every input in said row
		for input in row:
			# check if said input is valid
			if is_instance_valid(input) and not input.disabled:
				# give it focus and stop
				input.grab_focus()
				return




## applies offset to the given control if it should have offset
func _apply_offset_if_needed(control: Control, config: MenuConfigRecource) -> MarginContainer:
	# not ofset = instant return without change
	if not config.should_have_offset:
		return control
	
	# create a wrapper
	var wraper: MarginContainer = MarginContainer.new()
	
	# set the wrapper offset
	@warning_ignore("narrowing_conversion")
	wraper.add_theme_constant_override("margin_left", config.offset.x)
	@warning_ignore("narrowing_conversion")
	wraper.add_theme_constant_override("margin_top", config.offset.y)
	
	# add the wraper to the wraper group
	wraper.add_to_group(&"wraper")
	
	# add the given node to the wraper and return the wraper
	wraper.add_child(control)
	return wraper


## returns wether or not this menu has any focus inputs
func contains_focus_input() -> bool:
	# go through every row in the menu inputs
	for row in menu_inputs:
		# go through every input in said row
		for input in row:
			# if said input has focus return true
			if input.has_focus(): return true
	
	# if none had focus return false
	return false
