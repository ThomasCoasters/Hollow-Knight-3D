extends Node

## the location from where everything is saved
const start_save_location: String = "user://"

## the added stuff for the general save
const general_save_name: String = "GeneralSaves"

## the added stuff for the game's save slots
const slot_save_name: String = "Saves/Save_"

## the ending of the saves name
const save_type: String = ".json"


## the full path of off the general saves
var full_general_save_path: String


## the save that you have when there are no given new values (the backup) [br]
## This one is for the general game stuff like: settings
var DEFAULT_GENERAL_SAVE: Dictionary = {
	"cheese": true,
}

## the save that you have when there are no given new values (the backup) [br]
## this one is for the game itself like: health, current location
var DEFAULT_GAME_SAVE: Dictionary = {
	"dawgh": 1,
}



## the general save that is the CURRENT save
var general_contents: Dictionary = DEFAULT_GENERAL_SAVE.duplicate(true)
## the current gameplay's save
var current_game_contents: Dictionary = DEFAULT_GAME_SAVE.duplicate(true)




func _ready() -> void:
	# check if the "Saves" folder does not exists
	if not DirAccess.dir_exists_absolute("user://Saves"):
		# create that folder
		DirAccess.make_dir_absolute("user://Saves")
	
	# set the general save path
	full_general_save_path = start_save_location + general_save_name + save_type
	
	# load the general save
	load_general()


#region general
## saves the general game stuff but not the game's state
func save_general() -> void:
	_save(full_general_save_path, general_contents)


## loads the general game stuff but not the game's state
func load_general() -> void:
	# actually load it and get the value
	var loaded: Dictionary = _load(full_general_save_path, general_contents)
	
	# set the loading contents given to the loaded values
	general_contents.merge(loaded, true)
#endregion

#region slot save
## saves the games's state for the given slot. But not the general stuff
func save_game_slot(slot_number: int) -> void:
	# get the path
	var save_path: String = start_save_location + slot_save_name + str(slot_number) + save_type
	
	# save the game at the given path
	_save(save_path, current_game_contents)


## loads the game's state for the given slot. But not the general stuff
func load_game_slot(slot_number: int) -> void:
	# get the path
	var load_path: String = start_save_location + slot_save_name + str(slot_number) + save_type
	
	# actually load it and get the value
	var loaded: Dictionary = _load(load_path, current_game_contents)
	
	# set the loading contents given to the loaded values
	current_game_contents.merge(loaded, true)

#endregion



#region core
## save the given content to the given location
func _save(path: String, save_contents: Dictionary) -> void:
	# get the file
	var file = FileAccess.open(path, FileAccess.WRITE)
	# get the data as an JSON string
	var json_string: String = JSON.stringify(save_contents, "\t")
	# store the values in the file as text
	file.store_string(json_string)
	# stop storing stuff in the file, so close it
	file.close()


## loads the given content from the given path. [br]
## when there is no content there uses the given "loading_content" value to make a new save there
func _load(path: String, loading_content: Dictionary) -> Dictionary:
	# check if there even is a save in the given location
	if not FileAccess.file_exists(path):
		# if there is no save there create a new one and stop
		_save(path, loading_content)
		return loading_content
	
	# get the given path's save file
	var file = FileAccess.open(path, FileAccess.READ)
	# read the text
	var content: String = file.get_as_text()
	# stop reading the file and close it
	file.close()
	
	# parse the JSON
	var parsed = JSON.parse_string(content)
	
	# safety check
	if not parsed or typeof(parsed) != TYPE_DICTIONARY:
		# if it is corrupted reset it
		_save(path, loading_content)
		return loading_content
	
	
	# return the new loaded values
	return parsed
#endregion




#region deletion
## resets all saves
func reset_all_saves() -> void:
	# reset the general save
	reset_general_save()
	
	# get the directory of the save slots
	var dir_path = start_save_location + "Saves/"
	var dir = DirAccess.open(dir_path)
	
	# if it exists
	if dir:
		# list all the files in the dir
		dir.list_dir_begin()
		# get the file name
		var file_name = dir.get_next()
		
		# keep going untill there is no more file
		while file_name != "":
			# check if the file is actually a save file (ends with .json)
			if not dir.current_is_dir() and file_name.ends_with(save_type):
				# get the full path of the save file
				var full_path = dir_path + file_name
				# delete that file
				dir.remove(full_path)
			
			# get the next file
			file_name = dir.get_next()
		
		# stop the list
		dir.list_dir_end()
	
	# set the current game save to the hard resetted version
	current_game_contents = DEFAULT_GAME_SAVE.duplicate(true)


## resets the general save to the base values
func reset_general_save() -> void:
	# set the current values to the default values
	general_contents = DEFAULT_GENERAL_SAVE.duplicate(true)
	# save the reset
	save_general()


func reset_game_slot(slot_number: int) -> void:
	# set the current values to the default values
	current_game_contents = DEFAULT_GAME_SAVE.duplicate(true)
	
	# save the reset
	save_game_slot(slot_number)


#endregion
