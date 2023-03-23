@tool
extends CardAbilityTrigger

@export var this_unit: bool = true
@export var for_mana: bool = false

func handle_unit_tapped(
	e: TriggerEvents.UnitTapped, # The trigger event
	battle_state: BattleState,
	card_instance: CardInstance, # The card instance *this* ability belongs to
	ability_index: int, # Which ability slot *this* ability occupies on the card
	user_side: ZoneLocation.Side, # Which user will be activating *this* ability
) -> bool:
	if this_unit and not e.unit.card_instance.is_same(card_instance):
		return false
	
	if for_mana and not e.for_mana:
		return false
	
	return true
