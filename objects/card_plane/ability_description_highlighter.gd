@tool
extends Control

@export var highlight_sections: bool = false
@export var underline_sections: bool = true
@export var underline_condition_color: Color = Color("#76428a")
@export var underline_condition_tag: Texture2D = preload("res://objects/card_plane/images/condition_tag.png")
@export var underline_cost_color: Color = Color("#37946e")
@export var underline_cost_tag: Texture2D = preload("res://objects/card_plane/images/cost_tag.png")
@export var condition_style: StyleBox
@export var costs_style: StyleBox
@export var effect_style: StyleBox

var label: Label

func _ready() -> void:
	label = get_child(0)
	refresh()


func _draw() -> void:
	if not highlight_sections and not underline_sections:
		return
	
	if not label:
		return
	
	var text := label.text
	if not text:
		return
	
	var colon_pos := text.find(":")
	var semicolon_pos := text.find(";")
	
	var prelude := 0
	if colon_pos != -1:
		prelude = text.rfind(".", colon_pos) + 1
	elif semicolon_pos != -1:
		prelude = text.rfind(".", semicolon_pos) + 1
	while text[prelude] == " " and prelude < text.length():
		prelude += 1
	
	if underline_sections:
		if colon_pos != -1:
			_draw_underline(prelude, colon_pos, underline_condition_color, underline_condition_tag)
		
		if semicolon_pos != -1:
			var start = prelude
			if colon_pos != -1:
				start = colon_pos + 1
				while text[start] == " " and start < text.length():
					start += 1
			_draw_underline(start, semicolon_pos, underline_cost_color, underline_cost_tag)
	
	
	if highlight_sections:
		print(get_path())
		prints(highlight_sections, underline_sections)
		if colon_pos != -1:
			for i in range(prelude, colon_pos + 1):
				var rect := label.get_character_bounds(i)
				_draw_stylebox(condition_style, rect)
			if text[colon_pos + 1] == " ":
				var rect := label.get_character_bounds(colon_pos + 1)
				var left := Rect2(rect.position.x, rect.position.y, floor(rect.size.x / 2.0) - 1, rect.size.y)
				var right := Rect2(left.end.x + 2, rect.position.y, rect.size.x - left.size.x, rect.size.y)
				_draw_stylebox(condition_style, left)
				_draw_stylebox(costs_style if semicolon_pos != -1 else effect_style, right)
		
		if semicolon_pos != -1:
			for i in range((colon_pos + (2 if text[colon_pos + 1] == " " else 1)) if colon_pos != -1 else prelude, semicolon_pos + 1):
				_draw_stylebox(costs_style, label.get_character_bounds(i))
			if text[semicolon_pos + 1] == " ":
				var rect := label.get_character_bounds(semicolon_pos + 1)
				var left := Rect2(rect.position.x, rect.position.y, floor(rect.size.x / 2.0) - 1, rect.size.y)
				var right := Rect2(left.end.x + 2, rect.position.y, rect.size.x - left.size.x, rect.size.y)
				_draw_stylebox(costs_style, left)
				_draw_stylebox(effect_style, right)
		
		for i in range((semicolon_pos + 1) if semicolon_pos != -1 else (colon_pos + 2) if colon_pos != -1 else 0, text.length()):
			_draw_stylebox(effect_style, label.get_character_bounds(i))
		
		_flush_stylebox()
	


func refresh() -> void:
	queue_redraw()
	

var _current_style: StyleBox
var _current_style_rect: Rect2

func _draw_stylebox(style: StyleBox, where: Rect2) -> void:
	if not where or not style:
		_flush_stylebox()
		return
	where.position += label.position
	where.position.y += 3
	where.size.y -= 4
	if style != _current_style:
		_flush_stylebox()
		_current_style = style
		_current_style_rect = where
	elif where.position != Vector2(_current_style_rect.end.x, _current_style_rect.position.y):
		_flush_stylebox()
		_current_style = style
		_current_style_rect = where
	else:
		_current_style_rect = _current_style_rect.expand(where.end)

func _flush_stylebox() -> void:
	if not _current_style:
		return
	draw_style_box(_current_style, _current_style_rect)
	_current_style = null
	_current_style_rect = Rect2()



func _draw_underline(start: int, end: int, color: Color, tag_texture: Texture2D) -> void:
	for i in range(start, end + 1):
		var r := label.get_character_bounds(i)
		var points: PackedVector2Array
		if i == start:
			points = [
				Vector2(r.position.x, r.end.y - 1),
				Vector2(r.position.x + 2, r.end.y + 1),
				Vector2(r.end.x, r.end.y + 1),
			]
		elif i == end:
			points = [
				Vector2(r.position.x, r.end.y + 1),
				Vector2(r.end.x - 2, r.end.y + 1),
				Vector2(r.end.x, r.end.y - 1),
			]
		else:
			points = [
				Vector2(r.position.x, r.end.y + 1),
				Vector2(r.end.x, r.end.y + 1),
			]
		draw_polyline(points, color, 2.0)
	var r1 := label.get_character_bounds(start)
	#draw_texture(tag_texture, Vector2(r1.position.x + 4, r1.end.y - 2))
	
	
