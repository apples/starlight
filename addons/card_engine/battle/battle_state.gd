class_name BattleState extends Node

enum Side {
	Player,
	Opponent,
}

enum Zone {
	FrontRow,
	BackRow,
	Hand,
	Deck,
	Discard,
	Starlight,
	Banish,
	Floating,
}

@export var rules: BattleRules = null

@onready var fiber: CardFiber = $CardFiber

var current_turn: BattleState.Side = BattleState.Side.Player

@onready var player := BattleSideState.new(self, $PlayerAgent, BattleState.Side.Player)
@onready var opponent := BattleSideState.new(self, $OpponentAgent, BattleState.Side.Opponent)

var current_events: Array[Dictionary] = []

var next_card_instance_id: int = 0:
	get:
		next_card_instance_id += 1
		return next_card_instance_id

func declare_winner(side: BattleState.Side):
	fiber.stop_all_tasks()
	broadcast_message({ type = "declare_winner", winner = side })

func get_unit(location: ZoneLocation) -> UnitState:
	assert(location.zone in [Zone.FrontRow, Zone.BackRow])
	assert(location.slot >= 0 && location.slot < (2 if location.zone == Zone.FrontRow else 4))
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
	var unit = get_unit(location)
	
	if unit != null:
		push_error("Not implemented")
		return
	else:
		unit = UnitState.new()
		set_unit(location, unit)
		if card_instance.location.zone == Zone.Hand:
			var hand_side_state = get_side_state(card_instance.location.side)
			hand_side_state.remove_from_hand(card_instance)
		unit.card_instance = card_instance
		card_instance.location = location
	
	print("Summoned %s" % card_instance)
	
	broadcast_message({ type = "unit_summoned", location = location })


func summon_starters(side: BattleState.Side):
	var side_state := get_side_state(side)
	
	summon_unit(side_state.starters[0], ZoneLocation.new(side, Zone.FrontRow, 0))
	summon_unit(side_state.starters[1], ZoneLocation.new(side, Zone.FrontRow, 1))


func push_event(e: Dictionary) -> void:
	current_events.append(e)
	broadcast_message({ type = "event", what = e })


func flush_events() -> void:
	current_events.clear()


func get_side_state(side: BattleState.Side) -> BattleSideState:
	match (side):
		BattleState.Side.Player: return player
		BattleState.Side.Opponent: return opponent
		_:
			push_error("Invalid side: %s" % side)
			return null

func remove_from_hand(side: BattleState.Side, handIndex: int, card: Card):
	var sideState = get_side_state(side)
	if (sideState.hand[handIndex] == card):
		sideState.hand.RemoveAt(handIndex)
		return
	
	var success = sideState.hand.Remove(card)
	
	if (!success):
		push_error("Card not found in hand (side = %s, handIndex = %s, card = %s)." % [side, handIndex, card])


func shuffle_deck(side: BattleState.Side):
	var state = get_side_state(side)
	state.deck.shuffle()
	broadcast_message({ type = "deck_shuffled", side = side })


func draw_card(side: BattleState.Side) -> void:
	var state := get_side_state(side)
	
	if state.deck.size() == 0:
		declare_winner(flip(side))
		return
	
	var card_instance := state.deck[state.deck.size() - 1]
	state.deck.remove_at(state.deck.size() - 1)
	state.hand.append(card_instance)
	card_instance.location = ZoneLocation.new(side, Zone.Hand, state.hand.size() - 1)
	
	send_message_to(side, { type = "card_drawn", side = side, card_instance = card_instance })
	send_message_to(flip(side), { type = "card_drawn", side = side, card_instance = null })


func broadcast_message(e: Dictionary):
	player.agent.handle_message(e)
	opponent.agent.handle_message(e)


func send_message_to(side: BattleState.Side, e: Dictionary):
	var state = get_side_state(side)
	state.agent.handle_message(e)

func get_card_at(location: ZoneLocation) -> CardInstance:
	match location.tuple():
		[BattleState.Side.Player, Zone.Hand, var idx]:
			return player.hand[idx]
		[BattleState.Side.Player, Zone.BackRow, var idx]:
			return player.back_row[idx].card_instance if player.back_row[idx] else null
		[BattleState.Side.Player, Zone.FrontRow, var idx]:
			return player.front_row[idx].card_instance if player.front_row[idx] else null
		[BattleState.Side.Opponent, Zone.FrontRow, var idx]:
			return opponent.front_row[idx].card_instance if opponent.front_row[idx] else null
		[BattleState.Side.Opponent, Zone.BackRow, var idx]:
			return opponent.back_row[idx].card_instance if opponent.back_row[idx] else null
		[BattleState.Side.Opponent, Zone.Hand, var idx]:
			return opponent.hand[idx]
		_:
			push_warning("Not implemented")
	return null

func perform_ability(card_instance: CardInstance, ability: CardAbility):
	var task := ability.effect.task()
	task.source_card_instance = card_instance
	fiber.run_task(task)

class CardInstance:
	var card: Card
	var battle_id: int
	var location: ZoneLocation
	func _init(c: Card, id: int, l: ZoneLocation):
		card = c
		battle_id = id
		location = l
	func _to_string():
		return "<%s, %s, %s>" % [card, battle_id, location]

class BattleSideState extends Resource:
	var battle_state: BattleState
	var agent: BattleAgent
	var side: BattleState.Side
	
	var deck: Array[CardInstance] = []
	var hand: Array[CardInstance] = []
	var discard: Array[CardInstance] = []
	var starlights: Array[CardInstance] = []
	var starters: Array[CardInstance] = []
	
	var front_row: Array[UnitState] = [null, null]
	var back_row: Array[UnitState] = [null, null, null, null]
	
	func _init(bs: BattleState, a: BattleAgent, s: BattleState.Side):
		battle_state = bs
		agent = a
		side = s
		
		print("Initting %s" % s)
		
		agent.battle_state = bs
		
		var card_deck := agent.get_deck()
		
		for card in card_deck.main_deck_cards:
			deck.append(CardInstance.new(card, battle_state.next_card_instance_id, ZoneLocation.new(side, Zone.Deck)))
		for card in card_deck.starlight_cards:
			starlights.append(CardInstance.new(card, battle_state.next_card_instance_id, ZoneLocation.new(side, Zone.Starlight, starlights.size())))
		for card in card_deck.starter_unit_cards:
			starters.append(CardInstance.new(card_deck.starter_unit_cards[0], battle_state.next_card_instance_id, ZoneLocation.new(side, Zone.Floating)))
		
		deck.shuffle()
		starlights.shuffle()
	
	func get_field_zone(zone: Zone) -> Array[UnitState]:
		match zone:
			Zone.FrontRow: return front_row
			Zone.BackRow: return back_row
			_:
				push_error("Zone is non-field: %s" % zone)
				return front_row
	
	func remove_from_hand(card_instance: CardInstance):
		var idx := hand.find(card_instance)
		assert(idx != -1, "Card not found in hand.")
		hand.remove_at(idx)
		for i in range(hand.size()):
			hand[i].location.slot = i


class UnitState extends Resource:
	var card_instance: CardInstance
	var damage: int = 0
	
	var remaining_hp: int:
		get: return card_instance.hp - damage



class ZoneLocation extends Resource:
	var side: BattleState.Side
	var zone: Zone
	var slot: int
	
	func _init(s: BattleState.Side, z: Zone, i: int = -1):
		side = s
		zone = z
		slot = i
	
	func equals(other: ZoneLocation):
		return tuple() == other.tuple()
	
	func tuple() -> Array:
		return [side, zone, slot]
	
	func _to_string():
		return "<%s, %s, %s>" % [BattleState.Side.keys()[side], Zone.keys()[zone], slot]

static func flip(side: BattleState.Side) -> BattleState.Side:
	match side:
		BattleState.Side.Player: return BattleState.Side.Opponent
		BattleState.Side.Opponent: return BattleState.Side.Player
		_:
			push_error("Not implemented")
			return BattleState.Side.Player
