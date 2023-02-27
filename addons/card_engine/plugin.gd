@tool
extends EditorPlugin

const MainPanel = preload("res://addons/card_engine/editor/editor_panel.tscn")

var panel

func _enter_tree():
	panel = MainPanel.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(panel)
	_make_visible(false)
	add_autoload_singleton("CardDatabase", "res://addons/card_engine/card_database.gd")


func _exit_tree():
	if panel:
		panel.queue_free()
	remove_autoload_singleton("CardDatabase")


func _has_main_screen():
	return true


func _make_visible(visible):
	if panel:
		panel.visible = visible


func _get_plugin_name():
	return "Cards"


func _get_plugin_icon():
	return get_editor_interface().get_base_control().get_theme_icon("ActionCopy", "EditorIcons")
