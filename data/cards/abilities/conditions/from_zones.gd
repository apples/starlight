@tool
extends CardAbilityCondition

@export_flags("Front:1", "Rear:2", "Hand:4", "Graveyard:8") var zones: int = 0

func get_activation_zones() -> int:
	return zones

func is_met(
	battle_state: BattleState,
	card_instance: CardInstance,
	ability_index: int
) -> bool:
	match card_instance.location.zone:
		ZoneLocation.Zone.FrontRow:
			return zones & ActivationZoneFlags.FIELD_FRONT
		ZoneLocation.Zone.BackRow:
			return zones & ActivationZoneFlags.FIELD_REAR
		ZoneLocation.Zone.Hand:
			return zones & ActivationZoneFlags.HAND
		ZoneLocation.Zone.Discard:
			return zones & ActivationZoneFlags.GRAVEYARD
		_:
			return false
