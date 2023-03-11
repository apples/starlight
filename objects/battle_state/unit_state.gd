class_name UnitState extends Resource

var card_instance: CardInstance
var damage: int = 0
var is_tapped: bool = false

var remaining_hp: int:
	get: return card_instance.hp - damage
