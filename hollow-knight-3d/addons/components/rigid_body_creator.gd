@icon("transparancy_component.svg")
@tool

## creates rigid bodies for every node that has "cell" in it's name
class_name rigid_body_creator
extends component

## the node that holds all of the nodes
@export var chosen_node: Node

## create the rigid bodies
@export_tool_button("Create rigid body's") var create_rigid_body = _create_rigids


func _create_rigids() -> void:
	# do not continue if this is running in-game
	if !Engine.is_editor_hint():
		return
	
	# create a refrence for the godot undo redo
	var undo_redo := EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Create Rigid Bodies")
	
	
	# duplicate array cuz children will change
	var children := chosen_node.get_children()
	
	# go through every node
	for node: Node in children:
		# check if the name has "cell"
		if node.name.contains("cell") and node is MeshInstance3D:
			
			# create rigid body
			var rigid_body := RigidBody3D.new()
			
			# set basic settings
			rigid_body.name = node.name + "_Rigid"
			rigid_body.position = node.position
			rigid_body.rotation = node.rotation
			rigid_body.scale = node.scale
			
			# get the old position of the node (for the undo)
			var old_position = node.position
			var old_rotation = node.rotation
			var old_scale = node.scale
			
			# set the node pos to 0,0,0
			undo_redo.add_do_property(node, "position", Vector3.ZERO)
			undo_redo.add_do_property(node, "rotation", Vector3.ZERO)
			undo_redo.add_do_property(node, "scale", Vector3.ONE)
			
			# if you undo set back to normal pos
			undo_redo.add_undo_property(node, "position", old_position)
			undo_redo.add_undo_property(node, "rotation", old_rotation)
			undo_redo.add_undo_property(node, "scale", old_scale)
			
			
			# create collision
			node.create_convex_collision()
			
			# get the static body made and the collision shape made
			var static_body: StaticBody3D = node.get_child(0)
			var collision_shape: CollisionShape3D = static_body.get_child(0)
			
			# remove the collision shape and static body made
			static_body.remove_child(collision_shape)
			node.remove_child(static_body)
			
			# add rigidbody
			undo_redo.add_do_method(chosen_node, "add_child", rigid_body)
			undo_redo.add_do_method(rigid_body, "set_owner", get_tree().edited_scene_root)
			
			# remove mesh from old parent
			undo_redo.add_do_method(chosen_node, "remove_child", node)
			
			# add mesh to rigidbody
			undo_redo.add_do_method(rigid_body, "add_child", node)
			undo_redo.add_do_method(node, "set_owner", get_tree().edited_scene_root)
			
			# add collision
			undo_redo.add_do_method(rigid_body, "add_child", collision_shape)
			undo_redo.add_do_method(collision_shape, "set_owner", get_tree().edited_scene_root)
			
			# free temp staticbody
			undo_redo.add_do_method(static_body, "queue_free")
			
			# undo collision from rigidbody
			undo_redo.add_undo_method(rigid_body, "remove_child", collision_shape)
			
			# restore mesh to original parent
			undo_redo.add_undo_method(rigid_body, "remove_child", node)
			undo_redo.add_undo_method(chosen_node, "add_child", node)
			undo_redo.add_undo_method(node, "set_owner", get_tree().edited_scene_root)
			
			# undo rigidbody
			undo_redo.add_undo_method(chosen_node, "remove_child", rigid_body)
			
			# free rigidbody on undo
			undo_redo.add_undo_method(rigid_body, "queue_free")
	
	# make the undo redo do stuff
	undo_redo.commit_action()
