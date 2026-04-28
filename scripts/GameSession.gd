class_name GameSession
extends RefCounted

const MazeGraphScript = preload("res://scripts/MazeGraph.gd")

const OUTCOME_PROGRESS := "progress"
const OUTCOME_SUCCESS := "success"
const OUTCOME_WRONG_RESET := "wrong_reset"
const OUTCOME_GAME_OVER := "game_over"

var maze
var state := MazeGraphScript.START_STATE
var mistakes := 0


func _init(graph = null) -> void:
	maze = graph if graph != null else MazeGraphScript.new()
	reset_session()


func reset_session() -> void:
	state = MazeGraphScript.START_STATE
	mistakes = 0


func reset_maze_position() -> void:
	state = MazeGraphScript.START_STATE


func apply_move(move: String) -> Dictionary:
	var move_result: Dictionary = maze.apply_move(state, move)

	if move_result["valid"]:
		state = move_result["state"]
		if move_result["success"]:
			reset_session()
			return {
				"valid": true,
				"move": move,
				"outcome": OUTCOME_SUCCESS,
				"mistakes": mistakes,
			}

		return {
			"valid": true,
			"move": move,
			"outcome": OUTCOME_PROGRESS,
			"mistakes": mistakes,
		}

	mistakes += 1
	reset_maze_position()

	return {
		"valid": false,
		"move": move,
		"outcome": OUTCOME_GAME_OVER if mistakes >= 3 else OUTCOME_WRONG_RESET,
		"mistakes": mistakes,
	}
