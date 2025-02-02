@tool
extends CardAbilityEffect

@export var amount: int = 0
@export var amount_var: String = ""
@export var null_damage: bool = false
@export var prior_effect: CardAbilityEffect
@export var after_effect: CardAbilityEffect

func get_attack_damage() -> String:
	if null_damage:
		return "-"
	var damage_str := ""
	if amount_var:
		damage_str = "X"
	else:
		damage_str = str(amount)
	if prior_effect:
		damage_str += prior_effect.get_attack_suffix()
	return damage_str

class Task extends CardTask:
	var amount: int
	var null_damage: bool
	var prior_effect: CardAbilityEffect
	var after_effect: CardAbilityEffect
	
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
				
				var card_instance = unit.card_instance
				
				if battle_state.deal_damage(target, damage_amount):
					ability_instance.attack_info.targets_destroyed.append(card_instance)
		else:
			pass # TODO: apply null hit
		
		if after_effect == null:
			return done()
		
		var after_effect_task := after_effect.create_task(ability_instance)
		
		become(after_effect_task)
