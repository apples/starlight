class_name CardRender
extends Node2D

enum Highlight {
	OFF,
	YELLOW,
	BLUE,
}

@export var frame_texture: Texture2D = null

@export var back_texture: Texture2D = null

@export var card: Card = null:
	get:
		return card
	set(value):
		card = value
		call_deferred(&"refresh")

@export var highlight: Highlight = Highlight.OFF:
	get:
		return highlight
	set(value):
		highlight = value
		call_deferred(&"refresh")

func _ready():
	call_deferred(&"refresh")

func refresh():
	if card:
		$Background.texture = frame_texture
		$Artwork.visible = true
		$Artwork.texture = card.artwork
		$Name.visible = true
		$Name.text = card.card_name
	else:
		$Background.texture = back_texture
		$Artwork.visible = false
		$Name.visible = false
	
	match highlight:
		Highlight.OFF:
			$Highlight.visible = false
		Highlight.YELLOW:
			$Highlight.visible = true
			$Highlight.modulate = Color.YELLOW
		Highlight.BLUE:
			$Highlight.visible = true
			$Highlight.modulate = Color.DEEP_SKY_BLUE
