@icon("multi_mesh_member_component.svg")
@tool

## a component that tells the game this scene should be in a multimesh
class_name multi_mesh_member_component
extends Node


## ID that tells the game what mesh this is
@export_placeholder("give a name like: 'coin' or 'bullet'") var multimesh_id: String

## refrence to the actual mesh instance in this scene
@export var mesh_instance: MeshInstance3D

## refrence to the parent this mesh should follow (position, rotation etc..)
@export var transform_node: Node3D


## optionaasdasd asda
@export var transparency_component: transparancy_component

var current_opacity: float:
	get:
		if is_instance_valid(transparency_component):
			return transparency_component.multimesh_current_opacity
		return 1.0


func _notification(what: int) -> void:
	# do not run in editor
	if Engine.is_editor_hint():
		return
	
	# chack what the notification was
	match what:
		# when the node enters the tree register this to the batcher
		NOTIFICATION_ENTER_TREE:
			_register_to_batcher()
		
		# when it exits the tree unregister it from the batcher
		NOTIFICATION_EXIT_TREE:
			_unregister_from_batcher()


## registers this node to the multimesh batcher
func _register_to_batcher() -> void:
	# check if the required nodes are given, if not return
	if not mesh_instance or not is_instance_valid(transform_node):
		return
	
	# if the multimesh manager does not exist, give error
	if not has_node("/root/GlobalMultiMeshManager"):
		push_error("the GlobalMultiMeshManager does not exist, there will be meshes not loaded")
		return
	
	# make the local mesh invis so there is no double loading
	mesh_instance.visible = false
	
	# register the mesh to the manager
	GlobalMultiMeshManager.register_member(multimesh_id, self)


## unregisters this node from the multimesh batcher
func _unregister_from_batcher() -> void:
	# check if the GlobalMultiMeshManager exists
	if has_node("/root/GlobalMultiMeshManager"):
		# remove the mesh from the manager
		GlobalMultiMeshManager.unregister_member(multimesh_id, self)
