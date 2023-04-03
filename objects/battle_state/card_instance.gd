class_name CardInstance extends Resource

var card: Card
var uid: int
var location: ZoneLocation
var owner_side: ZoneLocation.Side
var unit: UnitState

var ability_scratch: Array[Scratch] = []

func _init(c: Card, id: int, l: ZoneLocation, o: ZoneLocation.Side):
	card = c
	uid = id
	location = l
	owner_side = o
	unit = null
	ability_scratch.resize(card.abilities.size())
	for i in range(card.abilities.size()):
		ability_scratch[i] = Scratch.new()

func _to_string():
	return "<%s, %s, %s>" % [card, uid, location]

func is_same(other: CardInstance) -> bool:
	return uid == other.uid

class Scratch:
	var for_mechanics: Dictionary = {}
	var for_turn: Dictionary = {}
