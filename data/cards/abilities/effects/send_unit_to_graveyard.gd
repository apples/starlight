@tool
extends CardAbilityEffect

# The task which will perform the effect
class Task extends CardTask:
	
	# Start of effect execution
	func start() -> void:
		for target in ability_instance.targets:
			var unit := battle_state.unit_get(target)
			if unit:
				battle_state.unit_discard(target)
		
		done()
