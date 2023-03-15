@tool
extends Control


var columns: Array[Control] = []

var data: Array[String] = []

@onready var column_container := $Columns

# Called when the node enters the scene tree for the first time.
func _ready():
	columns.assign(column_container.get_children())


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

