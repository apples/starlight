@tool
extends EditorPlugin

const MainPanel = preload("res://addons/card_engine/editor/editor_panel.tscn")

var panel

func _enter_tree():
	add_autoload_singleton("CardDatabase", "res://addons/card_engine/card_database.gd")
	panel = MainPanel.instantiate()
	panel.visible = false
	panel.edit_script_requested.connect(_edit_script)
	panel.show_in_filesystem_requested.connect(_show_in_filesystem)
	panel.plugin = self
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

func _show_in_filesystem(path: String):
	get_editor_interface().get_file_system_dock().navigate_to_path(path)

signal _delete_card_dialog_closed

func delete_card(path: String):
	var card = load(path)
	
	var note = get_editor_interface().get_node("/root/CardDatabase").get_design_note(card, true)
	
	assert(card)
	
	var card_owners := _find_owners(card.resource_path)
	
	if card_owners.size() > 0:
		var dialog := AcceptDialog.new()
		dialog.title = "Cancelled"
		dialog.size = Vector2i(400, 300)
		dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
		dialog.confirmed.connect(func ():
			dialog.queue_free()
			_delete_card_dialog_closed.emit())
		dialog.canceled.connect(func ():
			dialog.queue_free()
			_delete_card_dialog_closed.emit())
		var layout := VBoxContainer.new()
		var label := Label.new()
		label.text = """
		Refusing to delete card.
		It is currently in use by:
		"""
		layout.add_child(label)
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size.y = 100
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var scroll_layout := VBoxContainer.new()
		scroll.add_child(scroll_layout)
		layout.add_child(scroll)
		dialog.add_child(layout)
		
		for o in card_owners:
			var ol := Label.new()
			ol.text = o
			scroll_layout.add_child(ol)
		
		panel.add_child(dialog)
		dialog.show()
		
		await _delete_card_dialog_closed
		
		return false
	
	assert(FileAccess.file_exists(card.resource_path))
	DirAccess.remove_absolute(card.resource_path)
	
	if note:
		assert(FileAccess.file_exists(note.resource_path))
		DirAccess.remove_absolute(note.resource_path)
	
	get_editor_interface().get_resource_filesystem().scan()
	
	return true


func _find_owners(path: String) -> Array[String]:
	var results: Array[String] = []
	var efsd := get_editor_interface().get_resource_filesystem().get_filesystem()
	_find_owners_rec(path, efsd, results)
	return results

func _find_owners_rec(path: String, efsd: EditorFileSystemDirectory, results: Array[String]):
	if not efsd:
		return
	
	for i in range(efsd.get_subdir_count()):
		_find_owners_rec(path, efsd.get_subdir(i), results)
	
	for i in range(efsd.get_file_count()):
		var file := efsd.get_file_path(i)
		for dep in ResourceLoader.get_dependencies(file):
			if dep.begins_with("uid://"):
				dep = ResourceUID.get_id_path(ResourceUID.text_to_id(dep))
			if dep == path:
				results.append(file)
				break
