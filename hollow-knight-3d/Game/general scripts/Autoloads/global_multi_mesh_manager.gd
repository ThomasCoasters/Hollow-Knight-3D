class_name global_multi_mesh_manager
extends Node

## keeps track of different multimeshed meshes
## formated as: {"id": Array[multi_mesh_member_component]}
var _tracked_members: Dictionary[String, Array] = {}

## Keeps track of the Multimesh per ID that is given
## formated as: {"id": MultiMeshInstance3D}
var _multimesh_nodes: Dictionary[String, MultiMeshInstance3D] = {}

## how much the buffer should increase by per action (to prevent constant GPU memory blocking)
const BUFFER_CHUNK_SIZE: int = 32

## registers a new member to the multimesh 
func register_member(pool_id: String, member: multi_mesh_member_component) -> void:
	# if the new ID is not already tracked
	if not _tracked_members.has(pool_id):
		# add it to the tracked members
		_tracked_members[pool_id] = []
		# setup the multimesh node
		_setup_multimesh_node(pool_id, member.mesh_instance.mesh, member.mesh_instance)
	
	# if the new member is not already tracked
	if not _tracked_members[pool_id].has(member):
		# add the member to the tracked members
		_tracked_members[pool_id].append(member)
		# sync the buffer capacity
		_sync_buffer_capacity(pool_id)


## unregisters a member from the pool
func unregister_member(pool_id: String, member: multi_mesh_member_component) -> void:
	# check if the tracked member has the ID given
	if _tracked_members.has(pool_id):
		# remove the given obj
		_tracked_members[pool_id].erase(member)
		# re-sync the buffer capacity
		_sync_buffer_capacity(pool_id)


## setups the multimesh node that contains the meshes
func _setup_multimesh_node(pool_id: String, mesh_data: Mesh, mesh_instance: MeshInstance3D) -> void:
	# get the base mat from the mesh instance given
	var base_material = mesh_instance.get_surface_override_material(0)
	# if there is none get the mat from the mesh
	if not base_material:
		base_material = mesh_data.surface_get_material(0)
	
	
	# create the multimesh
	var multi_mesh_instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	multi_mesh_instance.multimesh = MultiMesh.new()
	
	# set the multimeshe's multimesh base settings
	multi_mesh_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh_instance.multimesh.use_colors = true 
	multi_mesh_instance.material_override = base_material
	multi_mesh_instance.multimesh.mesh = mesh_data
	multi_mesh_instance.multimesh.instance_count = 0
	
	# add the multimesh to the array containing them all
	_multimesh_nodes[pool_id] = multi_mesh_instance
	# add the multimesh to the game
	add_child(multi_mesh_instance)


func _sync_buffer_capacity(pool_id: String) -> void:
	var active_count = _tracked_members[pool_id].size()
	
	# Sync Base Buffer
	var mmi = _multimesh_nodes[pool_id]
	if active_count > mmi.multimesh.instance_count:
		mmi.multimesh.instance_count = active_count + BUFFER_CHUNK_SIZE
	mmi.multimesh.visible_instance_count = active_count


func _physics_process(_delta: float) -> void:
	for pool_id in _tracked_members.keys():
		var members: Array = _tracked_members[pool_id]
		var mmi: MultiMeshInstance3D = _multimesh_nodes[pool_id]
		
		for i in range(members.size()):
			var member = members[i] as multi_mesh_member_component
			if is_instance_valid(member) and is_instance_valid(member.transform_node):
				var global_tf = member.transform_node.global_transform
				var alpha = member.current_opacity
				var color_data = Color(1, 1, 1, alpha)
				
				# Update base mesh transform & alpha
				mmi.multimesh.set_instance_transform(i, global_tf)
				mmi.multimesh.set_instance_color(i, color_data)
