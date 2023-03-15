@tool
extends Control

@export var header_text: String = "":
	get:
		return header_text
	set(value):
		header_text = value
		if is_inside_tree():
			label.text = header_text


@export var resource_key: String = ""
@export var is_editable: bool = false

@export var is_last: bool = false:
	get:
		return is_last
	set(value):
		is_last = value
		if is_inside_tree():
			resize_handle.visible = not is_last
			size_flags_horizontal = SIZE_EXPAND_FILL if is_last else SIZE_FILL

@onready var label: Label = %Label
@onready var resize_handle: VSeparator = %ResizeHandle
@onready var items: Control = %Items

var property_info = null

var data_table_field_scene := preload("res://addons/card_engine/editor/data_table_field.tscn")
var data_table_field_enum_scene := preload("res://addons/card_engine/editor/data_table_field_enum.tscn")

var resizing: bool = false

signal saved(idx: int)

signal double_clicked(idx: int)

func _ready():
	label.text = header_text
	resize_handle.visible = not is_last
	size_flags_horizontal = SIZE_EXPAND_FILL if is_last else SIZE_FILL


func _on_resize_handle_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			resizing = true
			custom_minimum_size.x = size.x
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			resizing = false
	if not resizing:
		return
	if event is InputEventMouseMotion:
		custom_minimum_size.x = max(0, custom_minimum_size.x + event.relative.x)


func item_count():
	return items.get_child_count()

func get_item(idx: int) -> Control:
	assert(idx >= 0)
	assert(idx < item_count())
	return items.get_child(idx)

func append_item(item: Control):
	items.add_child(item)

func resize(count: int):
	for i in range(count, item_count()):
		get_item(i).queue_free()
	
	var enum_options = null
	
	if property_info:
		match property_info.hint:
			PROPERTY_HINT_ENUM:
				var hint_string: String = property_info.hint_string
				var option_strs := hint_string.split(",")
				enum_options = []
				for option in option_strs:
					var split := option.split(":")
					var label := split[0]
					var value: int = int(split[1]) if split.size() == 2 else -1
					assert(value != -1)
					enum_options.append([label, value])
	
	while item_count() < count:
		var item: Node
		if enum_options is Array:
			item = data_table_field_enum_scene.instantiate()
			append_item(item)
			item.set_options(enum_options)
			item.updated.connect(_item_updated)
		else:
			item = data_table_field_scene.instantiate()
			item.is_readonly = not is_editable
			append_item(item)
			item.double_clicked.connect(_item_double_clicked)
			item.updated.connect(_item_updated)

func _item_double_clicked(idx: int):
	double_clicked.emit(idx)

func set_datum(idx: int, data: Resource):
	assert(idx >= 0)
	assert(idx < item_count())
	
	assert(data)
	assert(resource_key in data)
	
	var c := get_item(idx)
	
	c.set_meta("data_table_resource", data.resource_path)
	
	if property_info is Dictionary:
		match property_info.hint:
			PROPERTY_HINT_RESOURCE_TYPE:
				push_error("Resource properties not supported")
				return
			PROPERTY_HINT_ENUM:
				c.value = int(data[resource_key])
			_:
				c.value = str(data[resource_key])
	else:
		c.value = str(data[resource_key])


func load_data(data: Array[String]):
	resize(data.size())
	for i in range(data.size()):
		set_datum(i, load(data[i]))


func _item_updated(who: Control):
	assert(who.has_meta("data_table_resource"))
	var data_file := who.get_meta("data_table_resource") as String
	assert(data_file)
	var data := load(data_file)
	assert(data)
	assert(resource_key in data)
	
	var value = who.value
	
	who.is_error = false
	
	if property_info is Dictionary:
		match property_info.hint:
			PROPERTY_HINT_RESOURCE_TYPE:
				push_error("Resource properties not supported")
				return
			_:
				data[resource_key] = who.value
	else:
		data[resource_key] = who.value
	
	ResourceSaver.save(data)
	
	saved.emit(who.get_index())

