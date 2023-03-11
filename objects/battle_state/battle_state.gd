class_name BattleState extends Node

@export var rules: BattleRules = null

@onready var fiber: CardFiber = $CardFiber

var current_turn: ZoneLocation.Side = ZoneLocation.Side.Player

@onready var player := BattleSideState.new(self, $PlayerAgent, ZoneLocation.Side.Player)
@onready var opponent := BattleSideState.new(self, $OpponentAgent, ZoneLocation.Side.Opponent)

var trigger_events: Array[TriggerEvent] = []
var ability_stack: Array[AbilityInstance] = []
var current_priority: ZoneLocation.Side = ZoneLocation.Side.Player
var consecutive_passes: int = 0

var _next_card_instance_id: int = 0:
	get:
		_next_card_instance_id += 1
		return _next_card_instance_id

var all_card_instances: Dictionary = {}

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
	if location.slot < zone.size():
		zone[location.slot] = null

func _set_unit(location: ZoneLocation, unit: UnitState) -> void:
	var state = get_side_state(location.side)
	var zone = state.get_field_zone(location.zone)
	assert(location.slot < zone.size())
	if location.slot < zone.size():
		zone[location.slot] = unit


func summon_unit(card_instance: CardInstance, location: ZoneLocation):
	var unit := get_unit(location)

	if unit != null:
		# TODO: verify requirements
		discard(unit.card_instance)
		unit.card_instance.unit = null
		if card_instance.location.zone == ZoneLocation.Zone.Hand:
			var hand_side_state = get_side_state(card_instance.location.side)
			hand_side_state.remove_from_hand(card_instance)
		unit.card_instance = card_instance
		card_instance.unit = unit
		card_instance.location = location
	else:
		unit = UnitState.new()
		_set_unit(location, unit)
		if card_instance.location.zone == ZoneLocation.Zone.Hand:
			var hand_side_state = get_side_state(card_instance.location.side)
			hand_side_state.remove_from_hand(card_instance)
		unit.card_instance = card_instance
		card_instance.unit = unit
		card_instance.location = location

	print("Summoned %s" % card_instance)

	broadcast_message(MessageTypes.UnitSummoned.new({ location = location }))


func destroy_unit(where: ZoneLocation):
	var card_instance := get_unit(where).card_instance
	_remove_unit(where)
	discard(card_instance)
	card_instance.unit = null

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
	trigger_events.push_front(e)
	#broadcast_message({ type = "event", what = e })

func flush_events() -> void:
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

func perform_ability(controller: ZoneLocation.Side, card_instance: CardInstance, ability: CardAbility) -> AbilityInstance:
	var ability_instance := AbilityInstance.new()
	
	ability_instance.battle_state = self
	ability_instance.controller = controller
	ability_instance.card_ability = ability
	ability_instance.card_instance = card_instance
	ability_instance.source_location = card_instance.location
	ability_instance.task =  TaskActivateAbility.new(card_instance, ability_instance)
	
	ability_stack.push_back(ability_instance)
	fiber.run_task(ability_instance.task)
	
	return ability_instance

func pop_ability():
	assert(ability_stack.size() > 0)
	ability_stack.pop_back()

func deal_damage(where: ZoneLocation, amount: int):
	assert(where)
	var unit := get_unit(where)
	assert(unit)
	unit.damage += amount
	print("deal_damage: to %s (%s / %s)" % [where, unit.damage, unit.card_instance.card.unit_hp])
	if unit.damage >= unit.card_instance.card.unit_hp:
		destroy_unit(where)

func set_tapped(unit: UnitState, is_tapped: bool = true):
	assert(unit)
	unit.is_tapped = is_tapped
	# TODO: broadcast message

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

