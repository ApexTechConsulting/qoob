extends Node

const GameSessionScript = preload("res://scripts/GameSession.gd")
const MoveInputScript = preload("res://scripts/MoveInput.gd")

const START_RADIUS := 100.0
const PLAYER_HEIGHT := 3.2
const QOOB_CENTER := Vector3(0.0, 13.0, 0.0)
const QOOB_LOOK_TARGET := Vector3(0.0, 7.6, 0.0)
const FORWARD_STEP := 11.0
const BACKWARD_STEP := 8.0
const STRAFE_STEP := 0.244346
const MOVE_TIME := 0.52
const MAZE_Y := 0.09
const MAZE_WIDTH := 1.15

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
var maze_segments: Array = []
var spectral_segments: Array = []
var prism_shards: Array = []
var concrete_blocks: Array = []

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
	base_environment.background_color = Color(0.52, 0.68, 0.78)
	base_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	base_environment.ambient_light_color = Color(0.62, 0.72, 0.78)
	base_environment.ambient_light_energy = 1.05
	base_environment.fog_enabled = true
	base_environment.fog_density = 0.011
	base_environment.fog_light_color = Color(0.58, 0.68, 0.72)

	environment_node = WorldEnvironment.new()
	environment_node.environment = base_environment
	world_root.add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.name = "Soft Sky Key Sun"
	sun.light_color = Color(0.82, 0.9, 1.0)
	sun.light_energy = 0.82
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-42.0, 38.0, 0.0)
	world_root.add_child(sun)

	_build_dome_fill_lights()
	_build_cloud_deck()

	var ground := MeshInstance3D.new()
	ground.name = "Barren Otherworldly Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(300.0, 300.0)
	ground.mesh = plane
	ground.material_override = _make_ground_material()
	world_root.add_child(ground)

	_build_visible_maze()
	_build_qoob()
	_build_set_dressing()
	_build_motes()

	camera = Camera3D.new()
	camera.name = "First Person Step Camera"
	camera.current = true
	camera.fov = 78.0
	camera.near = 0.05
	camera.far = 420.0
	world_root.add_child(camera)


func _build_dome_fill_lights() -> void:
	var directions := [
		Vector3(-0.7, -1.0, -0.2),
		Vector3(0.65, -1.0, -0.45),
		Vector3(-0.18, -1.0, 0.8),
		Vector3(0.38, -1.0, 0.72),
		Vector3(-0.92, -0.58, 0.28),
		Vector3(0.86, -0.62, 0.18),
	]
	var colors := [
		Color(0.62, 0.72, 0.82),
		Color(0.54, 0.65, 0.76),
		Color(0.72, 0.76, 0.72),
		Color(0.58, 0.7, 0.78),
		Color(0.42, 0.52, 0.64),
		Color(0.48, 0.58, 0.68),
	]

	for index in range(directions.size()):
		var light := DirectionalLight3D.new()
		light.name = "Concrete Dome Fill %d" % [index + 1]
		light.light_color = colors[index]
		light.light_energy = 0.14
		light.shadow_enabled = true
		light.look_at_from_position(-directions[index] * 10.0, Vector3.ZERO, Vector3.UP)
		world_root.add_child(light)


func _build_cloud_deck() -> void:
	var cloud_material := _make_additive_material(Color(0.92, 0.96, 1.0, 0.12), Color(0.8, 0.88, 0.94), 0.24)
	cloud_material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX

	for index in range(12):
		var cloud := MeshInstance3D.new()
		cloud.name = "Soft Sky Cloud Bank %d" % [index + 1]
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(54.0 + (index % 4) * 18.0, 16.0 + (index % 3) * 10.0)
		cloud.mesh = mesh
		cloud.material_override = cloud_material.duplicate()
		var angle := TAU * float(index) / 12.0
		var radius := 118.0 + (index % 3) * 18.0
		cloud.position = Vector3(sin(angle) * radius, 48.0 + (index % 5) * 7.0, cos(angle) * radius)
		cloud.rotation_degrees = Vector3(-82.0, rad_to_deg(angle) + 90.0, randf_range(-8.0, 8.0))
		world_root.add_child(cloud)


func _build_qoob() -> void:
	qoob_pivot = Node3D.new()
	qoob_pivot.name = "Qoob"
	qoob_pivot.position = Vector3(0.0, 12.35, 0.0)
	world_root.add_child(qoob_pivot)

	var cube := MeshInstance3D.new()
	cube.name = "Monstrously Large Spectral Alien Cube"
	var cube_mesh := BoxMesh.new()
	cube_mesh.size = Vector3(24.0, 24.0, 24.0)
	cube.mesh = cube_mesh
	qoob_material = _make_qoob_shader_material()
	cube.material_override = qoob_material
	qoob_pivot.add_child(cube)

	_build_qoob_edges()

	var ring_material := _make_additive_material(Color(0.24, 0.72, 1.0, 0.18), Color(0.18, 0.52, 0.85), 0.85, false)
	for ring_index in range(6):
		var ring := MeshInstance3D.new()
		ring.name = "Quiet Magnetic Field Ring %d" % [ring_index + 1]
		var torus := TorusMesh.new()
		var ring_radius := 17.0 + ring_index * 2.2
		var ring_thickness := 0.035 + ring_index * 0.004
		torus.inner_radius = ring_radius
		torus.outer_radius = ring_radius + ring_thickness
		torus.ring_segments = 192
		torus.rings = 8
		ring.mesh = torus
		ring.material_override = ring_material.duplicate()
		ring.rotation_degrees = Vector3(61.0 + ring_index * 8.0, ring_index * 24.0, 18.0 + ring_index * 29.0)
		qoob_pivot.add_child(ring)
		field_rings.append(ring)

	qoob_light = OmniLight3D.new()
	qoob_light.name = "Qoob Electric Interior Pulse"
	qoob_light.light_color = Color(0.22, 0.68, 1.0)
	qoob_light.light_energy = 2.2
	qoob_light.omni_range = 70.0
	qoob_pivot.add_child(qoob_light)


func _build_qoob_edges() -> void:
	var edge_material := _make_additive_material(Color(0.18, 0.58, 0.9, 0.5), Color(0.14, 0.48, 0.82), 1.6, true)
	var red_fringe := _make_additive_material(Color(0.8, 0.34, 0.18, 0.12), Color(0.75, 0.28, 0.16), 0.7)
	var blue_fringe := _make_additive_material(Color(0.1, 0.35, 1.0, 0.18), Color(0.1, 0.38, 0.9), 0.9)
	var h := 12.08
	var corners := [
		Vector3(-h, -h, -h), Vector3(h, -h, -h), Vector3(h, -h, h), Vector3(-h, -h, h),
		Vector3(-h, h, -h), Vector3(h, h, -h), Vector3(h, h, h), Vector3(-h, h, h),
	]
	var edges := [
		[0, 1], [1, 2], [2, 3], [3, 0],
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7],
	]

	for edge in edges:
		_add_box_line(qoob_pivot, corners[edge[0]], corners[edge[1]], 0.13, edge_material, "Qoob white edge")
		_add_box_line(qoob_pivot, corners[edge[0]] + Vector3(0.16, 0.0, 0.0), corners[edge[1]] + Vector3(0.16, 0.0, 0.0), 0.045, red_fringe, "Qoob red fringe")
		_add_box_line(qoob_pivot, corners[edge[0]] + Vector3(-0.16, 0.0, 0.0), corners[edge[1]] + Vector3(-0.16, 0.0, 0.0), 0.045, blue_fringe, "Qoob blue fringe")


func _build_prism_shards() -> void:
	var shard_material := _make_additive_material(Color(0.9, 0.98, 1.0, 0.14), Color(0.9, 0.98, 1.0), 1.15)
	var shard_sets := [
		[Vector3(-13.0, -4.5, 3.0), Vector3(0.0, 13.5, -8.0), Vector3(12.0, -3.0, 6.0)],
		[Vector3(-10.0, 7.0, -12.0), Vector3(12.0, 11.0, -3.0), Vector3(6.0, -11.0, 8.0)],
		[Vector3(-15.5, -9.0, -2.0), Vector3(-2.0, 5.0, 13.0), Vector3(11.5, -8.0, -7.0)],
		[Vector3(0.0, -12.0, -13.0), Vector3(13.0, 0.0, 0.0), Vector3(-2.0, 12.0, 11.0)],
	]

	for index in range(shard_sets.size()):
		var shard := MeshInstance3D.new()
		shard.name = "Transparent Particle Prism Shard %d" % [index + 1]
		shard.mesh = _make_triangle_mesh(shard_sets[index][0], shard_sets[index][1], shard_sets[index][2])
		shard.material_override = shard_material.duplicate()
		qoob_pivot.add_child(shard)
		prism_shards.append(shard)


func _build_spectral_ribbons() -> void:
	var white := _make_additive_material(Color(0.95, 0.98, 1.0, 0.38), Color(0.95, 0.98, 1.0), 2.5)
	var blue := _make_additive_material(Color(0.18, 0.54, 1.0, 0.18), Color(0.2, 0.58, 1.0), 1.75)
	var amber := _make_additive_material(Color(1.0, 0.46, 0.1, 0.14), Color(1.0, 0.36, 0.08), 1.55)

	for ribbon_index in range(7):
		var previous := Vector3.ZERO
		var has_previous := false
		var points := 76
		for point_index in range(points):
			var t := float(point_index) / float(points - 1)
			var sweep := -1.2 + t * 2.4
			var angle := t * TAU * (0.7 + ribbon_index * 0.09) + ribbon_index * 0.82
			var radius := 14.5 + sin(t * TAU * 2.0 + ribbon_index) * 2.8
			var point := Vector3(
				sin(angle) * radius,
				sin(sweep) * 12.0 + sin(t * TAU * 3.0 + ribbon_index) * 1.1,
				cos(angle * 0.72 + ribbon_index) * radius * 0.72
			)
			if has_previous:
				_add_box_line(qoob_pivot, previous, point, 0.055, white, "Qoob spectral white ribbon")
				if ribbon_index % 2 == 0:
					_add_box_line(qoob_pivot, previous + Vector3(0.18, 0.0, 0.0), point + Vector3(0.18, 0.0, 0.0), 0.025, blue, "Qoob spectral blue fringe")
				else:
					_add_box_line(qoob_pivot, previous + Vector3(-0.16, 0.0, 0.0), point + Vector3(-0.16, 0.0, 0.0), 0.025, amber, "Qoob spectral amber fringe")
			previous = point
			has_previous = true


func _build_spectral_beams() -> void:
	var white := _make_additive_material(Color(0.92, 0.98, 1.0, 0.2), Color(0.92, 0.98, 1.0), 1.6)
	var cyan := _make_additive_material(Color(0.12, 0.46, 1.0, 0.15), Color(0.12, 0.46, 1.0), 1.3)
	var amber := _make_additive_material(Color(1.0, 0.34, 0.08, 0.14), Color(1.0, 0.34, 0.08), 1.25)
	var beams := [
		[Vector3(-132.0, 30.0, 78.0), Vector3(128.0, 1.6, -72.0), white, 0.42],
		[Vector3(-132.0, 31.2, 79.2), Vector3(128.0, 2.4, -70.4), cyan, 0.24],
		[Vector3(-132.0, 28.8, 76.4), Vector3(128.0, 0.7, -74.2), amber, 0.22],
		[Vector3(-92.0, 4.2, 116.0), Vector3(82.0, 24.0, -96.0), white, 0.18],
	]

	for beam in beams:
		var segment := _add_box_line(world_root, beam[0], beam[1], beam[3], beam[2], "Prismatic reference beam")
		spectral_segments.append(segment)


func _build_visible_maze() -> void:
	var maze_root := Node3D.new()
	maze_root.name = "Visible Ground Maze"
	world_root.add_child(maze_root)

	var path_colors := [
		Color(0.88, 0.94, 0.96, 0.58),
		Color(0.48, 0.68, 0.82, 0.52),
		Color(0.78, 0.68, 0.52, 0.48),
		Color(0.58, 0.64, 0.78, 0.5),
	]
	var paths: Array = session.maze.get_solution_paths()

	for path_index in range(paths.size()):
		var color: Color = path_colors[path_index]
		var trace_material := _make_additive_material(color, Color(color.r, color.g, color.b), 0.7)
		var node_material := _make_additive_material(Color(color.r, color.g, color.b, 0.28), Color(color.r, color.g, color.b), 0.45)
		var arrow_material := _make_additive_material(Color(0.92, 0.96, 0.96, 0.54), Color(color.r, color.g, color.b), 0.8)
		var radius := START_RADIUS
		var angle := 0.0
		var start_pos := _orbit_position(radius, angle, MAZE_Y)
		_add_ground_node(maze_root, start_pos, node_material, "Maze start node")

		var path: Array = paths[path_index]
		for move_index in range(path.size()):
			var move: String = path[move_index]
			var next_radius := radius
			var next_angle := angle
			match move:
				MoveInputScript.FORWARD:
					next_radius = max(36.0, radius - FORWARD_STEP)
				MoveInputScript.BACKWARD:
					next_radius = min(124.0, radius + BACKWARD_STEP)
				MoveInputScript.LEFT:
					next_angle = angle - STRAFE_STEP
				MoveInputScript.RIGHT:
					next_angle = angle + STRAFE_STEP

			var a := _orbit_position(radius, angle, MAZE_Y)
			var b := _orbit_position(next_radius, next_angle, MAZE_Y)
			if is_equal_approx(radius, next_radius):
				_add_ground_arc(maze_root, radius, angle, next_angle, trace_material, "%s trace" % move)
			else:
				maze_segments.append(_add_box_line(maze_root, a, b, MAZE_WIDTH, trace_material, "%s trace" % move))

			var direction := (b - a).normalized()
			_add_ground_arrow(maze_root, a.lerp(b, 0.58), direction, arrow_material, "Maze direction arrow")
			_add_step_label(maze_root, move, a.lerp(b, 0.43), direction, Color(color.r, color.g, color.b, 0.92))
			_add_ground_node(maze_root, b, node_material, "Maze step node")

			radius = next_radius
			angle = next_angle


func _add_ground_arc(parent: Node3D, radius: float, start_angle: float, end_angle: float, material: Material, name: String) -> void:
	var slices := 10
	var previous := _orbit_position(radius, start_angle, MAZE_Y)
	for index in range(1, slices + 1):
		var t := float(index) / float(slices)
		var angle := lerpf(start_angle, end_angle, t)
		var current := _orbit_position(radius, angle, MAZE_Y)
		maze_segments.append(_add_box_line(parent, previous, current, MAZE_WIDTH, material, name))
		previous = current


func _add_ground_node(parent: Node3D, position: Vector3, material: Material, name: String) -> void:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.45
	mesh.bottom_radius = 1.45
	mesh.height = 0.035
	mesh.radial_segments = 44
	node.mesh = mesh
	node.material_override = material
	node.position = Vector3(position.x, MAZE_Y + 0.02, position.z)
	parent.add_child(node)
	maze_segments.append(node)


func _add_ground_arrow(parent: Node3D, position: Vector3, direction: Vector3, material: Material, name: String) -> void:
	var flat_direction := Vector3(direction.x, 0.0, direction.z).normalized()
	if flat_direction.length_squared() <= 0.001:
		return

	var right := Vector3(flat_direction.z, 0.0, -flat_direction.x)
	var tip := position + flat_direction * 1.55
	var left := position - flat_direction * 0.92 + right * 0.78
	var right_point := position - flat_direction * 0.92 - right * 0.78
	var arrow := MeshInstance3D.new()
	arrow.name = name
	arrow.mesh = _make_triangle_mesh(
		Vector3(tip.x, MAZE_Y + 0.08, tip.z),
		Vector3(left.x, MAZE_Y + 0.08, left.z),
		Vector3(right_point.x, MAZE_Y + 0.08, right_point.z)
	)
	arrow.material_override = material
	parent.add_child(arrow)
	maze_segments.append(arrow)


func _add_step_label(parent: Node3D, text: String, position: Vector3, direction: Vector3, color: Color) -> void:
	var flat_direction := Vector3(direction.x, 0.0, direction.z).normalized()
	if flat_direction.length_squared() <= 0.001:
		return

	var label := Label3D.new()
	label.name = "Ground Move Glyph %s" % text
	label.text = text
	label.font_size = 96
	label.pixel_size = 0.032
	label.modulate = color
	label.outline_size = 10
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector3(position.x, MAZE_Y + 0.13, position.z)
	label.rotation = Vector3(deg_to_rad(-90.0), atan2(flat_direction.x, flat_direction.z), 0.0)
	parent.add_child(label)


func _build_set_dressing() -> void:
	var concrete := _make_concrete_material(Color(0.46, 0.53, 0.56), 1.0)
	var dark_concrete := _make_concrete_material(Color(0.29, 0.35, 0.38), 1.0)

	# Procedural original "cubespew" architecture: matte concrete block stacks inspired by the reference's sky-lit austerity.
	var clusters := [
		{"angle": -0.82, "radius": 52.0, "height": 26.0, "count": 62},
		{"angle": 0.74, "radius": 57.0, "height": 31.0, "count": 58},
		{"angle": 1.72, "radius": 76.0, "height": 22.0, "count": 44},
		{"angle": -1.74, "radius": 82.0, "height": 28.0, "count": 48},
	]

	for cluster_index in range(clusters.size()):
		var cluster: Dictionary = clusters[cluster_index]
		_build_concrete_cluster(
			float(cluster["angle"]),
			float(cluster["radius"]),
			float(cluster["height"]),
			int(cluster["count"]),
			concrete,
			dark_concrete,
			cluster_index
		)

	_build_concrete_bridge(-0.82, 0.74, 58.0, 24.0, concrete, dark_concrete, "North Sky Bridge")
	_build_concrete_bridge(1.72, 0.74, 72.0, 18.0, concrete, dark_concrete, "East Sky Bridge")
	_build_concrete_bridge(-1.74, -0.82, 72.0, 20.0, concrete, dark_concrete, "West Sky Bridge")

	for index in range(22):
		var angle := TAU * float(index) / 22.0 + 0.09
		var radius := 70.0 + (index % 4) * 13.0
		var size := Vector3(2.2 + (index % 3) * 0.8, 2.0 + (index % 5) * 0.65, 2.2 + (index % 4) * 0.7)
		var height := 10.0 + (index % 8) * 2.8
		_add_concrete_block(
			world_root,
			Vector3(sin(angle) * radius, height, cos(angle) * radius),
			size,
			Vector3(0.0, angle + randf_range(-0.08, 0.08), 0.0),
			concrete,
			"Detached Concrete Floater"
		)


func _build_concrete_cluster(angle: float, radius: float, height: float, count: int, concrete: Material, dark_concrete: Material, cluster_index: int) -> void:
	var center := Vector3(sin(angle) * radius, 0.0, cos(angle) * radius)
	var tangent := Vector3(cos(angle), 0.0, -sin(angle)).normalized()
	var radial := Vector3(sin(angle), 0.0, cos(angle)).normalized()

	_add_concrete_block(
		world_root,
		center + Vector3(0.0, height * 0.48, 0.0),
		Vector3(8.5, height, 9.2),
		Vector3(0.0, angle, 0.0),
		dark_concrete,
		"Concrete Megastructure Core"
	)

	for index in range(count):
		var layer := index % 9
		var side := -1.0 if index % 2 == 0 else 1.0
		var outward := -1.0 if index % 5 == 0 else 1.0
		var local_x := tangent * (side * (4.4 + float(layer % 4) * 2.2 + randf_range(-0.4, 0.4)))
		var local_z := radial * (outward * (4.2 + float((index + cluster_index) % 5) * 1.7))
		var y := 3.0 + float((index * 5 + cluster_index * 3) % 15) * 1.9
		var size := Vector3(
			2.0 + float((index + 1) % 5) * 0.9,
			1.4 + float((index + 2) % 4) * 0.85,
			2.0 + float((index + 3) % 5) * 0.9
		)
		var mat := concrete if index % 4 != 0 else dark_concrete
		_add_concrete_block(
			world_root,
			center + local_x + local_z + Vector3(0.0, y, 0.0),
			size,
			Vector3(0.0, angle + randf_range(-0.035, 0.035), 0.0),
			mat,
			"Offset Concrete Cubespew"
		)

	for column_index in range(4):
		var offset := tangent * (-8.0 + column_index * 5.3) + radial * randf_range(-2.0, 2.0)
		_add_concrete_block(
			world_root,
			center + offset + Vector3(0.0, 8.0, 0.0),
			Vector3(2.2, 16.0 + column_index * 2.5, 2.2),
			Vector3(0.0, angle, 0.0),
			dark_concrete,
			"Slender Concrete Support"
		)


func _build_concrete_bridge(from_angle: float, to_angle: float, radius: float, height: float, concrete: Material, dark_concrete: Material, label: String) -> void:
	var from := Vector3(sin(from_angle) * radius, height, cos(from_angle) * radius)
	var to := Vector3(sin(to_angle) * radius, height + 1.5, cos(to_angle) * radius)
	var direction := to - from
	var length := direction.length()
	var bridge := _add_box_line(world_root, from, to, 5.2, concrete, label)
	bridge.scale.y = 0.42
	concrete_blocks.append(bridge)

	var steps := maxi(4, int(length / 8.0))
	for index in range(steps):
		var t := float(index) / float(maxi(1, steps - 1))
		var pos := from.lerp(to, t)
		var mat := dark_concrete if index % 3 == 0 else concrete
		_add_concrete_block(
			world_root,
			pos + Vector3(0.0, -2.2 - float(index % 2) * 0.8, 0.0),
			Vector3(6.2, 1.1, 3.0 + float(index % 3)),
			Vector3(0.0, atan2(direction.x, direction.z), 0.0),
			mat,
			"Bridge Underside Block"
		)


func _add_concrete_block(parent: Node3D, position: Vector3, size: Vector3, rotation: Vector3, material: Material, name: String) -> MeshInstance3D:
	var block := MeshInstance3D.new()
	block.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	block.mesh = mesh
	block.material_override = material.duplicate() if material != null else null
	block.position = position
	block.rotation = rotation
	parent.add_child(block)
	concrete_blocks.append(block)

	var edge_material := _make_emissive_material(Color(0.12, 0.15, 0.16, 0.55), Color(0.02, 0.025, 0.03), 0.55)
	var lip_count := 2 + int(abs(int(position.x + position.z)) % 3)
	for lip_index in range(lip_count):
		var lip := MeshInstance3D.new()
		lip.name = "Concrete Dirty Edge"
		var lip_mesh := BoxMesh.new()
		lip_mesh.size = Vector3(size.x * randf_range(0.55, 1.0), 0.08, 0.11)
		lip.mesh = lip_mesh
		lip.material_override = edge_material
		lip.position = position + Vector3(randf_range(-size.x * 0.2, size.x * 0.2), size.y * 0.5 + 0.045, randf_range(-size.z * 0.5, size.z * 0.5))
		lip.rotation = rotation
		parent.add_child(lip)
	return block


func _build_motes() -> void:
	var mote_material := _make_additive_material(Color(0.72, 0.8, 0.84, 0.18), Color(0.58, 0.66, 0.72), 0.28)

	for index in range(70):
		var mote := MeshInstance3D.new()
		mote.name = "Concrete Sky Dust %d" % [index + 1]
		var sphere := SphereMesh.new()
		sphere.radius = 0.035 + randf() * 0.045
		sphere.height = sphere.radius * 2.0
		mote.mesh = sphere
		mote.material_override = mote_material.duplicate()
		world_root.add_child(mote)
		motes.append(mote)
		mote_data.append(Vector4(randf() * TAU, randf_range(16.0, 96.0), randf_range(4.0, 38.0), randf_range(0.04, 0.22)))


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
	background.color = Color(0.38, 0.5, 0.58, 1.0)
	_full_rect(background)
	screen.add_child(background)

	var beam_colors := [Color(0.9, 0.94, 0.96, 0.24), Color(0.2, 0.28, 0.34, 0.16), Color(0.72, 0.78, 0.78, 0.14)]
	for index in range(beam_colors.size()):
		var beam := ColorRect.new()
		beam.name = "Title Spectral Beam %d" % [index + 1]
		beam.color = beam_colors[index]
		beam.anchor_left = -0.18
		beam.anchor_top = 0.47 + index * 0.018
		beam.anchor_right = 1.22
		beam.anchor_bottom = 0.495 + index * 0.018
		beam.rotation = deg_to_rad(-26.0)
		screen.add_child(beam)

	var title := Label.new()
	title.text = "Qoob"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color(0.94, 0.96, 0.94))

	var hint := Label.new()
	hint.text = "Follow the concrete ground paths. WASD, arrows, or screen clicks."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.86, 0.9, 0.88))

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
	background.color = Color(0.34, 0.46, 0.54, 1.0)
	_full_rect(background)
	screen.add_child(background)

	var label := Label.new()
	label.text = "The concrete sky is waking..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(0.92, 0.95, 0.94))
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
	strike_label.add_theme_color_override("font_color", Color(0.9, 0.97, 1.0, 0.88))
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
	background.color = Color(0.05, 0.065, 0.075, 0.94)
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
	hum_player.volume_db = -13.0
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
	_play_hum(-13.0)


func show_gameplay() -> void:
	screen_state = "gameplay"
	busy = false
	world_root.visible = true
	_show_only(hud_screen)
	_clear_lightning()
	_set_overlay_alpha(0.0)
	feedback_label.visible = false
	_update_hud()
	_play_hum(-2.5)


func show_game_over() -> void:
	screen_state = "game_over"
	busy = false
	world_root.visible = true
	_show_only(game_over_screen)
	_play_hum(-7.0)


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
	camera.look_at(QOOB_LOOK_TARGET, Vector3.UP)


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


func _play_hum(volume_db: float = -2.5) -> void:
	if hum_player == null:
		return

	hum_player.volume_db = volume_db
	if hum_player.stream != null and not hum_player.playing:
		hum_player.play()


func _stop_hum() -> void:
	if hum_player != null and hum_player.playing:
		hum_player.stop()


func _update_qoob(delta: float) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	var pulse := (sin(time * 1.65) + 1.0) * 0.5
	var twitch := (sin(time * 17.0) + sin(time * 23.0 + 0.7)) * 0.025

	qoob_pivot.position.y = 12.35 + sin(time * 0.88) * 0.34 + twitch
	qoob_pivot.rotation.y += delta * 0.075
	qoob_pivot.rotation.x = sin(time * 0.22) * 0.035
	qoob_pivot.rotation.z = sin(time * 0.19 + 1.2) * 0.028

	if qoob_material != null:
		qoob_material.set_shader_parameter("pulse", pulse)

	if qoob_light != null:
		qoob_light.light_energy = 4.7 + pulse * 4.8 + randf_range(-0.16, 0.16)

	for index in range(field_rings.size()):
		var ring: MeshInstance3D = field_rings[index]
		ring.rotation.y += delta * (0.035 + index * 0.014)
		ring.rotation.x += delta * (0.018 + index * 0.005)
		ring.scale = Vector3.ONE * (1.0 + sin(time * 1.2 + index) * 0.018)

	for index in range(prism_shards.size()):
		var shard: MeshInstance3D = prism_shards[index]
		shard.rotation.y += delta * (0.08 + index * 0.02)
		shard.rotation.z += delta * (0.025 + index * 0.01)


func _update_motes() -> void:
	var time := Time.get_ticks_msec() / 1000.0

	for index in range(motes.size()):
		var mote: MeshInstance3D = motes[index]
		var data: Vector4 = mote_data[index]
		var angle := data.x + time * data.w
		var radius := data.y + sin(time * 0.55 + data.x) * 2.3
		var height := data.z + sin(time * 1.1 + data.x * 2.0) * 1.2
		var skew := sin(time * 0.22 + data.x) * 10.0
		mote.position = Vector3(sin(angle) * radius + skew, height, cos(angle * 0.86) * radius)


func _orbit_position(radius: float, angle: float, y: float) -> Vector3:
	return Vector3(sin(angle) * radius, y, cos(angle) * radius)


func _add_box_line(parent: Node3D, a: Vector3, b: Vector3, width: float, material: Material, name: String) -> MeshInstance3D:
	var direction := b - a
	var length := direction.length()
	var segment := MeshInstance3D.new()
	segment.name = name
	if length <= 0.001:
		return segment

	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, width, length)
	segment.mesh = mesh
	segment.material_override = material
	segment.position = a.lerp(b, 0.5)
	var forward := direction.normalized()
	var up := Vector3.UP if abs(forward.dot(Vector3.UP)) < 0.96 else Vector3.FORWARD
	segment.basis = Basis.looking_at(forward, up)
	parent.add_child(segment)
	return segment


func _make_triangle_mesh(a: Vector3, b: Vector3, c: Vector3) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([a, b, c])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _make_qoob_shader_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.018, 0.024, 0.028, 1.0);
uniform vec4 vein_color : source_color = vec4(0.12, 0.55, 0.92, 1.0);
uniform vec4 blue_fringe : source_color = vec4(0.08, 0.36, 0.72, 1.0);
uniform vec4 red_fringe : source_color = vec4(0.58, 0.18, 0.08, 1.0);
uniform float pulse = 0.0;

void fragment() {
	float razor_x = smoothstep(0.972, 1.0, abs(sin(UV.x * 38.0 + TIME * 0.7)));
	float razor_y = smoothstep(0.965, 1.0, abs(sin(UV.y * 35.0 - TIME * 0.53)));
	float dust = smoothstep(0.6, 1.0, fract(sin(dot(UV * 240.0 + TIME, vec2(12.9898, 78.233))) * 43758.5453));
	float veil = smoothstep(0.78, 1.0, razor_x + razor_y * 0.85) * (0.7 + dust * 0.3);
	float diagonal = smoothstep(0.955, 1.0, abs(sin((UV.x + UV.y) * 19.0 + TIME * 0.42)));
	float chroma = sin((UV.x - UV.y) * 16.0 + TIME * 1.1) * 0.5 + 0.5;
	vec3 fringe = mix(red_fringe.rgb, blue_fringe.rgb, chroma);
	vec3 color = mix(base_color.rgb, vein_color.rgb, veil * 0.65 + pulse * 0.08);
	color = mix(color, fringe, diagonal * 0.22);
	ALBEDO = color;
	EMISSION = vein_color.rgb * (0.18 + pulse * 0.85 + veil * 1.15) + fringe * diagonal * 0.42;
	ROUGHNESS = 0.72;
	METALLIC = 0.06;
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("pulse", 0.0)
	return material


func _make_ground_material() -> Material:
	return _make_concrete_material(Color(0.58, 0.62, 0.61), 1.0)


func _make_concrete_material(base: Color, alpha: float = 1.0) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.55, 0.58, 0.57, 1.0);
uniform float stain_strength = 0.22;

void fragment() {
	vec2 uv = UV * 5.0;
	float grain_a = fract(sin(dot(floor(uv * 18.0), vec2(12.9898, 78.233))) * 43758.5453);
	float grain_b = fract(sin(dot(floor(uv * 47.0), vec2(39.346, 11.135))) * 17312.123);
	float seam_x = smoothstep(0.965, 0.99, abs(sin(UV.x * 18.8495)));
	float seam_y = smoothstep(0.965, 0.99, abs(sin(UV.y * 18.8495)));
	float edge_dirty = max(seam_x, seam_y);
	vec3 concrete = base_color.rgb * (0.82 + grain_a * 0.18);
	concrete = mix(concrete, concrete * 0.55, edge_dirty * stain_strength);
	concrete += (grain_b - 0.5) * 0.045;
	ALBEDO = concrete;
	ROUGHNESS = 0.96;
	METALLIC = 0.0;
	AO = 0.78 - edge_dirty * 0.18;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("base_color", Color(base.r, base.g, base.b, alpha))
	material.set_shader_parameter("stain_strength", 0.28)
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


func _make_additive_material(albedo: Color, emission: Color, energy: float, no_depth_test: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	material.no_depth_test = no_depth_test
	material.disable_receive_shadows = true
	return material


func _full_rect(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
