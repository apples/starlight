class_name BattleSideState extends Resource

var battle_state: BattleState
var agent: BattleAgent
var side: ZoneLocation.Side

var deck: CardZoneArray = null
var hand: CardZoneArray = null
var discard: CardZoneArray = null
var banish: CardZoneArray = null
var graces: CardZoneArray = null
var starters: Array[CardInstance] = []

var rulecard: CardInstance
var front_row: Array[UnitState] = [null, null]
var back_row: Array[UnitState] = [null, null, null, null]

var Zone := ZoneLocation.Zone

var token_amounts: Dictionary = {}

var rulecard_charge: int = 0

func _init(bs: BattleState, a: BattleAgent, s: ZoneLocation.Side):
	battle_state = bs
	agent = a
	side = s
	
	print("Initting %s" % s)
	
	deck = CardZoneArray.new(side, ZoneLocation.Zone.Deck)
	hand = CardZoneArray.new(side, ZoneLocation.Zone.Hand)
	discard = CardZoneArray.new(side, ZoneLocation.Zone.Discard)
	banish = CardZoneArray.new(side, ZoneLocation.Zone.Banish)
	graces = CardZoneArray.new(side, ZoneLocation.Zone.Grace)
	
	agent.battle_state = bs
	
	var card_deck := agent.get_deck()
	
	rulecard = battle_state.create_card_instance(CardDatabase.load_from_key(card_deck.rulecard_card_key), ZoneLocation.new(side, Zone.Rulecard), side)
	
	for card_count in card_deck.main_deck_cards:
		var card := CardDatabase.load_from_key(card_count.card_key)
		for i in range(card_count.count):
			deck.add_card(battle_state.create_card_instance(card, ZoneLocation.new(side, Zone.Floating), side))
	for card_key in card_deck.grace_card_keys:
		var card := CardDatabase.load_from_key(card_key)
		graces.add_card(battle_state.create_card_instance(card, ZoneLocation.new(side, Zone.Floating), side))
	for card_key in card_deck.starter_unit_card_keys:
		var card := CardDatabase.load_from_key(card_key)
		starters.append(battle_state.create_card_instance(card, ZoneLocation.new(side, Zone.Floating), side))
	
	deck.shuffle()
	graces.shuffle()

func get_field_zone(zone: ZoneLocation.Zone) -> Array[UnitState]:
	match zone:
		Zone.FrontRow: return front_row
		Zone.BackRow: return back_row
		_:
			push_error("Zone is non-field: %s" % zone)
			return front_row

func get_all_units() -> Array[UnitState]:
	var results: Array[UnitState] = []
	results.append_array(front_row)
	results.append_array(back_row)
	return results.filter(func (u): return u != null)

func get_token_amount(kind: BattleState.TokenType):
	if kind in token_amounts:
		return token_amounts[kind]
	else:
		return 0

func gain_tokens(kind: BattleState.TokenType, amount: int):
	if not kind in token_amounts:
		token_amounts[kind] = 0
	
	token_amounts[kind] += amount
