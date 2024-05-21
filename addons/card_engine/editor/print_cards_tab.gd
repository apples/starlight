@tool
extends VBoxContainer

@onready var viewports = $Viewports
@onready var trim_bleed: CheckButton = %TrimBleed
@onready var for_print: CheckButton = %ForPrint

var _job_queue = []

var _current_batch = null

var _rendered_files = []

const BATCH_SIZE = 10

func _on_visual_server_frame_post_draw():
	if _current_batch:
		for job in _current_batch:
			_finish_job(job)
	
	if _job_queue.size() > 0:
		_current_batch = _job_queue.slice(0, BATCH_SIZE)
		_job_queue = _job_queue.slice(BATCH_SIZE)
		
		for job in _current_batch:
			_start_job(job)
	else:
		_current_batch = null
		RenderingServer.frame_post_draw.disconnect(_on_visual_server_frame_post_draw)
		$Popup.hide()
		
		_rendered_files.sort_custom(func (a, b):
			if a.cardset != b.cardset:
				return a.cardset < b.cardset
			return a.idx < b.idx
		)
		
		var file_list = FileAccess.open("res://.renders/cardlist.txt", FileAccess.WRITE)
		for r in _rendered_files:
			file_list.store_line(r.filename)
		file_list.close()

func _start_job(job):
	print("JOB START: ", job)
	match job.type:
		"card":
			var dpi := CardDatabase.config.card_print_dpi
			var size_in := CardDatabase.config.card_print_size_in
			var bleed_in := CardDatabase.config.card_print_bleed_in
			if trim_bleed.button_pressed:
				bleed_in = Vector2.ZERO
			var result_size_px := Vector2i(dpi * (size_in + bleed_in))
			#var render_scale := dpi * size_in / Vector2(CardDatabase.config.card_size_pixels)
			var result_card_size_px := Vector2i(dpi * size_in)
			var viewport = SubViewport.new()
			viewport.size = result_size_px
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
			viewport.transparent_bg = true
			
			var render: Control = CardDatabase.config.card_control.instantiate()
			render.for_print = for_print.button_pressed
			render.card = load(job.card_path)
			render.position = Vector2i(dpi * bleed_in / 2)
			render.size = result_card_size_px
			
			viewport.add_child(render)
			viewports.add_child(viewport)
			
			job.card = render.card
			job.viewport = viewport

func _finish_job(job):
	print("JOB FINISH: ", job)
	match job.type:
		"card":
			var vp = job.viewport as SubViewport
			var image = vp.get_texture().get_image()
			image.convert(Image.FORMAT_RGBA8)
			
			var filename = "%s_%s_%s.png" % [job.card.cardset_name, job.card.cardset_idx, (job.card.card_name as String).replace(" ", "_")]
			var path = "res://.renders/images/".path_join(filename)
			image.save_png(path)
			
			vp.queue_free()
			
			_rendered_files.append({ cardset = job.card.cardset_name, idx = job.card.cardset_idx, filename = filename })
			

func _on_button_pressed():
	DirAccess.make_dir_recursive_absolute("res://.renders/images")
	
	_rendered_files = []
	
	for path in CardDatabase.get_all_cards():
		_job_queue.append({
			type = "card",
			card_path = path,
		})
	
	RenderingServer.frame_post_draw.connect(_on_visual_server_frame_post_draw)
	
	$Popup.popup_centered()
