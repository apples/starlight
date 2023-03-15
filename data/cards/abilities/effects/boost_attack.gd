@tool
extends CardAbilityEffect

@export var amount: int = 0

func task() -> CardTask: return Task.new(amount)

class Task extends CardTask:
	var _amount: int
	
	func _init(amount: int):
		_amount = amount
	
	func start() -> void:
		var scratch = ability_instance.card_instance.ability_scratch[ability_instance.ability_index]
		assert(scratch)
		assert(typeof(scratch) == TYPE_DICTIONARY)
		assert("target_ability_instance" in scratch)
		var target_ability_instance := scratch.target_ability_instance as AbilityInstance
		assert(target_ability_instance)
		
		info("amount = %s, target = %s" % [_amount, target_ability_instance])
		
		target_ability_instance.attack_bonus_damage += _amount
		return done()
