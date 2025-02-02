@tool
extends ScrollContainer


var columns: Array[Control] = []

var data: Array[Card] = []

@onready var column_container := %Columns
@onready var data_table_popup_menu: PopupMenu = %DataTablePopupMenu

signal row_clicked(idx: int)
signal show_in_filesystem_requested(path: String)
signal delete_requested(cardfilepath: String)

var primary_selection: int = -1:
	set(v):
		if primary_selection == v:
			return
		primary_selection = v
		queue_redraw()

var multi_selection: Array[int] = []

var right_click_index: int

# Called when the node enters the scene tree for the first time.
func _ready():
	columns.assign(column_container.get_children())
	for col in columns:
		col.clicked.connect(_column_clicked)
		col.right_clicked.connect(_column_right_clicked)
	self.get_v_scroll_bar().value_changed.connect(func (v):
		queue_redraw())

func _draw() -> void:
	for m in multi_selection:
		var col_control: Control = column_container.get_child(0).get_item(primary_selection)
		var pos: Vector2 = col_control.global_position - column_container.global_position
		pos.x = 0
		pos.y -= get_v_scroll_bar().value
		var sz := Vector2(size.x - get_v_scroll_bar().size.x, 32)
		draw_rect(Rect2(pos, sz), Color("#457095"))
	if primary_selection != -1:
		var col_control: Control = column_container.get_child(0).get_item(primary_selection)
		var pos: Vector2 = col_control.global_position - column_container.global_position
		pos.x = 0
		pos.y -= get_v_scroll_bar().value
		var sz := Vector2(size.x - get_v_scroll_bar().size.x, 32)
		draw_rect(Rect2(pos, sz), Color("#5f9fd5"))

func _column_clicked(column: Control, row: int):
	primary_selection = row
	row_clicked.emit(row)


func _column_right_clicked(column: Control, row: int):
	right_click_index = row
	var pos := get_viewport().get_window().position + Vector2i(get_viewport().get_mouse_position())
	data_table_popup_menu.size = Vector2(0,0)
	data_table_popup_menu.position = pos
	data_table_popup_menu.show()


func set_data(new_data: Array[Card]):
	data = new_data
	primary_selection = -1
	multi_selection.clear()
	
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
			show_in_filesystem_requested.emit(data[right_click_index].resource_path)
		1: # Delete
			_delete(data[right_click_index])


func _delete(card: Card):
	var dialog := ConfirmationDialog.new()
	dialog.title = "Delete card"
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	var label := Label.new()
	label.text = """
	You are about to permanently delete the card:
	%s
	%s
	This cannot be undone.
	Are you sure?
	""" % [card.resource_path, card.card_name]
	
	dialog.add_child(label)
	add_child(dialog)
	
	dialog.show()
	
	dialog.canceled.connect(func ():
		dialog.queue_free())
	
	await dialog.confirmed
	
	dialog.queue_free()
	
	delete_requested.emit(card.resource_path)
