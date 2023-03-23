class_name CardAbilityTrigger
extends Resource

func can_activate(battle_state: BattleState, card_instance: CardInstance, ability_index: int, user_side: ZoneLocation.Side) -> bool:
	for e in battle_state.trigger_events:
		if can_activate_single(e, battle_state, card_instance, ability_index, user_side):
			return true
	
	return false

func can_activate_single(e: TriggerEvent, battle_state: BattleState, card_instance: CardInstance, ability_index: int, user_side: ZoneLocation.Side) -> bool:
	if not e.is_respondable:
		return false
	
	var handler: StringName = "handle_%s" % e.get_type()
	if self.has_method(handler):
		if self.call(handler, e, battle_state, card_instance, ability_index, user_side):
			card_instance.ability_scratch[ability_index].trigger_event = e
			return true
	
	return false
