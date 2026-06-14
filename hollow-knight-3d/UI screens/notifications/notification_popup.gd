## the popup for achievements
class_name notification_popup
extends Control

## queue of all the to be displayed achievements
var queue: Array[Dictionary] = []
## if there is currently an achievement showing
var showing: bool = false

## the label that has the title of achievements
@onready var title_label: Label = %TitleLabel
## the label that has the description of achievements
@onready var description_label: Label = %DescriptionLabel
## the margin container
@onready var margin_container: MarginContainer = %MarginContainer


@export_group("popup animation")
## the start (and end) Y value
@export var start_y: float = 1100.0
## the y value the popup will rest at
@export var target_y: float = 1000.0

## time the in animation takes
@export_range(0, 5, 0.1) var in_time: float = 1.0
## hold time
@export_range(0, 20, 0.1) var hold_time: float = 3.0
## time the out animation takes
@export_range(0, 5, 0.1) var out_time: float = 1.0

## the easing type of the animations
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT
## the transition type
@export var trans_type: Tween.TransitionType = Tween.TRANS_SINE

## the tween used
var tween: Tween


func _ready():
	# add achievements to the queue when they are unlocked
	NotificationManager.achievement_unlocked.connect(_queue_achievement)
	
	# also add notifications to the queue
	NotificationManager.notification_sent.connect(_queue_notification)


## queues the given achievement
func _queue_achievement(id: String):
	# add the achievement to the queue
	queue.append({
		&"title": NotificationManager.get_title(id),
		&"description": NotificationManager.get_description(id),
	})
	
	# if there is no achievement showing, show it
	if not showing:
		_show_next()

## queues the given notification
func _queue_notification(title: String, description: String) -> void:
	queue.append({
		"title": title,
		"description": description,
	})
	
	# if there is no achievement showing, show it
	if not showing:
		_show_next()



## shows the next achievement in the queue
func _show_next():
	# if there is nothing left in the queue
	if queue.is_empty():
		# stop showing
		showing = false
		return
	
	# set showing to true
	showing = true
	
	# get the ID of the next in the queue
	var queue_item: Dictionary = queue.pop_front()
	
	# get the x value on how far right this object is
	var right_x: float = margin_container.position.x + margin_container.size.x
	
	
	# set the text
	title_label.text = queue_item[&"title"]
	description_label.text = queue_item[&"description"]
	
	# reset the text size
	title_label.custom_minimum_size = Vector2.ZERO
	description_label.custom_minimum_size = Vector2.ZERO
	
	# reset the container size
	margin_container.size.x = 0
	
	# recalculate every size
	margin_container.update_minimum_size()
	margin_container.queue_sort()
	# wait one frame to have the resized stuff be visible
	await get_tree().process_frame
	
	# set the right position back to where is should be
	margin_container.position.x = right_x - margin_container.size.x
	
	# play anim and wait untill the tween is finished
	await _play_animation(margin_container)
	
	# show the next achievement
	_show_next()



## plays the in and out animation
func _play_animation(node: Node) -> void:
	# delete the old tween
	if tween and tween.is_running():
		tween.kill()
	
	# reset position
	node.position.y = start_y
	
	# create the new tween
	tween = create_tween()
	
	# tween inwards
	tween.tween_property(node, "position:y", target_y, in_time).set_trans(trans_type).set_ease(ease_type)
	
	# add the hold
	tween.tween_interval(hold_time)
	
	# go out
	tween.tween_property(node, "position:y", start_y, out_time).set_trans(trans_type).set_ease(ease_type)
	
	# wait untill tween finished
	await tween.finished
