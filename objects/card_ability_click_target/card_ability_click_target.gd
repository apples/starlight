extends MarginContainer

@onready var group = %Group

@onready var click_target = %ClickTarget


func _on_gui_input(event):
	if not click_target.enabled:
		return
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			click_target.confirm()


func _on_mouse_entered():
	if click_target.enabled:
		click_target.make_current()

