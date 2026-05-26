@icon("Component_holder.svg")
@tool
## component that detects when hitbox components hit it with customisable settings
class_name detector_component
extends component


## called when the collider enters this area
signal detected_collider(hitbox: hitbox_component)
## called when the collider exits this area
signal lost_collider(hitbox: hitbox_component)

## selected collider types this one should listen for
var detection_mask: int = 0

@export_group("Transform")
## see details in a normal node's position property
@export var position: Vector3 = Vector3.ZERO:
	set(value):
		# set to the new value
		position = value
		# update the visuals
		_update_detection_geometry()

## see details in a normal node's rotation property
@export var rotation: Vector3 = Vector3.ZERO:
	set(value):
		# set to the new
		rotation = value
		# update the visuals
		_update_detection_geometry()

## see details in a normal node's scale property
@export var scale: Vector3 = Vector3.ONE:
	set(value):
		# set to the new value
		scale = value
		# update the visuals
		_update_detection_geometry()


## settings for a simple shape as the collision shape
@export_group("simple shape")
## use for simple 3D shapes (eg. capsule, sphere)
@export var detection_shape: Shape3D:
	set(value):
		# set to the new value
		detection_shape = value
		# update the visuals
		_update_detection_geometry()


## settings for a more complex as the collision shape
@export_group("polygon shape")
## set points here for the polygon shape
@export var polygon_points: PackedVector2Array:
	set(value):
		# set to the new value
		polygon_points = value
		# update the visuals
		_update_detection_geometry()
## the depth of the polygon
@export var polygon_depth: float = 1.0:
	set(value):
		# set to the new value
		polygon_depth = value
		# update the visuals
		_update_detection_geometry()

@export_group("")

## if you can view the changes in the editor
@export var view_in_editor: bool = true:
	set(value):
		# set to the new value
		view_in_editor = value
		# update the visuals
		_update_detection_geometry()


## a Node3D that has the global position
@export var node_3D_parent: Node3D

## the currently entered collisions
var active_collisions: Array[hitbox_component] = []


func _get_property_list() -> Array[Dictionary]:
	# get the exported properties
	var properties: Array[Dictionary] = []
	# add the collision selector
	properties.append({
		"name": "detection_mask",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_FLAGS,
		"hint_string": CollisionTypes.FLAGS_STRING
	})
	# return the properties
	return properties








func _ready() -> void:
	# update the collision when starting
	_update_detection_geometry.call_deferred()




func _update_detection_geometry() -> void:
	# get the old area to delete it
	var old_area = null
	if is_instance_valid(node_3D_parent):
		old_area = node_3D_parent.get_node_or_null("GeneratedDetectorArea")
	else:
		old_area = get_node_or_null("GeneratedDetectorArea")
	
	# if it exists
	if old_area:
		# get the parent of the area
		var current_parent = old_area.get_parent()
		# it it exists remove its child
		if current_parent:
			current_parent.remove_child(old_area)
		# then delete it
		old_area.free()
	
	
	# if in editor and not view in editor
	if Engine.is_editor_hint() and not view_in_editor:
		return
	
	
	# if there is no collision shape or collision polygon return
	if not detection_shape and polygon_points.size() <= 2:
		return
	
	# create a new Area and set basic settings
	var new_area = Area3D.new()
	new_area.name = "GeneratedDetectorArea"
	new_area.monitoring = true
	new_area.monitorable = false
	
	# add the custom transform and add it
	new_area.position = position
	new_area.rotation_degrees = rotation
	new_area.scale = scale
	# add to the node 3D parent if possible else itself
	if is_instance_valid(node_3D_parent):
		node_3D_parent.add_child(new_area)
	else:
		add_child(new_area)
	
	# if it is a polygon shape
	if polygon_points.size() > 2:
		# get a new internal polygon
		var internal_poly := CollisionPolygon3D.new()
		# set name and settings, then add it
		internal_poly.name = "CollisionPolygon3D"
		internal_poly.polygon = polygon_points
		internal_poly.depth = polygon_depth
		new_area.add_child(internal_poly)
	
	
	# if it was no polygon but a normal shape
	elif detection_shape:
		# get a new internal collision shape
		var internal_shape := CollisionShape3D.new()
		# set name and settings, then add it
		internal_shape.name = "CollisionShape3D"
		internal_shape.shape = detection_shape
		new_area.add_child(internal_shape)
	
	
	# if it is in-game
	if not Engine.is_editor_hint():
		# add the area's entered and exited functions
		new_area.area_entered.connect(_on_area_entered)
		new_area.area_exited.connect(_on_area_exited)
	
	
	# if it is in editor
	if Engine.is_editor_hint() and is_inside_tree():
		# check if currently loading
		if get_tree().edited_scene_root == null: 
			pass

		var scene_root = get_tree().edited_scene_root
		if scene_root:
			# Only assign owner if the node isn't already owned
			if new_area.owner != scene_root:
				new_area.owner = scene_root
			for child in new_area.get_children():
				if child.owner != scene_root:
					child.owner = scene_root
			
			new_area.update_configuration_warnings()



## when the area is entered
func _on_area_entered(incoming_area: Area3D) -> void:
	# check if the entered area is a hitbox_component
	if incoming_area.has_meta("hitbox_component"):
		# get the area's component
		var hitbox = incoming_area.get_meta("hitbox_component") as hitbox_component
		
		# if it has a component and this AND the incoming area has the same thing they detect
		if hitbox and (hitbox.collider_type & detection_mask) > 0:
			# if this collision is not already in this node
			if not active_collisions.has(hitbox):
				# add it to this node and call the detected_collider signal
				active_collisions.append(hitbox)
				detected_collider.emit(hitbox)


## when the area is exited
func _on_area_exited(incoming_area: Area3D) -> void:
	# check if the entered area is a hitbox_component
	if incoming_area.has_meta("hitbox_component"):
		# get the area's component
		var hitbox = incoming_area.get_meta("hitbox_component") as hitbox_component
		
		# if it has a component and it is inside this node already
		if hitbox and active_collisions.has(hitbox):
			# remove it from this node and call the lost_collider signal
			active_collisions.erase(hitbox)
			lost_collider.emit(hitbox)
