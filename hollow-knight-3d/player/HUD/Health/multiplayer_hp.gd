extends MeshInstance3D

## the scene of a singular heart
const HeartScene := preload("uid://hkpp3jyx1isp")

## an array of all the hearts
var hearts: Array[Control] = []

## the space between every hart
@export var space_between: float = 50

## how many 3D meters represents 10 UI pixels
@export var pixel_to_3d_ratio: float = 0.01

## the health component of this player
@export var health_comp: health_component

## the subviewport that displays the HP
@onready var multiplayer_hp_sub_viewport: SubViewport = %MultiplayerHpSubViewport



func _ready() -> void:
	# wait a few frames to make sure everything is made
	await get_tree().process_frame
	await get_tree().process_frame
	
	# create all the hearts
	_on_max_hp_change(health_comp.max_health, health_comp.max_health)
	
	# when the health or max health changed connect those functions
	health_comp.health_changed.connect(_on_hp_change)
	health_comp.max_health_changed.connect(_on_max_hp_change)



## creates all the hearts
## also runs when the max_hp_changes
func _on_max_hp_change(_new_max_health: int = 5, _old_max_health: int = 5):
	# delete all old hearts first
	_delete_old()
	
	# get a refrence of the size of the hearts
	var heart_width: float = 0.0
	var heart_height: float = 0.0
	
	
	# create the heart for every max health there is
	for i in range(health_comp.max_health):
		# create the heart scene
		var heart = HeartScene.instantiate()
		# set the position
		heart.position.x = i * space_between
		# add the heart scene to the game
		multiplayer_hp_sub_viewport.add_child(heart)
		# add the heart to the hearts dictionairy
		hearts.append(heart)
		# set the heart to be filled
		heart.set_full(hearts.size() <= health_comp.health)
		
		# get a single heart's size
		if i == 0:
			heart_width = heart.size.x * heart.scale.x
			heart_height = heart.size.y * heart.scale.y
	
	# get the total width of all the hearts
	var total_width: float = ((health_comp.max_health - 1) * space_between) + heart_width
	
	# set the subviewport size
	multiplayer_hp_sub_viewport.size = Vector2i(int(total_width), int(heart_height))
	
	# center the hearts
	var start_x: float = (multiplayer_hp_sub_viewport.size.x - total_width) / 2.0
	var bottom_y: float = multiplayer_hp_sub_viewport.size.y - heart_height
	for i in range(hearts.size()):
		hearts[i].position.x = start_x + (i * space_between)
		hearts[i].position.y = bottom_y
	
	# get the 3D meters width and height
	var target_3d_width:  float = total_width  * pixel_to_3d_ratio / 10
	var target_3d_height: float = heart_height * pixel_to_3d_ratio / 10
	
	# set the size to the mesh holding the health billboard
	mesh.size = Vector2(target_3d_width, target_3d_height)


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
