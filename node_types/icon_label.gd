@tool
@icon("IconLabel.svg")
class_name IconLabel
extends Control

#region Export Variables

@export_multiline var text: String = "": set = set_text

@export var label_settings: IconLabelSettings: set = set_label_settings

@export_custom(PROPERTY_HINT_NONE, "suffix:px") var indent: int = 0: set = set_indent

@export var horizontal_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT: set = set_horizontal_alignment

@export var autowrap_mode: TextServer.AutowrapMode = TextServer.AUTOWRAP_OFF: set = set_autowrap_mode

@export var highlights: Array[IconLabelHighlight] = []

#endregion Export Variables

#region Public Variables

var font: Font:
	get(): return label_settings.font if label_settings else get_theme_font("font", "Label")

var font_size: int:
	get(): return label_settings.font_size if label_settings else get_theme_font_size("font_size", "Label")

var color: Color:
	get(): return label_settings.color if label_settings else get_theme_color("color", "Label")

var line_spacing: int:
	get(): return label_settings.line_spacing if label_settings else 2

var icon_collection: IconCollection:
	get(): return label_settings.icon_collection if label_settings else null

#endregion Public Variables

#region Private Variables

var _dirty: bool = true: set = _set_dirty

var _paragraph: TextParagraph = TextParagraph.new()

var _icon_scene_nodes: Dictionary = {}

#endregion Private Variables

#region Virtual Method Overrides

func _enter_tree() -> void:
	_shape()

func _ready() -> void:
	if not font:
		font = get_theme_font("font", "Label")
	if font_size == 0:
		font_size = get_theme_font_size("font_size", "Label")

func _get_minimum_size() -> Vector2:
	if (_dirty): _shape()
	
	match autowrap_mode:
		TextServer.AUTOWRAP_OFF:
			return _paragraph.get_size() + Vector2(0, (_paragraph.get_line_count() - 1) * line_spacing)
		_:
			return Vector2(1, _paragraph.get_size().y + (_paragraph.get_line_count() - 1) * line_spacing)

func _draw() -> void:
	if (_dirty): _shape()
	
	if highlights:
		for highlight: IconLabelHighlight in highlights:
			if not highlight or not highlight.regex or not highlight.style:
				continue
			var regex := RegEx.create_from_string(highlight.regex)
			var matches := regex.search_all(text)
			for m: RegExMatch in matches:
				var rects := get_selection_rects(m.get_start(), m.get_end())
				for rect: Rect2 in rects:
					if line_spacing < 0:
						rect.position.y += floori(-line_spacing / 2)
						rect.size.y -= -line_spacing
					rect = rect.grow_individual(highlight.margin_left, highlight.margin_top, highlight.margin_right, highlight.margin_bottom)
					draw_style_box(highlight.style, rect)
	
	var pos := Vector2.ZERO
	
	for line: int in _paragraph.get_line_count():
		pos.x = get_line_left(line)
		_paragraph.draw_line(get_canvas_item(), pos, line)
		for key in _paragraph.get_line_objects(line):
			if not "icon" in key:
				continue
			var icon: IconCollectionItem = key.icon
			var rect := _paragraph.get_line_object_rect(line, key)
			rect.position.y += line_spacing * line
			if icon.texture:
				draw_texture_rect(icon.texture, rect, false)
		pos.y += _paragraph.get_line_size(line).y + line_spacing

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			mark_dirty()

#endregion Virtual Method Overrides

#region Public Methods

func get_selection_rects(start: int, end: int, include_icons: bool = true) -> Array[Rect2]:
	start += 1
	end += 1
	var result: Array[Rect2] = []
	var y := 0
	var TS := TextServerManager.get_primary_interface()
	for line: int in _paragraph.get_line_count():
		var line_height := _paragraph.get_line_size(line).y
		var r := _paragraph.get_line_range(line)
		if start < r.y and end > r.x:
			var rid := _paragraph.get_line_rid(line)
			var objects := []
			if include_icons:
				objects = _paragraph.get_line_objects(line).map(func (k): return {
					key = k,
					rect = _paragraph.get_line_object_rect(line, k),
					range = TS.shaped_text_get_object_range(rid, k),
				}).filter(func (o):
					return o.range.x >= start and o.range.y <= end and o.key.tok != -1)
			objects.sort_custom(func (a, b): return a.rect.position.x < b.rect.position.x)
			var line_start := maxi(r.x, start)
			var line_end := mini(r.y, end)
			var sel := TS.shaped_text_get_selection(rid, line_start, line_end)
			var rect_accum := [Rect2()]
			var expand_accum := func expand_accum(rect: Rect2) -> void:
				rect.position.y = y
				rect.size.y = line_height
				if rect_accum[0] and rect_accum[0].end.x == rect.position.x:
					rect_accum[0] = rect_accum[0].expand(rect.end)
					rect_accum[0] = rect_accum[0].expand(Vector2(rect.end.x, rect.position.y))
				else:
					if rect_accum[0]:
						result.append(rect_accum[0])
					rect_accum[0] = rect
			
			for s in sel:
				var rect := Rect2(Vector2(s.x, y), Vector2(s.y - s.x, line_height))
				rect.position.x += get_line_left(line)
				while not objects.is_empty() and objects[0].rect.end.x <= rect.position.x:
					var o = objects.pop_front()
					expand_accum.call(o.rect)
				expand_accum.call(rect)
			for o in objects:
				expand_accum.call(o.rect)
			
			if rect_accum[0]:
				result.append(rect_accum[0])
		if end <= r.y:
			break
		y += line_height + line_spacing
	return result

func get_character_rect(pos: int) -> Rect2:
	var rs := get_selection_rects(pos, pos + 1)
	if rs:
		return rs[0]
	return Rect2()

func get_line_left(line: int) -> float:
	match horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			return floor((size.x - _paragraph.get_line_width(line)) / 2.0)
		HORIZONTAL_ALIGNMENT_RIGHT:
			return size.x - _paragraph.get_line_width(line)
	return 0

func mark_dirty() -> void:
	_dirty = true

func set_text(v) -> void:
	if text != v:
		text = v
		mark_dirty()

func set_label_settings(v) -> void:
	if label_settings != v:
		label_settings = v
		mark_dirty()

func set_indent(v) -> void:
	if indent != v:
		indent = v
		mark_dirty()

func set_horizontal_alignment(v) -> void:
	if horizontal_alignment != v:
		horizontal_alignment = v
		mark_dirty()

func set_autowrap_mode(v) -> void:
	if autowrap_mode != v:
		autowrap_mode = v
		mark_dirty()

func set_highlights(v) -> void:
	if highlights != v:
		highlights = v
		mark_dirty()

#endregion Public Methods

#region Private Methods

func _set_dirty(v) -> void:
	_dirty = v
	if _dirty:
		queue_redraw()
		update_minimum_size()

func _shape() -> void:
	_dirty = false
	
	_paragraph.clear()
	
	_paragraph.alignment = horizontal_alignment
	
	for k in _icon_scene_nodes:
		_icon_scene_nodes[k].queue_free()
	_icon_scene_nodes.clear()
	
	match autowrap_mode:
		TextServer.AUTOWRAP_OFF:
			_paragraph.width = -1
			_paragraph.break_flags = TextServer.BREAK_MANDATORY
		TextServer.AUTOWRAP_ARBITRARY:
			_paragraph.width = size.x
			_paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_GRAPHEME_BOUND
		TextServer.AUTOWRAP_WORD:
			_paragraph.width = size.x
			_paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
		TextServer.AUTOWRAP_WORD_SMART:
			_paragraph.width = size.x
			_paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	
	if not font:
		return
	
	_paragraph.add_object({ tok = -1 }, Vector2(indent, 1), INLINE_ALIGNMENT_CENTER, 1)
	
	_parse_text()

func _parse_text() -> void:
	var tok: int = 0
	var text_accum := ""
	
	var _prev_tok := -1
	
	while tok < text.length():
		assert(tok != _prev_tok, "Stuck in an infinite loop!")
		_prev_tok = tok
		
		match text[tok]:
			"\\":
				if tok + 1 < text.length():
					if text_accum:
						_paragraph.add_string(
							text_accum,
							font,
							font_size)
						text_accum = ""
					_paragraph.add_object({ tok = tok }, Vector2.ZERO)
					text_accum += text[tok + 1]
				tok += 2
			"{":
				if tok + 1 < text.length() and text[tok + 1] == "{":
					if text_accum:
						_paragraph.add_string(
							text_accum,
							font,
							font_size)
						text_accum = ""
					tok = _parse_icon(tok)
				else:
					text_accum += "{"
					tok += 1
			var x:
				text_accum += x
				tok += 1
	
	if text_accum:
		_paragraph.add_string(
			text_accum,
			font,
			font_size)

func _parse_icon(icon_start: int) -> int:
	var tok := icon_start + 2
	var icon_end := text.find("}}", tok)
	var icon_name := text.substr(tok, icon_end - tok if icon_end != -1 else -1).strip_edges()
	
	if icon_end == -1:
		tok = text.length()
	else:
		tok = icon_end + 2
	
	var icon := icon_collection.get_icon(icon_name) if icon_collection else null
	
	if icon:
		var key := { icon = icon, tok = icon_start }
		var icon_size := icon.size if icon.size else icon.texture.get_size() if icon.texture else Vector2.ZERO
		icon_size *= label_settings.icon_scale
		_paragraph.add_object(
			key,
			icon_size,
			icon.alignment_image_point | icon.alignment_text_point,
			tok - icon_start)
	
	return tok

#endregion Private Methods
