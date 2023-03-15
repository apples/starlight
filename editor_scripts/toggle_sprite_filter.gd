@tool
extends EditorScript


func _run():
	Settings.sprite_filter_trilinear = not Settings.sprite_filter_trilinear
