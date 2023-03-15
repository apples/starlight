@tool
extends Control


var columns: Array[Control] = []

var data: Array[String] = []

@onready var column_container := %Columns
@onready var highlight_panel: Control = %HighlightPanel

signal row_clicked(idx: int)

# Called when the node enters the scene tree for the first time.
func _ready():
	columns.assign(column_container.get_children())
	for col in columns:
		col.clicked.connect(_column_clicked)
	highlight_panel.visible = false

func _column_clicked(column: Control, row: int):
	var col_control: Control = column.get_item(row)
	var pos: Vector2 = col_control.global_position - highlight_panel.get_parent().global_position
	pos.x = 0
	var sz := Vector2(size.x, 32)
	highlight_panel.visible = true
	highlight_panel.position = pos
	highlight_panel.size = sz
	row_clicked.emit(row)


func set_data(new_data: Array[String]):
	data = new_data
	
	if data.size() == 0:
		for col in columns:
			col.resize(0)
		return
	
	var props := {}
	for prop in CardDatabase.card_script.get_script_property_list():
		props[prop.name] = prop
	
	for col in columns:
		assert(col.resource_key in props)
		col.property_info = props[col.resource_key]
		col.load_data(data)

