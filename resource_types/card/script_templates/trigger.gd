@tool
extends CardAbilityTrigger

# Determines if the trigger can be activated based on the current event stack
# This is a dynamically detected function:
# The format is `handle_<event>`
# The various trigger events can be found in: "res://objects/battle_state/trigger_events.gd"
# Scratch data can be stored in `scratch.for_turn`
# Scratch data will be available to the ability's effect task
# The handlers are executed for trigger events in order from newest to oldest
# The first handler which returns `true` will stop older events from being handled

# This handler is called when an ability is activated
func handle_ability_activated(
	e: TriggerEvents.AbilityActivated, # The trigger event
	battle_state: BattleState,
	card_instance: CardInstance, # The card instance *this* ability belongs to
	ability_index: int, # Which ability slot *this* ability occupies on the card
	user_side: ZoneLocation.Side, # Which user will be activating *this* ability
) -> bool:
	# Get the ability from the other card
	var ability := e.ability_instance.get_ability()
	
	# Check for an attack which was activated by our controller
	if ability.type == CardAbility.CardAbilityType.ATTACK:
		if e.ability_instance.controller == user_side:
			
			return true
	
	# Don't handle any other kinds of ability activations
	return false
