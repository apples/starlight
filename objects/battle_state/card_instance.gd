class_name CardInstance extends Resource

var card: Card
var id: int
var location: ZoneLocation
var owner_side: ZoneLocation.Side
var unit: UnitState

var ability_scratch: Array[Scratch] = []

func _init(c: Card, p_id: int, l: ZoneLocation, o: ZoneLocation.Side):
	card = c
	id = p_id
	location = l
	owner_side = o
	unit = null
	ability_scratch.resize(card.abilities.size())
	for i in range(card.abilities.size()):
		ability_scratch[i] = Scratch.new()

func _to_string():
	return "<%s, %s, %s>" % [card, id, location]

func is_same(other: CardInstance) -> bool:
	return id == other.id

class Scratch:
	var for_mechanics: Dictionary = {}
	var for_turn: Dictionary = {}
