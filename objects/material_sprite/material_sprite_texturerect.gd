extends TextureRect

signal updated

func _ready():
	#connect("texture_changed", _refresh)
	print("ddfdfdf")
	print(material)
	Settings.connect("sprite_filter_trilinear_changed", _refresh)
	_refresh()

func _refresh():
	var mat = material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("texture_albedo", texture)
		mat.set_shader_parameter("sprite_filter_trilinear", Settings.sprite_filter_trilinear)
		emit_signal("updated")
