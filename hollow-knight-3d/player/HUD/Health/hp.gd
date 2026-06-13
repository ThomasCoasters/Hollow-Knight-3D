extends Control

## the scene of a singular heart
const HeartScene := preload("uid://hkpp3jyx1isp")

## an array of all the hearts
var hearts: Array[Control] = []

## the space between every hart
@export var space_between: float = 50


func _ready() -> void:
	# wait a few frames to make sure everything is made
	await get_tree().process_frame
	await get_tree().process_frame
	
	# create all the hearts
	_on_max_hp_change(Global.player.health_comp.max_health, Global.player.health_comp.max_health)
	
	# when the health or max health changed connect those functions
	Global.player.health_comp.health_changed.connect(_on_hp_change)
	Global.player.health_comp.max_health_changed.connect(_on_max_hp_change)



## creates all the hearts
## also runs when the max_hp_changes
func _on_max_hp_change(_new_max_health: int = 5, _old_max_health: int = 5):
	# delete all old hearts first
	_delete_old()
	
	# create the heart for every max health there is
	for i in range(Global.player.health_comp.max_health):
		# create the heart scene
		var heart = HeartScene.instantiate()
		# set the position
		heart.position.x = i * space_between
		# add the heart scene to the game
		add_child(heart)
		# add the heart to the hearts dictionairy
		hearts.append(heart)
		# set the heart to be filled
		heart.set_full(hearts.size() <= Global.player.health_comp.health)


## runs when the health changes
func _on_hp_change(new_health: int, _old_health: int):
	# wait one frame to make sure is there are any freezeframes it waits after that
	await get_tree().process_frame
	
	# go through every heart and set the full
	for i in range(hearts.size()):
		# set the full to true if it should be full else not full
		hearts[i].set_full(i + 1 < new_health)


## deletes all the old hearts
func _delete_old():
	# go through every heart
	for i in range(hearts.size()):
		# delete the front one
		hearts[0].queue_free()
		hearts.remove_at(0)
