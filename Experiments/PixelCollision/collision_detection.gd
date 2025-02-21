extends Node2D

@onready var terrain_sprite: Sprite2D = $Sprite2D

var terrain_bitmap_texture: ImageTexture
var terrain_bitmap: BitMap


func _ready() -> void:
	terrain_bitmap = BitMap.new()
	terrain_bitmap.create_from_image_alpha(terrain_sprite.texture.get_image())
	terrain_bitmap_texture = ImageTexture.create_from_image(terrain_bitmap.convert_to_image())
	terrain_sprite.texture = terrain_bitmap_texture
	var grid_cells = create_grid_from_image(terrain_bitmap.convert_to_image(),Vector2(5,5),0.40)
	terrain_sprite.debug_cells(grid_cells.values())
	var data = extract_bitmaps_from_cells(terrain_bitmap,grid_cells)
	print(data)
	#extract_bitmaps_from_cells(terrain)
	#print("cell_size ", grid_cells.size())
	
# Function to create a grid and check for white pixels
func create_grid_from_image(image: Image, cell_count: Vector2, min_white_coverage: float) -> Dictionary:
	var grid_cells = {}  # Array to store Rect2 locations
	var width = image.get_width()
	var height = image.get_height()
	
	
	# Adjust cell_size to ensure it perfectly divides the image width and height
	var cell_size = calculate_cell_size(cell_count,Vector2(width,height))
	print("Adjusted cell_size: ", cell_size)
	
	# Loop through the image in steps of cell_size
	for y in range(0, height, cell_size.y):
		for x in range(0, width, cell_size.x):
			# Define the Rect2 for the current cell
			var cell_rect = Rect2(x, y, cell_size.x, cell_size.y)
			# Check if the cell meets the white percentage threshold
			if check_white_threshold(image, cell_rect, min_white_coverage):
				var quadrant = Vector2i(x / cell_size.x, y / cell_size.y)
				print("quadrant ", quadrant)
				#print("rec_local :" ,cell_rect)
				grid_cells[quadrant] = cell_rect

	return grid_cells
	
func extract_bitmaps_from_cells(mask: BitMap, grid_cells: Dictionary) -> Dictionary:
	var data = {}
	#var bitmaps = []  # Array to store extracted BitMaps

	for key in grid_cells.keys():
		var rect = grid_cells[key]
		var packed_data = PackedByteArray()
		var bitmap_size = mask.get_size()
		# Extract pixel data from the image
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				if x < bitmap_size.x and y < bitmap_size.y:
					var bit = mask.get_bit(x, y)
					# Convert pixel to a byte (1 for white, 0 for black)
					packed_data.append(1 if bit == true else 0)

		# Create a new BitMap and store extracted data
		var bitmap = BitMap.new()
		var rect_size : Vector2 = Vector2(rect.size.x,rect.size.y)
		print(rect_size)
		bitmap.create(rect_size)
		bitmap.data["data"] = packed_data  # Assign pixel data
		data[key] = bitmap

		#bitmaps.append(bitmap)

		# Debug: Print data for validation
		#print("Extracted Bitmap Data:", packed_data)

	return data  # Return the array of bitmaps

func calculate_cell_size(cell_count: Vector2, grid_size: Vector2) -> Vector2:
	var cell_width = grid_size.x / cell_count.x
	var cell_height = grid_size.y / cell_count.y
	return Vector2(cell_width, cell_height)




# Helper function to check if a Rect2 area meets the white percentage threshold
func check_white_threshold(image: Image, rect: Rect2, min_white_coverage: float) -> bool:
	var white_pixel_count = 0
	var total_pixels = 0
	var min_white_pixels = int(rect.size.x * rect.size.y * min_white_coverage)  # Minimum required white pixels
	
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			# Ensure we don't go out of bounds
			if x < image.get_width() and y < image.get_height():
				total_pixels += 1
				var pixel = image.get_pixel(x, y)
				# Check if the pixel is white (assuming white is RGB(1, 1, 1))
				if pixel == Color(1, 1, 1):
					white_pixel_count += 1
					
					# Early return if the minimum required white pixels are already reached
					if white_pixel_count >= min_white_pixels:
						return true
	
	# If the loop completes, check if the white percentage meets the threshold
	var white_percentage = float(white_pixel_count) / float(total_pixels)
	return white_percentage >= min_white_coverage
