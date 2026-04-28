class_name MazeGraph
extends RefCounted

const START_STATE := "start"

const MOVE_FORWARD := "F"
const MOVE_BACKWARD := "B"
const MOVE_LEFT := "L"
const MOVE_RIGHT := "R"

const SOLUTION_PATHS := [
	[MOVE_FORWARD, MOVE_RIGHT, MOVE_FORWARD, MOVE_LEFT, MOVE_FORWARD, MOVE_FORWARD, MOVE_RIGHT],
	[MOVE_RIGHT, MOVE_FORWARD, MOVE_RIGHT, MOVE_BACKWARD, MOVE_RIGHT, MOVE_FORWARD, MOVE_FORWARD],
	[MOVE_LEFT, MOVE_FORWARD, MOVE_FORWARD, MOVE_RIGHT, MOVE_FORWARD, MOVE_LEFT, MOVE_FORWARD],
	[MOVE_FORWARD, MOVE_FORWARD, MOVE_LEFT, MOVE_BACKWARD, MOVE_LEFT, MOVE_FORWARD, MOVE_RIGHT, MOVE_FORWARD],
]

var transitions: Dictionary = {}
var success_states: Dictionary = {}


func _init() -> void:
	_build_graph()


func _build_graph() -> void:
	transitions.clear()
	success_states.clear()
	transitions[START_STATE] = {}

	for path_index in range(SOLUTION_PATHS.size()):
		var current_state := START_STATE
		var path: Array = SOLUTION_PATHS[path_index]

		for move_index in range(path.size()):
			var move: String = path[move_index]
			if not transitions.has(current_state):
				transitions[current_state] = {}

			var state_transitions: Dictionary = transitions[current_state]
			if state_transitions.has(move):
				current_state = state_transitions[move]
			else:
				var next_state := "path_%d_step_%d_%s" % [path_index + 1, move_index + 1, move]
				state_transitions[move] = next_state
				transitions[current_state] = state_transitions
				current_state = next_state

		success_states[current_state] = true
		if not transitions.has(current_state):
			transitions[current_state] = {}


func apply_move(state: String, move: String) -> Dictionary:
	var state_transitions: Dictionary = transitions.get(state, {})
	if not state_transitions.has(move):
		return {
			"valid": false,
			"state": START_STATE,
			"success": false,
		}

	var next_state: String = state_transitions[move]
	return {
		"valid": true,
		"state": next_state,
		"success": success_states.has(next_state),
	}


func get_valid_moves(state: String) -> Array:
	var state_transitions: Dictionary = transitions.get(state, {})
	return state_transitions.keys()


func count_success_paths() -> int:
	return _count_success_paths_from(START_STATE)


func _count_success_paths_from(state: String) -> int:
	var total := 0
	if success_states.has(state):
		total += 1

	var state_transitions: Dictionary = transitions.get(state, {})
	for next_state in state_transitions.values():
		total += _count_success_paths_from(next_state)

	return total


func get_solution_paths() -> Array:
	return SOLUTION_PATHS.duplicate(true)

