## a class for visual 3D geo stuff that will be pooled
class_name GeoNode3D
extends GlobalPoolingNode3D

## the rigid body this node has
@export var rigid_body: RigidBody3D

## the light
@export var light: OmniLight3D

## the hitbox component
@export var hitbox_comp: hitbox_component

## the transparancy component
@export var trans_comp: transparancy_component



## a random force this starts at between - this and this
@export var random_starting_force: Vector3 = Vector3(3, 3, 3)



func _on_pool_enable() -> void:
	# enable the rigid body
	rigid_body.freeze = false
	# make the light visible
	light.visible = true
	# make the hitbox work
	hitbox_comp.enabled = true
	# set the collision to work
	rigid_body.set_collision_layer_value(1, true)
	
	# do the normal stuff
	super()
	
	# wait until this node is in the tree
	if not is_inside_tree():
		await ready
	await get_tree().physics_frame
	
	# make the geo visible
	trans_comp.change_opacity(1.0, 0.2)
	
	
	# wait untill the rigid body is inside the tree
	for i in range(5):
		await get_tree().physics_frame
	# expolde outwards
	rigid_body.apply_central_impulse(
		Vector3(
			randf_range(-random_starting_force.x, random_starting_force.x),
			randf_range(-random_starting_force.y, random_starting_force.y),
			randf_range(-random_starting_force.z, random_starting_force.z),
		)
	)



func _on_pool_disable() -> void:
	# disable the rigid body
	rigid_body.freeze = true
	# make the light invisible
	light.visible = false
	# make the hitbox no longer work
	hitbox_comp.enabled = false
	# set the collision no longer to work
	rigid_body.set_collision_layer_value(1, false)
	
	# do the normal stuff
	super()
