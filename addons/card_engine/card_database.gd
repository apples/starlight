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
var design_notes_path: String


func reset():
	if config == null:
		card_script = null
		ability_script = null
		data_root = ""
		cards_path = ""
		ability_effects_path = ""
		ability_triggers_path = ""
		ability_costs_path = ""
		design_notes_path = ""
	else:
		card_script = config.card_script
		ability_script = config.ability_script
		data_root = config.data_root
		cards_path = data_root.path_join(config.cards_path)
		ability_effects_path = data_root.path_join(config.ability_effects_path)
		ability_triggers_path = data_root.path_join(config.ability_triggers_path)
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
 

func get_design_note(card: Resource) -> CardEngineDesignNote:
	var card_filename := card.resource_path.get_file()
	var notes_filename := design_notes_path.path_join(card_filename)
	
	var note: CardEngineDesignNote
	if not FileAccess.file_exists(notes_filename):
		print("Creating new design notes at ", notes_filename)
		note = CardEngineDesignNote.new()
		ResourceSaver.save(note, notes_filename, ResourceSaver.FLAG_CHANGE_PATH)
	else:
		print("Loading existing design notes ", notes_filename)
		note = load(notes_filename)
	
	return note


func create_script(script_key: String, filename: String) -> String:
	var template_key := script_key + "_template_path"
	assert(template_key in config)
	var path_key := "ability_%ss_path" % script_key
	assert(path_key in self)
	
	var template_path := config[template_key] as String
	assert(FileAccess.file_exists(template_path))
	
	var script_path := (self[path_key] as String).path_join(filename)
	
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

