@tool

## the node that holds all of the menus
class_name menu_holder
extends Control


## the menu that will start as active
@export var initial_menu: Menu



func _ready() -> void:
	# bind all the menu signals
	_bind_menu_signals()
	
	# open the initial menu
	open_menu(initial_menu, false)


## hides all menus and shows the selected menu after
func open_menu(new_menu: Menu, fade_in_out: bool = true) -> void:
	# get the current menu
	var current_menu: Menu = _get_current_menu()
	
	# fade out the current menu
	if current_menu and fade_in_out:
		# fade the menu out and wait until the fade is finished
		await _animate_menu_fade(current_menu, false)
	
	# hide all menus after fading out
	_hide_all_menus()
	
	
	# show and fadde the new menu
	if new_menu:
		# make the new menu visible
		_show_menu(new_menu)
		
		#check if you should fade
		if fade_in_out:
			# fade the new menu in
			await _animate_menu_fade(new_menu, true)





## handles all the paralell fades for all the items in a selected menu
func _animate_menu_fade(menu: Menu, fading_in: bool) -> void:
	#disable all the buttons for every menu
	_toggle_buttons(true)
	
	# create a new tween and set everything as a parallel
	var tween = create_tween().set_parallel(true)
	
	# get all the menu items
	var items = menu.VerticalVisualContainer.get_children()
	
	# track what is the longest animation so we know when the whole menu is finished fading
	var max_time: float = 0.0
	
	# the current item index without the spacers
	var visual_index: int = 0
	
	# go through every item in the menu and set the animation
	for item_index: int in range(items.size()):
		# get the current item
		var item: Control = items[item_index] as Control
		
		# if the current item is not a control something is wrong and just ignore it
		if not item: continue
		
		# also continue if the current item is an spacer
		if item.is_in_group(&"spacer"): continue
		
		
		# get the config that is responsible for this visual
		var config: MenuConfigRecource = menu.visuals[visual_index]
		# we have no spacer now so increase the visual_index
		# make sure this increases after being used
		visual_index += 1
		
		
		# if there was no config for this item index continue
		if not config: continue
		
		# get the alpha we try to hit and start at
		var target_alpha: float = 1.0 if fading_in else 0.0
		var start_alpha : float = 0.0 if fading_in else 1.0
		
		# actually set the initial alpha
		item.modulate.a = start_alpha
		
		# look at how long the anim takes
		var delay:    float = config.in_start_delay if fading_in else config.out_start_delay
		var duration: float
		
		
		# if the item is an animated texture
		if config.mode == config.Mode.ANIMATED_TEXTURE:
			# find the AnimatedSprite2D inside the wraper
			var sprite: AnimatedSprite2D = item.get_child(0) as AnimatedSprite2D
			
			# if the sprite exists
			if sprite:
				# calculate duration based on frames
				var frame_count = sprite.sprite_frames.get_frame_count("default")
				duration = (1.0 / max(config.fps, 0.001)) * frame_count
				
				# force visible
				item.modulate.a = 1.0
				
				# handle the animation for animated textures
				_start_sprite_anim_with_delay(sprite, delay, fading_in)
				
				# sets the max time to the highest untill now
				max_time = max(max_time, delay + duration)
				
				
				# continue so that the normal animation stuff does not trigger
				continue
		
		# if the item is no animated texture
		else:
			# calculate the duration just by the values
			duration = config.in_fade_duration if fading_in else config.out_fade_duration
		
		# sets the max time to the highest untill now
		max_time = max(max_time, delay + duration)
		
		
		
		# animate the alpha
		tween.tween_property(item, "modulate:a", target_alpha, duration).set_delay(delay)
	
	
	# start the tween
	tween.play()
	
	# wait untill the longest item has finished playing
	await get_tree().create_timer(max_time).timeout
	
	
	
	# re-enable all buttons
	_toggle_buttons(false)


## helper function to delay the start of an animated texture
func _start_sprite_anim_with_delay(sprite: AnimatedSprite2D, delay: float, fading_in: bool) -> void:
	# if there is any delay
	if delay > 0:
		# wait until that delay has finished
		await get_tree().create_timer(delay).timeout
	
	# if it is fading in play it just forwards
	if fading_in:
		sprite.frame = 0
		sprite.play()
	
	# else play it backwards
	else:
		# play backwards
		sprite.play(&"default", -1.0, true)



## gets the current active menu
func _get_current_menu() -> Menu:
	# goes through every menu
	for menu in get_children():
		# check if it is visible (current menu)
		if menu.visible:
			# return that current menu
			return menu
	
	# if no menu is visible return null
	push_error("there is no currently active menu. HOW!?!?!?")
	return null

## binds all the menus signals to the correct func
func _bind_menu_signals() -> void:
	# get every menu
	for child: Menu in get_children():
		child.menu_button_pressed.connect(_on_menu_button_pressed)


## makes every menu invisible
func _hide_all_menus() -> void:
	# get every child
	for child: Menu in get_children():
		# make the child invis
		child.visible = false


## shows the selected menu
func _show_menu(menu: Menu) -> void:
	# makes the menu visible
	menu.visible = true
	
	# make the animated textures run
	_reset_animated_textures(menu)


## resets all animated textures in this menu
func _reset_animated_textures(menu: Menu) -> void:
	# get every item
	for item in menu.VerticalVisualContainer.get_children():
		#check if it is not an spacer
		if item.is_in_group(&"spacer"): continue
		
		# If this item has a child that is an AnimatedSprite2D
		if item.get_child_count() > 0 and item.get_child(0) is AnimatedSprite2D:
			# get that AnimatedSprite2D
			var sprite: AnimatedSprite2D = item.get_child(0)
			# stop the animation and reset it
			sprite.stop()
			sprite.frame = 0


## runs when a menu button is pressed
func _on_menu_button_pressed(config: MenuConfigRecource, menu: Menu) -> void:
	# get the configs send to
	var send_to: Menu = get_node(str(get_path_to(menu)) + "/" + str(config.send_to)) as Menu
	# gets if the config has a send to (and if it is a menu)
	if send_to:
		# open the menu you should be send to
		open_menu(send_to)



## dissables or enables all buttons
func _toggle_buttons(disable: bool) -> void:
	# get every menu
	for menu: Menu in get_children():
		# set the buttons to the selected vars in every menu
		menu.toggle_buttons(disable)
