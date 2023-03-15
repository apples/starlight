@tool
extends ConfirmationDialog

signal change_set(set: String)

@onready var option_button: OptionButton = %Set

var is_new_set: bool = false

func _ready():
	%NewSetContainer.visible = false
	


func set_sets(options: Array[String]):
	option_button.clear()
	for o in options:
		option_button.add_item(o)
	option_button.add_item("NEW SET")

func _on_confirmed():
	change_set.emit(%NewSet.text if is_new_set else option_button.get_item_text(option_button.selected))
	queue_free()


func _on_canceled():
	queue_free()


func _on_set_item_selected(index):
	is_new_set = option_button.get_item_text(index) == "NEW SET"
	%NewSetContainer.visible = is_new_set
	if is_new_set:
		%NewSet.text = ""
		%NewSet.call_deferred("grab_focus")

