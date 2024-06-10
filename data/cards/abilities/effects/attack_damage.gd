@tool
extends CardAbilityEffect

@export var amount: int = 0
@export var amount_var: String = ""
@export var null_damage: bool = false
@export var plus_damage: bool = false
@export var effect: CardAbilityEffect

func get_attack_damage() -> String:
	if null_damage:
		return "-"
	elif amount_var:
		return "?"
	elif plus_damage:
		return str(amount) + "+"
	return str(amount)

class Task extends CardTask:
	var amount: int
	var null_damage: bool
	var effect: CardAbilityEffect
	
	func start() -> void:
		info("amount = %s" % amount)
		
		if not null_damage:
			var damage_amount := amount + ability_instance.attack_info.bonus_damage
			
			for target in ability_instance.targets:
				info("target location: %s" % target)
				info("total damage: %s" % damage_amount)
				
				var unit := battle_state.unit_get(target)
				if not unit:
					continue
				
				if battle_state.deal_damage(target, damage_amount):
					ability_instance.attack_info.targets_destroyed.append(unit)
		else:
			pass # TODO: apply null hit
		
		if effect == null:
			return done()
		
		var effect_task := effect.create_task(ability_instance)
		
		become(effect_task)
