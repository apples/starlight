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

@export var enabled: bool = true:
	get:
		return enabled if not temporary_disable else false
	set(value):
		if enabled != value:
			enabled = value
			enabled_changed.emit(self, enabled)

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

var temporary_disable: bool = false

signal confirmed(cursor_location: CursorLocation)
signal made_current(cursor_location: CursorLocation)
signal enabled_changed(cursor_location: CursorLocation, enabled: bool)

func _ready():
	self.visible = is_current
	CardCursor.add_location(self)

func navigate(dir: StringName) -> CursorLocation:
	assert([&"up", &"down", &"left", &"right"].has(dir), "Invalid direction")
	var next = self[dir]
	if is_instance_valid(next):
		if next.enabled:
			return next
		else:
			return next.navigate(dir)
	else:
		return null

func confirm():
	confirmed.emit(self)

func make_current():
	assert(enabled)
	made_current.emit(self)

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
