@tool
extends LineEdit

signal opened()
signal selected_id(id: int)
signal search_changed(new_text: String)
signal search_submitted(new_text: String)

@onready var popup_menu = %PopupMenu

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
			_open_search()

func _open_search():
	popup_menu.show()
	var edit_pos := get_screen_position()
	var edit_xform := get_global_transform_with_canvas()
	var edit_size := edit_xform.get_scale() * size
	popup_menu.position = edit_pos
	popup_menu.size.x = edit_size.x
	popup_menu.edit.text = ""
	popup_menu.edit.call_deferred("grab_focus")
	opened.emit()

func _on_popup_menu_search_changed(new_text):
	search_changed.emit(new_text)


func _on_popup_menu_search_submitted(new_text):
	search_submitted.emit(new_text)


func _on_popup_menu_selected_id(id):
	selected_id.emit(id)


func _on_popup_menu_close_requested():
	release_focus()
