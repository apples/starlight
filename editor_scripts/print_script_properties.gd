@tool
extends EditorScript

var the_script: Script = preload("res://objects/battle_state/trigger_events.gd")

func _run():
	print("PROPERTIES: ", the_script.get_script_property_list())
	print("CONSTANTS: ", the_script.get_script_constant_map())
