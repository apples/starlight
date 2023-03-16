extends CardAbilityTrigger

# Determines if the trigger can be activated based on the current event stack
# This is a dynamically detected function:
# The format is `handle_<event>`
# The various trigger events can be found in: "res://objects/battle_state/trigger_events.gd"
# Scratch data can be stored in `card_instance.ability_scratch[ability_index]`
# Scratch data will be available to the ability's effect task
# The handlers are executed for trigger events in order from newest to oldest
# The first handler which returns `true` will stop older events from being handled

# This handler is called when an ability is activated
func handle_ability_activated(e: TriggerEvents.AbilityActivated, battle_state: BattleState, card_instance: CardInstance, ability_index: int, user_side: ZoneLocation.Side):
	# Get the ability from the card
	var ability := e.ability_instance.get_ability()
	
	# Check for an attack which was activated by our controller
	if ability.type == CardAbility.CardAbilityType.ATTACK:
		if e.ability_instance.controller == user_side:
			
			# Store this ability instance as the target in scratch
			card_instance.ability_scratch[ability_index] = {
				target_ability_instance = e.ability_instance,
			}
			
			return true
	
	# Don't handle any other kinds of ability activations
	return false
