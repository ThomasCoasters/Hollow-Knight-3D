@tool
extends Control

## Emitted when the user requests to toggle the sidebar.
signal sidebar_toggle_requested()

## The currently selected node or null
var _selected_node:Node
## The editor interface
var _editor_interface:EditorInterface
## The undo/redo facility
var _undo_redo:EditorUndoRedoManager

@onready var _add_section:Control = %AddSection
@onready var _Search_node_line_edit:LineEdit = %SearchNodeLineEdit
@onready var _add_grid_container:Control = %AddGridContainer


func setup(editor_interface:EditorInterface, undo_redo:EditorUndoRedoManager) -> void:
	_editor_interface = editor_interface
	_undo_redo = undo_redo


func change_selected_node(node) -> void:
	_selected_node = node


func _create_node(type, name:StringName) -> void:
	var final_name := name
	var new_node = type.new()
	
	var target_parent := _selected_node
	
	# If the selected node is a component use its parent instead
	if _selected_node is component and _selected_node.get_parent():
		target_parent = _selected_node.get_parent()
	
	_undo_redo.create_action("Add " + final_name)
	_undo_redo.add_do_method(target_parent, "add_child", new_node)
	_undo_redo.add_undo_method(target_parent, "remove_child", new_node)
	_undo_redo.add_do_reference(new_node)
	_undo_redo.add_do_method(new_node, "set_owner", _selected_node.get_tree().edited_scene_root)
	_undo_redo.add_do_property(new_node, "name", final_name)
	_undo_redo.commit_action()

	if Input.is_key_pressed(KEY_SHIFT):
		_editor_interface.get_selection().clear()
		_editor_interface.get_selection().add_node(new_node)
	
	_editor_interface.edit_node(new_node)



func _on_search_node_line_edit_text_changed(new_text: String) -> void:
	#get the searched input
	new_text = new_text.strip_edges().to_lower()
	
	for section in _add_grid_container.get_children():
		var flow := section.get_node_or_null("AddGridContainer")
		
		if flow == null:
			continue
		
		var any_visible := false
		
		for btn in flow.get_children():
			if btn is Button:
				var text = btn.tooltip_text.to_lower()
				btn.visible = new_text == "" or text.contains(new_text)
				
				if btn.visible:
					any_visible = true
		
		section.visible = any_visible






func _on_toggle_sidebar_button_pressed() -> void:
	sidebar_toggle_requested.emit()


func _on_animation_component_pressed() -> void:
	_create_node(animation_component, "AnimationComponent")


func _on_transparancy_component_pressed() -> void:
	_create_node(transparancy_component, "TransparancyComponent")


func _on_health_component_pressed() -> void:
	_create_node(health_component, "HealthComponent")


func _on_spawn_pooled_component_pressed() -> void:
	_create_node(spawn_pooled_component, "SpawnPooledComponent")


func _on_component_holder_pressed() -> void:
	_create_node(Component_holder, "ComponentHolder")
