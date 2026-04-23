@icon("transparancy_component.svg")
@tool

##component used to change the transparancy of objects
class_name transparancy_component
extends component


##all the meshes off the model you want to change
@export var meshes: Array[MeshInstance3D]


##mesh that should either be fully invisible or fully visible at all times
@export var hidden_mesh: Array[MeshInstance3D]


## called when the mesh transparancy changing process is finished
signal transparancy_changing_finished()



##changes the opacity
func change_opacity(to: float = 0.0, time: float = 0.5) -> void:
	#change every mesh
	for mesh: MeshInstance3D in meshes:
		#the ending opacity
		var ending_opacity: float = to
		
		#make the strict mesh always invis instead of see through (otherwise really ugly)
		if mesh in hidden_mesh:
			#check if it would be see through
			if to < 1.0:
				#make to always 0.0 (invis)
				ending_opacity = 0.0
		
		
		
		#get the mesh material
		var mat: StandardMaterial3D = mesh.get_active_material(0)
		
		
		# Enable transparency
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		
		
		
		#make the opacity tween to the correct value nicely
		var tween := create_tween()
		tween.tween_property(mat, "albedo_color:a", ending_opacity, time)
		
		
		#check if the outline exists
		if mat and mat.next_pass:
			#store the outline in a var
			var next = mat.next_pass
			
			#make sure the outline is always fully visible or fully invisible
			var end_outline_opacity: float = 1.0 if ending_opacity >= 1.0 else 0.0
			
			#check if it is a shadermaterial
			if next is ShaderMaterial:
				#smooth tween to the opacity chosen
				tween.parallel().tween_property(next, "shader_parameter/alpha", end_outline_opacity, time)
		
		
		#when finished make the material transparant if needed else make it normal
		tween.finished.connect(func():
			#emit the finished signal
			transparancy_changing_finished.emit()
			
			if to < 1.0:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			else:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			)
