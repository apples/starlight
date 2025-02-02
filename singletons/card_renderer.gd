@tool
extends Node

signal card_ready(card_uid: StringName)

const CARD_RENDERER_SUBVIEWPORT = preload("res://singletons/card_renderer_subviewport.tscn")

var card_textures = {} # { [card_uid: StringName]: Texture2D }



func get_card_texture_async(card: Card) -> Texture2D:
	if card.uid in card_textures:
		if card_textures[card.uid] != null:
			return card_textures[card.uid]
		while await card_ready != card.uid:
			pass
		assert(card_textures[card.uid] != null)
		return card_textures[card.uid]
	
	print("Generating ", card.uid)
	
	card_textures[card.uid] = null
	
	var viewports = CARD_RENDERER_SUBVIEWPORT.instantiate()
	viewports.get_node("Full/CardRender").card = card
	
	add_child(viewports)
	
	await RenderingServer.frame_post_draw
	
	var image: Image = viewports.get_node("Full").get_texture().get_image()
	image.generate_mipmaps()
	
	var texture = ImageTexture.create_from_image(image)
	
	card_textures[card.uid] = texture
	
	viewports.queue_free()
	
	image.save_png("user://%s.png" % card.uid)
	
	return texture
