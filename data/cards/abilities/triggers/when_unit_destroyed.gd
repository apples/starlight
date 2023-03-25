@tool
extends CardAbilityTrigger

@export var this_unit: bool = true
@export var other_own_unit: bool = false
@export var opponent_unit: bool = false

func handle_unit_destroyed(
	e: TriggerEvents.UnitDestroyed, # The trigger event
	battle_state: BattleState,
	card_instance: CardInstance, # The card instance *this* ability belongs to
	ability_index: int, # Which ability slot *this* ability occupies on the card
	user_side: ZoneLocation.Side, # Which user will be activating *this* ability
) -> bool:
	
	if this_unit and e.was.is_same(card_instance):
		return true
	
	if other_own_unit and not e.was.is_same(card_instance) and e.unit.get_controller() == user_side:
		return true
	
	if opponent_unit and e.unit.get_controller() == ZoneLocation.flip(user_side):
		return true
	
	return false
