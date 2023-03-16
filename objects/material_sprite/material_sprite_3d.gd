@tool
extends Sprite3D

func _ready():
	var mat := material_override as ShaderMaterial
	assert(mat)
	mat.set_shader_parameter("texture_albedo", texture)
