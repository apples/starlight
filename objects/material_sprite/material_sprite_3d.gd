@tool
extends Sprite3D

func _ready():
	Settings.connect("sprite_filter_trilinear_changed", _update_filtering)
	var material := material_override as ShaderMaterial
	material.set_shader_parameter("texture_albedo", texture)
	_update_filtering()

func _update_filtering():
	var material := material_override as ShaderMaterial
	material.set_shader_parameter("sprite_filter_trilinear", Settings.sprite_filter_trilinear)
