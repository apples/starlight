class_name CardInstance extends Resource

var card: Card
var battle_id: int
var location: ZoneLocation

func _init(c: Card, id: int, l: ZoneLocation):
	card = c
	battle_id = id
	location = l

func _to_string():
	return "<%s, %s, %s>" % [card, battle_id, location]
