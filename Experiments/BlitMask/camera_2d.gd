extends Camera2D

# Lower cap for the _zoom_level.
@export var zoom_speed : float = 100.0

@export var zoom_margin : float = 0.3

@export var zoom_min := 0.5
# Upper cap for the _zoom_level.
@export var zoom_max := 2.0

@export var zoom_pos : Vector2 = Vector2()
# Controls how much we increase or decrease the _zoom_level on every turn of the scroll wheel.
@export var zoom_factor := 0.1
# Duration of the zoom's tween animation.
@export var zoom_duration := 0.2


func _process(delta: float) -> void:
	zoom = zoom.lerp(zoom * zoom_factor,zoom_speed * delta)
	zoom.x = clamp(zoom.x,zoom_min,zoom_max)
	zoom.y = clamp(zoom.y,zoom_min,zoom_max)

func _input(event: InputEvent) -> void:
	if abs(zoom_pos.x - get_global_mouse_position().x) > zoom_margin:
		zoom_factor = 1.0
	if abs(zoom_pos.y - get_global_mouse_position().y) > zoom_margin:
		zoom_factor = 1.0
		
	if Input.is_action_pressed("zoom_in"):
		zoom_factor -= 0.01
		zoom_pos  = get_global_mouse_position()
	if Input.is_action_pressed("zoom_out"):
		zoom_factor += 0.01
		zoom_pos = get_global_mouse_position()
	
