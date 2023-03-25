class_name BattleField extends Node3D

var stella: CardPlane
var front_row: Array[CardPlane] = []
var back_row: Array[CardPlane] = []

@export var side: ZoneLocation.Side = ZoneLocation.Side.Player
@export var flip_cursor_dirs: bool = false

func _ready():
	for x in get_children():
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
		row.resize(idx + 1)
		row[idx] = x
	
	stella = $Stella
	stella.location = ZoneLocation.new(side, ZoneLocation.Zone.Stella)
	
	for i in range(back_row.size()):
		back_row[i].location = ZoneLocation.new(side, ZoneLocation.Zone.BackRow, i)
		var cursor_location := back_row[i].cursor_location
		if i > 0:
			var left := back_row[i - 1].cursor_location
			if !flip_cursor_dirs:
				left.right = cursor_location
				cursor_location.left = left
			else:
				left.left = cursor_location
				cursor_location.right = left
		if front_row.size() > 0:
			var idx: int = i * front_row.size() / back_row.size()
			var front := front_row[idx].cursor_location
			if !flip_cursor_dirs:
				if !front.down or i < back_row.size() / 2:
					front.down = cursor_location
				cursor_location.up = front
			else:
				if !front.up or i < back_row.size() / 2:
					front.up = cursor_location
				cursor_location.down = front
	
	for i in range(front_row.size()):
		front_row[i].location = ZoneLocation.new(side, ZoneLocation.Zone.FrontRow, i)
		var cursor_location := front_row[i].cursor_location
		if i > 0:
			var left := front_row[i - 1].cursor_location
			if !flip_cursor_dirs:
				left.right = cursor_location
				cursor_location.left = left
			else:
				left.left = cursor_location
				cursor_location.right = left
	
	if !flip_cursor_dirs:
		front_row[1].cursor_location.right = stella.cursor_location
		stella.cursor_location.left = front_row[1].cursor_location
		
		back_row[3].cursor_location.up = stella.cursor_location
		stella.cursor_location.down = back_row[3].cursor_location
	else:
		front_row[1].cursor_location.left = stella.cursor_location
		stella.cursor_location.right = front_row[1].cursor_location
		
		back_row[3].cursor_location.down = stella.cursor_location
		stella.cursor_location.up = back_row[3].cursor_location
	
