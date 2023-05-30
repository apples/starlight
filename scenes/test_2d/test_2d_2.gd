extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var vp := get_viewport() as Window
	vp.content_scale_size = Vector2i(400,224)
	vp.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT

