extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("toggle_fullscreen"):
		match DisplayServer.window_get_mode():
			DisplayServer.WINDOW_MODE_WINDOWED, \
			DisplayServer.WINDOW_MODE_MAXIMIZED:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if Input.is_action_just_pressed("debug_1"):
		match get_viewport().scaling_3d_mode:
			Viewport.SCALING_3D_MODE_BILINEAR:
				get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
				print("FSR2 ON")
			Viewport.SCALING_3D_MODE_FSR2:
				get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
				print("FSR2 OFF")
	if Input.is_action_just_pressed("debug_2"):
		match get_viewport().msaa_3d:
			Viewport.MSAA_DISABLED:
				get_viewport().msaa_3d = Viewport.MSAA_4X
				print("MSAA x4")
			_:
				get_viewport().msaa_3d = Viewport.MSAA_DISABLED
				print("MSAA OFF")
