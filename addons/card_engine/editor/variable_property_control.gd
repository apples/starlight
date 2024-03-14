@tool
extends Control

@onready var fixed_value_container = %FixedValueContainer
@onready var variable_line_edit: LineEdit = %VariableLineEdit
@onready var check_button = %CheckButton
@onready var searchable_popup_menu = %SearchablePopupMenu

signal variable_changed(new_text: String)

var all_options: Array[String] = []

var variable_text: String:
	set(v):
		variable_text = v
		if variable_line_edit: variable_line_edit.text = v
		variable_changed.emit(v)

func _ready() -> void:
	searchable_popup_menu.edit.text = ""
	variable_line_edit.visible = variable_text != ""
	variable_line_edit.text = variable_text
	fixed_value_container.visible = not variable_line_edit.visible
	check_button.button_pressed = variable_line_edit.visible
	_update_filtered_options()

func set_options(options: Array[String]) -> void:
	all_options = options
	if not is_inside_tree():
		return
	_update_filtered_options()

func add_fixed_value_control(control: Control) -> void:
	%FixedValueContainer.add_child(control)

func _update_filtered_options():
	searchable_popup_menu.clear()
	for i in range(all_options.size()):
		var o := all_options[i]
		if searchable_popup_menu.edit.text == "" or o.contains(searchable_popup_menu.edit.text):
			searchable_popup_menu.add_item(o, i)
	


func _on_variable_line_edit_text_changed(new_text):
	variable_text = new_text

func _on_variable_line_edit_text_submitted(new_text):
	variable_text = new_text

func _on_check_button_toggled(button_pressed):
	if button_pressed:
		variable_line_edit.visible = true
		fixed_value_container.visible = false
	else:
		variable_line_edit.visible = false
		fixed_value_container.visible = true
		variable_text = ""

func _on_searchable_popup_menu_search_changed(new_text):
	_update_filtered_options()


func _on_searchable_popup_menu_search_submitted(new_text):
	variable_text = new_text
	searchable_popup_menu.hide()


func _on_searchable_popup_menu_selected_id(id):
	var text := all_options[id]
	variable_text = text
	searchable_popup_menu.hide()


func _open_search():
	searchable_popup_menu.show()
	var edit_pos := variable_line_edit.get_screen_position()
	var edit_xform := variable_line_edit.get_global_transform_with_canvas()
	var edit_size := edit_xform.get_scale() * variable_line_edit.size
	searchable_popup_menu.position = edit_pos
	searchable_popup_menu.size.x = edit_size.x
	searchable_popup_menu.edit.call_deferred("grab_focus")
	searchable_popup_menu.edit.text = ""
	_update_filtered_options()
	searchable_popup_menu.edit.text = variable_line_edit.text
	searchable_popup_menu.edit.select_all()


func _on_variable_line_edit_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
			_open_search()
