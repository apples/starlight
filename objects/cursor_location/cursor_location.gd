class_name CursorLocation extends Node

enum {
	LAYER_BATTLE = 1,
	LAYER_PLAYER = 2,
	LAYER_OPPONENT = 4,
	LAYER_FIELD = 8,
	LAYER_HAND = 16,
	LAYER_ACTIONS = 32,
	LAYER_CARD_ABILITIES = 64,
}

@export_flags("Battle", "Player", "Opponent", "Field", "Hand", "Actions", "Card Abilities") var layers: int = LAYER_BATTLE

@export var enabled: bool = true

@export var custom_tag: String = ""

@export var location: ZoneLocation = null

@export var up: CursorLocation = null
@export var down: CursorLocation = null
@export var left: CursorLocation = null
@export var right: CursorLocation = null

var is_current: bool = false:
	get:
		return is_current
	set(value):
		is_current = value
		self.visible = is_current

func _ready():
	self.visible = is_current

func navigate(dir: StringName) -> CursorLocation:
	assert([&"up", &"down", &"left", &"right"].has(dir), "Invalid direction")
	var next = self[dir]
	if next:
		if next.enabled:
			return next
		else:
			return next.navigate(dir)
	else:
		return null

static func find_location(tree: SceneTree, location: ZoneLocation, layer: int) -> CursorLocation:
	for cl in tree.get_nodes_in_group("cursor_location"):
		var cursor_location := cl as CursorLocation
		assert(cursor_location)
		if (cursor_location.layers & layer) != 0:
			if cursor_location.location:
				if cursor_location.location.equals(location):
					return cursor_location
	return null

static func filter_enable(tree: SceneTree, layer: int, filter: Callable) -> Array[CursorLocation]:
	var results: Array[CursorLocation] = []
	for cl in tree.get_nodes_in_group("cursor_location"):
		var cursor_location := cl as CursorLocation
		if (cursor_location.layers & layer) == 0:
			cursor_location.enabled = false
		else:
			cursor_location.enabled = filter.call(cursor_location)
			if cursor_location.enabled:
				results.append(cursor_location)
	return results
