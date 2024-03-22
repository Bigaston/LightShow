extends Camera3D

@export var moving_speed = 5
@export var rotation_speed = 0.2
@export var minimum_height = 0.1

var is_move_button_pressed: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_move_button_pressed:
		if Input.is_action_pressed("flying_cam_forward"):
			position = position + (-basis.z * moving_speed * delta)
			
		if Input.is_action_pressed("flying_cam_backward"):
			position = position + (basis.z * moving_speed * delta)
			
		if Input.is_action_pressed("flying_cam_left"):
			position = position + (-basis.x * moving_speed * delta)
		
		if Input.is_action_pressed("flying_cam_right"):
			position = position + (basis.x * moving_speed * delta)
			
		if Input.is_action_pressed("flying_cam_up"):
			position = position + Vector3.UP * moving_speed * delta
			
		if Input.is_action_pressed("flying_cam_down"):
			position = position + Vector3.DOWN * moving_speed * delta
			
		if position.y < minimum_height:
			position.y = minimum_height
		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			is_move_button_pressed = true
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			is_move_button_pressed = false
			
	if event is InputEventMouseMotion and is_move_button_pressed:
		rotation_degrees.y += -event.relative.x * rotation_speed
		rotation_degrees.x += -event.relative.y * rotation_speed
		
		if rotation_degrees.x > 90:
			rotation_degrees.x = 90
		elif rotation_degrees.x < -90:
			rotation_degrees.x = -90
