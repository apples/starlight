class_name CursorLocation extends Node

enum {
	LAYER_BATTLE = 1,
	LAYER_ACTIONS = 2,
}

@export_flags("Battle", "Actions") var layers: int = LAYER_BATTLE

@export var enabled: bool = true

@export var location: BattleState.ZoneLocation = null

@export var up: CursorLocation = null
@export var down: CursorLocation = null
@export var left: CursorLocation = null
@export var right: CursorLocation = null

func _init():
	add_to_group("cursor_location")

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

static func find_location(tree: SceneTree, location: BattleState.ZoneLocation, layer: int) -> CursorLocation:
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
