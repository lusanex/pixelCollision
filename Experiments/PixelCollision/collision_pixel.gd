extends TextureRect

var terrain_image: Image
var terrain_mask: ImageTexture
@onready var mask: Sprite2D = $"../mask"
@onready var debug_texture: TextureRect = $"../DebugTexture"
@onready var mask_texture: TextureRect = $"../MaskTexture"

var is_mouse_in : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	terrain_image = texture.get_image()
	var debug_image = Image.create_empty(terrain_image.get_width(),terrain_image.get_height(),false,Image.FORMAT_RGBA8)
	#debug_texture.texture = ImageTexture.create_from_image(debug_image)
	var d = texture.get_image()
	#draw_point(d,Vector2(d.get_width()/2,d.get_height()/2),1,Color.DARK_GOLDENROD)
	#debug_texture.texture = ImageTexture.create_from_image(d)
	var terrain_bitmap : BitMap = BitMap.new()
	var explosion_texture = preload("res://Assets/Tiles (Grayscale)/tile_0035.png") as Texture2D
	terrain_bitmap.create_from_image_alpha(terrain_image)
	var data = terrain_bitmap.data["data"]
	print("tyoeif " ,typeof(data))
	terrain_mask = ImageTexture.create_from_image(terrain_bitmap.convert_to_image())
	mask_texture.texture = terrain_mask
	var start_pos = Vector2i(terrain_image.get_width() - 1, terrain_image.get_height() / 2)
	print(start_pos)  # Right-middle starting position
	#start_pos = find_starting_edge(terrain_bitmap.convert_to_image(),start_pos)
	print(start_pos)
	#follow_edge_debug(terrain_bitmap.convert_to_image(), start_pos, 280, debug_image)  # Example usage
	#debug_texture.texture = ImageTexture.create_from_image(debug_image)  # Update the debug texture

	#material.set_shader_parameter("terrain_mask",terrain_mask)
	#material.set_shader_parameter("explosion_texture",explosion_texture)

func find_starting_edge(image: Image, start_pos: Vector2i) -> Vector2i:
	"""
	Moves left from the given start position until it finds the first white pixel (edge).
	Returns the position of the detected edge or (-1, -1) if no edge is found.
	"""
	var x = start_pos.x
	var y = start_pos.y

	# Ensure starting position is within bounds
	if x < 0 or x >= image.get_width() or y < 0 or y >= image.get_height():
		return Vector2i(-1, -1)  # Invalid start position

	# Move left until a white pixel is found
	while x > 0:
		if image.get_pixel(x, y).r == 1:  # Found a white pixel (terrain edge)
			return Vector2i(x, y)
		x -= 1  # Move left

	return Vector2i(-1, -1)  # No white pixel found

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#print(is_mouse_in)
	if is_mouse_in:
		var mouse_pos = get_local_mouse_position()
		var rect_size = size
		var normalized_mouse_pos = mouse_pos / rect_size
		print(normalized_mouse_pos)
		material.set_shader_parameter("mouse_position",normalized_mouse_pos)
	
func _draw() -> void:
	draw_line(Vector2.ZERO,Vector2(0.5,0),Color.AQUA,1,true)
	

func _on_mouse_entered() -> void:
	print("mos")
	is_mouse_in = true

func _on_mouse_exited() -> void:
	is_mouse_in = false

func follow_edge_debug(image: Image, start_pos: Vector2i, target_x: int, debug_image: Image, radius: int = 1, color: Color = Color.YELLOW) -> bool:
	"""
	Uses Marching Squares to follow the edge and plots the detected edge.
	Stops when:
	- It reaches the given target_x with a white pixel (terrain is still connected).
	- It completes the loop and returns to the start position.
	
	Returns true if the terrain is still connected, false if a new island is formed.
	"""
	var pos = start_pos
	var visited = {}  # Track visited positions to prevent loops
	var first_iteration = true

	# Movement directions based on Marching Squares index
	var movement_map = {
		1:  Vector2i(0, 1),  # Down
		2:  Vector2i(-1, 0), # Left
		3:  Vector2i(0, 1),  # Down
		4:  Vector2i(1, 0),  # Right
		5:  Vector2i(0, 1),  # Down
		6:  Vector2i(0, 1),  # Down
		7:  Vector2i(1, 0),  # Right
		8:  Vector2i(-1, 0), # Left
		9:  Vector2i(-1, 0), # Left
		10: Vector2i(1, 0),  # Right
		11: Vector2i(0, 1),  # Down
		12: Vector2i(-1, 0), # Left
		13: Vector2i(-1, 0), # Left
		14: Vector2i(1, 0),  # Right
		15: Vector2i(0, 0)   # Stop (inside terrain)
	}

	while true:
		# Mark position as visited
		visited[pos] = true
		
		# Plot the detected edge on the debug image
		draw_point(debug_image, pos, radius, color)

		# Check if we have reached the target X position with a white pixel
		if pos.x >= target_x and image.get_pixel(pos.x, pos.y).r == 1:
			print("reach tart")
			return true  # Terrain is still connected

		# Get the 2x2 block and calculate the Marching Squares index
		var index = get_marching_squares_index(image, pos)
		print(index)
		if index == 15:
			break  # Fully inside terrain, stop

		# Determine next movement
		var next_move = movement_map.get(index, Vector2i(0, 0))
		var next_pos = pos + next_move

		# Stop if we return to the start position (after first move)
		if next_pos == start_pos :
			print("next pos == start")
			break

		# Prevent infinite loops by checking visited pixels
		if visited.has(next_pos):
			print("visted?")
			break

		# Move to next edge position
		pos = next_pos
		first_iteration = false

	return false  # If we never reached target_x, a new island was created

func follow_edge(image: Image, start_pos: Vector2i, target_x: int) -> bool:
	"""
	Uses Marching Squares to follow the edge. Stops when:
	- It reaches the given target_x with a white pixel (terrain is still connected).
	- It completes the loop without reaching target_x (terrain is split).
	
	Returns true if the terrain is still connected, false if a new island is formed.
	"""
	var pos = start_pos
	var visited = {}  # Track visited positions to prevent loops
	
	# Movement directions based on Marching Squares index
	var movement_map = {
		1:  Vector2i(0, 1),  # Down
		2:  Vector2i(-1, 0), # Left
		3:  Vector2i(0, 1),  # Down
		4:  Vector2i(1, 0),  # Right
		5:  Vector2i(0, 1),  # Down
		6:  Vector2i(0, 1),  # Down
		7:  Vector2i(1, 0),  # Right
		8:  Vector2i(-1, 0), # Left
		9:  Vector2i(-1, 0), # Left
		10: Vector2i(1, 0),  # Right
		11: Vector2i(0, 1),  # Down
		12: Vector2i(-1, 0), # Left
		13: Vector2i(-1, 0), # Left
		14: Vector2i(1, 0),  # Right
		15: Vector2i(0, 0)   # Stop (inside terrain)
	}

	while true:
		# Mark position as visited
		visited[pos] = true

		# Check if we have reached the target X position with a white pixel
		if pos.x >= target_x and image.get_pixel(pos.x, pos.y).r == 1:
			return true  # Terrain is still connected

		# Get the 2x2 block and calculate the Marching Squares index
		var index = get_marching_squares_index(image, pos)
		if index == 15:
			break  # Fully inside terrain, stop

		# Determine next movement
		var next_move = movement_map.get(index, Vector2i(0, 0))
		var next_pos = pos + next_move

		# Stop if we revisit the starting position or loop indefinitely
		if next_pos == start_pos or visited.has(next_pos):
			break

		# Move to next edge position
		pos = next_pos

	return false  # If we never reached target_x, a new island was created

func get_marching_squares_index(image: Image, pos: Vector2i) -> int:
	"""
	Calculates the 2x2 block index for Marching Squares.
	"""
	var TL = get_pixel_value(image, pos.x, pos.y) * 8
	var TR = get_pixel_value(image, pos.x + 1, pos.y) * 4
	var BL = get_pixel_value(image, pos.x, pos.y + 1) * 2
	var BR = get_pixel_value(image, pos.x + 1, pos.y + 1) * 1

	return TL + TR + BL + BR

func get_pixel_value(image: Image, x: int, y: int) -> int:
	"""
	Returns 1 if the pixel is white (terrain), 0 if black (empty space).
	"""
	if x < 0 or x >= image.get_width() or y < 0 or y >= image.get_height():
		return 0  # Out of bounds treated as black (empty)
	return 1 if image.get_pixel(x, y).r == 1 else 0

func draw_point(image: Image, position: Vector2i, radius: int, color: Color):
	"""
	Draws a square point centered at `position` with a given `radius` in the `image`.
	- `image`: The target Image to modify.
	- `position`: The center of the point.
	- `radius`: The size of the square (half of the width/height).
	- `color`: The color to draw.
	"""
	var width = image.get_width()
	var height = image.get_height()

	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var px = position.x + dx
			var py = position.y + dy

			# Ensure within image bounds
			if px >= 0 and px < width and py >= 0 and py < height:
				#print("setting color")
				image.set_pixel(px, py, color)
