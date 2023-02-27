class_name CardInstance extends Resource

var card: Card
var battle_id: int
var location: ZoneLocation
var owner: ZoneLocation.Side

func _init(c: Card, id: int, l: ZoneLocation, o: ZoneLocation.Side):
	card = c
	battle_id = id
	location = l
	owner = o

func _to_string():
	return "<%s, %s, %s>" % [card, battle_id, location]
