@tool
class_name CardAbilityCondition
extends Resource

@warning_ignore("unused_parameter")
func is_met(battle_state: BattleState, card_instance: CardInstance, ability_index: int) -> bool:
	push_error("CardAbilityCondition: is_met() not implemented")
	return false

func get_output_variables() -> Array[String]:
	return []
