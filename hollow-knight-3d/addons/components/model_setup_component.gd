@icon("model_setup_component.svg")
@tool

## creates rigid bodies for every node that has "cell" in it's name
class_name model_setup_component
extends component

## the node that holds all of the nodes
@export var chosen_node: Node

## create rigid bodies on all the cell nodes
@export_tool_button("Create rigid body's") var create_rigid_body = _create_rigids














## creates rigid bodies on every MeshInstance3D
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
		if node is MeshInstance3D:
			# the mesh
			var cell: MeshInstance3D = node
			
			# create rigid body
			var rigid_body := RigidBody3D.new()
			
			# set basic settings
			rigid_body.name = cell.name + "_Rigid"
			rigid_body.position = cell.position
			rigid_body.rotation = cell.rotation
			rigid_body.scale = cell.scale
			
			# get the old position of the cell (for the undo)
			var old_position = cell.position
			var old_rotation = cell.rotation
			var old_scale = cell.scale
			
			# set the cell pos to 0,0,0
			undo_redo.add_do_property(cell, "position", Vector3.ZERO)
			undo_redo.add_do_property(cell, "rotation", Vector3.ZERO)
			undo_redo.add_do_property(cell, "scale", Vector3.ONE)
			
			# if you undo set back to normal pos
			undo_redo.add_undo_property(cell, "position", old_position)
			undo_redo.add_undo_property(cell, "rotation", old_rotation)
			undo_redo.add_undo_property(cell, "scale", old_scale)
			
			
			# create collision
			cell.create_convex_collision(false, true)
			
			# get the static body made and the collision shape made
			var static_body: StaticBody3D = cell.get_child(0)
			var collision_shape: CollisionShape3D = static_body.get_child(0)
			
			# remove the collision shape and static body made
			static_body.remove_child(collision_shape)
			cell.remove_child(static_body)
			
			# add rigidbody
			undo_redo.add_do_method(chosen_node, "add_child", rigid_body)
			undo_redo.add_do_method(rigid_body, "set_owner", get_tree().edited_scene_root)
			
			# remove mesh from old parent
			undo_redo.add_do_method(chosen_node, "remove_child", cell)
			
			# add mesh to rigidbody
			undo_redo.add_do_method(rigid_body, "add_child", cell)
			undo_redo.add_do_method(cell, "set_owner", get_tree().edited_scene_root)
			
			# add collision
			undo_redo.add_do_method(rigid_body, "add_child", collision_shape)
			undo_redo.add_do_method(collision_shape, "set_owner", get_tree().edited_scene_root)
			
			# free temp staticbody
			undo_redo.add_do_method(static_body, "queue_free")
			
			# undo collision from rigidbody
			undo_redo.add_undo_method(rigid_body, "remove_child", collision_shape)
			
			# restore mesh to original parent
			undo_redo.add_undo_method(rigid_body, "remove_child", cell)
			undo_redo.add_undo_method(chosen_node, "add_child", cell)
			undo_redo.add_undo_method(cell, "set_owner", get_tree().edited_scene_root)
			
			# undo rigidbody
			undo_redo.add_undo_method(chosen_node, "remove_child", rigid_body)
			
			# free rigidbody on undo
			undo_redo.add_undo_method(rigid_body, "queue_free")
	
	# make the undo redo do stuff
	undo_redo.commit_action()
