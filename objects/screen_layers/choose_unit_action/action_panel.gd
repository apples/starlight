extends PanelContainer

@export var custom_tag: String

@onready var click_target = %ClickTarget
@onready var label = %Label

signal confirm()

# Called when the node enters the scene tree for the first time.
func _ready():
	label.text = name
	click_target.custom_tag = custom_tag



func _on_gui_input(event: InputEvent):
	if not click_target.enabled:
		return
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			click_target.confirm()


func _on_mouse_entered():
	if click_target.enabled:
		click_target.make_current()
