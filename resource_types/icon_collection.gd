@tool
class_name IconCollection
extends Resource

@export var icons: Array[IconCollectionItem] = []

func get_icon(name: String) -> IconCollectionItem:
	for i in icons:
		if i.name == name:
			return i
	return null
