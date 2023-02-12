extends CardAbilityEffect
class_name AttackDamageEffect

@export var amount: int = 0

func task() -> CardTask:
	return Task.new(self)

class Task extends CardTask:
	var effect: AttackDamageEffect
	
	func _init(e: AttackDamageEffect):
		self.effect = e
	
	func start():
		pass
