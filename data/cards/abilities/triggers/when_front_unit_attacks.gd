extends CardAbilityTrigger

@export var amount: int = 0

func can_activate(battle_state: BattleState, user_side: ZoneLocation.Side) -> bool:
	for e in battle_state.trigger_events:
		match e.
