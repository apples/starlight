@tool
extends Control


var columns: Array[Control] = []

var data: Array[String] = []

@onready var column_container := %Columns
@onready var highlight_panel: Control = %HighlightPanel
@onready var data_table_popup_menu: PopupMenu = %DataTablePopupMenu

signal row_clicked(idx: int)
signal show_in_filesystem_requested(path: String)

var right_click_index: int

# Called when the node enters the scene tree for the first time.
func _ready():
	columns.assign(column_container.get_children())
	for col in columns:
		col.clicked.connect(_column_clicked)
		col.right_clicked.connect(_column_right_clicked)
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

func _column_right_clicked(column: Control, row: int):
	right_click_index = row
	var pos := get_viewport().get_window().position + Vector2i(get_viewport().get_mouse_position())
	data_table_popup_menu.size = Vector2(0,0)
	data_table_popup_menu.position = pos
	data_table_popup_menu.show()


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




func _on_data_table_popup_menu_id_pressed(id):
	match id:
		0: # Show in FileSystem
			show_in_filesystem_requested.emit(data[right_click_index])
