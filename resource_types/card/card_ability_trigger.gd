class_name CardAbilityTrigger
extends Resource

func can_activate(battle_state: BattleState, card_instance: CardInstance, ability_index: int, user_side: ZoneLocation.Side) -> bool:
	for e in battle_state.trigger_events:
		if not e.is_respondable:
			continue
		var handler: StringName = "handle_%s" % e.get_type()
		if self.has_method(handler):
			if self.call(handler, e, battle_state, card_instance, ability_index, user_side):
				return true
	
	return false
