class_name BattleState extends Node

@export var rules: BattleRules = null

@onready var fiber: CardFiber = $CardFiber

var current_turn: ZoneLocation.Side = ZoneLocation.Side.Player

@onready var player := BattleSideState.new(self, $PlayerAgent, ZoneLocation.Side.Player)
@onready var opponent := BattleSideState.new(self, $OpponentAgent, ZoneLocation.Side.Opponent)

var current_events: Array[Event] = []

var next_card_instance_id: int = 0:
	get:
		next_card_instance_id += 1
		return next_card_instance_id

class Event:
	var is_ongoing: bool = false

func declare_winner(side: ZoneLocation.Side):
	fiber.stop_all_tasks()
	broadcast_message(MessageTypes.DeclareWinner.new({ winner = side }))

func get_unit(location: ZoneLocation) -> UnitState:
	assert(location.zone in [ZoneLocation.Zone.FrontRow, ZoneLocation.Zone.BackRow])
	assert(location.slot >= 0 && location.slot < (2 if location.zone == ZoneLocation.Zone.FrontRow else 4))
	var state = get_side_state(location.side)
	var zone = state.get_field_zone(location.zone)
	return zone[location.slot] if location.slot < zone.size() else null

func remove_unit(location: ZoneLocation) -> void:
	var state = get_side_state(location.side)
	var zone = state.get_field_zone(location.zone)
	if location.slot < zone.size():
		zone[location.slot] = null

func set_unit(location: ZoneLocation, unit: UnitState) -> void:
	var state = get_side_state(location.side)
	var zone = state.get_field_zone(location.zone)
	assert(location.slot < zone.size())
	if location.slot < zone.size():
		zone[location.slot] = unit


func summon_unit(card_instance: CardInstance, location: ZoneLocation):
	var unit := get_unit(location)

	if unit != null:
		# TODO: verify requirements
		add_discard(location.side, unit.card_instance)
		if card_instance.location.zone == ZoneLocation.Zone.Hand:
			var hand_side_state = get_side_state(card_instance.location.side)
			hand_side_state.remove_from_hand(card_instance)
		unit.card_instance = card_instance
		card_instance.location = location
	else:
		unit = UnitState.new()
		set_unit(location, unit)
		if card_instance.location.zone == ZoneLocation.Zone.Hand:
			var hand_side_state = get_side_state(card_instance.location.side)
			hand_side_state.remove_from_hand(card_instance)
		unit.card_instance = card_instance
		card_instance.location = location

	print("Summoned %s" % card_instance)

	broadcast_message(MessageTypes.UnitSummoned.new({ location = location }))


func summon_starters(side: ZoneLocation.Side):
	var side_state := get_side_state(side)

	summon_unit(side_state.starters[0], ZoneLocation.new(side, ZoneLocation.Zone.FrontRow, 0))
	summon_unit(side_state.starters[1], ZoneLocation.new(side, ZoneLocation.Zone.FrontRow, 1))

func add_discard(side: ZoneLocation.Side, card_instance: CardInstance):
	var side_state := get_side_state(side)
	card_instance.location = ZoneLocation.new(side, ZoneLocation.Zone.Discard, side_state.discard.size())
	side_state.discard.append(card_instance)
	broadcast_message(MessageTypes.AddDiscard.new({ what = card_instance }))

func push_event(e: Event) -> void:
	current_events.append(e)
	#broadcast_message({ type = "event", what = e })


func flush_events() -> void:
	current_events.clear()


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

func perform_ability(who: ZoneLocation.Side, card_instance: CardInstance, ability: CardAbility) -> CardTask:
	var task := ability.effect.task()
	task.source_card_instance = card_instance
	task.source_location = card_instance.location
	task.source_side = who
	fiber.run_task(task)
	return task

func deal_damage(where: ZoneLocation, amount: int):
	pass
