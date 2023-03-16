@tool
extends EditorPlugin

const MainPanel = preload("res://addons/card_engine/editor/editor_panel.tscn")

var panel

func _enter_tree():
	panel = MainPanel.instantiate()
	panel.visible = false
	panel.edit_script_requested.connect(_edit_script)
	add_autoload_singleton("CardDatabase", "res://addons/card_engine/card_database.gd")
	get_editor_interface().get_editor_main_screen().add_child(panel)
	_make_visible(false)
	add_custom_type(
		"CardEngineConfig",
		"Resource",
		preload("res://addons/card_engine/resource_types/card_engine_config.gd"),
		preload("res://addons/card_engine/icons/card_engine_config.png")
	)
	add_custom_type(
		"CardEngineDesignNote",
		"Resource",
		preload("res://addons/card_engine/resource_types/card_engine_design_note.gd"),
		preload("res://addons/card_engine/icons/card_engine_design_note.png")
	)

func _exit_tree():
	if panel:
		panel.queue_free()
	remove_autoload_singleton("CardDatabase")
	remove_custom_type("CardEngineConfig")
	remove_custom_type("CardEngineDesignNote")


func _has_main_screen():
	return true


func _make_visible(visible):
	if panel:
		panel.visible = visible


func _get_plugin_name():
	return "Cards"


func _get_plugin_icon():
	return get_editor_interface().get_base_control().get_theme_icon("ActionCopy", "EditorIcons")


func _edit_script(script: Script):
	get_editor_interface().edit_script(script)
	get_editor_interface().set_main_screen_editor("Script")
