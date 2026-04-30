## the root node off off the HUD that is displayed
class_name HUDMain
extends Control


## the current amount of mana
var mana: int = 0:
	set(value):
		#actually set the mana
		mana = clamp(value, 0, max_mana)
		
		
		#set the visual mana
		_change_visual_mana(value)


## the max amount of mana
@export var max_mana: int = 99 

## the visual of the mana
@export var Mana_HUD: mana_ball



## adds mana
func add_mana(amount: int) -> void:
	# add the amount to the mana and clamp it
	mana = clamp(mana + amount, 0, max_mana)

## removes mana
func remove_mana(amount: int) -> void:
	# add the amount to the mana and clamp it
	mana = clamp(mana - amount, 0, max_mana)


## visually changes the mana
func _change_visual_mana(new_amount: int) -> void:
	Mana_HUD.current_mana = new_amount


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Attack"):
		add_mana(11)
	
	if Input.is_action_just_pressed("Dash"):
		remove_mana(11)
