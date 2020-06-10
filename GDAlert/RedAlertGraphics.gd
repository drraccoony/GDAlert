extends TextureRect

var page_width = 0
var page_height = 0
var game_image = Image.new()
var has_selected = false
var is_scrolling = false
var scroll_start = Vector2(0, 0)

var time_since_game_tick = 0.0

func debug_message(msg):
	print (msg)

func play_speech(sample: AudioStreamSample):
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(player)
	player.set_stream(sample)
	player.volume_db = -15;
	player.play()
	yield(player, "finished")
	player.queue_free()

func play_sound(sample: AudioStreamSample, x: int, y: int):
	var player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	var main: Control = get_node("/root/main")
	main.add_child(player)
	player.set_stream(sample)
	player.position = Vector2(x, y)
	player.volume_db = -15;
	player.play()
	yield(player, "finished")
	player.queue_free()

func _ready():
	RedAlert.connect("event", self, "debug_message");
	RedAlert.connect("play_sound", self, "play_sound");
	RedAlert.connect("play_speech", self, "play_speech");
	# RedAlert.cnc_start_instance(scenario_number, build_level, "ALLY" or "USSR")
	RedAlert.cnc_start_instance(1, 10, "ALLY")
	game_image.create(256, 256, false, Image.FORMAT_RGBA8)
	game_image.fill(Color(1,0,0,1))
	texture = ImageTexture.new()
	texture.create_from_image(game_image)

	var score_player: AudioStreamPlayer = get_node("/root/main/ScorePlayer")
	var score_sample: AudioStreamSample = RedAlert.get_score_sample("BIGF226M.AUD")
	score_sample.loop_mode = AudioStreamSample.LOOP_FORWARD
	score_sample.loop_end = score_sample.data.size()
	score_player.set_stream(score_sample)
	score_player.play()

func _process(delta):
	time_since_game_tick += delta

	if time_since_game_tick >= 0.03333333333:
		RedAlert.cnc_advance_instance(0)
		time_since_game_tick = 0

	var data = RedAlert.cnc_get_visible_page()
	var width = RedAlert.cnc_get_visible_page_width()
	var height = RedAlert.cnc_get_visible_page_height()
	if width != page_width or height != page_height:
		page_width = width
		page_height = height
		game_image.create(width, height, false, Image.FORMAT_RGBA8)
	game_image.data.data = data
	texture.set_data(game_image)
	texture.flags = 0
	texture.set_size_override(Vector2(width, height))

func _gui_input(event):
	if event is InputEventMouseButton:
		var x = event.position.x
		var y = event.position.y
		if event.button_index == BUTTON_LEFT:
			if !event.pressed:
				if !has_selected:
					RedAlert.cnc_handle_left_mouse_up(x, y)
				else:
					has_selected = false
		if event.button_index == BUTTON_RIGHT:
			if event.pressed:
				RedAlert.cnc_handle_right_mouse_down(x, y)
			else:
				RedAlert.cnc_handle_right_mouse_up(x, y)
		if event.button_index == BUTTON_WHEEL_UP and event.pressed:
			$GameCamera.zoom /= 2
			$GameCamera.position += $GameCamera.get_viewport_rect().size * $GameCamera.zoom * 0.5
			clamp_camera_position()
		if event.button_index == BUTTON_WHEEL_DOWN and event.pressed:
			$GameCamera.position -= $GameCamera.get_viewport_rect().size * $GameCamera.zoom * 0.5
			$GameCamera.zoom *= 2
			clamp_camera_position()
		if event.button_index == BUTTON_MIDDLE:
			if event.pressed:
				is_scrolling = true
				scroll_start = event.position
			else:
				is_scrolling = false
	if event is InputEventMouseMotion:
		if is_scrolling:
			var x = $GameCamera.position.x + (scroll_start.x - event.position.x)
			var y = $GameCamera.position.y + (scroll_start.y - event.position.y)
			$GameCamera.position.x = x
			$GameCamera.position.y = y
			clamp_camera_position()


func clamp_camera_position():
	var max_x = page_width - ($GameCamera.get_viewport_rect().size.x * $GameCamera.zoom.x)
	var new_x = clamp($GameCamera.position.x, 0, max(0, max_x))
	var max_y = page_height - ($GameCamera.get_viewport_rect().size.y * $GameCamera.zoom.y)
	var new_y = clamp($GameCamera.position.y, 0, max(0, max_y))
	$GameCamera.position.x = new_x
	$GameCamera.position.y = new_y

func _on_select_rect_finish(p1, p2):
	RedAlert.cnc_handle_mouse_area(p1.x, p1.y, p2.x, p2.y)
	has_selected = true
