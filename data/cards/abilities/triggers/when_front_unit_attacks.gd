@tool
extends CardAbilityTrigger

func handle_ability_activated(
	e: TriggerEvents.AbilityActivated,
	battle_state: BattleState,
	card_instance: CardInstance,
	ability_index: int,
	user_side: ZoneLocation.Side
) -> bool:
	var ability := e.ability_instance.get_ability()
	
	if ability.type == CardAbility.CardAbilityType.ATTACK:
		if e.ability_instance.controller == user_side:
			return true
	
	return false
