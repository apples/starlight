@tool
extends EditorPlugin

var dialog_window_scene := preload("res://addons/noise_maker/noise_maker.tscn")
var dialog_window: ConfirmationDialog = null

func _enter_tree():
	add_tool_menu_item("NoiseMaker", make_some_noise)
	dialog_window = dialog_window_scene.instantiate()
	dialog_window.connect("canceled", _on_cancelled)
	dialog_window.connect("confirmed", _on_confirm)
	get_editor_interface().get_base_control().add_child(dialog_window)
	pass


func _exit_tree():
	remove_tool_menu_item("NoiseMaker")
	dialog_window.queue_free()
	pass

func make_some_noise():
	dialog_window.show()

func _on_cancelled():
	dialog_window.hide()

func _on_confirm():
	dialog_window.hide()
	
	var path := dialog_window.get_node("%FilePath").text as String
	var size := int(dialog_window.get_node("%Size").text)
	var scale := float(dialog_window.get_node("%Scale").text)
	
	if path == "":
		push_error("No path!")
		return
	if size <= 0:
		push_error("No size!")
		return
	if size > 512:
		push_error("Size too big!")
		return
	
	print("Creating noise \"%s\" of size %s with scale %s..." % [path, size, scale])
	
	var image := Image.create(size, size * size, false, Image.FORMAT_RGBA8)
	
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	var root_r := Vector3(rng.randf_range(-1000000,1000000),rng.randf_range(-1000000,1000000),rng.randf_range(-1000000,1000000))
	var root_g := Vector3(rng.randf_range(-1000000,1000000),rng.randf_range(-1000000,1000000),rng.randf_range(-1000000,1000000))
	var root_b := Vector3(rng.randf_range(-1000000,1000000),rng.randf_range(-1000000,1000000),rng.randf_range(-1000000,1000000))
	var root_a := Vector3(rng.randf_range(-1000000,1000000),rng.randf_range(-1000000,1000000),rng.randf_range(-1000000,1000000))
	
	for k in range(size):
		for j in range(size):
			for i in range(size):
				var offset := Vector3(i,j,k) / size
				var color := Color(0,0,0,0)
				color.r = noise.get_noise_3dv(root_r + offset * scale) * 0.5 + 0.5
				color.g = noise.get_noise_3dv(root_g + offset * scale * 2) * 0.5 + 0.5
				color.b = noise.get_noise_3dv(root_b + offset * scale * 4) * 0.5 + 0.5
				color.a = noise.get_noise_3dv(root_a + offset * scale * 8) * 0.5 + 0.5
				image.set_pixel(i, j + k * size, color)
	
	image.save_png(path)
	print("Done.")
