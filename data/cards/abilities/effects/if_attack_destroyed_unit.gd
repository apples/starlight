@tool
extends CardAbilityEffect

@export var effect: CardAbilityEffect

func get_output_variables() -> Array[String]:
	return ["destroyed_unit_level"]

class Task extends CardTask:
	var effect: CardAbilityEffect
	
	func start() -> void:
		if not effect:
			info("WARNING: no effect")
			return done()
		
		if ability_instance.attack_info.targets_destroyed.size() == 0:
			return done()
		
		ability_instance.variables.destroyed_unit_level = \
			ability_instance.attack_info.targets_destroyed[0].card_instance.card.level
		
		var effect_task := effect.create_task(ability_instance)
		
		become(effect_task)
