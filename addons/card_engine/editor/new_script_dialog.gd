@tool
extends ConfirmationDialog


@export var error_string: String:
	get:
		return error_string
	set(value):
		error_string = value
		_refresh_error()

@onready var error_label = %ErrorLabel
@onready var line_edit = %LineEdit

var check_error: Callable

signal submit(str: String)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _submit():
	assert(error_string == "")
	submit.emit(line_edit.text)

func _on_line_edit_text_submitted(new_text):
	if error_string == "":
		_submit()

func _refresh_error():
	if not is_inside_tree():
		return
	
	error_label.text = error_string
	
	get_ok_button().disabled = error_string != ""



func _on_line_edit_text_changed(new_text):
	if check_error:
		error_string = check_error.call(new_text)
		_refresh_error()



func _on_confirmed():
	if error_string == "":
		_submit()


func _on_visibility_changed():
	if visible:
		line_edit.grab_focus()
