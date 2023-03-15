@tool
extends EditorScript


# Called when the node enters the scene tree for the first time.
func _run():
	print("howdy")
	CardDatabase.config = load("res://card_engine_config.tres")
