@tool
extends ConfirmationDialog


signal new_card(set: String, name: String)

@export var change_set_window: PackedScene = preload("res://addons/card_engine/editor/change_set_window.tscn")


@onready var cardset_edit: LineEdit = %Set
@onready var name_edit: LineEdit = %Name

var options: Array[String]

func set_sets(set_options: Array[String]):
	options = set_options


func _on_confirmed():
	new_card.emit(cardset_edit.text, name_edit.text)
	queue_free()

func _on_canceled():
	queue_free()


func _on_change_set_button_pressed():
	var popup := change_set_window.instantiate()
	add_child(popup)
	popup.set_sets(options)
	popup.change_set.connect(func (cardset_name: String):
		cardset_edit.text = cardset_name
	)
	


func _on_visibility_changed():
	if visible:
		name_edit.grab_focus()


func _on_name_text_submitted(new_text):
	_on_confirmed()
