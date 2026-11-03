class_name TouchSteer
extends RefCounted
## Reads the player's steering: the touch joystick while it is held,
## otherwise arrow keys or WASD. Length 0 to 1; up on screen is negative y.


static func read(joystick: VirtualJoystick) -> Vector2:
	if joystick.is_active():
		return joystick.output
	var keys := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_physical_key_pressed(KEY_A):
		keys.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		keys.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		keys.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		keys.y += 1.0
	return keys.limit_length(1.0)
