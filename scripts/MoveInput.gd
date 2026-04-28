class_name MoveInput
extends RefCounted

const FORWARD := "F"
const BACKWARD := "B"
const LEFT := "L"
const RIGHT := "R"

const BOTTOM_REGION_RATIO := 0.72
const LEFT_REGION_RATIO := 0.33
const RIGHT_REGION_RATIO := 0.67


static func from_event(event: InputEvent, viewport_size: Vector2) -> String:
	if event is InputEventKey:
		return from_key_event(event)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			return from_mouse_position(event.position, viewport_size)

	return ""


static func from_key_event(event: InputEventKey) -> String:
	if not event.pressed or event.echo:
		return ""

	var code := event.physical_keycode if event.physical_keycode != 0 else event.keycode
	return from_keycode(code)


static func from_keycode(keycode: int) -> String:
	match keycode:
		KEY_W, KEY_UP:
			return FORWARD
		KEY_A, KEY_LEFT:
			return LEFT
		KEY_S, KEY_DOWN:
			return BACKWARD
		KEY_D, KEY_RIGHT:
			return RIGHT
		_:
			return ""


static func from_mouse_position(position: Vector2, viewport_size: Vector2) -> String:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return ""

	if position.y >= viewport_size.y * BOTTOM_REGION_RATIO:
		return BACKWARD

	if position.x < viewport_size.x * LEFT_REGION_RATIO:
		return LEFT

	if position.x > viewport_size.x * RIGHT_REGION_RATIO:
		return RIGHT

	return FORWARD

