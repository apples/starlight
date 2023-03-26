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


func summon_unit(card_instance: CardInstance, location: ZoneLocation, suppress_trigger: bool = false):
	var unit := get_unit(location)

	if unit != null:
		# Ascend exisitng unit
		# TODO: verify requirements
		var prev_card_instance = unit.card_instance
		
		# Tear down passives
		for i in range(prev_card_instance.card.abilities.size()):
			_teardown_passive(prev_card_instance, i)
		
		_discard(prev_card_instance)
		prev_card_instance.unit = null
		if card_instance.location.zone == ZoneLocation.Zone.Hand:
			var hand_side_state = get_side_state(card_instance.location.side)
			hand_side_state.remove_from_hand(card_instance)
		unit.card_instance = card_instance
		card_instance.unit = unit
		card_instance.location = location
		
		# Set up passives
		for i in range(card_instance.card.abilities.size()):
			_setup_passive(card_instance, i)
		
		if not suppress_trigger:
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
		for i in range(card_instance.card.abilities.size()):
			_setup_passive(card_instance, i)
		
		if not suppress_trigger:
			push_event(TriggerEvents.UnitSummoned.new({
				unit = unit,
				to = card_instance,
			}))
	
	info("Summoned %s" % card_instance)
	
	broadcast_message(MessageTypes.UnitSummoned.new({ location = location }))

func destroy_unit(where: ZoneLocation):
	var unit := get_unit(where)
	var card_instance := unit.card_instance
	
	push_event(TriggerEvents.UnitDestroyed.new({
		unit = unit,
		was = card_instance,
	}))
	
	# Tear down passives
	for i in range(card_instance.card.abilities.size()):
		_teardown_passive(card_instance, i)
	
	card_instance.unit = null
	
	_remove_unit(where)
	_discard(card_instance)

func discard_unit(where: ZoneLocation):
	var unit := get_unit(where)
	var card_instance := unit.card_instance
	
	push_event(TriggerEvents.UnitDiscarded.new({
		unit = unit,
		was = card_instance,
	}))
	
	# Tear down passives
	for i in range(card_instance.card.abilities.size()):
		_teardown_passive(card_instance, i)
	
	card_instance.unit = null
	
	_remove_unit(where)
	_discard(card_instance)


func _teardown_passive(card_instance: CardInstance, ability_index: int):
	var ability := card_instance.card.abilities[ability_index]
	
	assert(ability != null)
	if ability.type != CardAbility.CardAbilityType.PASSIVE:
		return
	
	for i in range(passive_effects.size(), 0, -1):
		var effect := passive_effects[i - 1]
		if effect.card_instance.is_same(card_instance) and effect.ability_index == ability_index:
			passive_effects.remove_at(i - 1)
	

func _setup_passive(card_instance: CardInstance, ability_index: int):
	assert(ability_index >= 0)
	assert(ability_index < card_instance.card.abilities.size())
	
	var ability := card_instance.card.abilities[ability_index]
	
	assert(ability != null)
	if ability == null or ability.type != CardAbility.CardAbilityType.PASSIVE:
		return
	
	assert(ability.passive)
	
	var effect := PassiveEffect.new()
	passive_effects.append(effect)
	
	effect.battle_state = self
	effect.controller = card_instance.owner_side
	effect.card_instance = card_instance
	effect.ability_index = ability_index
	effect.source_location = card_instance.location



func summon_starters(side: ZoneLocation.Side):
	var side_state := get_side_state(side)
	
	summon_unit(side_state.starters[0], ZoneLocation.new(side, ZoneLocation.Zone.FrontRow, 0), true)
	summon_unit(side_state.starters[1], ZoneLocation.new(side, ZoneLocation.Zone.FrontRow, 1), true)

func _discard(card_instance: CardInstance):
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
			effect.get_ability().passive.process_trigger_event(effect, e, self)

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

func init_stella(side: ZoneLocation.Side):
	var state = get_side_state(side)
	for i in range(state.stella.card.abilities.size()):
		_setup_passive(state.stella, i)

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
		[ZoneLocation.Side.Player, ZoneLocation.Zone.Stella, _]:
			return player.stella
		[ZoneLocation.Side.Opponent, ZoneLocation.Zone.Stella, _]:
			return opponent.stella
		_:
			push_warning("Not implemented")
	return null

func perform_ability(controller: ZoneLocation.Side, card_instance: CardInstance, ability_index: int) -> AbilityInstance:
	var ability_instance := AbilityInstance.new(self, controller, card_instance, ability_index)
	
	ability_instance.source_location = card_instance.location
	ability_instance.task =  TaskActivateAbility.new(card_instance, ability_instance)
	
	match card_instance.card.abilities[ability_index].type:
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
	info("deal_damage: to %s (%s / %s)" % [where, unit.damage, unit.card_instance.card.unit_hp])
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

func stella_charge(who: ZoneLocation.Side, amount: int):
	var side_state := get_side_state(who)
	var actual_amount: int = max(amount, -side_state.stella_charge)
	side_state.stella_charge += actual_amount
	
	push_event(TriggerEvents.StellaCharge.new({
		side = who,
		amount_gained = actual_amount,
		total_amount = side_state.stella_charge,
	}))


func can_be_targeted(target_location: ZoneLocation, card_instance: CardInstance, ability_index: int) -> bool:
	assert(ability_index >= 0)
	assert(ability_index < card_instance.card.abilities.size())
	
	var ability := card_instance.card.abilities[ability_index]
	assert(ability)
	
	match ability.type:
		CardAbility.CardAbilityType.ATTACK:
			if get_unit(target_location) == null:
				return false
	
	return true

## Returns a dictionary of available activated abilities for the given side.
## The dictionary is formatted as follows:
## [code]
## {
##     [uid: int]: Array[ability_index: int]
## }
## [/code]
func get_available_activations(side: ZoneLocation.Side) -> Dictionary:
	var side_state := get_side_state(side)
	
	var results := {}
	
	var check_card := func (card_instance: CardInstance):
		var ability_indices: Array[int] = []
		for i in range(card_instance.card.abilities.size()):
			if can_be_activated(card_instance, i, side):
				ability_indices.append(i)
		if ability_indices.size() > 0:
			return ability_indices
		return null
	
	# Stella
	var stella = check_card.call(side_state.stella)
	if stella:
		results[side_state.stella.uid] = stella
	
	var process_cards = func (cards: Array[CardInstance]):
		for ci in cards:
			if not ci:
				continue
			var ab = check_card.call(ci)
			if ab:
				results[ci.uid] = ab
	
	var process_units = func (units: Array[UnitState]):
		for u in units:
			if not u:
				continue
			var ci = u.card_instance
			var ab = check_card.call(ci)
			if ab:
				results[ci.uid] = ab
	
	process_units.call(side_state.front_row)
	process_units.call(side_state.back_row)
	process_cards.call(side_state.hand)
	
	return results

## Determines whether the specified ability can currently be activated by the specified user
func can_be_activated(card_instance: CardInstance, ability_index: int, side: ZoneLocation.Side) -> bool:
	assert(card_instance)
	var ability := card_instance.card.abilities[ability_index]
	assert(ability)
	
	# Unit cards must be on the field
	if card_instance.card.kind == Card.Kind.UNIT and card_instance.unit == null:
		return false
	
	match ability.type:
		CardAbility.CardAbilityType.ACTION,\
		CardAbility.CardAbilityType.ATTACK:
			for cond in ability.conditions:
				if not cond.is_met(self, card_instance, ability_index):
					return false
			if ability.cost and not ability.cost.can_be_paid(self, card_instance, ability_index, side):
				return false
		_:
			return false
	
	return true

## Returns an array of summonable (from hand) cards for the given side.
func get_available_summons(side: ZoneLocation.Side) -> Array[int]:
	var side_state := get_side_state(side)
	
	var results: Array[int] = []
	
	for card_instance in side_state.hand:
		if card_instance.card.kind != Card.Kind.UNIT:
			continue
		results.append(card_instance.uid)
	
	return results
