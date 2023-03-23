@tool
extends EditorScript

var the_script: Script = preload("res://data/cards/abilities/passives/when_trigger_run_effect.gd")

func _run():
	print("PROPERTIES: ", the_script.get_script_property_list())
	print("CONSTANTS: ", the_script.get_script_constant_map())
