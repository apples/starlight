@tool
extends Node

var config: CardEngineConfig:
	get:
		return config
	set(value):
		config = value
		reset()

var card_script: Script

var data_root: String
var cards_path: String
var ability_costs_path: String
var ability_effects_path: String
var ability_triggers_path: String


func reset():
	if config == null:
		data_root = ""
		cards_path = ""
		ability_effects_path = ""
		ability_triggers_path = ""
		ability_costs_path = ""
	else:
		card_script = config.card_script
		data_root = config.data_root
		cards_path = data_root.path_join(config.cards_path)
		ability_effects_path = data_root.path_join(config.ability_effects_path)
		ability_triggers_path = data_root.path_join(config.ability_triggers_path)
		ability_costs_path = data_root.path_join(config.ability_costs_path)



func get_all_cards() -> Array[String]:
	return get_all_files(cards_path)


func get_all_ability_costs() -> Array[String]:
	return get_all_files(ability_costs_path)

func get_all_ability_effects() -> Array[String]:
	return get_all_files(ability_effects_path)

func get_all_ability_triggers() -> Array[String]:
	return get_all_files(ability_triggers_path)


func get_all_files(dir_path: String, accum = null) -> Array[String]:
	if accum == null:
		accum = Array([], TYPE_STRING, &"", null)
	var results := accum as Array[String]
	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				get_all_files(dir_path.path_join(file_name), accum)
			else:
				results.append(dir_path.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("An error occurred when trying to access the path: " + dir_path)
	return results

