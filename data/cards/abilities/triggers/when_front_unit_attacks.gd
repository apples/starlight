extends CardAbilityTrigger

@export var amount: int = 0

func can_activate(battle_state: BattleState, user_side: ZoneLocation.Side) -> bool:
	for e in battle_state.trigger_events:
		var handler: StringName = "handle_%s" % e.get_type()
		if self.has_method(handler):
			if self.call(handler):
				return true
	return false

func handle_ability_activated(e: TriggerEvents.AbilityActivated):
	pass
