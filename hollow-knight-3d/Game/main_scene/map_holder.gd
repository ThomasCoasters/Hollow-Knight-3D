## the holder for the maps that will be played
class_name MapHolder
extends Node


## a refrence for a peer for online
var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()


## the node that holds the maps
@onready var map_container: Node = %MapContainer
## the node that holds the player scenes
@onready var player_holder: Node = %PlayerHolder
# the node that spawns multiplayer players
@onready var player_spawner: MultiplayerSpawner = %MultiplayerPlayerSpawner

## the root node of the currently loaded map
var current_map_node: Node


## the normal player scene
@export var player_scene: PackedScene


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
	
	
	# check the multiplayer mode
	match SaveLoad.general_contents[&"Online"][&"MultiplayerMode"]:
		# when playing solo
		"Solo":
			_add_player()
		
		# when you are the host
		"Host":
			_create_host()
		
		# when you are just joining a host
		"Join":
			_join_host()





## creates the host
func _create_host() -> void:
	# add a server to the multiplayer peer
	peer.create_server(135)
	# add the peer to the multiplayer peer
	multiplayer.multiplayer_peer = peer
	# add the player when a new peer is connected
	multiplayer.peer_connected.connect(_add_player)
	
	# add the player for the host
	_add_player(peer.get_unique_id())


## join the host
func _join_host() -> void:
	# add a server to the multiplayer peer
	var ERROR: Error = peer.create_client("localhost", 135)
	
	# check if there is a error
	match ERROR:
		# if the peer is already in use close it
		ERR_ALREADY_IN_USE:
			peer.close()
		
		# if it could not be created, just do like it is a solo game
		ERR_CANT_CREATE:
			_add_player(peer.get_unique_id())
			return
	
	# add the peer to the multiplayer peer
	multiplayer.multiplayer_peer = peer




## adds a player
func _add_player(id: int = 1) -> void:
	# instantiate the player
	var player: Player = player_scene.instantiate()
	
	# set the name to the id
	player.name = str(id)
	
	# add the player to the scene
	player_holder.call_deferred("add_child", player)
	
