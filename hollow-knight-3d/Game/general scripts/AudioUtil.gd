## a util to make audio changing easier
class_name AudioUtil


# gets if a given bus exists
static func bus_exists(bus_name: StringName) -> bool:
	# Get the index of the given bus
	var index := AudioServer.get_bus_index(bus_name)
	# return true if there is a index else false
	return index != -1
