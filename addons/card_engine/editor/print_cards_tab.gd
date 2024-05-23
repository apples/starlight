@tool
extends VBoxContainer

@onready var viewports = $Viewports
@onready var trim_bleed: CheckButton = %TrimBleed
@onready var for_print: CheckButton = %ForPrint
@onready var save_tts_object: CheckButton = %SaveTTSObject
@onready var tts_name: LineEdit = %TTSName
@onready var tts_folder: LineEdit = %TTSFolder
@onready var backblaze_upload: CheckButton = %BackblazeUpload
@onready var backblaze_api_key_id: LineEdit = %BackblazeApiKeyId
@onready var backblaze_api_key: LineEdit = %BackblazeApiKey
@onready var backblaze_url_for_tts: CheckButton = %BackblazeURLForTTS
@onready var card_names_as_filenames: CheckButton = %CardNamesAsFilenames


var _job_queue = []

var _current_batch = null

var _rendered_files = []

const BATCH_SIZE = 10


func _ready() -> void:
	if Engine.is_editor_hint() and (EditorInterface.get_edited_scene_root() == self or (EditorInterface.get_edited_scene_root() and EditorInterface.get_edited_scene_root().is_ancestor_of(self))):
		return
	
	if OS.has_feature("windows"):
		if OS.has_environment("OneDrive"):
			tts_folder.text = OS.get_environment("OneDrive").path_join("Documents/My Games/Tabletop Simulator/Saves/Saved Objects")
		else:
			tts_folder.text = OS.get_environment("USERPROFILE").path_join("Documents/My Games/Tabletop Simulator/Saves/Saved Objects")
	if not DirAccess.dir_exists_absolute(tts_folder.text):
		tts_folder.text = "res://renders"
	
	tts_name.text = EditorInterface.get_editor_settings().get_project_metadata("card_engine", "tts_name")
	tts_folder.text = EditorInterface.get_editor_settings().get_project_metadata("card_engine", "tts_folder")
	backblaze_api_key_id.text = EditorInterface.get_editor_settings().get_project_metadata("card_engine", "backblaze_api_key_id")
	backblaze_api_key.text = EditorInterface.get_editor_settings().get_project_metadata("card_engine", "backblaze_api_key")


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
		
		var file_list = FileAccess.open("res://renders/cardlist.txt", FileAccess.WRITE)
		for r in _rendered_files:
			file_list.store_line(r.filename)
		file_list.close()
		
		var http: HTTPRequest = $HTTPRequest as HTTPRequest
		
		var b2_api_url := ""
		var b2_api_headers := []
		var b2_prefix := "starlight_tts/"
		var b2_bucket_id := ""
		var b2_bucket_name := ""
		var b2_download_url := ""
		var b2_upload_url := ""
		var b2_upload_auth := ""
		
		if backblaze_upload.button_pressed or backblaze_url_for_tts.button_pressed:
			print("Getting B2 creds...")
			
			var key_id = backblaze_api_key_id.text
			assert(key_id)
			var key = backblaze_api_key.text
			assert(key)
			
			var headers = [
				"Authorization: Basic" + Marshalls.utf8_to_base64("%s:%s" % [key_id, key])
			]
			
			http.request("https://api.backblazeb2.com/b2api/v3/b2_authorize_account", headers, HTTPClient.METHOD_GET)
			var response = await http.request_completed
			var body = JSON.parse_string(response[3].get_string_from_utf8())
			
			b2_api_url = body.apiInfo.storageApi.apiUrl
			b2_bucket_id = body.apiInfo.storageApi.bucketId
			
			b2_download_url = body.apiInfo.storageApi.downloadUrl
			b2_bucket_name = body.apiInfo.storageApi.bucketName
			
			print({ b2_api_url = b2_api_url, b2_bucket_id = b2_bucket_id, b2_bucket_name = b2_bucket_name, b2_download_url = b2_download_url })
			
			b2_api_headers = [
				"Authorization: %s" % body.authorizationToken
			]
			
			http.request(b2_api_url.path_join("b2api/v3/b2_get_upload_url")+"?bucketId="+b2_bucket_id, b2_api_headers)
			response = await http.request_completed
			body = JSON.parse_string(response[3].get_string_from_utf8())
			
			b2_upload_auth = "Authorization: %s" % body.authorizationToken
			b2_upload_url = body.uploadUrl
		
		if backblaze_upload.button_pressed:
			print("Uploading to B2...")
			
			var bucket_file_hashes = {}
			var nextFileName = null
			
			while true:
				var params := "?bucketId=%s&prefix=%s&maxFileCount=%s" % [b2_bucket_id, b2_prefix.uri_encode(), 10000]
				if nextFileName:
					params += "&startFileName=%s" % [nextFileName]
				http.request(b2_api_url.path_join("b2api/v3/b2_list_file_names")+params, b2_api_headers)
				var response = await http.request_completed
				assert(response[1] == 200)
				var body = JSON.parse_string(response[3].get_string_from_utf8())
				for f in body.files:
					bucket_file_hashes[f.fileName] = f.contentSha1
				nextFileName = body.nextFileName
				if nextFileName == null:
					break
			
			for i in _rendered_files.size():
				var c = _rendered_files[i]
				var b2_filename := b2_prefix.path_join(c.filename)
				
				print("    (%s/%s) " % [i+1, _rendered_files.size()], c.filename, " => ", b2_filename)
				
				if b2_filename in bucket_file_hashes:
					if bucket_file_hashes[b2_filename] == c.filehash:
						print("        NO CHANGE")
						continue
					print("        UPDATING")
				else:
					print("        NEW")
				
				var filepath = "res://renders/images".path_join(c.filename)
				var headers = [
					b2_upload_auth,
					"X-Bz-File-Name: " + b2_filename.uri_encode(),
					"X-Bz-Content-Sha1: " + c.filehash,
					"Content-Type: b2/x-auto",
				]
				var f = FileAccess.get_file_as_bytes(filepath)
				http.request_raw(b2_upload_url, headers, HTTPClient.METHOD_POST, f)
				var response = await http.request_completed
				var body = JSON.parse_string(response[3].get_string_from_utf8())
				if response[1] != 200:
					print(body)
					break
		
		if backblaze_url_for_tts.button_pressed:
			for c in _rendered_files:
				c.download_url = b2_download_url.path_join("file").path_join(b2_bucket_name).path_join("starlight_tts/"+c.filename.uri_encode())
		
		if save_tts_object.button_pressed:
			print("Creating TTS deck...")
			
			var tts_deck = {
				"GUID": "903b4e",
				"Name": "Deck",
				"Transform": {
					"posX": 0,
					"posY": 5,
					"posZ": 0,
					"rotX": 0,
					"rotY": 0,
					"rotZ": 0,
					"scaleX": 1.0,
					"scaleY": 1.0,
					"scaleZ": 1.0
				},
				"Nickname": "",
				"Description": "",
				"GMNotes": "",
				"AltLookAngle": {
					"x": 0.0,
					"y": 0.0,
					"z": 0.0
				},
				"ColorDiffuse": {
					"r": 0.713235259,
					"g": 0.713235259,
					"b": 0.713235259
				},
				"LayoutGroupSortIndex": 0,
				"Value": 0,
				"Locked": false,
				"Grid": true,
				"Snap": true,
				"IgnoreFoW": false,
				"MeasureMovement": false,
				"DragSelectable": true,
				"Autoraise": true,
				"Sticky": true,
				"Tooltip": true,
				"GridProjection": false,
				"HideWhenFaceDown": true,
				"Hands": false,
				"SidewaysCard": false,
				"DeckIDs": [],
				"CustomDeck": {},
				"LuaScript": "",
				"LuaScriptState": "",
				"XmlUI": "",
				"ContainedObjects": []
			}
			
			var tts_idx := 0
			
			for c in _rendered_files:
				var url = ProjectSettings.globalize_path("res://renders/images".path_join(c.filename))
				var back_url = ProjectSettings.globalize_path("res://objects/card_plane/images/back.png")
				
				if "download_url" in c:
					url = c.download_url
					back_url = (url as String).get_base_dir().path_join("back.png")
				
				tts_idx += 1
				
				var tts_card = {
					"GUID": "667031",
					"Name": "CardCustom",
					"Transform": {
						"posX": 0,
						"posY": 0,
						"posZ": 0,
						"rotX": 0,
						"rotY": 0,
						"rotZ": 0,
						"scaleX": 1,
						"scaleY": 1,
						"scaleZ": 1
					},
					"Nickname": "",
					"Description": "",
					"GMNotes": "",
					"ColorDiffuse": {
						"r": 0.713235259,
						"g": 0.713235259,
						"b": 0.713235259
					},
					"LayoutGroupSortIndex": 0,
					"Value": 0,
					"Locked": false,
					"Grid": true,
					"Snap": true,
					"IgnoreFoW": false,
					"MeasureMovement": false,
					"DragSelectable": true,
					"Autoraise": true,
					"Sticky": true,
					"Tooltip": true,
					"GridProjection": false,
					"HideWhenFaceDown": true,
					"Hands": true,
					"CardID": tts_idx * 100,
					"SidewaysCard": false,
					"CustomDeck": {
						str(tts_idx): {
							"FaceURL": url,
							"BackURL": back_url,
							"NumWidth": 1,
							"NumHeight": 1,
							"BackIsHidden": true,
							"UniqueBack": false,
							"Type": 0
						}
					},
					"LuaScript": "",
					"LuaScriptState": "",
					"XmlUI": "",
					"PhysicsMaterial": {
						"StaticFriction": 1,
						"DynamicFriction": 0.7,
						"Bounciness": 0,
						"FrictionCombine": 0,
						"BounceCombine": 0
					},
					"Rigidbody": {
						"Mass": 0.5,
						"Drag": 0.1,
						"AngularDrag": 0.1,
						"UseGravity": true
					}
				}
				
				var tts_custom_deck_entry = {
					"FaceURL": url,
					"BackURL": back_url,
					"NumWidth": 1,
					"NumHeight": 1,
					"BackIsHidden": true,
					"UniqueBack": false,
					"Type": 0
				}
				
				tts_deck["ContainedObjects"].append(tts_card)
				tts_deck["CustomDeck"][str(tts_idx)] = tts_custom_deck_entry
				tts_deck["DeckIDs"].append(tts_idx * 100)
			
			var tts_saved_object = {
				"SaveName": "",
				"Date": "",
				"VersionNumber": "",
				"GameMode": "",
				"GameType": "",
				"GameComplexity": "",
				"Tags": [],
				"Gravity": 0.5,
				"PlayArea": 0.5,
				"Table": "",
				"Sky": "",
				"Note": "",
				"TabStates": {},
				"LuaScript": "",
				"LuaScriptState": "",
				"XmlUI": "",
				"ObjectStates": [tts_deck]
			}
			
			var json = JSON.stringify(tts_saved_object)
			
			var json_file := FileAccess.open(tts_folder.text.path_join(tts_name.text+".json"), FileAccess.WRITE)
			json_file.store_string(json)
			json_file.close()
		
		print("Done.")
		
		EditorInterface.get_editor_settings().set_project_metadata("card_engine", "tts_name", tts_name.text)
		EditorInterface.get_editor_settings().set_project_metadata("card_engine", "tts_folder", tts_folder.text)
		EditorInterface.get_editor_settings().set_project_metadata("card_engine", "backblaze_api_key_id", backblaze_api_key_id.text)
		EditorInterface.get_editor_settings().set_project_metadata("card_engine", "backblaze_api_key", backblaze_api_key.text)

func _hash_stuff(stuff: PackedByteArray) -> String:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA1)
	ctx.update(stuff)
	var res = ctx.finish()
	return res.hex_encode()

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
			
			var filename = "%s.png" % [job.card.uid]
			if card_names_as_filenames.button_pressed:
				filename = "%s_%s_%s.png" % [job.card.cardset_name, job.card.cardset_idx, (job.card.card_name as String).replace(" ", "_")]
			
			var path = "res://renders/images/".path_join(filename)
			image.save_png(path)
			
			vp.queue_free()
			
			var hash = _hash_stuff(FileAccess.get_file_as_bytes(path))
			
			_rendered_files.append({ cardset = job.card.cardset_name, idx = job.card.cardset_idx, filename = filename, filehash = hash })
			

func _on_button_pressed():
	DirAccess.make_dir_recursive_absolute("res://renders/images")
	
	_rendered_files = []
	
	for path in CardDatabase.get_all_cards():
		_job_queue.append({
			type = "card",
			card_path = path,
		})
	
	RenderingServer.frame_post_draw.connect(_on_visual_server_frame_post_draw)
	
	$Popup.popup_centered()


func _on_backblaze_upload_toggled(toggled_on: bool) -> void:
	card_names_as_filenames.button_pressed = not toggled_on
	card_names_as_filenames.disabled = toggled_on
	
