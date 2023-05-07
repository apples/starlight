@tool
extends ConfirmationDialog

@onready var line_edit: LineEdit = %LineEdit
@onready var warning_label = %WarningLabel

func _ready():
	_validate()

func _on_line_edit_text_changed(new_text: String):
	_validate()

func _validate():
	if line_edit.text == "":
		warning_label.text = ""
		get_ok_button().disabled = true
		return
	
	var filename := line_edit.text
	if not filename.ends_with(".tres"):
		filename += ".tres"
	
	if not filename.is_valid_filename():
		warning_label.text = "Not a valid filename."
	elif FileAccess.file_exists(CardDatabase.decks_path.path_join(filename)):
		warning_label.text = "Deck name already exists."
	else:
		warning_label.text = ""
	
	get_ok_button().disabled = warning_label.text != ""
