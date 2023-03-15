@tool
extends Sprite3D

func _ready():
	set_instance_shader_parameter("texture_albedo", texture)
