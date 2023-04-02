class_name BattleField extends Node3D

var stella: CardPlane
var front_row: Array[CardPlane] = []
var back_row: Array[CardPlane] = []

@export var side: ZoneLocation.Side = ZoneLocation.Side.Player
@export var flip_cursor_dirs: bool = false

func _ready():
	for x in $BackRow.get_children() + $FrontRow.get_children():
		var row: Array[CardPlane] = front_row
		var idx: int = 0
		if x.name.begins_with("FrontRow"):
			row = front_row
			idx = int(x.name.substr(8))
		elif x.name.begins_with("BackRow"):
			row = back_row
			idx = int(x.name.substr(7))
		else:
			continue
		if idx >= row.size():
			row.resize(idx + 1)
		row[idx] = x
	
	stella = $FrontRow/Stella
	stella.location = ZoneLocation.new(side, ZoneLocation.Zone.Stella)
	
	for i in range(back_row.size()):
		back_row[i].location = ZoneLocation.new(
			side,
			ZoneLocation.Zone.BackRow,
			i)
	
	for i in range(front_row.size()):
		front_row[i].location = ZoneLocation.new(
			side,
			ZoneLocation.Zone.FrontRow,
			i)
