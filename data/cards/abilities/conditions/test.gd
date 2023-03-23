@tool
extends CardAbilityCondition

func is_met(battle_state: BattleState, card_instance: CardInstance, ability_index: int) -> bool:
	return false
