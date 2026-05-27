## the holder for the maps that will be played
class_name MapHolder
extends Node


## the node that holds the maps
@onready var map_container: Node = %MapContainer

## the root node of the currently loaded map
var current_map_node: Node


func _ready() -> void:
	# set this to the map holder
	Global.map_holder = self
	
	# get saved map path
	var map_path: String = SaveLoad.current_game_contents[&"Location"][&"current_map"]
	
	# load map
	var packed: PackedScene = SceneLoader.force_get_scene(map_path)
	
	# add the packed map to the scene
	add_packed_map(packed)





## loads a new packed scene as the map
func add_packed_map(packed_map: PackedScene) -> void:
	# instantiate the map
	var map: Node = packed_map.instantiate()
	
	# set the current map node to the new map
	current_map_node = map
	
	
	# remove all the old maps
	for current_map: Node in map_container.get_children():
		current_map.queue_free()
	
	
	# add the map to the scene
	map_container.add_child(map)
