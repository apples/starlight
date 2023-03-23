@tool
extends Window

@onready var panel := $Panel
@onready var items := %Items

@onready var edit: LineEdit = $Panel/VBoxContainer/LineEdit

signal selected_id(id: int)
signal search_changed(new_text: String)
signal search_submitted(new_text: String)

func clear():
	while items.get_child_count() > 0:
		var c := items.get_child(0)
		c.queue_free()
		items.remove_child(c)

func add_item(text: String, id: int):
	var mc := MarginContainer.new()
	items.add_child(mc)
	
	var label := Label.new()
	label.text = text
	mc.add_child(label)
	
	mc.gui_input.connect(func (event):
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				selected_id.emit(id)
				visible = false)

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			hide()

func _on_close_requested():
	hide()
	edit.release_focus()

func _on_line_edit_text_changed(new_text):
	search_changed.emit(new_text)

func _on_line_edit_text_submitted(new_text):
	search_submitted.emit(new_text)
