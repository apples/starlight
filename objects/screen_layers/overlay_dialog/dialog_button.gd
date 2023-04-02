extends Control

var text: String:
	get:
		return text
	set(value):
		text = value
		if label:
			label.text = value

signal clicked()

@onready var label = %Label
@onready var click_target = %ClickTarget

# Called when the node enters the scene tree for the first time.
func _ready():
	label.text = text


func _on_click_target_confirmed(click_target):
	clicked.emit()


func _on_mouse_entered():
	click_target.make_current()


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			clicked.emit()
