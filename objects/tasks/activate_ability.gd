class_name TaskActivateAbility extends CardTask

var card_instance: CardInstance

var activation_event: TriggerEvents.AbilityActivated

func _init(ci: CardInstance, ai: AbilityInstance):
	card_instance = ci
	ability_instance = ai

func start() -> void:
	var ability := ability_instance.get_ability()
	var card := ability_instance.card_instance.card
	
	# Assertions
	
	assert(ability)
	match ability.type:
		CardAbility.CardAbilityType.ACTION,\
		CardAbility.CardAbilityType.ATTACK,\
		CardAbility.CardAbilityType.STARLIGHT:
			pass
		CardAbility.CardAbilityType.TRIGGER:
			assert(ability.trigger)
			assert(ability.trigger.can_activate(battle_state, card_instance, ability_instance.ability_index, card_instance.owner_side))
		CardAbility.CardAbilityType.PASSIVE:
			assert(false)
	
	# Check scratch trigger_event
	
	var scratch := ability_instance.card_instance.ability_scratch[ability_instance.ability_index]
	if "trigger_event" in scratch.for_mechanics:
		ability_instance.trigger_event = scratch.for_mechanics["trigger_event"]
	scratch.for_mechanics.erase("trigger_event")
	
	# Store scratch in easy place for ability scripts to access
	
	ability_instance.scratch = scratch
	
	# Push Trigger Event
	
	activation_event = TriggerEvents.AbilityActivated.new({ ability_instance = ability_instance })
	battle_state.trigger_event_push(activation_event)
	
	# Pay cost
	
	# Discard as part of cost for cards held in hand
	if ability_instance.source_location.zone == ZoneLocation.Zone.Hand:
		battle_state.discard_hand_card(ability_instance.card_instance)
	
	if ability.cost:
		if not ability.cost.can_be_paid(battle_state, card_instance, ability_instance.ability_index, ability_instance.controller):
			assert(false)
			return fail()
		var cost_task := ability.cost.pay_task(ability_instance)
		return wait_for(cost_task, response_window)
	
	# If no cost, go straight to response window
	
	goto(response_window)

func response_window() -> void:
	if ability_instance.get_ability().is_uninterruptable:
		return goto(run_effect)
	
	# Ask for response
	
	var response_task := TaskRequestTriggerResponse.new(ZoneLocation.flip(ability_instance.controller))
	wait_for(response_task, run_effect)

func run_effect() -> void:
	var effect_task := ability_instance.get_ability().effect.create_task(ability_instance)
	wait_for(effect_task, effect_done)

func effect_done() -> void:
	# Mark done
	
	activation_event.is_respondable = false
	
	# Push event
	
	battle_state.trigger_event_push(TriggerEvents.AbilityPerformed.new({
		ability_instance = ability_instance
	}))
	
	# Ask for response
	
	var response_task := TaskRequestTriggerResponse.new(ZoneLocation.flip(ability_instance.controller))
	wait_for(response_task, pop_stack)

func pop_stack() -> void:
	battle_state.ability_pop(ability_instance)
	done()
