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
	open_menu(initial_menu)


## hides all menus and shows the selected menu after
func open_menu(menu: Menu) -> void:
	# hide all menus first
	_hide_all_menus()
	
	# show the selected menu
	_show_menu(menu)



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


## runs when a menu button is pressed
func _on_menu_button_pressed(config: MenuConfigRecource, menu: Menu) -> void:
	# get the configs send to
	var send_to: Menu = get_node(str(get_path_to(menu)) + "/" + str(config.send_to)) as Menu
	# gets if the config has a send to (and if it is a menu)
	if send_to:
		# open the menu you should be send to
		open_menu(send_to)
