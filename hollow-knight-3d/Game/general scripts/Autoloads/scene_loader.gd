## loads scenes in an more efficient way
class_name Scene_Loader
extends Node


## all the values that are currently loading
var _loading: Dictionary = {}


## values that are finished loading
var _loaded: Dictionary = {}




## called when any scene finishes loading
signal scene_loaded(path: String)




## requests a scene path to be loaded
func request_scene(path: String) -> void:
	# check if it not already is loaded
	if _loaded.has(path): return
	# also check if it not is loading currently
	if _loading.has(path): return
	
	# set the loading to contain the new path
	_loading[path] = true
	
	
	# actually ask to threaded load this path
	ResourceLoader.load_threaded_request(path)
	
	print(path)


## update the current states for how far it is in loading
func _process(_delta: float) -> void:
	# go through every path that is loading
	for path in _loading.keys():
		# the var that will represent the progress
		var progress := []
		# get the current status of the load
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path, progress)
		
		# if the scene at the given path is loaded
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			# add to the loaded var (because it is done loading)
			_loaded[path] = ResourceLoader.load_threaded_get(path)
			# remove from the loading var (it is finished loading)
			_loading.erase(path)
			
			# a new scene is loaded so emit the scene loaded signal
			scene_loaded.emit(path)
		
		
		# if it failed loading the given path
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			# give an error
			push_error("Failed loading: " + path)
			# and remove it from loading
			_loading.erase(path)





## removes a scene from memory
func unload_scene(path: String) -> void:
	# get if it even is loaded
	if _loaded.has(path):
		# remove it from memory
		_loaded.erase(path)





## returns true if the given scene has finished loading
func has_scene(path: String) -> bool:
	# just gets if the loaded var contains the given path
	return _loaded.has(path)


## gets the PackedScene from the loaded var
func get_scene(path: String) -> PackedScene:
	# returns the value form the loaded var at the given path
	return _loaded.get(path)


## returns instantly if loaded[br]
## if not already loaded force the load to be finished now
func force_get_scene(path: String) -> PackedScene:
	# if it already is loaded
	if _loaded.has(path):
		# just return that
		return _loaded[path]
	
	
	
	# if it is not already requested
	if not _loading.has(path):
		# request it
		request_scene(path)
	
	# this will get blocked untill the load finishes
	# get the packed scene from the load
	var packed_scene: PackedScene = ResourceLoader.load_threaded_get(path)
	
	# just set the dict values
	_loaded[path] = packed_scene
	_loading.erase(path)
	
	# emit the scene loaded signal
	scene_loaded.emit(path)
	
	# return the loaded packed scene
	return packed_scene




## faster way to instantiate a loaded scene directly
func instantiate_scene(path: String) -> Node:
	# gets the scene
	var packed_scene: PackedScene = get_scene(path)
	
	# check if the packed scene exists
	if packed_scene:
		# return the instantiated packed scene
		return packed_scene.instantiate()
	
	# returns null if thhe packed scene does not exist
	return null




## waits untill a specified scene is loaded[br]
## to use await this func
func wait_for_scene(path: String) -> void:
	# get if it is already loaded
	if has_scene(path):
		# immediate return (because already loaded)
		return
	
	# keep waiting until the given path has loaded
	while true:
		# get the loaded path every time a new path has been loaded
		var loaded_path: String = await scene_loaded
		
		# check if that is the path we are waiting for and return if it is
		if loaded_path == path: return






#
