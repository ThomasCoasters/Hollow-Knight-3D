@icon("model_setup_component.svg")
@tool

## creates rigid bodies for every node that has "cell" in it's name
class_name model_setup_component
extends component

## the node that holds all of the nodes
@export var chosen_node: Node

## create rigid bodies on all the cell nodes
@export_tool_button("Create rigid body's") var create_rigid_body = _create_rigids

## make all the shaders unique
@export_tool_button("Create unique shaders") var create_unique_shaders = _create_unique_shaders














## creates rigid bodies on every MeshInstance3D that has "cell" in the name
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










## makes every shader in the given node's childeren unique
func _create_unique_shaders() -> void:
	# give error if there was no node chosen
	if not chosen_node:
		push_warning("forgot to assign a node to work from")
		return
	
	# create a refrence for the godot undo redo
	var undo_redo := EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Make Shaders Unique")
	
	
	# duplicate array cuz children will change
	var children := chosen_node.get_children()
	
	# go through every node
	for node: Node in children:
		# check if it is has a material override
		if "material_override" in node and node.get("material_override") is Material:
			# get the material
			var mat = node.get("material_override")
			# process the undo redo of the material
			_process_material_undo_redo(undo_redo, node, "material_override", mat)
		
		# same as last one but now normal materials
		if "material" in node and node.get("material") is Material:
			# get the material
			var mat = node.get("material")
			# process the undo redo of the material
			_process_material_undo_redo(undo_redo, node, "material", mat)
		
		# now for surface material overrides
		if node.has_method("get_surface_override_material") and node.get("mesh") != null:
			# get the mesh
			var mesh = node.get("mesh")
			# go through every surface count
			for i in range(mesh.get_surface_count()):
				# get the current surface material
				var surf_mat = node.call("get_surface_override_material", i)
				# check if it is a material
				if surf_mat is Material:
					# process it in the undo redo
					_process_surface_material_undo_redo(undo_redo, node, i, surf_mat)
	
	
	# make the undo redo do stuff
	undo_redo.commit_action()







## helper for setting material's properties in the undo redo
func _process_material_undo_redo(undo_redo: EditorUndoRedoManager, target_node: Node, property_path: String, old_material: Material) -> void:
	# get a refrence to the new material
	var new_material: Material = old_material.duplicate()
	
	# if it is a shader
	if new_material is ShaderMaterial and new_material.shader:
		# set the material's shader also to a new one
		new_material.shader = new_material.shader.duplicate()
	
	# get the old mat and new mat
	var current_new_mat = new_material
	var current_old_mat = old_material
	
	# go through every pass
	while current_old_mat.next_pass != null:
		# get the new pass and old pass refrences
		var old_next_pass: Material = current_old_mat.next_pass
		var new_next_pass: Material = old_next_pass.duplicate()
		
		# if the new pass is a shader
		if new_next_pass is ShaderMaterial and new_next_pass.shader:
			# set the new pass shader to the new one
			new_next_pass.shader = new_next_pass.shader.duplicate()
		
		# set the new and old values
		current_new_mat.next_pass = new_next_pass
		current_new_mat = new_next_pass
		current_old_mat = old_next_pass
	
	# add all these settings to the undo redo
	undo_redo.add_do_property(target_node, property_path, new_material)
	undo_redo.add_undo_property(target_node, property_path, old_material)


## helper for setting surface material's properties in the undo redo
func _process_surface_material_undo_redo(undo_redo: EditorUndoRedoManager, target_node: Node, surface_idx: int, old_material: Material) -> void:
	# get a refrence to the new material
	var new_material: Material = old_material.duplicate()
	
	# if it is a shader
	if new_material is ShaderMaterial and new_material.shader:
		# set the material's shader also to a new one
		new_material.shader = new_material.shader.duplicate()
	
	# get the old mat and new mat
	var current_new_mat = new_material
	var current_old_mat = old_material
	
	# go through every pass
	while current_old_mat.next_pass != null:
		# get the new pass and old pass refrences
		var old_next_pass: Material = current_old_mat.next_pass
		var new_next_pass: Material = old_next_pass.duplicate()
		
		# if the new material is a shader
		if new_next_pass is ShaderMaterial and new_next_pass.shader:
			# set the new pass shader to the new one
			new_next_pass.shader = new_next_pass.shader.duplicate()
		
		# set the new and old values
		current_new_mat.next_pass = new_next_pass
		current_new_mat = new_next_pass
		current_old_mat = old_next_pass
	
	# add all these settings to the undo redo
	undo_redo.add_do_method(target_node, "set_surface_override_material", surface_idx, new_material)
	undo_redo.add_undo_method(target_node, "set_surface_override_material", surface_idx, old_material)
