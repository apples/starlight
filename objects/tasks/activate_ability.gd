class_name TaskActivateAbility extends CardTask

var card_instance: CardInstance


func _init(ci: CardInstance, ai: AbilityInstance):
	card_instance = ci
	ability_instance = ai

func start() -> void:
	var ability := ability_instance.card_ability
	var card := ability_instance.card_instance.card
	
	assert(card.ability1 == ability or card.ability2 == ability)
	assert(ability_instance.controller == battle_state.current_priority)
	match ability.type:
		CardAbility.CardAbilityType.ACTION,\
		CardAbility.CardAbilityType.ATTACK,\
		CardAbility.CardAbilityType.STARLIGHT:
			pass
		CardAbility.CardAbilityType.TRIGGER:
			assert(ability.trigger.can_activate(battle_state, card_instance.owner_side))
		CardAbility.CardAbilityType.PASSIVE:
			assert(false)
	
	# Pay cost
	
	if ability.cost:
		if not ability.cost.can_be_paid(battle_state, card_instance, ability_instance.controller):
			assert(false)
			return fail()
		var cost_task := ability.cost.pay_task()
		cost_task.ability_instance = ability_instance
		return wait_for(cost_task, response_window)
	
	# If no cost, go straight to response window
	goto(response_window)

func response_window() -> void:
	
	battle_state.push_event(TriggerEvents.AbilityActivated.new({
		ability_instance = ability_instance
	}))
	
	var response_task := TaskRequestTriggerResponse.new(ZoneLocation.flip(ability_instance.controller))
	wait_for(response_task, run_effect)

func run_effect() -> void:
	var effect_task := ability_instance.card_ability.effect.task()
	effect_task.ability_instance = ability_instance
	wait_for(effect_task, pop_stack)

func pop_stack() -> void:
	assert(battle_state.ability_stack.back() == ability_instance)
	battle_state.pop_ability()
	done()
