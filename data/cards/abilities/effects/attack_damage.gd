extends CardAbilityEffect
class_name AttackDamageEffect

@export var amount: int = 0

func task() -> CardTask: return Task.new(self)

class Task extends CardTask:
	var effect: AttackDamageEffect
	func _init(e: AttackDamageEffect):
		self.effect = e
	
	func start() -> void:
		print("attack_damage task start (amount = %s)" % effect.amount)
		var choose := ChooseTargetTask.new()
		choose.allowed_locations = [
			ZoneLocation.new(ZoneLocation.flip(ability_instance.controller), ZoneLocation.Zone.FrontRow, 0),
			ZoneLocation.new(ZoneLocation.flip(ability_instance.controller), ZoneLocation.Zone.FrontRow, 1),
		]
		wait_for(choose, chosen)
	
	func chosen(where: ZoneLocation) -> void:
		if not where:
			print("attack_damage cancelled")
			return done()
		print("attack_damage task target location: %s" % where)
		
		var damage_amount := effect.amount + ability_instance.attack_bonus_damage
		
		battle_state.deal_damage(where, effect.amount)
		done()
