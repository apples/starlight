class_name BattleState extends Node

@export var rules: BattleRules = null

@onready var fiber: CardFiber = $CardFiber

var current_turn: ZoneLocation.Side = ZoneLocation.Side.Player

@onready var player := BattleSideState.new(self, $PlayerAgent, ZoneLocation.Side.Player)
@onready var opponent := BattleSideState.new(self, $OpponentAgent, ZoneLocation.Side.Opponent)

var trigger_events: Array[TriggerEvent] = []
var ability_stack: Array[AbilityInstance] = []
var passive_effects: Array[PassiveEffect] = []

var _next_card_instance_id: int = 0:
	get:
		_next_card_instance_id += 1
		return _next_card_instance_id

var all_card_instances: Dictionary = {}

enum TokenType {
	Darkness = 0,
}


func info(a="", b="", c=""):
	TokenType.find_key(1)
	print("[BattleState] ", a, b, c)

func create_card_instance(card: Card, location: ZoneLocation, owner_side: ZoneLocation.Side) -> CardInstance:
	var ci := CardInstance.new(card, _next_card_instance_id, location, owner_side)
	all_card_instances[ci.uid] = ci
	return ci

func declare_winner(side: ZoneLocation.Side):
	fiber.stop_all_tasks()
	broadcast_message(MessageTypes.DeclareWinner.new({ winner = side }))

func get_unit(location: ZoneLocation) -> UnitState:
	assert(location.zone in [ZoneLocation.Zone.FrontRow, ZoneLocation.Zone.BackRow])
	assert(location.slot >= 0 && location.slot < (2 if location.zone == ZoneLocation.Zone.FrontRow else 4))
	var state = get_side_state(location.side)
	var zone = state.get_field_zone(location.zone)
	return zone[location.slot] if location.slot < zone.size() else null

func _remove_unit(location: ZoneLocation) -> void:
	var state = get_side_state(location.side)
	var zone = state.get_field_zone(location.zone)
	assert(location.slot < zone.size())
	assert(zone[location.slot] != null)
	zone[location.slot].exists = false
	zone[location.slot] = null

func _set_unit(location: ZoneLocation, unit: UnitState) -> void:
	var state = get_side_state(location.side)
	var zone = state.get_field_zone(location.zone)
	assert(location.slot < zone.size())
	assert(zone[location.slot] == null)
	zone[location.slot] = unit
	unit.exists = true


func summon_unit(card_instance: CardInstance, location: ZoneLocation):
	var unit := get_unit(location)

	if unit != null:
		# Ascend exisitng unit
		# TODO: verify requirements
		var prev_card_instance = unit.card_instance
		
		# Tear down passives
		_teardown_passive(prev_card_instance, 0)
		_teardown_passive(prev_card_instance, 1)
		
		discard(prev_card_instance)
		prev_card_instance.unit = null
		if card_instance.location.zone == ZoneLocation.Zone.Hand:
			var hand_side_state = get_side_state(card_instance.location.side)
			hand_side_state.remove_from_hand(card_instance)
		unit.card_instance = card_instance
		card_instance.unit = unit
		card_instance.location = location
		
		# Set up passives
		_setup_passive(card_instance, 0)
		_setup_passive(card_instance, 1)
		
		push_event(TriggerEvents.UnitAscended.new({
			unit = unit,
			from = prev_card_instance,
			to = card_instance,
		}))
	else:
		# Summon new unit
		unit = UnitState.new()
		_set_unit(location, unit)
		if card_instance.location.zone == ZoneLocation.Zone.Hand:
			var hand_side_state = get_side_state(card_instance.location.side)
			hand_side_state.remove_from_hand(card_instance)
		unit.card_instance = card_instance
		card_instance.unit = unit
		card_instance.location = location
		
		# Set up passives
		_setup_passive(card_instance, 0)
		_setup_passive(card_instance, 1)
		
		push_event(TriggerEvents.UnitSummoned.new({
			unit = unit,
			to = card_instance,
		}))

	print("Summoned %s" % card_instance)

	broadcast_message(MessageTypes.UnitSummoned.new({ location = location }))

func destroy_unit(where: ZoneLocation):
	var unit := get_unit(where)
	var card_instance := unit.card_instance
	
	push_event(TriggerEvents.UnitDestroyed.new({
		unit = unit,
		was = card_instance,
	}))
	
	# Tear down passives
	_teardown_passive(card_instance, 0)
	_teardown_passive(card_instance, 1)
	
	card_instance.unit = null
	
	_remove_unit(where)
	discard(card_instance)
	

func _teardown_passive(card_instance: CardInstance, ability_index: int):
	var ability := card_instance.card.get_ability(ability_index)
	
	if ability == null or ability.type != CardAbility.CardAbilityType.PASSIVE:
		return
	
	for i in range(passive_effects.size(), 0, -1):
		var effect := passive_effects[i - 1]
		if effect.unit.card_instance.is_same(card_instance) and effect.ability_index == ability_index:
			passive_effects.remove_at(i - 1)
	

func _setup_passive(card_instance: CardInstance, ability_index: int):
	var ability := card_instance.card.get_ability(ability_index)
	
	if ability == null or ability.type != CardAbility.CardAbilityType.PASSIVE:
		return
	
	assert(ability.passive)
	
	var effect := PassiveEffect.new()
	passive_effects.append(effect)
	
	effect.battle_state = self
	effect.controller = card_instance.owner_side
	effect.unit = card_instance.unit
	effect.ability_index = ability_index
	effect.source_location = card_instance.location



func summon_starters(side: ZoneLocation.Side):
	var side_state := get_side_state(side)
	
	summon_unit(side_state.starters[0], ZoneLocation.new(side, ZoneLocation.Zone.FrontRow, 0))
	summon_unit(side_state.starters[1], ZoneLocation.new(side, ZoneLocation.Zone.FrontRow, 1))

func discard(card_instance: CardInstance):
	var side := card_instance.owner_side
	var side_state := get_side_state(side)
	card_instance.location = ZoneLocation.new(side, ZoneLocation.Zone.Discard, side_state.discard.size())
	side_state.discard.append(card_instance)
	broadcast_message(MessageTypes.AddDiscard.new({ what = card_instance }))

func push_event(e: TriggerEvent) -> void:
	info("push_event: ", e)
	trigger_events.push_front(e)
	
	for effect in passive_effects:
		if effect.is_active():
			var task := effect.get_ability().passive.task()
			task.passive_effect = effect
			task.trigger_event = e
			fiber.run_task(task)

func clear_events() -> void:
	trigger_events.clear()

func get_side_state(side: ZoneLocation.Side) -> BattleSideState:
	match (side):
		ZoneLocation.Side.Player: return player
		ZoneLocation.Side.Opponent: return opponent
		_:
			push_error("Invalid side: %s" % side)
			return null

func remove_from_hand(side: ZoneLocation.Side, handIndex: int, card: Card):
	var sideState = get_side_state(side)
	if (sideState.hand[handIndex] == card):
		sideState.hand.RemoveAt(handIndex)
		return

	var success = sideState.hand.Remove(card)

	if (!success):
		push_error("Card not found in hand (side = %s, handIndex = %s, card = %s)." % [side, handIndex, card])


func shuffle_deck(side: ZoneLocation.Side):
	var state = get_side_state(side)
	state.deck.shuffle()
	broadcast_message(MessageTypes.DeckShuffled.new({ side = side }))

func draw_card(side: ZoneLocation.Side) -> void:
	var state := get_side_state(side)

	if state.deck.size() == 0:
		declare_winner(ZoneLocation.flip(side))
		return

	var card_instance := state.deck[state.deck.size() - 1]
	state.deck.remove_at(state.deck.size() - 1)
	state.hand.append(card_instance)
	card_instance.location = ZoneLocation.new(side, ZoneLocation.Zone.Hand, state.hand.size() - 1)

	send_message_to(side, MessageTypes.CardDrawn.new({ side = side, card_instance = card_instance }))
	send_message_to(ZoneLocation.flip(side), MessageTypes.CardDrawn.new({ side = side, card_instance = null }))


func broadcast_message(m: BattleAgent.Message):
	player.agent.handle_message(m)
	opponent.agent.handle_message(m)


func send_message_to(side: ZoneLocation.Side, m: BattleAgent.Message):
	var state = get_side_state(side)
	state.agent.handle_message(m)

func get_card_at(location: ZoneLocation) -> CardInstance:
	match location.tuple():
		[ZoneLocation.Side.Player, ZoneLocation.Zone.Hand, var idx]:
			return player.hand[idx]
		[ZoneLocation.Side.Player, ZoneLocation.Zone.BackRow, var idx]:
			return player.back_row[idx].card_instance if player.back_row[idx] else null
		[ZoneLocation.Side.Player, ZoneLocation.Zone.FrontRow, var idx]:
			return player.front_row[idx].card_instance if player.front_row[idx] else null
		[ZoneLocation.Side.Opponent, ZoneLocation.Zone.FrontRow, var idx]:
			return opponent.front_row[idx].card_instance if opponent.front_row[idx] else null
		[ZoneLocation.Side.Opponent, ZoneLocation.Zone.BackRow, var idx]:
			return opponent.back_row[idx].card_instance if opponent.back_row[idx] else null
		[ZoneLocation.Side.Opponent, ZoneLocation.Zone.Hand, var idx]:
			return opponent.hand[idx]
		_:
			push_warning("Not implemented")
	return null

func perform_ability(controller: ZoneLocation.Side, card_instance: CardInstance, ability_index: int) -> AbilityInstance:
	var ability_instance := AbilityInstance.new(self, controller, card_instance, ability_index)
	
	ability_instance.source_location = card_instance.location
	ability_instance.task =  TaskActivateAbility.new(card_instance, ability_instance)
	
	match card_instance.card.get_ability(ability_index).type:
		CardAbility.CardAbilityType.ATTACK:
			ability_instance.attack_info = AbilityInstance.AttackInfo.new()
	
	ability_stack.push_back(ability_instance)
	fiber.run_task(ability_instance.task)
	
	return ability_instance

func pop_ability():
	assert(ability_stack.size() > 0)
	ability_stack.pop_back()

func deal_damage(where: ZoneLocation, amount: int) -> bool:
	assert(where)
	var unit := get_unit(where)
	assert(unit)
	unit.damage += amount
	print("deal_damage: to %s (%s / %s)" % [where, unit.damage, unit.card_instance.card.unit_hp])
	broadcast_message(MessageTypes.UnitDamaged.new({
		card_uid = unit.card_instance.uid,
		location = unit.card_instance.location,
		amount = amount,
	}))
	if unit.damage >= unit.card_instance.card.unit_hp:
		destroy_unit(where)
		return true
	return false

func set_tapped(unit: UnitState, is_tapped: bool = true, for_mana: bool = false):
	assert(unit)
	if unit.is_tapped == is_tapped:
		return
	
	unit.is_tapped = is_tapped
	
	if is_tapped:
		push_event(TriggerEvents.UnitTapped.new({
			unit = unit,
			for_mana = for_mana,
		}))
	else:
		push_event(TriggerEvents.UnitUntapped.new({
			unit = unit,
		}))

func get_tappable_units(controller: ZoneLocation.Side, exclude_uids: Array[int] = []) -> Array[ZoneLocation]:
	var side_state := get_side_state(controller)
	var all_units := side_state.get_all_units()
	
	# Build list of tappable units
	var tappable: Array[ZoneLocation] = []
	
	# Mana is paid by tapping units - check tappable units
	for unit in all_units:
		if unit.card_instance.uid in exclude_uids:
			continue
		
		if not unit.is_tapped:
			tappable.append(unit.card_instance.location)
	
	return tappable

func gain_tokens(who: ZoneLocation.Side, kind: TokenType, amount: int):
	var side_state := get_side_state(who)
	side_state.gain_tokens(kind, amount)
	
	push_event(TriggerEvents.GainedTokens.new({
		side = who,
		kind = kind,
		amount_gained = amount,
		total_amount = side_state.get_token_amount(kind),
	}))


func can_be_targeted(target_location: ZoneLocation, card_instance: CardInstance, ability_index: int) -> bool:
	var ability := card_instance.card.get_ability(ability_index)
	
	match ability.type:
		CardAbility.CardAbilityType.ATTACK:
			if get_unit(target_location) == null:
				return false
	
	return true
