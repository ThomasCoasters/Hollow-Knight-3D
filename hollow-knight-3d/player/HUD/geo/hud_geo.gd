## the geo visuals in the UI
class_name GeoCounter
extends Control


## the time the plus amount will stay until it increases visually
@export var increase_wait_time: float = 1.5
## the current time left until it increases visually
var increase_wait_timer: float = 0.0

## the sprite
@onready var geo_visual: Sprite2D = %Geo_Visual
## label containing the current geo count - the increasing amount
@onready var current_txt: Label = %current_txt
## label containing the amount the current amount will increase by
@onready var increase_txt: Label = %increase_txt


## the current amount of geo you have
var current_geo_amount: int
## the current amount of geo that is displayed
var displayed_geo_amount: int
## the current amount of geo that will be added to the displayed amount
var increasing_geo_amount: int = 0
## the increasing amount that is currently displayed
var displayed_increase_amount: int = 0

## the tween for the increase text
var increase_tween: Tween



func _ready() -> void:
	# get the geo amount
	current_geo_amount = SaveLoad.current_game_contents[&"UI"][&"GeoAmount"]
	
	# if the amount is 0 or less make all the visuals invis
	if current_geo_amount <= 0:
		geo_visual.visible  = false
		current_txt.visible = false
	
	# set the displayed amounts
	displayed_geo_amount = current_geo_amount
	current_txt.text = str(displayed_geo_amount)
	
	
	# always start increase text invis
	increase_txt.visible = false



func _process(delta: float) -> void:
	# decrease the wait timer
	if increase_wait_timer > 0.0:
		increase_wait_timer -= delta
		
		# check if the time is done
		if increase_wait_timer <= 0.0:
			_visual_increase_geo()




## increases the geo
func increase_geo(amount: int) -> void:
	# increase the vars
	current_geo_amount += amount
	increasing_geo_amount += amount
	
	# reset the increase timer
	increase_wait_timer = increase_wait_time
	
	# show the increase label
	_show_increase_label()
	
	# change the saved geo amount
	SaveLoad.current_game_contents[&"UI"][&"GeoAmount"] = current_geo_amount



## shows the increase text label
func _show_increase_label() -> void:
	# if the text is not currently visible
	if not increase_txt.visible:
		# make the increase label visual
		increase_txt.visible = true
		# set the position
		increase_txt.global_position = current_txt.global_position + Vector2(current_txt.size.x + 40.0, 0.0)
	
	# make all other visuals visible
	if not geo_visual.visible:  geo_visual.visible  = true
	if not current_txt.visible: current_txt.visible = true
	
	
	
	# create the tween
	if increase_tween:
		increase_tween.kill()
	increase_tween = create_tween()
	
	# set the text
	increase_tween.tween_method(
		func(value):
			displayed_increase_amount = roundi(value)
			increase_txt.text = "+" + str(displayed_increase_amount) if displayed_increase_amount >= 0 else str(displayed_increase_amount),
		displayed_increase_amount,
		increasing_geo_amount,
		0.5
	)



## increases the geo visually
func _visual_increase_geo() -> void:
	# create the tween
	if increase_tween:
		increase_tween.kill()
	increase_tween = create_tween()
	
	# the starting amount of increasing geo and displayed geo
	var start_increase_amount = increasing_geo_amount
	var start_displayed_amount = displayed_geo_amount
	
	# set the text of the increase value
	increase_tween.tween_method(
		func(value):
			increasing_geo_amount = roundi(value)
			displayed_geo_amount = roundi(start_displayed_amount + start_increase_amount - value)
			displayed_increase_amount = increasing_geo_amount
			current_txt.text = str(displayed_geo_amount)
			increase_txt.text = "+" + str(increasing_geo_amount) if increasing_geo_amount >= 0 else str(increasing_geo_amount),
			
		increasing_geo_amount,
		0.0,
		0.75
	)
	
	increase_tween.finished.connect(func(): increase_txt.visible = false)
