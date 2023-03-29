@tool
extends CardAbilityTrigger

@export_flags( \
	"Opponent Back:1",
	"Opponent Front:2",
	"Own Front:4",
	"Own Back:8"
	) var from_zone: int = TargetZone.OWN_FRONT

enum TargetZone {
	OPPONENT_BACK = 1,
	OPPONENT_FRONT = 2,
	OWN_FRONT = 4,
	OWN_BACK = 8,
}

func handle_ability_activated(
	e: TriggerEvents.AbilityActivated,
	battle_state: BattleState,
	card_instance: CardInstance,
	ability_index: int,
	user_side: ZoneLocation.Side
) -> bool:
	var ability := e.ability_instance.get_ability()
	
	var opponent_side := ZoneLocation.flip(user_side)
	
	if ability.type == CardAbility.CardAbilityType.ATTACK:
		match e.ability_instance.source_location.tuple():
			[opponent_side, ZoneLocation.Zone.BackRow, _]:
				return from_zone & TargetZone.OPPONENT_BACK
			[opponent_side, ZoneLocation.Zone.FrontRow, _]:
				return from_zone & TargetZone.OPPONENT_FRONT
			[user_side, ZoneLocation.Zone.FrontRow, _]:
				return from_zone & TargetZone.OWN_FRONT
			[user_side, ZoneLocation.Zone.BackRow, _]:
				return from_zone & TargetZone.OWN_BACK
	
	return false
