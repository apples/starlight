extends Sprite3D

signal updated

func _ready():
	connect("texture_changed", _refresh)
	Settings.connect("sprite_filter_trilinear_changed", _refresh)
	_refresh()

func _refresh():
	var material = material_override as ShaderMaterial
	if material:
		material.set_shader_parameter("texture_albedo", texture)
		material.set_shader_parameter("sprite_filter_trilinear", Settings.sprite_filter_trilinear)
		emit_signal("updated")
