extends MarginContainer

@onready var cursor_location = %CursorLocation


func _on_gui_input(event):
	if not cursor_location.enabled:
		return
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			cursor_location.confirm()


func _on_mouse_entered():
	if cursor_location.enabled:
		cursor_location.make_current()

