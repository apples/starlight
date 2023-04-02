class_name BattleState extends Node

enum TokenType {
	Darkness = 0,
}

@export var rules: BattleRules = null

var current_turn: ZoneLocation.Side = ZoneLocation.Side.Player

var all_card_instances: Dictionary = {}

var trigger_events: Array[TriggerEvent] = []
var ability_stack: Array[AbilityInstance] = []
var passive_effects: Array[PassiveEffect] = []

var _next_card_instance_id: int = 0:
	get:
		_next_card_instance_id += 1
		return _next_card_instance_id

@onready var fiber: CardFiber = $CardFiber

@onready var player := BattleSideState.new(self, $PlayerAgent, ZoneLocation.Side.Player)
@onready var opponent := BattleSideState.new(self, $OpponentAgent, ZoneLocation.Side.Opponent)

# === PUBLIC ===
# ==============

## Creates a new card instance. Usually only called when loading a deck.
func create_card_instance(card: Card, location: ZoneLocation, owner_side: ZoneLocation.Side) -> CardInstance:
	var ci := CardInstance.new(card, _next_card_instance_id, location, owner_side)
	all_card_instances[ci.uid] = ci
	return ci

## Gets the card instance for the given uid. Returns null if uid is 0.
func get_card_instance(uid: int) -> CardInstance:
	if uid == 0:
		return null
	assert(uid in all_card_instances)
	return all_card_instances[uid]

## Declares a winner and immediately halts the gameplay fiber.
func declare_winner(side: ZoneLocation.Side):
	fiber.stop_all_tasks()
	broadcast_message(MessageTypes.DeclareWinner.new({ winner = side }))

## Summons each player's starter units. Only called at the start of the battle.
func summon_starters(side: ZoneLocation.Side):
	var side_state := get_side_state(side)
	
	unit_summon(side_state.starters[0], ZoneLocation.new(side, ZoneLocation.Zone.FrontRow, 0), true)
	unit_summon(side_state.starters[1], ZoneLocation.new(side, ZoneLocation.Zone.FrontRow, 1), true)

## Discards a card from the player's hand.
func discard_hand_card(card_instance: CardInstance):
	assert(card_instance.location.zone == ZoneLocation.Zone.Hand)
	_discard(card_instance)

## Pushes a trigger event to the stack. 
func trigger_event_push(e: TriggerEvent) -> void:
	_info("trigger_event_push: ", e)
	trigger_events.push_front(e)
	
	for effect in passive_effects:
		if effect.is_active():
			effect.get_ability().passive.process_trigger_event(effect, e, self)

## Clears the trigger event stack.
func trigger_events_clear() -> void:
	trigger_events.clear()

## Gets the side state for the given side.
func get_side_state(side: ZoneLocation.Side) -> BattleSideState:
	match (side):
		ZoneLocation.Side.Player: return player
		ZoneLocation.Side.Opponent: return opponent
		_:
			push_error("Invalid side: %s" % side)
			return null

## Initializes the Stella card. Only called at the start of battle.
func init_stella(side: ZoneLocation.Side):
	var state = get_side_state(side)
	for i in range(state.stella.card.abilities.size()):
		_setup_passive(state.stella, i)

## Shuffles the given side's deck.
func shuffle_deck(side: ZoneLocation.Side):
	var state = get_side_state(side)
	state.deck.shuffle()
	broadcast_message(MessageTypes.DeckShuffled.new({ side = side }))

## Draws a card from the given side's deck and places it into their hand.
func draw_card(side: ZoneLocation.Side) -> void:
	var state := get_side_state(side)
	
	if state.deck.size() == 0:
		declare_winner(ZoneLocation.flip(side))
		return
	
	var card_instance := state.deck.get_card(state.deck.size() - 1)
	_move_card(card_instance, ZoneLocation.new(side, ZoneLocation.Zone.Hand))

## Broadcast a message to all agents.
func broadcast_message(m: BattleAgent.Message):
	player.agent.handle_message(m)
	opponent.agent.handle_message(m)

## Sends a message only to the given side's agent.
func send_message_to(side: ZoneLocation.Side, m: BattleAgent.Message):
	var state = get_side_state(side)
	state.agent.handle_message(m)

## Gets the card at the given location. Returns null if the location has no card.
func get_card_at(location: ZoneLocation) -> CardInstance:
	match location.tuple():
		[ZoneLocation.Side.Player, ZoneLocation.Zone.Hand, var idx]:
			return player.hand.get_card(idx)
		[ZoneLocation.Side.Player, ZoneLocation.Zone.BackRow, var idx]:
			return player.back_row[idx].card_instance if player.back_row[idx] else null
		[ZoneLocation.Side.Player, ZoneLocation.Zone.FrontRow, var idx]:
			return player.front_row[idx].card_instance if player.front_row[idx] else null
		[ZoneLocation.Side.Opponent, ZoneLocation.Zone.FrontRow, var idx]:
			return opponent.front_row[idx].card_instance if opponent.front_row[idx] else null
		[ZoneLocation.Side.Opponent, ZoneLocation.Zone.BackRow, var idx]:
			return opponent.back_row[idx].card_instance if opponent.back_row[idx] else null
		[ZoneLocation.Side.Opponent, ZoneLocation.Zone.Hand, var idx]:
			return opponent.hand.get_card(idx)
		[ZoneLocation.Side.Player, ZoneLocation.Zone.Stella, _]:
			return player.stella
		[ZoneLocation.Side.Opponent, ZoneLocation.Zone.Stella, _]:
			return opponent.stella
		_:
			push_warning("Not implemented")
	return null

## Deals damage to the specified location. Assumes a unit exists at that location.
## If the unit's damage exceeds its unit_hp, the unit is destroyed.
## Returns whether the unit was destroyed.
func deal_damage(where: ZoneLocation, amount: int) -> bool:
	assert(where)
	var unit := unit_get(where)
	assert(unit)
	assert(unit.damage < unit.card_instance.card.unit_hp)
	var actual_amount: int = min(amount, unit.card_instance.card.unit_hp - unit.damage)
	unit.damage += actual_amount
	_info("deal_damage: to %s (%s / %s)" % [where, unit.damage, unit.card_instance.card.unit_hp])
	broadcast_message(MessageTypes.UnitDamaged.new({
		card_uid = unit.card_instance.uid,
		location = unit.card_instance.location,
		amount = amount,
	}))
	if unit.damage >= unit.card_instance.card.unit_hp:
		unit_destroy(where)
		return true
	return false

## Sets a unit to be tapped or untapped, depending on is_tapped.
## If the unit state does not change, no trigger events are emitted.
func unit_set_tapped(unit: UnitState, is_tapped: bool = true, for_mana: bool = false):
	assert(unit)
	if unit.is_tapped == is_tapped:
		return
	
	unit.is_tapped = is_tapped
	
	broadcast_message(MessageTypes.UnitTappedChanged.new({
		location = unit.card_instance.location,
		is_tapped = is_tapped,
	}))
	
	if is_tapped:
		trigger_event_push(TriggerEvents.UnitTapped.new({
			unit = unit,
			for_mana = for_mana,
		}))
	else:
		trigger_event_push(TriggerEvents.UnitUntapped.new({
			unit = unit,
		}))
	

## Gets a list of untapped units on the given side, excluding cards with the specified UIDs. 
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

## Grants the specified tokens to the given side. Can be negative.
## Will not lower the side's token amount below zero.
func gain_tokens(who: ZoneLocation.Side, kind: TokenType, amount: int):
	var side_state := get_side_state(who)
	side_state.gain_tokens(kind, amount)
	
	trigger_event_push(TriggerEvents.GainedTokens.new({
		side = who,
		kind = kind,
		amount_gained = amount,
		total_amount = side_state.get_token_amount(kind),
	}))

## Grants the given side a specified amount of Stella Charge. Can be negative.
## Will not lower the side's stella charges below zero. 
func stella_charge(who: ZoneLocation.Side, amount: int):
	var side_state := get_side_state(who)
	var actual_amount: int = max(amount, -side_state.stella_charge)
	side_state.stella_charge += actual_amount
	
	trigger_event_push(TriggerEvents.StellaCharge.new({
		side = who,
		amount_gained = actual_amount,
		total_amount = side_state.stella_charge,
	}))

## Pushes the ability onto the stack and starts its task. Does not check requirements.
func ability_perform(controller: ZoneLocation.Side, card_instance: CardInstance, ability_index: int) -> AbilityInstance:
	var ability_instance := AbilityInstance.new(self, controller, card_instance, ability_index)
	
	ability_instance.source_location = card_instance.location
	ability_instance.task =  TaskActivateAbility.new(card_instance, ability_instance)
	
	match card_instance.card.abilities[ability_index].type:
		CardAbility.CardAbilityType.ATTACK:
			ability_instance.attack_info = AbilityInstance.AttackInfo.new()
	
	ability_stack.push_back(ability_instance)
	fiber.run_task(ability_instance.task)
	
	if card_instance.location.zone == ZoneLocation.Zone.Hand:
		card_reveal(card_instance)
	
	return ability_instance

## Pops the given ability from the stack. Assumes the given ability is the one on top of the stack.
func ability_pop(ability_instance: AbilityInstance):
	assert(ability_stack.size() > 0)
	assert(ability_stack.back() == ability_instance)
	ability_stack.pop_back()

## Determines if the specified location can be targeted by the card ability.
func ability_can_target_location(card_instance: CardInstance, ability_index: int, target_location: ZoneLocation) -> bool:
	assert(ability_index >= 0)
	assert(ability_index < card_instance.card.abilities.size())
	
	var ability := card_instance.card.abilities[ability_index]
	assert(ability)
	
	match ability.type:
		CardAbility.CardAbilityType.ATTACK:
			if unit_get(target_location) == null:
				return false
	
	return true

## Determines whether the specified ability can currently be activated by the specified user
func ability_can_be_activated_by(card_instance: CardInstance, ability_index: int, side: ZoneLocation.Side) -> bool:
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

## Temporarily reveals the card to both players.
func card_reveal(card_instance: CardInstance):
	broadcast_message(MessageTypes.CardRevealed.new({ uid = card_instance.uid }))

## Returns the unit at the given location, or null if there is no unit.
func unit_get(location: ZoneLocation) -> UnitState:
	assert(location.zone in [ZoneLocation.Zone.FrontRow, ZoneLocation.Zone.BackRow])
	assert(location.slot >= 0 && location.slot < (2 if location.zone == ZoneLocation.Zone.FrontRow else 4))
	var state = get_side_state(location.side)
	var zone = state.get_field_zone(location.zone)
	return zone[location.slot] if location.slot < zone.size() else null

## Summons a unit to the given location. If there is already a unit, asencds instead.
## Assumes the requirements are already checked.
func unit_summon(card_instance: CardInstance, location: ZoneLocation, suppress_trigger: bool = false):
	var unit := unit_get(location)
	
	var is_ascend := unit != null
	
	if is_ascend:
		# Ascend exisitng unit
		# TODO: verify requirements
		var prev_card_instance = unit.card_instance
		
		if not suppress_trigger:
			trigger_event_push(TriggerEvents.UnitAscended.new({
				unit = unit,
				from = prev_card_instance,
				to = card_instance,
			}))
		
		# Tear down passives
		for i in range(prev_card_instance.card.abilities.size()):
			_teardown_passive(prev_card_instance, i)
		
		_discard(prev_card_instance)
	else:
		# Summon new unit
		unit = UnitState.new()
		_set_unit(location, unit)
	
	_move_card(card_instance, location)
	
	# Set up passives
	for i in range(card_instance.card.abilities.size()):
		_setup_passive(card_instance, i)
	
	if not suppress_trigger and not is_ascend:
		trigger_event_push(TriggerEvents.UnitSummoned.new({
			unit = unit,
			to = card_instance,
		}))
	
	_info("Summoned %s" % card_instance)
	
	broadcast_message(MessageTypes.UnitSummoned.new({ location = location }))

## Destroys the unit at the given location. Assumes the unit exists.
func unit_destroy(where: ZoneLocation):
	var unit := unit_get(where)
	assert(unit)
	
	var card_instance := unit.card_instance
	
	trigger_event_push(TriggerEvents.UnitDestroyed.new({
		unit = unit,
		was = card_instance,
	}))
	
	# Tear down passives
	for i in range(card_instance.card.abilities.size()):
		_teardown_passive(card_instance, i)
	
	_discard(card_instance)
	
	_remove_unit(where)

## Discards the unit at the given location, without destroying it. Assumes the unit exists.
func unit_discard(where: ZoneLocation):
	var unit := unit_get(where)
	assert(unit)
	
	var card_instance := unit.card_instance
	
	trigger_event_push(TriggerEvents.UnitDiscarded.new({
		unit = unit,
		was = card_instance,
	}))
	
	# Tear down passives
	for i in range(card_instance.card.abilities.size()):
		_teardown_passive(card_instance, i)
	
	_discard(card_instance)
	
	_remove_unit(where)

## Returns a list of possible summon locations for the given card instance.
func unit_get_summon_locations(card_instance: CardInstance) -> Array[ZoneLocation]:
	var side := card_instance.owner_side
	var side_state := get_side_state(side)
	
	var results: Array[ZoneLocation] = []
	
	var process_row := func (row: Array[UnitState], zone: ZoneLocation.Zone):
		for i in range(row.size()):
			if card_instance.card.level == 0 and row[i] == null:
				results.append(ZoneLocation.new(side, zone, i))
			if card_instance.card.level > 0 and row[i] != null:
				if row[i].card_instance.card.level == card_instance.card.level + 1:
					results.append(ZoneLocation.new(side, zone, i))
	
	process_row.call(side_state.front_row, ZoneLocation.Zone.FrontRow)
	process_row.call(side_state.back_row, ZoneLocation.Zone.BackRow)
	
	return results

## Returns a dictionary of available activated abilities for the given side.
## The dictionary is formatted as follows:
##
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
			if ability_can_be_activated_by(card_instance, i, side):
				ability_indices.append(i)
		if ability_indices.size() > 0:
			return ability_indices
		return null
	
	# Stella
	var stella = check_card.call(side_state.stella)
	if stella:
		results[side_state.stella.uid] = stella
	
	var process_cards = func (cards: CardZoneArray):
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

## Returns an array of summonable (from hand) cards for the given side.
func get_available_summons(side: ZoneLocation.Side) -> Array[int]:
	var side_state := get_side_state(side)
	
	var results: Array[int] = []
	
	for card_instance in side_state.hand:
		if card_instance.card.kind != Card.Kind.UNIT:
			continue
		if unit_get_summon_locations(card_instance).size() == 0:
			continue
		results.append(card_instance.uid)
	
	return results

# === PRIVATE ===
# ===============

func _info(a="", b="", c=""):
	print("[BattleState] ", a, b, c)

func _set_unit(location: ZoneLocation, unit: UnitState) -> void:
	var state = get_side_state(location.side)
	var zone = state.get_field_zone(location.zone)
	assert(location.slot < zone.size())
	assert(zone[location.slot] == null)
	zone[location.slot] = unit
	unit.exists = true

func _remove_unit(location: ZoneLocation) -> void:
	var state = get_side_state(location.side)
	var zone = state.get_field_zone(location.zone)
	assert(location.slot < zone.size())
	assert(zone[location.slot] != null)
	zone[location.slot].exists = false
	zone[location.slot] = null
	
	broadcast_message(MessageTypes.UnitRemoved.new({
		location = location,
	}))
	

func _discard(card_instance: CardInstance):
	_move_card(card_instance, ZoneLocation.new(card_instance.owner_side, ZoneLocation.Zone.Discard))
	broadcast_message(MessageTypes.AddDiscard.new({ what = card_instance }))

func _move_card(card_instance: CardInstance, new_location: ZoneLocation):
	if card_instance.location.equals(new_location):
		return
	
	var from := card_instance.location.duplicate()
	
	_float_card(card_instance)
	
	_drop_card(card_instance, new_location)
	
	var to := card_instance.location.duplicate()
	
	var owner_side := card_instance.owner_side
	
	var is_hidden = from.is_hidden() and to.is_hidden()
	
	send_message_to(owner_side, MessageTypes.CardMoved.new({
		uid = card_instance.uid,
		from = from,
		to = to,
	}))
	send_message_to(ZoneLocation.flip(owner_side), MessageTypes.CardMoved.new({
		uid = 0 if is_hidden else card_instance.uid,
		from = from,
		to = to,
	}))


func _float_card(card_instance: CardInstance):
	var side := card_instance.location.side
	var side_state := get_side_state(side)
	match card_instance.location.zone:
		ZoneLocation.Zone.FrontRow:
			var unit := side_state.front_row[card_instance.location.slot]
			assert(unit)
			unit.card_instance = null
			card_instance.unit = null
			card_instance.location = ZoneLocation.new(side, ZoneLocation.Zone.Floating)
		ZoneLocation.Zone.BackRow:
			var unit := side_state.back_row[card_instance.location.slot]
			assert(unit)
			unit.card_instance = null
			card_instance.unit = null
			card_instance.location = ZoneLocation.new(side, ZoneLocation.Zone.Floating)
		ZoneLocation.Zone.Hand:
			side_state.hand.remove_card(card_instance)
		ZoneLocation.Zone.Deck:
			side_state.deck.remove_card(card_instance)
		ZoneLocation.Zone.Discard:
			side_state.discard.remove_card(card_instance)
		ZoneLocation.Zone.Starlight:
			assert(false, "not implemented")
		ZoneLocation.Zone.Banish:
			assert(false, "Cannot float banished card")
		ZoneLocation.Zone.Floating:
			pass
		ZoneLocation.Zone.Stella:
			assert(false, "Cannot float Stella card")

func _drop_card(card_instance: CardInstance, new_location: ZoneLocation):
	assert(card_instance.location.zone == ZoneLocation.Zone.Floating)
	assert(new_location.zone != ZoneLocation.Zone.Floating)
	
	var side := new_location.side
	var side_state := get_side_state(side)
	match new_location.zone:
		ZoneLocation.Zone.FrontRow:
			var unit := side_state.front_row[new_location.slot]
			assert(unit)
			assert(unit.card_instance == null)
			card_instance.location = new_location
			unit.card_instance = card_instance
			card_instance.unit = unit
		ZoneLocation.Zone.BackRow:
			var unit := side_state.back_row[new_location.slot]
			assert(unit)
			assert(unit.card_instance == null)
			card_instance.location = new_location
			unit.card_instance = card_instance
			card_instance.unit = unit
		ZoneLocation.Zone.Hand:
			side_state.hand.add_card(card_instance)
		ZoneLocation.Zone.Deck:
			side_state.deck.add_card(card_instance)
		ZoneLocation.Zone.Discard:
			side_state.discard.add_card(card_instance)
		ZoneLocation.Zone.Starlight:
			assert(false, "not implemented")
		ZoneLocation.Zone.Banish:
			side_state.banish.add_card(card_instance)
		ZoneLocation.Zone.Floating:
			assert(false, "Cannot drop card to floating")
		ZoneLocation.Zone.Stella:
			assert(side_state.stella == null)
			card_instance.location = new_location
			side_state.stella = card_instance

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
