extends CharacterBody3D
class_name Player

##exported nodes
@export_group("nodes")
##player model
@export var knight: Player_Model














#region camera stuff
##runs when the camera enters the camera detector
func _on_camera_detector_area_entered(area: Area3D) -> void:
	if !area.is_in_group("camera_area"):
		return
	
	#makes the player see through
	change_player_opacity(0.0, 0.2)

##runs when the camera leaves the camera detector
func _on_camera_detector_area_exited(area: Area3D) -> void:
	if !area.is_in_group("camera_area"):
		return
	
	#makes the player visible again
	change_player_opacity(1.0, 0.2)
#endregion


#region better feel
##changes the opacity of the player
func change_player_opacity(to: float = 0.0, time: float = 0.5) -> void:
	#only change the player model opacity if it is the player model
	if knight is Player_Model:
		#change every mesh of the player
		for mesh: MeshInstance3D in knight.meshes:
			#get the mesh material
			var mat = mesh.get_active_material(0)
			
			
			# Enable transparency
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			
			#make the opacity tween to the correct value nicely
			var tween := create_tween()
			tween.tween_property(mat, "albedo_color:a", to, time)
			#when finished make the material transparant if needed else make it normal
			tween.finished.connect(func():
				if to < 1.0:
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				else:
					mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				)
#endregion
