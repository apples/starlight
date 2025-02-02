@tool
class_name CardAbilityCondition
extends Resource

enum ActivationZoneFlags {
	FIELD_FRONT = 1,
	FIELD_REAR = 2,
	HAND = 4,
	GRAVEYARD = 8,
	
	FIELD = 3,
}

@warning_ignore("unused_parameter")
func is_met(battle_state: BattleState, card_instance: CardInstance, ability_index: int) -> bool:
	push_error("CardAbilityCondition: is_met() not implemented")
	return false

func get_variable_names() -> Array[String]:
	return []

func get_activation_zones() -> int:
	return -1

func compute_variables(ability_instance: AbilityInstance) -> Dictionary:
	if not get_variable_names().is_empty():
		push_error("CardAbilityCondition (%s) specified some output variables, but did not implement compute_variables().")
		breakpoint
	return {}
