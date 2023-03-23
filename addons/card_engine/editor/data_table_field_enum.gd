@tool
extends Control

@export var is_readonly: bool = false

@export var hide_separator: bool = false:
	get:
		return hide_separator
	set(value):
		hide_separator = value
		if is_inside_tree():
			$HSeparator.visible = not hide_separator

var value: int = -1:
	get:
		return value
	set(v):
		value = v
		if is_inside_tree():
			_refresh()

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


@onready var option_button: OptionButton = %OptionButton

signal updated(me: Control)

var _options: Array

func _ready():
	$HSeparator.visible = not hide_separator
	_refresh()

func _refresh():
	option_button.clear()
	for o in _options:
		option_button.add_item(o[0], o[1])
	option_button.select(option_button.get_item_index(value))

func set_options(options: Array):
	_options = options
	if is_inside_tree():
		_refresh()

func _on_option_button_item_selected(index):
	value = option_button.get_item_id(index)
	updated.emit(self)



