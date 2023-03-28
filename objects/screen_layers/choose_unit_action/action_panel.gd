extends PanelContainer


@onready var cursor_location = %CursorLocation
@onready var label = %Label

signal confirm()

# Called when the node enters the scene tree for the first time.
func _ready():
	label.text = name



func _on_gui_input(event: InputEvent):
	if not cursor_location.enabled:
		return
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			cursor_location.confirm()


func _on_mouse_entered():
	if cursor_location.enabled:
		cursor_location.make_current()
