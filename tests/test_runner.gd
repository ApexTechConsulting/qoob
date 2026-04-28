extends SceneTree

const MazeGraphScript = preload("res://scripts/MazeGraph.gd")
const GameSessionScript = preload("res://scripts/GameSession.gd")
const MoveInputScript = preload("res://scripts/MoveInput.gd")

var failures: Array[String] = []


func _init() -> void:
	_run()
	quit(1 if failures.size() > 0 else 0)


func _run() -> void:
	_test_exactly_four_success_paths()
	_test_all_valid_paths_succeed()
	_test_invalid_move_fails()
	_test_wrong_move_strike_loop()
	_test_success_resets_player_and_mistakes()
	_test_wasd_input_mapping()
	_test_arrow_input_mapping()
	_test_mouse_region_mapping()

	if failures.is_empty():
		print("All Qoob tests passed.")
	else:
		for failure in failures:
			push_error(failure)


func _test_exactly_four_success_paths() -> void:
	var maze = MazeGraphScript.new()
	_expect_equal(maze.get_solution_paths().size(), 4, "Maze data defines exactly 4 documented paths.")
	_expect_equal(maze.count_success_paths(), 4, "Maze graph exposes exactly 4 paths to success.")


func _test_all_valid_paths_succeed() -> void:
	var maze = MazeGraphScript.new()
	for path in maze.get_solution_paths():
		var session = GameSessionScript.new(maze)
		var result := {}
		for move in path:
			result = session.apply_move(move)

		_expect_true(result["valid"], "Solution path final move is valid: %s" % [path])
		_expect_equal(result["outcome"], GameSessionScript.OUTCOME_SUCCESS, "Solution path succeeds: %s" % [path])
		_expect_equal(session.state, MazeGraphScript.START_STATE, "Success resets maze state.")
		_expect_equal(session.mistakes, 0, "Success resets mistake count.")


func _test_invalid_move_fails() -> void:
	var session = GameSessionScript.new()
	var result: Dictionary = session.apply_move(MazeGraphScript.MOVE_BACKWARD)
	_expect_equal(result["valid"], false, "Backward from start is invalid.")
	_expect_equal(result["outcome"], GameSessionScript.OUTCOME_WRONG_RESET, "First invalid move triggers wrong reset.")
	_expect_equal(session.state, MazeGraphScript.START_STATE, "Invalid move resets maze state.")
	_expect_equal(session.mistakes, 1, "Invalid move increments mistake count.")


func _test_wrong_move_strike_loop() -> void:
	var session = GameSessionScript.new()
	var first: Dictionary = session.apply_move(MazeGraphScript.MOVE_BACKWARD)
	var second: Dictionary = session.apply_move(MazeGraphScript.MOVE_BACKWARD)
	var third: Dictionary = session.apply_move(MazeGraphScript.MOVE_BACKWARD)

	_expect_equal(first["outcome"], GameSessionScript.OUTCOME_WRONG_RESET, "First wrong move resets.")
	_expect_equal(first["mistakes"], 1, "First wrong move count is 1.")
	_expect_equal(second["outcome"], GameSessionScript.OUTCOME_WRONG_RESET, "Second wrong move resets.")
	_expect_equal(second["mistakes"], 2, "Second wrong move count is 2.")
	_expect_equal(third["outcome"], GameSessionScript.OUTCOME_GAME_OVER, "Third wrong move triggers Game Over.")
	_expect_equal(third["mistakes"], 3, "Third wrong move count is 3.")
	_expect_equal(session.state, MazeGraphScript.START_STATE, "Game Over keeps maze position reset.")


func _test_success_resets_player_and_mistakes() -> void:
	var maze = MazeGraphScript.new()
	var session = GameSessionScript.new(maze)
	session.apply_move(MazeGraphScript.MOVE_BACKWARD)
	_expect_equal(session.mistakes, 1, "Precondition: session has one mistake.")

	var result := {}
	for move in maze.get_solution_paths()[0]:
		result = session.apply_move(move)

	_expect_equal(result["outcome"], GameSessionScript.OUTCOME_SUCCESS, "Valid path succeeds after prior mistake.")
	_expect_equal(session.state, MazeGraphScript.START_STATE, "Success returns player to start state.")
	_expect_equal(session.mistakes, 0, "Success clears mistake count.")


func _test_wasd_input_mapping() -> void:
	_expect_equal(MoveInputScript.from_keycode(KEY_W), MoveInputScript.FORWARD, "W maps to forward.")
	_expect_equal(MoveInputScript.from_keycode(KEY_A), MoveInputScript.LEFT, "A maps to strafe left.")
	_expect_equal(MoveInputScript.from_keycode(KEY_S), MoveInputScript.BACKWARD, "S maps to backward.")
	_expect_equal(MoveInputScript.from_keycode(KEY_D), MoveInputScript.RIGHT, "D maps to strafe right.")


func _test_arrow_input_mapping() -> void:
	_expect_equal(MoveInputScript.from_keycode(KEY_UP), MoveInputScript.FORWARD, "Up arrow maps to forward.")
	_expect_equal(MoveInputScript.from_keycode(KEY_LEFT), MoveInputScript.LEFT, "Left arrow maps to strafe left.")
	_expect_equal(MoveInputScript.from_keycode(KEY_DOWN), MoveInputScript.BACKWARD, "Down arrow maps to backward.")
	_expect_equal(MoveInputScript.from_keycode(KEY_RIGHT), MoveInputScript.RIGHT, "Right arrow maps to strafe right.")


func _test_mouse_region_mapping() -> void:
	var size := Vector2(1000.0, 1000.0)
	_expect_equal(MoveInputScript.from_mouse_position(Vector2(500.0, 120.0), size), MoveInputScript.FORWARD, "Upper-center click maps to forward.")
	_expect_equal(MoveInputScript.from_mouse_position(Vector2(40.0, 320.0), size), MoveInputScript.LEFT, "Left-side click maps to strafe left.")
	_expect_equal(MoveInputScript.from_mouse_position(Vector2(920.0, 320.0), size), MoveInputScript.RIGHT, "Right-side click maps to strafe right.")
	_expect_equal(MoveInputScript.from_mouse_position(Vector2(500.0, 900.0), size), MoveInputScript.BACKWARD, "Bottom click maps to backward.")


func _expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s Expected %s but got %s." % [message, str(expected), str(actual)])

