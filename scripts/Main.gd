extends Node

const GameSessionScript = preload("res://scripts/GameSession.gd")
const MoveInputScript = preload("res://scripts/MoveInput.gd")

const START_RADIUS := 100.0
const PLAYER_HEIGHT := 3.2
const QOOB_CENTER := Vector3(0.0, 13.0, 0.0)
const FORWARD_STEP := 11.0
const BACKWARD_STEP := 8.0
const STRAFE_STEP := 0.244346
const MOVE_TIME := 0.52

const AUDIO_HUM := "res://assets/audio/qoob_hum.wav"
const AUDIO_SCREECH := "res://assets/audio/wrong_screech.wav"
const AUDIO_STORM := "res://assets/audio/lightning_storm.wav"
const AUDIO_SUCCESS := "res://assets/audio/success_chime.wav"

var session
var screen_state := "title"
var busy := false

var orbit_angle := 0.0
var orbit_radius := START_RADIUS

var world_root: Node3D
var camera: Camera3D
var qoob_pivot: Node3D
var qoob_material: ShaderMaterial
var qoob_light: OmniLight3D
var environment_node: WorldEnvironment
var base_environment: Environment
var motes: Array = []
var mote_data: Array = []
var field_rings: Array = []

var ui_layer: CanvasLayer
var title_screen: Control
var loading_screen: Control
var hud_screen: Control
var game_over_screen: Control
var sky_overlay: ColorRect
var feedback_label: Label
var strike_label: Label
var lightning_holder: Control

var hum_player: AudioStreamPlayer
var effect_player: AudioStreamPlayer
var storm_player: AudioStreamPlayer
var success_player: AudioStreamPlayer


func _ready() -> void:
	randomize()
	session = GameSessionScript.new()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	_build_world()
	_build_ui()
	_build_audio()
	reset_player_view()
	show_title()


func _process(delta: float) -> void:
	if world_root == null:
		return

	_update_qoob(delta)
	_update_motes()
	_update_player_camera()


func _unhandled_input(event: InputEvent) -> void:
	if screen_state != "gameplay":
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var move := MoveInputScript.from_event(event, viewport_size)
	if move == "":
		return

	get_viewport().set_input_as_handled()
	process_move(move)


func process_move(move: String) -> void:
	if busy:
		return

	busy = true
	var result: Dictionary = session.apply_move(move)
	_update_hud()

	if result["valid"]:
		await _animate_step(move)
		if result["outcome"] == GameSessionScript.OUTCOME_SUCCESS:
			await _animate_to_qoob()
			await _show_success_sequence()
	else:
		if result["outcome"] == GameSessionScript.OUTCOME_GAME_OVER:
			await _show_final_failure_sequence()
		else:
			await _show_wrong_move_sequence()

	if screen_state == "gameplay":
		busy = false


func _build_world() -> void:
	world_root = Node3D.new()
	world_root.name = "World"
	add_child(world_root)

	base_environment = Environment.new()
	base_environment.background_mode = Environment.BG_COLOR
	base_environment.background_color = Color(0.016, 0.012, 0.032)
	base_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	base_environment.ambient_light_color = Color(0.12, 0.07, 0.18)
	base_environment.ambient_light_energy = 0.68
	base_environment.fog_enabled = true
	base_environment.fog_density = 0.018
	base_environment.fog_light_color = Color(0.18, 0.12, 0.24)

	environment_node = WorldEnvironment.new()
	environment_node.environment = base_environment
	world_root.add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.name = "Cold Ritual Key Light"
	sun.light_color = Color(0.42, 0.58, 0.78)
	sun.light_energy = 0.72
	sun.rotation_degrees = Vector3(-38.0, 44.0, 0.0)
	world_root.add_child(sun)

	var ground := MeshInstance3D.new()
	ground.name = "Barren Otherworldly Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(240.0, 240.0)
	ground.mesh = plane
	ground.material_override = _make_ground_material()
	world_root.add_child(ground)

	_build_qoob()
	_build_set_dressing()
	_build_motes()

	camera = Camera3D.new()
	camera.name = "First Person Step Camera"
	camera.current = true
	camera.fov = 72.0
	camera.near = 0.05
	world_root.add_child(camera)


func _build_qoob() -> void:
	qoob_pivot = Node3D.new()
	qoob_pivot.name = "Qoob"
	qoob_pivot.position = Vector3(0.0, 12.35, 0.0)
	world_root.add_child(qoob_pivot)

	var cube := MeshInstance3D.new()
	cube.name = "Monstrously Large Alien Cube"
	var cube_mesh := BoxMesh.new()
	cube_mesh.size = Vector3(24.0, 24.0, 24.0)
	cube.mesh = cube_mesh
	qoob_material = _make_qoob_shader_material()
	cube.material_override = qoob_material
	qoob_pivot.add_child(cube)

	# Procedural field rings are MVP art: clear, original, and replaceable with authored VFX later.
	var ring_material := _make_emissive_material(Color(0.14, 0.92, 1.0, 0.18), Color(0.18, 1.0, 1.0), 0.18)
	for ring_index in range(5):
		var ring := MeshInstance3D.new()
		ring.name = "Magnetic Field Ring %d" % [ring_index + 1]
		var torus := TorusMesh.new()
		var ring_radius := 17.5 + ring_index * 2.2
		var ring_thickness := 0.06 + ring_index * 0.01
		torus.inner_radius = ring_radius
		torus.outer_radius = ring_radius + ring_thickness
		torus.ring_segments = 128
		torus.rings = 8
		ring.mesh = torus
		ring.material_override = ring_material.duplicate()
		ring.rotation_degrees = Vector3(65.0 + ring_index * 12.0, ring_index * 24.0, 25.0 + ring_index * 37.0)
		qoob_pivot.add_child(ring)
		field_rings.append(ring)

	qoob_light = OmniLight3D.new()
	qoob_light.name = "Qoob Low Frequency Pulse"
	qoob_light.light_color = Color(0.2, 0.95, 1.0)
	qoob_light.light_energy = 4.0
	qoob_light.omni_range = 82.0
	qoob_pivot.add_child(qoob_light)


func _build_set_dressing() -> void:
	var pylon_material := _make_emissive_material(Color(0.05, 0.04, 0.065, 1.0), Color(0.1, 0.55, 0.65), 0.08)

	# MVP placeholder: simple procedural obelisks stand in for hand-painted alien-industrial set dressing.
	for index in range(10):
		var angle := TAU * float(index) / 10.0
		var distance := 42.0 + (index % 2) * 9.0
		var pylon := MeshInstance3D.new()
		pylon.name = "Ritual Pylon %d" % [index + 1]
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.2, 6.0 + (index % 3), 1.2)
		pylon.mesh = mesh
		pylon.material_override = pylon_material
		pylon.position = Vector3(sin(angle) * distance, 3.0, cos(angle) * distance)
		pylon.rotation_degrees = Vector3(0.0, rad_to_deg(angle), 8.0 if index % 2 == 0 else -8.0)
		world_root.add_child(pylon)


func _build_motes() -> void:
	var mote_material := _make_emissive_material(Color(0.42, 0.9, 1.0, 0.62), Color(0.4, 0.95, 1.0), 0.62)

	for index in range(34):
		var mote := MeshInstance3D.new()
		mote.name = "Faint Field Particle %d" % [index + 1]
		var sphere := SphereMesh.new()
		sphere.radius = 0.075 + randf() * 0.05
		sphere.height = 0.15 + randf() * 0.08
		mote.mesh = sphere
		mote.material_override = mote_material
		world_root.add_child(mote)
		motes.append(mote)
		mote_data.append(Vector4(randf() * TAU, randf_range(18.0, 43.0), randf_range(2.0, 22.0), randf_range(0.18, 0.8)))


func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"
	add_child(ui_layer)

	title_screen = _build_title_screen()
	loading_screen = _build_loading_screen()
	hud_screen = _build_hud()
	game_over_screen = _build_game_over_screen()

	ui_layer.add_child(title_screen)
	ui_layer.add_child(loading_screen)
	ui_layer.add_child(hud_screen)
	ui_layer.add_child(game_over_screen)


func _build_title_screen() -> Control:
	var screen := Control.new()
	screen.name = "Title Screen"
	_full_rect(screen)

	var background := ColorRect.new()
	background.color = Color(0.014, 0.01, 0.024, 1.0)
	_full_rect(background)
	screen.add_child(background)

	var title := Label.new()
	title.text = "Qoob"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color(0.72, 1.0, 1.0))

	var hint := Label.new()
	hint.text = "Step toward the hovering intelligence. WASD, arrows, or screen clicks."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.82, 0.78, 0.9))

	var start_button := Button.new()
	start_button.text = "Start"
	start_button.custom_minimum_size = Vector2(240.0, 48.0)
	start_button.pressed.connect(_on_start_pressed)

	var quit_button := Button.new()
	quit_button.text = "Quit"
	quit_button.custom_minimum_size = Vector2(240.0, 48.0)
	quit_button.pressed.connect(_on_quit_pressed)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.anchor_left = 0.5
	box.anchor_top = 0.5
	box.anchor_right = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -300.0
	box.offset_top = -210.0
	box.offset_right = 300.0
	box.offset_bottom = 210.0
	box.add_theme_constant_override("separation", 18)
	box.add_child(title)
	box.add_child(hint)
	box.add_child(start_button)
	box.add_child(quit_button)
	screen.add_child(box)

	return screen


func _build_loading_screen() -> Control:
	var screen := Control.new()
	screen.name = "Loading Screen"
	_full_rect(screen)

	var background := ColorRect.new()
	background.color = Color(0.004, 0.004, 0.012, 1.0)
	_full_rect(background)
	screen.add_child(background)

	var label := Label.new()
	label.text = "The Qoob is noticing you..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(0.62, 0.96, 1.0))
	_full_rect(label)
	screen.add_child(label)

	return screen


func _build_hud() -> Control:
	var screen := Control.new()
	screen.name = "Gameplay HUD"
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_rect(screen)

	sky_overlay = ColorRect.new()
	sky_overlay.name = "Sky Darkening Overlay"
	sky_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	sky_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_rect(sky_overlay)
	screen.add_child(sky_overlay)

	lightning_holder = Control.new()
	lightning_holder.name = "Lightning Holder"
	lightning_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full_rect(lightning_holder)
	screen.add_child(lightning_holder)

	strike_label = Label.new()
	strike_label.name = "Strike Counter"
	strike_label.text = "Mistakes 0/3"
	strike_label.position = Vector2(24.0, 20.0)
	strike_label.add_theme_font_size_override("font_size", 18)
	strike_label.add_theme_color_override("font_color", Color(0.74, 0.93, 1.0, 0.86))
	strike_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(strike_label)

	feedback_label = Label.new()
	feedback_label.name = "Feedback Text"
	feedback_label.text = ""
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 46)
	feedback_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_label.visible = false
	_full_rect(feedback_label)
	screen.add_child(feedback_label)

	return screen


func _build_game_over_screen() -> Control:
	var screen := Control.new()
	screen.name = "Game Over Screen"
	_full_rect(screen)

	var background := ColorRect.new()
	background.color = Color(0.006, 0.0, 0.012, 0.93)
	_full_rect(background)
	screen.add_child(background)

	var title := Label.new()
	title.text = "Game Over"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.62))

	var verdict := Label.new()
	verdict.text = "Qoob says: That was foolish."
	verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	verdict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	verdict.add_theme_font_size_override("font_size", 26)
	verdict.add_theme_color_override("font_color", Color(0.82, 0.95, 1.0))

	var restart_button := Button.new()
	restart_button.text = "Restart"
	restart_button.custom_minimum_size = Vector2(260.0, 48.0)
	restart_button.pressed.connect(_on_restart_pressed)

	var title_button := Button.new()
	title_button.text = "Quit to Title"
	title_button.custom_minimum_size = Vector2(260.0, 48.0)
	title_button.pressed.connect(_on_return_to_title_pressed)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.anchor_left = 0.5
	box.anchor_top = 0.5
	box.anchor_right = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -320.0
	box.offset_top = -190.0
	box.offset_right = 320.0
	box.offset_bottom = 190.0
	box.add_theme_constant_override("separation", 18)
	box.add_child(title)
	box.add_child(verdict)
	box.add_child(restart_button)
	box.add_child(title_button)
	screen.add_child(box)

	return screen


func _build_audio() -> void:
	hum_player = AudioStreamPlayer.new()
	hum_player.name = "Qoob Hum Player"
	hum_player.volume_db = -11.0
	hum_player.stream = _load_audio(AUDIO_HUM, true)
	add_child(hum_player)

	effect_player = AudioStreamPlayer.new()
	effect_player.name = "Wrong Move Screech Player"
	effect_player.volume_db = -3.0
	effect_player.stream = _load_audio(AUDIO_SCREECH, false)
	add_child(effect_player)

	storm_player = AudioStreamPlayer.new()
	storm_player.name = "Lightning Storm Player"
	storm_player.volume_db = -5.0
	storm_player.stream = _load_audio(AUDIO_STORM, false)
	add_child(storm_player)

	success_player = AudioStreamPlayer.new()
	success_player.name = "Success Chime Player"
	success_player.volume_db = -4.0
	success_player.stream = _load_audio(AUDIO_SUCCESS, false)
	add_child(success_player)


func _load_audio(path: String, loop: bool) -> AudioStream:
	var stream := load(path)
	if stream == null:
		push_warning("Audio asset missing: %s" % path)
		return null

	if stream is AudioStreamWAV and loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	return stream


func _on_start_pressed() -> void:
	_start_loading_flow()


func _on_restart_pressed() -> void:
	session.reset_session()
	reset_player_view()
	show_gameplay()


func _on_return_to_title_pressed() -> void:
	session.reset_session()
	reset_player_view()
	show_title()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _start_loading_flow() -> void:
	screen_state = "loading"
	_show_only(loading_screen)
	world_root.visible = false
	await get_tree().create_timer(1.15).timeout
	session.reset_session()
	reset_player_view()
	show_gameplay()


func show_title() -> void:
	screen_state = "title"
	busy = false
	_show_only(title_screen)
	world_root.visible = false
	_stop_hum()


func show_gameplay() -> void:
	screen_state = "gameplay"
	busy = false
	world_root.visible = true
	_show_only(hud_screen)
	_clear_lightning()
	_set_overlay_alpha(0.0)
	feedback_label.visible = false
	_update_hud()
	_play_hum()


func show_game_over() -> void:
	screen_state = "game_over"
	busy = false
	world_root.visible = true
	_show_only(game_over_screen)
	_stop_hum()


func _show_only(screen: Control) -> void:
	title_screen.visible = screen == title_screen
	loading_screen.visible = screen == loading_screen
	hud_screen.visible = screen == hud_screen
	game_over_screen.visible = screen == game_over_screen


func _update_hud() -> void:
	if strike_label != null:
		strike_label.text = "Mistakes %d/3" % session.mistakes


func reset_player_view() -> void:
	orbit_angle = 0.0
	orbit_radius = START_RADIUS
	_update_player_camera()


func _update_player_camera() -> void:
	if camera == null:
		return

	camera.position = Vector3(sin(orbit_angle) * orbit_radius, PLAYER_HEIGHT, cos(orbit_angle) * orbit_radius)
	camera.look_at(QOOB_CENTER, Vector3.UP)


func _animate_step(move: String) -> void:
	var target_radius := orbit_radius
	var target_angle := orbit_angle

	match move:
		MoveInputScript.FORWARD:
			target_radius = max(36.0, orbit_radius - FORWARD_STEP)
		MoveInputScript.BACKWARD:
			target_radius = min(124.0, orbit_radius + BACKWARD_STEP)
		MoveInputScript.LEFT:
			target_angle = orbit_angle - STRAFE_STEP
		MoveInputScript.RIGHT:
			target_angle = orbit_angle + STRAFE_STEP

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "orbit_radius", target_radius, MOVE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "orbit_angle", target_angle, MOVE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _animate_to_qoob() -> void:
	var tween := create_tween()
	tween.tween_property(self, "orbit_radius", 31.5, 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _show_wrong_move_sequence() -> void:
	if effect_player.stream != null:
		effect_player.play()

	feedback_label.text = "Qoob hates that"
	feedback_label.visible = true
	await _tween_overlay_alpha(0.42, 0.16)
	await get_tree().create_timer(0.95).timeout
	reset_player_view()
	_update_hud()
	await _tween_overlay_alpha(0.0, 0.34)
	feedback_label.visible = false


func _show_final_failure_sequence() -> void:
	if effect_player.stream != null:
		effect_player.play()
	if storm_player.stream != null:
		storm_player.play()

	feedback_label.text = "Qoob says: That was foolish."
	feedback_label.visible = true
	await _tween_overlay_alpha(0.72, 0.18)
	_spawn_lightning_burst(9)
	await get_tree().create_timer(1.35).timeout
	feedback_label.visible = false
	show_game_over()


func _show_success_sequence() -> void:
	if success_player.stream != null:
		success_player.play()

	feedback_label.text = ":)\nNice!"
	feedback_label.visible = true
	await _tween_overlay_alpha(0.16, 0.18, Color(0.1, 0.42, 0.33, 0.0))
	await get_tree().create_timer(1.05).timeout
	reset_player_view()
	_update_hud()
	await _tween_overlay_alpha(0.0, 0.32, Color(0.1, 0.42, 0.33, 0.0))
	feedback_label.visible = false


func _spawn_lightning_burst(count: int) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	for index in range(count):
		var bolt := ColorRect.new()
		bolt.name = "Procedural Lightning Bolt"
		bolt.color = Color(0.72, 0.96, 1.0, 0.0)
		bolt.size = Vector2(randf_range(7.0, 18.0), randf_range(viewport_size.y * 0.45, viewport_size.y * 1.05))
		bolt.position = Vector2(randf_range(0.0, viewport_size.x), randf_range(-80.0, 60.0))
		bolt.rotation = randf_range(-0.32, 0.32)
		bolt.pivot_offset = Vector2(bolt.size.x * 0.5, 0.0)
		bolt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lightning_holder.add_child(bolt)

		var tween := create_tween()
		tween.tween_property(bolt, "color", Color(0.72, 0.96, 1.0, 0.9), 0.06)
		tween.tween_property(bolt, "color", Color(0.72, 0.96, 1.0, 0.0), 0.28)
		tween.tween_callback(bolt.queue_free)


func _clear_lightning() -> void:
	for child in lightning_holder.get_children():
		child.queue_free()


func _set_overlay_alpha(alpha: float, base_color: Color = Color(0.0, 0.0, 0.0, 0.0)) -> void:
	sky_overlay.color = Color(base_color.r, base_color.g, base_color.b, alpha)


func _tween_overlay_alpha(alpha: float, duration: float, base_color: Color = Color(0.0, 0.0, 0.0, 0.0)) -> void:
	var tween := create_tween()
	tween.tween_property(sky_overlay, "color", Color(base_color.r, base_color.g, base_color.b, alpha), duration)
	await tween.finished


func _play_hum() -> void:
	if hum_player.stream != null and not hum_player.playing:
		hum_player.play()


func _stop_hum() -> void:
	if hum_player != null and hum_player.playing:
		hum_player.stop()


func _update_qoob(delta: float) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	var pulse := (sin(time * 2.1) + 1.0) * 0.5

	qoob_pivot.position.y = 12.35 + sin(time * 1.17) * 0.28
	qoob_pivot.rotation.y += delta * 0.1

	if qoob_material != null:
		qoob_material.set_shader_parameter("pulse", pulse)

	if qoob_light != null:
		qoob_light.light_energy = 3.2 + pulse * 2.6 + randf_range(-0.08, 0.08)

	for index in range(field_rings.size()):
		var ring: MeshInstance3D = field_rings[index]
		ring.rotation.y += delta * (0.05 + index * 0.017)
		ring.rotation.x += delta * (0.021 + index * 0.006)


func _update_motes() -> void:
	var time := Time.get_ticks_msec() / 1000.0

	for index in range(motes.size()):
		var mote: MeshInstance3D = motes[index]
		var data: Vector4 = mote_data[index]
		var angle := data.x + time * data.w
		var radius := data.y + sin(time * 0.9 + data.x) * 1.7
		var height := data.z + sin(time * 1.4 + data.x * 2.0) * 0.8
		mote.position = Vector3(sin(angle) * radius, height, cos(angle) * radius)


func _make_qoob_shader_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.06, 0.03, 0.11, 1.0);
uniform vec4 vein_color : source_color = vec4(0.13, 0.95, 1.0, 1.0);
uniform vec4 hot_color : source_color = vec4(1.0, 0.75, 0.35, 1.0);
uniform float pulse = 0.0;

void fragment() {
	float grid_a = abs(sin(UV.x * 31.0 + TIME * 0.8));
	float grid_b = abs(sin(UV.y * 27.0 - TIME * 0.55));
	float glyph = smoothstep(0.92, 1.0, grid_a * grid_b);
	float slow = 0.5 + 0.5 * sin(TIME * 1.7 + UV.x * 4.0 - UV.y * 3.0);
	vec3 color = mix(base_color.rgb, vein_color.rgb, glyph * 0.65 + pulse * 0.18);
	color = mix(color, hot_color.rgb, glyph * slow * 0.22);
	ALBEDO = color;
	EMISSION = vein_color.rgb * (0.55 + pulse * 2.2 + glyph * 1.9) + hot_color.rgb * glyph * 0.28;
	ROUGHNESS = 0.42;
	METALLIC = 0.12;
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("pulse", 0.0)
	return material


func _make_ground_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.075, 0.056, 0.079)
	material.roughness = 0.92
	material.metallic = 0.0
	material.emission_enabled = true
	material.emission = Color(0.02, 0.05, 0.055)
	material.emission_energy_multiplier = 0.24
	return material


func _make_emissive_material(albedo: Color, emission: Color, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(albedo.r, albedo.g, albedo.b, alpha)
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = 1.3
	material.roughness = 0.55
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.no_depth_test = false
	return material


func _full_rect(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
