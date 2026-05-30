@icon("res://addons/at-icons/node3d/arrow_down_to_bracket.svg")
@tool
## component that hits a detector_component with customisable settings
class_name hitbox_component
extends component


## select what kind of collision this object is
var collider_type: int = CollisionTypes.Type.PLAYER_BODY

## refrence for the generated area
var Area_Made: Area3D


@export_group("Transform")
## see details in a normal node's position property
@export var position: Vector3 = Vector3.ZERO:
	set(value):
		# set to the new value
		position = value
		# update the visuals
		if is_node_ready():
			_update_collision_geometry()

## see details in a normal node's rotation property
@export var rotation: Vector3 = Vector3.ZERO:
	set(value):
		# set to the new
		rotation = value
		# update the visuals
		if is_node_ready():
			_update_collision_geometry()

## see details in a normal node's scale property
@export var scale: Vector3 = Vector3.ONE:
	set(value):
		# set to the new value
		scale = value
		# update the visuals
		if is_node_ready():
			_update_collision_geometry()


## settings for a simple shape as the collision shape
@export_group("simple shape")
## use for simple 3D shapes (eg. capsule, sphere)
@export var collision_shape: Shape3D:
	set(value):
		# set to the new value
		collision_shape = value
		# update the visuals
		if is_node_ready():
			_update_collision_geometry()


## settings for a more complex as the collision shape
@export_group("polygon shape")
## set points here for the polygon shape
@export var polygon_points: PackedVector2Array:
	set(value):
		# set to the new value
		polygon_points = value
		# update the visuals
		if is_node_ready():
			_update_collision_geometry()
## the depth of the polygon
@export var polygon_depth: float = 1.0:
	set(value):
		# set to the new value
		polygon_depth = value
		# update the visuals
		if is_node_ready():
			_update_collision_geometry()

@export_group("")

## if you can view the changes in the editor
@export var view_in_editor: bool = true:
	set(value):
		# set to the new value
		view_in_editor = value
		# update the visuals
		if is_node_ready():
			_update_collision_geometry()

## a Node3D that has the global position
@export var node_3D_parent: Node3D


func _get_property_list() -> Array[Dictionary]:
	# get the exported properties
	var properties: Array[Dictionary] = []
	# add the collision selector
	properties.append({
		"name": "collider_type",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_FLAGS,
		"hint_string": CollisionTypes.FLAGS_STRING
	})
	# return the properties
	return properties




func _ready() -> void:
	# update the collision when starting
	_update_collision_geometry.call_deferred()


## updates the collision's geometry
func _update_collision_geometry() -> void:
	var old_area = null
	if is_instance_valid(node_3D_parent):
		old_area = node_3D_parent.get_node_or_null("GeneratedHitboxArea")
	else:
		old_area = get_node_or_null("GeneratedHitboxArea")
	
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
	
	
	if not collision_shape and polygon_points.size() <= 2:
		return
	
	var new_area = Area3D.new()
	new_area.name = "GeneratedHitboxArea"
	new_area.monitoring = false
	new_area.monitorable = true
	Area_Made = new_area
	
	new_area.position = position
	new_area.rotation_degrees = rotation
	new_area.scale = scale
	
	if is_instance_valid(node_3D_parent):
		node_3D_parent.add_child(new_area)
	else:
		add_child(new_area)
	
	if polygon_points.size() > 2:
		var internal_poly := CollisionPolygon3D.new()
		internal_poly.name = "CollisionPolygon3D"
		internal_poly.polygon = polygon_points
		internal_poly.depth = polygon_depth
		new_area.add_child(internal_poly)
	elif collision_shape:
		var internal_shape := CollisionShape3D.new()
		internal_shape.name = "CollisionShape3D"
		internal_shape.shape = collision_shape
		new_area.add_child(internal_shape)
	
	new_area.set_meta("hitbox_component", self)
	
	if Engine.is_editor_hint() and is_inside_tree():
		var scene_root = get_tree().edited_scene_root
		if scene_root:
			if new_area.owner != scene_root:
				new_area.owner = scene_root
			for child in new_area.get_children():
				if child.owner != scene_root:
					child.owner = scene_root
			
			new_area.update_configuration_warnings()
