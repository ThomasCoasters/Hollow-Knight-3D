extends Node

## if the save should be reset on start
const RESET_ON_LOAD: bool = false




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


## the current save file
var current_slot: int = -1



## the save that you have when there are no given new values (the backup) [br]
## This one is for the general game stuff like: settings
var DEFAULT_GENERAL_SAVE: Dictionary = {
	&"Buttons": {
		&"ZoomIn"       : MOUSE_BUTTON_WHEEL_UP,   # 4 (Mouse 1-99)
		&"ZoomOut"      : MOUSE_BUTTON_WHEEL_DOWN, # 5 (Mouse 1-99)
		&"ChangeCamera" : KEY_F1 + 1000,           # Keyboard range 1000+
		&"MoveLeft"     : KEY_A + 1000,
		&"MoveRight"    : KEY_D + 1000,
		&"MoveForward"  : KEY_W + 1000,
		&"MoveBackward" : KEY_S + 1000,
		&"Attack"       : MOUSE_BUTTON_LEFT,       # 1 (Mouse 1-99)
		&"Jump"         : KEY_SPACE + 1000,
		&"Dash"         : KEY_SHIFT + 1000,
	},
	&"Audio": {
		&"Master": 10,
		&"SFX"   : 10,
		&"Music" : 10,
	},
	
	&"Extras": {
		&"Background": &"Classic",
	},
	
	&"Video": {
		&"VSyncEnabled": true,
		&"MaxFPS": 0,
	},
}

## the save that you have when there are no given new values (the backup) [br]
## this one is for the game itself like: health, current location
var DEFAULT_GAME_SAVE: Dictionary = {
	&"Location": {
		&"Area": &"KingsPass",
		&"current_map": "res://map/testing stuff/testing_map.tscn",
		&"player_position": Vector3.ZERO,
	},
}



## the general save that is the CURRENT save
var general_contents: Dictionary = DEFAULT_GENERAL_SAVE.duplicate(true)
## the current gameplay's save
var current_game_contents: Dictionary = DEFAULT_GAME_SAVE.duplicate(true)







## called when the save is finished
signal save_finished(path: String)
## called when something went wrong with saving
signal save_failed(path: String)
## calles when the saving is stoped by completion or error
signal save_exited(path: String)

## called when the load is finished
signal load_finished(path: String)
## called when the loading is stoped by completion or error
signal load_exited(path: String)


## if the save is currently saving something (stop overlapping)
var is_saving: bool = false


func _ready() -> void:
	# make the game not be able to be exited without saving first
	get_tree().auto_accept_quit = false
	
	
	# check if the "Saves" folder does not exists
	if not DirAccess.dir_exists_absolute("user://Saves"):
		# create that folder
		DirAccess.make_dir_absolute("user://Saves")
	
	# set the general save path
	full_general_save_path = start_save_location + general_save_name + save_type
	
	
	# resets all saves when loading if that is turned on
	if RESET_ON_LOAD:
		reset_all_saves()
	
	
	# load the general save
	load_general()



#region general
## saves the general game stuff but not the game's state
func save_general(show_visual: bool = true) -> void:
	_save(full_general_save_path, general_contents, show_visual)


## loads the general game stuff but not the game's state
func load_general() -> void:
	# actually load it and get the value
	var loaded: Dictionary = await _load(full_general_save_path, general_contents)
	
	# set the loading contents given to the loaded values
	general_contents = deep_merge(DEFAULT_GENERAL_SAVE.duplicate(true), loaded)
	
	# load the keys
	_load_keys()
	# load the audio
	_load_audio()
	# load the video settings
	_load_video()


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
	# set the current save slot to the new slot number
	current_slot = slot_number
	
	# get the path
	var load_path: String = start_save_location + slot_save_name + str(slot_number) + save_type
	
	# actually load it and get the value
	var loaded: Dictionary = await _load(load_path, current_game_contents)
	
	# set the loading contents given to the loaded values
	current_game_contents = deep_merge(DEFAULT_GAME_SAVE.duplicate(true), loaded)

#endregion



#region core
## save the given content to the given location
func _save(path: String, save_contents: Dictionary, show_visual: bool = true) -> void:
	# stop overlapping saves
	if is_saving:
		await save_finished
	
	# play the saving animation if you should
	if show_visual: transition.play_save_anim()
	
	# set that is currently saving
	is_saving = true
	
	# get the file
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	# check if the file exists
	if file == null:
		# call the saved failed and stop saving
		is_saving = false
		save_failed.emit(path)
		save_exited.emit(path)
		return
	
	# get the data as an JSON string
	var json_string: String = JSON.stringify(save_contents, "\t")
	# store the values in the file as text
	file.store_string(json_string)
	# stop storing stuff in the file, so close it
	file.close()
	
	
	# stop the saving and emit the completion
	is_saving = false
	save_finished.emit(path)
	save_exited.emit(path)



## loads the given content from the given path. [br]
## when there is no content there uses the given "loading_content" value to make a new save there
func _load(path: String, loading_content: Dictionary, show_visual: bool = true) -> Dictionary:
	# play the loading animation if you should
	if show_visual: transition.play_load_loading_anim()
	
	# check if there even is a save in the given location
	if not FileAccess.file_exists(path):
		# if there is no save there create a new one and stop
		await _save(path, loading_content, false)
		
		# emit exit and exit
		load_exited.emit(path)
		
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
		await _save(path, loading_content, false)
		
		# emit exit and exit
		load_exited.emit(path)
		return loading_content
	
	
	# emit exit and finished
	load_exited.emit(path)
	load_finished.emit(path)
	
	# return the new loaded values
	return parsed




## loads the buttons to the correct new code
func _load_keys() -> void:
	# get every button
	var buttons: Dictionary = general_contents[&"Buttons"]
	
	# go through every action in the buttons
	for action in buttons:
		# get the value of the new action
		var val = int(buttons[action])
		# refrence for the final event
		var final_event: InputEvent = null
		
		# 1-99: mouse buttons
		if val > 0 and val < 100:
			var mouse_event = InputEventMouseButton.new()
			mouse_event.button_index = val as MouseButton
			final_event = mouse_event
			
		# 100-999: Controller buttons
		elif val >= 100 and val < 1000:
			var joy_event = InputEventJoypadButton.new()
			joy_event.button_index = (val - 100) as JoyButton
			final_event = joy_event
			
		# 1000+: Keyboard buttons
		elif val >= 1000:
			var key_event = InputEventKey.new()
			key_event.keycode = (val - 1000) as Key
			final_event = key_event
		
		
		# check if there is a final event
		if final_event:
			# replace old keybinds
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, final_event)



## loads the audio to the new loaded value
func _load_audio() -> void:
	# get the audio settings from the save dict
	var audio: Dictionary = general_contents[&"Audio"]
	
	# go through every audio setting
	for audio_key in audio:
		# check if that bus exists
		if AudioUtil.bus_exists(audio_key):
			# get the bus index
			var bus_index: int = AudioServer.get_bus_index(audio_key)
			# get the new volume (3 × (x - 10)
			var volume: int = 3 * (audio[audio_key] - 10)
			# set the bus volume to the new correct one
			AudioServer.set_bus_volume_db(bus_index, volume)

## loads the video settings
func _load_video() -> void:
	# get the video settings from the save dict
	var video: Dictionary = general_contents[&"Video"]
	
	# go through every video setting
	for video_key in video:
		# get what the current key is and change settings correctly
		match video_key:
			&"VSyncEnabled":
				# check if it should be enabled or dissabled
				if general_contents[&"Video"][&"VSyncEnabled"]:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
				else:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			&"MaxFPS":
				Engine.max_fps = general_contents[&"Video"][&"MaxFPS"]


## deeply meges the saved and the existing dict
func deep_merge(target: Dictionary, source: Dictionary) -> Dictionary:
	# get the key in the source
	for key in source:
		# if it has a key and the source and target are dicts
		# deep merge that
		if (target.has(key) and target[key] is Dictionary and source[key] is Dictionary):
			deep_merge(target[key], source[key])
		
		# if not set the target to the source
		else:
			target[key] = source[key]
	
	# return the target
	return target


## returns true if the given save slot exists
func save_slot_exists(slot_number: int) -> bool:
	# get the save path
	var save_path: String = (start_save_location + slot_save_name + str(slot_number) + save_type)
	
	# check if the file exists
	return FileAccess.file_exists(save_path)
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


## resets the save slot
func reset_game_slot(slot_number: int) -> void:
	# set the current values to the default values
	current_game_contents = DEFAULT_GAME_SAVE.duplicate(true)
	
	# save the reset
	save_game_slot(slot_number)


## deletes the save slot
func delete_save_slot(slot_number: int) -> void:
	# check if the file exists
	if not save_slot_exists(slot_number): return
	
	# get the file
	var save_path: String = (start_save_location + slot_save_name + str(slot_number) + save_type)
	
	# remove the save file
	DirAccess.remove_absolute(save_path)


## gets a value from a save slot without loading the slot
func get_slot_value(slot_number: int, keys: Array) -> Variant:
	# get the save path
	var load_path := start_save_location + slot_save_name + str(slot_number) + save_type
	
	# check if slot exists
	if not FileAccess.file_exists(load_path):
		return null
	
	# open file
	var file := FileAccess.open(load_path, FileAccess.READ)
	
	# check if file exists
	if file == null:
		return null
	
	# read
	var content := file.get_as_text()
	file.close()
	
	# parse
	var parsed = JSON.parse_string(content)
	
	# check if valid
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	
	# go through current values
	var current = parsed
	for key in keys:
		# if it is a dict and has the key you search for
		if current is Dictionary and current.has(key):
			current = current[key]
		else:
			# if not return null
			return null
	
	# return the current value found
	return current

#endregion

#region quitting game
## runs when this node gets a notification
func _notification(what: int) -> void:
	# if you want to close the game
	# first save the game and play the transition
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# get a refrence of if the save is done and the transition is done
		var state := {
			"save_done": false,
			"transition_done": false
		}
		
		# create listeners for when the signals are finished
		save_exited.connect(func(_path):
			state.save_done = true
		, CONNECT_ONE_SHOT)
		transition.on_transition_finished.connect(func():
			state.transition_done = true
		, CONNECT_ONE_SHOT)
		
		
		# save the general settings
		SaveLoad.save_general()
		
		# play the transition
		transition.play_transition(false, true)
		
		
		# wait until both signals are done
		while not state.save_done or not state.transition_done:
			await get_tree().process_frame
		
		# wait a small extra amount to let the save animation finish
		await get_tree().create_timer(0.7).timeout
		
		
		# quit the game
		get_tree().quit()
#endregion
