@tool
extends CardAbilityEffect

enum Target {
	SELF = 0,
}

@export var target: Target = Target.SELF

# The task which will perform the effect
class Task extends CardTask:
	var target: Target
	
	# Start of effect execution
	func start() -> void:
		var card_instance: CardInstance
		
		match target:
			Target.SELF:
				card_instance = ability_instance.card_instance
		
		assert(card_instance)
		
		battle_state.unit_set_tapped(card_instance.unit, false)
