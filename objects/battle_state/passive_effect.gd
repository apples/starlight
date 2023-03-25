class_name PassiveEffect extends RefCounted

var battle_state: BattleState
var controller: ZoneLocation.Side
var card_instance: CardInstance
var ability_index: int
var source_location: ZoneLocation

func get_ability() -> CardAbility:
	return card_instance.card.abilities[ability_index]

func is_active() -> bool:
	var ability := get_ability()
	for condition in ability.conditions:
		if not condition.is_met(battle_state, card_instance, ability_index):
			return false
	return true

