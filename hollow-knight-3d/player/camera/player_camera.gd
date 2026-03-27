extends Camera3D

@export var neck_node: Marker3D

@export_enum("3rd_person", "1st_person", "side_view", "free", "locked") var camera_mode: int
@export var distance: Vector3 = Vector3(0, 1, 3)
@export var camera_rotation: Vector3 = Vector3(-10, 0, 0)

func _ready() -> void:
	global_position = neck_node.global_position + distance
	global_rotation_degrees = camera_rotation
