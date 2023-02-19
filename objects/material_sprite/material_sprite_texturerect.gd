@tool
extends TextureRect

func _ready():
	Settings.connect("sprite_filter_trilinear_changed", _refresh_filter)
	var mat = material as ShaderMaterial
	mat.set_shader_parameter("texture_albedo", texture)
	mat.set_shader_parameter("sprite_filter_trilinear", Settings.sprite_filter_trilinear)

func _refresh_filter():
	var mat = material as ShaderMaterial
	mat.set_shader_parameter("sprite_filter_trilinear", Settings.sprite_filter_trilinear)
