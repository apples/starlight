class_name BattleSideState extends Resource

var battle_state: BattleState
var agent: BattleAgent
var side: ZoneLocation.Side

var deck: Array[CardInstance] = []
var hand: Array[CardInstance] = []
var discard: Array[CardInstance] = []
var starlights: Array[CardInstance] = []
var starters: Array[CardInstance] = []

var front_row: Array[UnitState] = [null, null]
var back_row: Array[UnitState] = [null, null, null, null]

var Zone := ZoneLocation.Zone

func _init(bs: BattleState, a: BattleAgent, s: ZoneLocation.Side):
	print("ASDF ", Zone, typeof(Zone))
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

func get_field_zone(zone: ZoneLocation.Zone) -> Array[UnitState]:
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
