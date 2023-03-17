class_name CardInstance extends Resource

var card: Card
var uid: int
var location: ZoneLocation
var owner_side: ZoneLocation.Side
var unit: UnitState

var ability_scratch: Array[Dictionary] = [{}, {}]

func _init(c: Card, id: int, l: ZoneLocation, o: ZoneLocation.Side):
	card = c
	uid = id
	location = l
	owner_side = o
	unit = null

func _to_string():
	return "<%s, %s, %s>" % [card, uid, location]

func is_same(other: CardInstance) -> bool:
	return uid == other.uid
