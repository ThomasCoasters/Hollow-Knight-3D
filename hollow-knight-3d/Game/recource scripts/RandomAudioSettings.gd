class_name RandomAudioSettings
extends Resource

## the audio that should play
@export var Audio: Array[AudioStream]

## settings for better sound reusing
@export_group("Sound Settings")

## the random pitch
@export var random_ptich: float = 1.2

## random offset db
@export var random_offset_db: float = 2.0

## the audio bus
@export var audio_bus: StringName = &"SFX"

### no group again
#@export_group("", "")

var audio_player: AudioStreamPlayer3D
