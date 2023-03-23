@tool
extends CardAbilityEffect

@export var amount: int = 0

class Task extends CardTask:
	var amount: int
	
	func start() -> void:
		var trigger_event := ability_instance.trigger_event as TriggerEvents.AbilityActivated
		var target_ability_instance := trigger_event.ability_instance
		
		info("amount = %s, target = %s" % [amount, target_ability_instance])
		
		target_ability_instance.attack_info.bonus_damage += amount
		return done()
