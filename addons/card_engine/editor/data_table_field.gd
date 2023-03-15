@tool
extends Control

@export var is_readonly: bool = false

@export var value: String = "":
	get:
		return value
	set(v):
		value = v
		if is_inside_tree():
			_refresh()

@export var allow_file_drops: Array[String] = []

var is_error: bool = false:
	get:
		return is_error
	set(value):
		is_error = value
		if is_inside_tree():
			pass
			#assert(has_theme_stylebox_override("panel"))
			#var stylebox := get_theme_stylebox("panel") as StyleBoxFlat
			#assert(stylebox)
			#stylebox.bg_color.a = 1 if is_error else 0


@onready var label: Label = %Label
@onready var edit: LineEdit = %LineEdit

var is_editing := false

signal updated(me: Control)
signal clicked(me: Control)
signal double_clicked(idx: int)

func _ready():
	label.visible = true
	label.text = value
	edit.visible = false
	edit.text = value
	set_process_unhandled_input(false)

func _refresh():
	label.text = value
	edit.text = value

func start_editing():
	if is_readonly:
		return
	if is_editing:
		return
	
	is_editing = true
	label.visible = false
	edit.visible = true
	edit.call_deferred("grab_focus")
	edit.select_all()
	set_process_unhandled_input(true)

func stop_editing(cancelled: bool = false):
	if not is_editing:
		return
	
	is_editing = false
	label.visible = true
	edit.visible = false
	if not cancelled and edit.text != value:
		value = edit.text
		updated.emit(self)
	set_process_unhandled_input(false)


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(self)
		if not is_editing:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT && event.double_click:
				if not is_readonly:
					start_editing()
				else:
					double_clicked.emit(get_index() - 1)
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_ENTER,KEY_KP_ENTER,KEY_ESCAPE:
					stop_editing()


func _unhandled_input(event):
	assert(is_editing)
	if event is InputEventMouseButton:
		if event.pressed and not edit.get_global_rect().has_point(event.position):
			stop_editing()


func _on_line_edit_focus_exited():
	stop_editing()



func _on_line_edit_gui_input(event):
	_on_gui_input(event)


func _can_drop_data(at_position, data):
	if allow_file_drops.size() == 0:
		return false
	if data.type != "files":
		return false
	if data.files.size() != 1:
		return false
	var file_path: String = data.files[0]
	var file_ext := file_path.get_extension()
	if not file_ext in allow_file_drops:
		return false
	return true

func _drop_data(at_position, data):
	assert(data.type == "files")
	assert(data.files[0].get_extension() in allow_file_drops)
	var file_path: String = data.files[0]
	value = file_path
	updated.emit(self)

