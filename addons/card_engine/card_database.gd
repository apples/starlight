@tool
extends Node

var config: CardEngineConfig:
	get:
		return config
	set(value):
		config = value
		reset()

var card_script: Script
var ability_script: Script

var data_root: String
var cards_path: String
var ability_costs_path: String
var ability_effects_path: String
var ability_triggers_path: String
var ability_conditionss_path: String
var ability_passives_path: String
var design_notes_path: String


func reset():
	if config == null:
		card_script = null
		ability_script = null
		data_root = ""
		cards_path = ""
		ability_effects_path = ""
		ability_triggers_path = ""
		ability_conditionss_path = ""
		ability_passives_path = ""
		ability_costs_path = ""
		design_notes_path = ""
	else:
		card_script = config.card_script
		ability_script = config.ability_script
		data_root = config.data_root
		cards_path = data_root.path_join(config.cards_path)
		ability_effects_path = data_root.path_join(config.ability_effects_path)
		ability_triggers_path = data_root.path_join(config.ability_triggers_path)
		ability_conditionss_path = data_root.path_join(config.ability_conditions_path)
		ability_passives_path = data_root.path_join(config.ability_passives_path)
		ability_costs_path = data_root.path_join(config.ability_costs_path)
		design_notes_path = data_root.path_join(config.design_notes_path)



func get_all_cards() -> Array[String]:
	return get_all_files(cards_path)


func get_all_ability_costs() -> Array[String]:
	return get_all_files(ability_costs_path)

func get_all_ability_effects() -> Array[String]:
	return get_all_files(ability_effects_path)

func get_all_ability_triggers() -> Array[String]:
	return get_all_files(ability_triggers_path)

func get_all_ability_conditions() -> Array[String]:
	return get_all_files(ability_conditionss_path)

func get_all_ability_passives() -> Array[String]:
	return get_all_files(ability_passives_path)


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
 

func get_design_note(card: Resource, no_create: bool = false) -> CardEngineDesignNote:
	var card_filename := card.resource_path.get_file()
	var notes_filename := design_notes_path.path_join(card_filename)
	
	var note: CardEngineDesignNote
	if not FileAccess.file_exists(notes_filename):
		if no_create:
			return null
		print("Creating new design notes at ", notes_filename)
		note = CardEngineDesignNote.new()
		ResourceSaver.save(note, notes_filename, ResourceSaver.FLAG_CHANGE_PATH)
	else:
		note = load(notes_filename)
	
	return note

func get_script_path(script_key: String, filename: String) -> String:
	var path_key := "ability_%ss_path" % script_key
	assert(path_key in self)
	return (self[path_key] as String).path_join(filename)

func create_script(script_key: String, filename: String) -> String:
	var template_key := script_key + "_template_path"
	assert(template_key in config)
	
	var template_path := config[template_key] as String
	assert(FileAccess.file_exists(template_path))
	
	var script_path := get_script_path(script_key, filename)
	
	if FileAccess.file_exists(script_path):
		return script_path
	
	print("Creating script: ", script_path)
	
	var fa := FileAccess.open(template_path, FileAccess.READ)
	var source_code := fa.get_as_text()
	fa.close()
	
	var script := GDScript.new()
	script.source_code = source_code
	ResourceSaver.save(script, script_path, ResourceSaver.FLAG_CHANGE_PATH)
	
	return script_path

func get_enum_options(prop: Dictionary) -> Array:
	assert(prop.hint == PROPERTY_HINT_ENUM || prop.hint == PROPERTY_HINT_FLAGS)
	var result := []
	var option_strs = prop.hint_string.split(",")
	for i in range(option_strs.size()):
		var option = option_strs[i]
		var split = option.split(":")
		var label = split[0]
		var value: int = int(split[1]) if split.size() == 2 else i
		result.append([label, value])
	return result

func get_mana_types():
	if card_script == null:
		print("Card script not set!")
		return []
	
	for p in card_script.get_script_property_list():
		if p.name == "mana":
			if p.hint != PROPERTY_HINT_ENUM:
				return []
			return get_enum_options(p)
	
	print("Mana property not found!")
	return []
