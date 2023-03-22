@tool
extends "res://addons/card_engine/editor/ability_script_panel.gd"

@onready var move_down_button = %MoveDownButton
@onready var move_up_button = %MoveUpButton

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	call_deferred("_refresh_move_buttons")
	get_parent().child_entered_tree.connect(_on_parent_child_something_tree)
	get_parent().child_exiting_tree.connect(_on_parent_child_something_tree)
	saved.connect(_refresh_move_buttons)


func _on_move_down_button_pressed():
	_move(1)

func _on_move_up_button_pressed():
	_move(-1)

func _move(dir: int):
	var other = get_parent().get_child(self.get_index() + dir)
	assert(is_array)
	assert(other.is_array)
	assert(ability == other.ability)
	
	get_parent().move_child(self, self.get_index() + dir)
	
	_refresh_move_buttons()
	other._refresh_move_buttons()
	
	var tmp = ability[script_key][get_index()]
	ability[script_key][get_index()] = ability[script_key][other.get_index()]
	ability[script_key][other.get_index()] = tmp
	
	_save()

func _refresh_move_buttons():
	if get_parent() == null:
		return
	if self.get_index() < ability[script_key].size():
		move_up_button.disabled = self.get_index() == 0
		move_down_button.disabled = self.get_index() == ability[script_key].size() - 1
	else:
		move_up_button.disabled = true
		move_down_button.disabled = true
	if self.get_index() > 0:
		get_parent().get_child(get_index() - 1)._refresh_move_buttons()

# Called when a sibling either enters or exits the parent tree
func _on_parent_child_something_tree(_node):
	call_deferred("_refresh_move_buttons")
