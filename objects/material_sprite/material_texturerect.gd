@tool
extends Control

func _ready():
	assert("texture" in self)
	var mat = material as ShaderMaterial
	mat.set_shader_parameter("texture_albedo", self.texture)
	
