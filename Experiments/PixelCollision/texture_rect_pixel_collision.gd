extends TextureRect

@onready var tex: TextureRect = $"../TextureRect2"

var cell_size: int = 32
var grid: Array[Rect2i]
var is_mouse_in : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var new_image : Image = resize_and_center_image(texture.get_image())
	print(new_image.get_size())
	print("used rect ", new_image.get_used_rect())
	print("used rect size ", new_image.get_used_rect().size)
	var image_tex = ImageTexture.create_from_image(new_image)
	texture = image_tex
	#tex.texture = image_tex
	grid = divide_into_grid(new_image.get_size(),cell_size )
	print(grid)

func _draw() -> void:
	# Iterate over each grid cell
	for row in range(grid.size()):
		var rect = grid[row]

		# Calculate the color based on the position of the cell
		var is_red = (rect.position.x / cell_size + rect.position.y / cell_size) % 2 == 0
		
		# Alternate between red and blue based on the cell's position
		var cell_color = Color.RED if is_red else Color.BLUE
		
		# Draw the rectangle with the alternating colors
		draw_rect(rect, cell_color, false)



func _process(delta: float) -> void:
	# Check if the mouse is inside the TextureRect
	
	if is_mouse_in:
		# Get the mouse position relative to the TextureRect
		var mouse_pos = get_local_mouse_position()
		
		# Get the actual mouse position in the texture (integer values)
		var actual_mouse_pos = Vector2(int(mouse_pos.x), int(mouse_pos.y))

		# Print the actual mouse position in pixels
		#print(size)
		#print(get_grid_position(actual_mouse_pos,size))

func get_grid_position(mouse_pos: Vector2, image_size: Vector2) -> Vector2i:
	# Calculate the grid position by dividing the mouse position by the cell size for both x and y
	var grid_pos = Vector2i(
		int(mouse_pos.x / cell_size),
		int(mouse_pos.y / cell_size)
		)
	
	# Return the grid coordinates as a Vector2i (grid_pos)
	return grid_pos
	
	
func divide_into_grid(image_size: Vector2, cell_size: int) -> Array[Rect2i]:
	# Calculate the number of cells in each dimension (rows and columns)
	var cols = int(image_size.x / cell_size)
	var rows = int(image_size.y / cell_size)

	# Array to store the grid rects
	var grid_rects: Array[Rect2i] = []

	# Iterate through the rows and columns to create the grid
	for row in range(rows):
		for col in range(cols):
			# Calculate the position for each rect in the grid
			var rect_position = Vector2(col * cell_size, row * cell_size)

			# Ensure there's no overlap by adjusting the size by 1 pixel for the next rect
			var rect_width = cell_size
			var rect_height = cell_size

			# Adjust for the last column and row to avoid exceeding the image boundary
			if col == cols - 1:
				rect_width = image_size.x - col * cell_size
			if row == rows - 1:
				rect_height = image_size.y - row * cell_size

			# Adjust for the overlap: reduce by 1 pixel for the next section
			if col < cols - 1:
				rect_width -= 1
			if row < rows - 1:
				rect_height -= 1

			# Create the Rect2i with the adjusted position and size
			var rect = Rect2i(rect_position, Vector2(rect_width, rect_height))
			grid_rects.append(rect)

	# Return the array of grid rects
	return grid_rects



func resize_and_center_image(image: Image) -> Image:
	# Get the used rectangle of the image (the actual content area)
	var used_rect = image.get_used_rect()
	# Get the size of the used area (width and height)
	var image_size: Vector2 = used_rect.size
	
	# Find the nearest power of 2 greater than or equal to the width and height
	var new_image_size = nearest_power_of_2(image_size)

	# Create a new image with the new dimensions and the same format as the original
	var new_image = Image.create_empty(new_image_size.x, new_image_size.y, false, image.get_format())

	# Fill the new image with transparent pixels (or any background color)
	#new_image.fill(Color(0, 1, 0, 0.4))  # Transparent padding is optional

	# Calculate the offsets to center the original image in the new image using Vector2
	var offset = (new_image_size - image_size) / 2
	
	# Convert offset to integer values (required by blit_rect)
	var offset_int = Vector2i(offset)

	# Blit the original image into the new image at the calculated offset to center it
	new_image.blit_rect(image, used_rect, offset_int)

	return new_image


func nearest_power_of_2(size: Vector2) -> Vector2:
	# Ensure the input size is valid
	if size.x <= 0 or size.y <= 0:
		return Vector2(1, 1)  # Default to a minimum size of 1x1
	
	# Calculate the nearest power of 2 for width and height
	var new_width = pow(2, ceil(log(size.x) / log(2)))
	var new_height = pow(2, ceil(log(size.y) / log(2)))
	
	# Ensure the result is at least 1
	new_width = max(new_width, 1)
	new_height = max(new_height, 1)
	
	return Vector2(new_width, new_height)
	
	
func _on_mouse_entered() -> void:
	#print("mos")
	is_mouse_in = true

func _on_mouse_exited() -> void:
	#print("exit")
	is_mouse_in = false
