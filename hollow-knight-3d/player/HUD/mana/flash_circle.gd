class_name ManaFlashCircle
extends ColorRect

var time_alive: float = 0.0

func _process(delta):
	time_alive += delta
	material.set_shader_parameter("lifetime", time_alive)
