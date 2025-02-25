extends TextureRect

@onready var tex: TextureRect = $"../TextureRect2"

var cell_size: int = 32
var grid: Dictionary
var is_mouse_in : bool = false
var affected_cells
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
	#print(grid)

func _draw() -> void:
	# Iterate over each grid cell
	for key in grid.keys():
		var rect = grid[key]

		# Calculate the color based on the position of the cell
		var is_red = (rect.position.x / cell_size + rect.position.y / cell_size) % 2 == 0
		
		# Alternate between red and blue based on the cell's position
		var cell_color = Color.RED if is_red else Color.BLUE
		
		# Draw the rectangle with the alternating colors
		draw_rect(rect, cell_color, false)
	if affected_cells:
		for key in affected_cells.keys():
			draw_circle(affected_cells[key].diagonal_end_point,1,Color.RED)


func _process(delta: float) -> void:
	# Check if the mouse is inside the TextureRect
	
	if is_mouse_in:
		# Get the mouse position relative to the TextureRect
		var mouse_pos = get_local_mouse_position()
		#print(mouse_pos)
		# Get the actual mouse position in the texture (integer values)
		var actual_mouse_pos = Vector2(int(mouse_pos.x), int(mouse_pos.y))

		# Print the actual mouse position in pixels
		#print(size)
		affected_cells = get_affected_cells(mouse_pos,Vector2(16,16))
		#print(affected_cells)
		var rects = calculate_brush_rects(affected_cells,Vector2(16,16))
		#var rects = calculate_bounding_rect(affected_cells)
		#print(rects)
		queue_redraw()
		#print(get_grid_position(actual_mouse_pos))

func get_grid_position(mouse_pos: Vector2, image_size: Vector2 = size) -> Vector2i:
	#print(size)
	# Calculate the grid position by dividing the mouse position by the cell size for both x and y
	if mouse_pos.x < 0 or mouse_pos.y < 0 or mouse_pos.x >= image_size.x or mouse_pos.y >= image_size.y:
		return Vector2i(-1, -1)  # Indicate out-of-bounds
	
	var grid_pos = Vector2i(
		int(mouse_pos.x / cell_size),
		int(mouse_pos.y / cell_size)
		)
	
	# Return the grid coordinates as a Vector2i (grid_pos)
	return grid_pos


func get_affected_cells(center: Vector2, used_size: Vector2) -> Dictionary:
	var affected_regions: Dictionary = {}
	var diagonal_range = used_size / 2  # Half the size for max diagonal reach

	# Define diagonal directions
	var diagonal_directions = {
		"top_left": Vector2(-diagonal_range.x, -diagonal_range.y),
		"top_right": Vector2(diagonal_range.x, -diagonal_range.y),
		"bottom_left": Vector2(-diagonal_range.x, diagonal_range.y),
		"bottom_right": Vector2(diagonal_range.x, diagonal_range.y)
	}
	
	# Iterate over each diagonal direction
	for key in diagonal_directions.keys():
		var direction = diagonal_directions[key]
		var check_pos = center + direction
		var grid_pos = get_grid_position(check_pos)  # Convert to grid coordinates
		if grid_pos == Vector2i(-1,-1): continue
		# Store the result (grid_pos is -1,-1 if out of bounds)
		affected_regions[key] = {
			"grid_pos": grid_pos,
			"diagonal_end_point": check_pos,
			"region_type": key,
		}

	# Debugging
	#print(affected_regions)
	
	return affected_regions

func calculate_brush_rects(affected_regions: Dictionary, brush_size: Vector2):
	
	# Get the first key in the dictionary
	var first_key = affected_regions.keys()[0]  # Get the first key
	var first_entry = affected_regions[first_key]  # Get the corresponding value
	
	# Extract values
	var pos = first_entry.grid_pos
	var diagonal_end_point = first_entry.diagonal_end_point
	#print("region ? ", first_entry.region_type)
	#print("First Key:", first_key)
	#print("Grid Position:", pos)

	# Get the rect at this grid position from your grid dictionary
	var rect_at_pos = grid.get(pos, null)  # Use .get() to avoid errors if pos is missing
	if rect_at_pos == null:
		print("Grid position not found in grid dictionary!")
		return

	print("Rect at Grid Position:", rect_at_pos)

	# Convert the diagonal end point to local space within the rect
	var to_local_rect = Vector2i(diagonal_end_point) - rect_at_pos.position
	print("To Local Rect:", to_local_rect)

	
	
func divide_into_grid(image_size: Vector2, cell_size: int) -> Dictionary:
	# Calculate the number of cells in each dimension (rows and columns)
	var cols = int(image_size.x / cell_size)
	var rows = int(image_size.y / cell_size)

	# Array to store the grid rects
	var grid_rects: Dictionary = {}

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
			grid_rects[Vector2i(col,row)] = rect

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
