@tool
class_name CardAbilityCondition
extends Resource

@warning_ignore("unused_parameter")
func is_met(battle_state: BattleState, card_instance: CardInstance, ability_index: int) -> bool:
	push_error("CardAbilityCondition: is_met() not implemented")
	return false

func get_variable_names() -> Array[String]:
	return []

func compute_variables(ability_instance: AbilityInstance) -> Dictionary:
	if not get_variable_names().is_empty():
		push_error("CardAbilityCondition (%s) specified some output variables, but did not implement compute_variables().")
		breakpoint
	return {}
