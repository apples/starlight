class_name UnitState extends Resource

var exists: bool = false
var card_instance: CardInstance
var damage: int = 0
var is_tapped: bool = false

var remaining_hp: int:
	get: return card_instance.hp - damage

func get_controller() -> ZoneLocation.Side:
	return card_instance.location.side
