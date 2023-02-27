extends CardAbilityEffect
class_name AttackDamageEffect

@export var amount: int = 0

func task() -> CardTask: return Task.new(self)

class Task extends CardTask:
	var effect: AttackDamageEffect
	func _init(e: AttackDamageEffect):
		self.effect = e
	
	func start():
		print("attack_damage task start (amount = %s)" % effect.amount)
		var choose := ChooseTargetTask.new()
		choose.allowed_locations = [
			ZoneLocation.new(ZoneLocation.flip(source_side), ZoneLocation.Zone.FrontRow, 0),
			ZoneLocation.new(ZoneLocation.flip(source_side), ZoneLocation.Zone.FrontRow, 1),
		]
		wait_for(choose, chosen)
	
	func chosen(where: ZoneLocation):
		print(where)
		battle_state.deal_damage(where, effect.amount)
		done()
