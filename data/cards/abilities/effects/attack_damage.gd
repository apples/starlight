extends CardAbilityEffect
class_name AttackDamageEffect

@export var amount: int = 0

func task() -> CardTask: return Task.new(self)

class Task extends CardTask:
	var effect: AttackDamageEffect
	
	func _init(e: AttackDamageEffect):
		self.effect = e
	
	func start() -> void:
		info("amount = %s" % effect.amount)
		var choose := ChooseTargetTask.new()
		choose.allowed_locations = [
			ZoneLocation.new(ZoneLocation.flip(ability_instance.controller), ZoneLocation.Zone.FrontRow, 0),
			ZoneLocation.new(ZoneLocation.flip(ability_instance.controller), ZoneLocation.Zone.FrontRow, 1),
		]
		wait_for(choose, chosen)
	
	func chosen(where: ZoneLocation) -> void:
		if not where:
			info("cancelled by player")
			return done()
		
		var damage_amount := effect.amount + ability_instance.attack_bonus_damage
		
		info("target location: %s" % where)
		info("total damage: %s" % damage_amount)
		
		battle_state.deal_damage(where, damage_amount)
		done()
