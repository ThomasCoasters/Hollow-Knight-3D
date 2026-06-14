## autoload that manages achievements
class_name notification_manager 
extends Node


## emitted when a new achievement is unlocked
signal achievement_unlocked(id: StringName)
## emitted when a notification is sent
signal notification_sent(title: String, description: String)

## the scene of the popups
const POPUP_SCENE: Resource = preload("res://UI screens/notifications/NotificationPopup.tscn")



func _ready() -> void:
	# add the popup scene to the game
	var popup = POPUP_SCENE.instantiate()
	add_child(popup)




## sents an notification
func notify(title: String, description: String) -> void:
	# emit the signal with the given settings
	notification_sent.emit(title, description)


## unlocks an achievement with the given ID
func unlock(id: StringName) -> void:
	# it the given achievement is already unlocked return
	if is_unlocked(id): return
	
	# set achievement to be unlocked
	SaveLoad.general_contents[&"Achievements"][id][&"unlocked"] = true
	
	# emit the achievement unlocked signal
	achievement_unlocked.emit(id)




## gets the given achievement ID is already unlocked
func is_unlocked(id: StringName) -> bool:
	return SaveLoad.general_contents[&"Achievements"][id][&"unlocked"]


## gets the data of the achievement with the given ID
func get_data(id: StringName) -> Dictionary:
	return SaveLoad.general_contents[&"Achievements"][id]



## gets the title of the given achievement ID
func get_title(id: StringName) -> String:
	return get_data(id)[&"title"]

## gets the description of the given achievement ID
func get_description(id: StringName) -> String:
	return get_data(id)[&"description"]


@rpc("any_peer", "call_local")
## notifies every player with the given notification
func global_notification(title: String, description: String) -> void:
	# This reuses your existing notify logic, but runs on all clients
	notify(title, description)
