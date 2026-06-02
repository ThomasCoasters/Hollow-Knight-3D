@icon("random_audio_component.svg")
@tool

## component used to Play a random audio with a random pitch / speed.
## mostly used for sfx. Not reccomended to use for music
class_name random_audio_component
extends component


## the audios that should be randomised between.
## first is the name on how to find this then the settings
@export var random_audios: Dictionary[StringName, RandomAudioSettings]

## folows the position of this node
@export var following_node: Node3D

var AudioHolder: Node3D = Node3D.new()

var audio_players: Dictionary[StringName, AudioStreamPlayer3D]



func _process(_delta):
	# if there is a following node set the position to that node
	if following_node:
		AudioHolder.global_transform = following_node.global_transform


func _ready() -> void:
	# do not play in editor
	if Engine.is_editor_hint():
		return
	
	# add a Node3D that will be the parent for all the audioplayers
	add_child(AudioHolder)
	
	
	# go through the settings in the dictionary
	for key in random_audios:
		# the current RandomAudioSettings
		var settings: RandomAudioSettings = random_audios[key]
		
		# the randomizer
		var rando: AudioStreamRandomizer = AudioStreamRandomizer.new()
		
		
		# set all the basic settings
		rando.random_pitch = settings.random_ptich
		rando.random_volume_offset_db = settings.random_offset_db
		
		# add all the sounds to the randomizer
		for audio_index in settings.Audio.size():
			rando.add_stream(audio_index, settings.Audio[audio_index])
		
		
		# create the audio player
		var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		AudioHolder.add_child(player)
		audio_players[key] = player
		
		# change simple settings
		player.stream = rando
		player.bus = settings.audio_bus
		
		#set the settings audio player to the new audio player
		settings.audio_player = player




## plays the audio for the specified name
func play_audio(name: StringName):
	if audio_players.has(name):
		audio_players[name].play()
