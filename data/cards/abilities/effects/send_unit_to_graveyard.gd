@tool
extends CardAbilityEffect

# The task which will perform the effect
class Task extends CardTask:
	
	# Start of effect execution
	func start() -> void:
		for target in ability_instance.targets:
			var unit := battle_state.get_unit(target)
			if unit:
				battle_state.discard_unit(target)
		
		done()
