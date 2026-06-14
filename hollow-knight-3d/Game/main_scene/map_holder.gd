## the holder for the maps that will be played
class_name MapHolder
extends Node


## a refrence for a peer for online
var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

## the port the IP will be broadcasted on
const BROADCAST_PORT: int = 27016
## a UDP socket
var udp_socket: PacketPeerUDP = PacketPeerUDP.new()
## if this is currently broadcasting
var is_broadcasting: bool = false
## if this is currently listening
var is_listening: bool = false




## the node that holds the maps
@onready var map_container: Node = %MapContainer
## the node that holds the player scenes
@onready var player_holder: Node = %PlayerHolder
## the node that spawns multiplayer players
@onready var player_spawner: MultiplayerSpawner = %MultiplayerPlayerSpawner
## the timer that check how long the connection is taking
@onready var connection_timeout: Timer = %ConnectionTimeout

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
	
	# when the connection is taking to long, just go to solo
	connection_timeout.timeout.connect(_on_connection_failed)
	
	
	# load the startscreen for if something happens
	SceneLoader.request_scene("res://UI screens/startscreen/startscreen.tscn")




func _process(_delta: float) -> void:
	# if this is a client waiting for a host
	if is_listening and udp_socket.get_available_packet_count() > 0:
		# go through every packet
		while udp_socket.get_available_packet_count() > 0:
			# get the packet
			var packet: PackedByteArray = udp_socket.get_packet()
			# get the host's IP
			var host_ip: String = udp_socket.get_packet_ip()
			
			# create a new JSON
			var json: JSON = JSON.new()
			# get if the packed could be parced in a JSON
			if json.parse(packet.get_string_from_utf8()) == OK:
				# get the data
				var data = json.get_data()
				# if the data has a message with "GODOT_GAME_HOST"
				if data.get("message") == "GODOT_GAME_HOST":
					# we found a host, so stop the udp and connect to the IP
					_stop_udp()
					_connect_to_host_ip(host_ip)
					break




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
	peer.create_server(27015)
	# add the peer to the multiplayer peer
	multiplayer.multiplayer_peer = peer
	# add the player when a new peer is connected
	multiplayer.peer_connected.connect(_add_player)
	# delete the player when they disconnect
	multiplayer.peer_disconnected.connect(_remove_player)
	
	# add the player for the host
	_add_player(peer.get_unique_id())
	
	# start broadcasting this IP
	_start_broadcasting()
	
	# play a server start notification
	NotificationManager.notify(
		"Server Made",
		"You succesfully created a new server!"
	)


## join the host
func _join_host() -> void:
	# when the connection fails, run the connection failed
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# start listening for a host
	is_listening = true
	# close the udp socket
	udp_socket.close()
	# bind the broadcast port to the udp socked and listen for errors
	var ERROR: Error = udp_socket.bind(BROADCAST_PORT)
	
	# if something went wrong give error and stop
	if ERROR != OK:
		print("could not bind the BROADCAST_PORT (%s) to the udp_socket" % [BROADCAST_PORT])
		_on_connection_failed()
		return
	
	# start the connection timeout while we wait to find a broadcast
	connection_timeout.start()


## connects to the host IP that was found
func _connect_to_host_ip(host_ip: String) -> void:
	# get the error with connecting
	var ERROR: Error = peer.create_client(host_ip, 27015)
	
	# check if there is a error
	if not ERROR == OK:
		_on_connection_failed()
		return
	
	# add the peer to the multiplayer peer
	multiplayer.multiplayer_peer = peer


## background loop to tell the WIFI we exist
func _start_broadcasting() -> void:
	# set broadcasting to true
	is_broadcasting = true
	# close the udp_socket and bind any free port to send from
	udp_socket.close()
	udp_socket.bind(0)
	
	# create new data for the packet to send
	var packet_data: Dictionary[String, String] = {"message": "GODOT_GAME_HOST"}
	# get the JSON string and the packed buffer from it
	var json_string: String = JSON.stringify(packet_data)
	var packet_buffer: PackedByteArray = json_string.to_utf8_buffer()
	
	# broadcast every second
	while is_broadcasting:
		# set the destination to the broadcasting port on a broadcasting address
		udp_socket.set_dest_address("255.255.255.255", BROADCAST_PORT)
		# put a packed on the socket
		udp_socket.put_packet(packet_buffer)
		# wait
		await get_tree().create_timer(1.0).timeout



## stops the udp when connected or finished connecting
func _stop_udp() -> void:
	# stop broadcasting and listening
	is_broadcasting = false
	is_listening = false
	# close the udp socket
	udp_socket.close()


## runs when the connection is timed out or fails
func _on_connection_failed() -> void:
	# stop the udp
	_stop_udp()
	
	# check if not already connected
	if not peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		# exit the server
		peer.close()
		multiplayer.multiplayer_peer = null
		
		# just add the player
		_add_player()
		
		# send a notification about the problem
		NotificationManager.notify(
			"Connecting Failed",
			"The Server Could Not Be Reached. Starting Solo Game."
		)


## adds a player
func _add_player(id: int = 1) -> void:
	# If a client successfully joined, we can stop the timeout
	if multiplayer.multiplayer_peer != null:
		if id == multiplayer.get_unique_id() and id != 1:
			connection_timeout.stop()
	
	# instantiate the player
	var player: Player = player_scene.instantiate()
	
	# set the name to the id
	player.name = str(id)
	
	# add the player to the scene
	player_holder.call_deferred("add_child", player)
	
	
	if multiplayer.multiplayer_peer != null:
		if not id == multiplayer.get_unique_id():
			NotificationManager.global_notification.rpc("Player Joined", "A new player has just entered the game.")


## removes a player when they disconnect
func _remove_player(id: int) -> void:
	# get the player node by their ID
	var player_to_remove = player_holder.get_node_or_null(str(id))
	
	# if they exist
	if player_to_remove:
		# delete them
		player_to_remove.queue_free()
		
		
		# send a notification about them leaving
		NotificationManager.global_notification.rpc(
			"Player Left The Game",
			"A player has just left the game."
		)


## runs when a joined player disconnects from the server
func _on_server_disconnected() -> void:
	# stop the network peer
	peer.close()
	multiplayer.multiplayer_peer = null
	
	# notify the player
	NotificationManager.notify(
		"Disconnected", 
		"The connection to the host was lost."
	)
	
	#makes the mouse visible again
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# go back to the startscreen
	get_tree().change_scene_to_packed(SceneLoader.force_get_scene("res://UI screens/startscreen/startscreen.tscn"))
