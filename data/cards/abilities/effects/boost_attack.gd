@tool
extends CardAbilityEffect

@export var amount: int = 0

func task() -> CardTask: return Task.new(amount)

class Task extends CardTask:
	var _amount: int
	
	func _init(amount: int):
		_amount = amount
	
	func start() -> void:
		var trigger_event := ability_instance.trigger_event as TriggerEvents.AbilityActivated
		var target_ability_instance := trigger_event.ability_instance
		
		info("amount = %s, target = %s" % [_amount, target_ability_instance])
		
		target_ability_instance.attack_bonus_damage += _amount
		return done()
