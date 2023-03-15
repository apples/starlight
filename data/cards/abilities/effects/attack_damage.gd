@tool
extends CardAbilityEffect

@export var amount: int = 0

func get_attack_damage() -> String:
	return str(amount)

func task() -> CardTask: return Task.new(amount)

class Task extends CardTask:
	var _amount: int
	
	func _init(amount: int):
		_amount = amount
	
	func start() -> void:
		info("amount = %s" % _amount)
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
		
		var damage_amount := _amount + ability_instance.attack_bonus_damage
		
		info("target location: %s" % where)
		info("total damage: %s" % damage_amount)
		
		battle_state.deal_damage(where, damage_amount)
		done()
