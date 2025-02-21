extends Node2D
@onready var island: Sprite2D = $Island
@onready var debug_sprite: Sprite2D = $DebugRects
@onready var brush_pointer: Sprite2D = $BrushPointer
#const ISLAND = preload("res://Assets/island.png")
const BRUSH_1 = preload("res://Assets/brush_1.png")
var brush_image : Image
var terrain_image : Image
var terrain_mask_image: Image
var mask_texture: ImageTexture
var terrain_bitmask: BitMap 
var chunks_size : Vector2 = Vector2(6,6)
var per_terrain: float = 0.40
var is_mouse_in : bool = false
var cells_data : Dictionary 

func _input(event):
	if event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		brush_pointer.position = mouse_pos
		var local_mouse_pos = to_local(mouse_pos)
		var rect_texture = island.get_rect()
		#print("local_mouse_pos " , local_mouse_pos)
		if rect_texture.has_point(local_mouse_pos):
			if not is_mouse_in:
				is_mouse_in = true
				#print("Mouse entered the sprite!")
		else:
			if is_mouse_in:
				is_mouse_in = false
				#print("Mouse exited the sprite!")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	brush_image = BRUSH_1.get_image()
	terrain_image = island.texture.get_image()
	terrain_bitmask = BitMap.new()
	terrain_bitmask.create_from_image_alpha(terrain_image)
	terrain_mask_image = terrain_bitmask.convert_to_image()
	mask_texture = ImageTexture.create_from_image(terrain_mask_image)
	var grid_cells = create_grid_from_image(terrain_bitmask.convert_to_image(),chunks_size,per_terrain)
	
	cells_data = extract_bitmaps_from_cells(terrain_bitmask,grid_cells)
	debug_sprite.debug_cells(grid_cells.values(),island.texture.get_size())
	#create_static_objects(grid_cells)
	print(cells_data)
	
func get_mouse_pos_as_control():
	var local_mouse_pos = to_local(get_global_mouse_position())  # Convert global to local space
	var texture_size = island.texture.get_size()  # Get texture size
	
	# Shift coordinates to be like a UI buffer (ensure top-left is 0,0)
	local_mouse_pos.x += texture_size.x / 2
	local_mouse_pos.y += texture_size.y / 2

	# Normalize the coordinates (0.0 - 1.0 range like TextureRect)
	var normalized_pos = Vector2(
		clamp(local_mouse_pos.x / texture_size.x, 0.0, 1.0),
		clamp(local_mouse_pos.y / texture_size.y, 0.0, 1.0)
	)
	
	return normalized_pos
	
func _process(delta: float) -> void:
	if is_mouse_in and Input.is_action_pressed("mouse_left"):
		 # Check if left mouse is clicked
		var normalized_mouse_pos = get_mouse_pos_as_control()
		
		#var grid_pos = get_grid_position(normalized_mouse_pos,chunks_size)
		var affected_cells = update_grid_cells_with_brush(normalized_mouse_pos,chunks_size,brush_image,terrain_mask_image,cells_data)
		print(affected_cells)
		#print(grid_pos)
		#print("Normalized Mouse Position:", normalized_mouse_pos)

		# Apply the brush mask dynamically
		blit_with_mask(terrain_mask_image, brush_image, normalized_mouse_pos)
		mask_texture.update(terrain_mask_image)
		island.material.set_shader_parameter("mask_texture",mask_texture)

		#island.texture = mask_texture
		#debug_sprite.texture = mask_texture

		#Update texture in real-time
		#texture = ImageTexture.create_from_image(terrain_image)


func blit_with_mask(src: Image, brush: Image, normalized_pos: Vector2):
	"""
	Blits the `brush` onto `src` using normalized coordinates.
	
	- `src`: The destination image to modify.
	- `brush`: The brush image.
	- `normalized_pos`: The center position where the brush is applied, in normalized coordinates (0.0 - 1.0).
	"""

	var src_width = src.get_width()
	var src_height = src.get_height()
	
	var brush_width = brush.get_width()
	var brush_height = brush.get_height()

	# Convert normalized position to image-space coordinates
	var image_x = int(normalized_pos.x * src_width)
	var image_y = int(normalized_pos.y * src_height)

	# Define `src_rect` in image coordinates
	var src_rect = Rect2i(
		Vector2i(image_x - brush_width / 2, image_y - brush_height / 2),
		Vector2i(brush_width, brush_height)
	)

	# Ensure `src_rect` is within image bounds
	var start_x = max(0, src_rect.position.x)
	var end_x = min(src_width, src_rect.position.x + src_rect.size.x)
	var start_y = max(0, src_rect.position.y)
	var end_y = min(src_height, src_rect.position.y + src_rect.size.y)

	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			var brush_x = x - src_rect.position.x
			var brush_y = y - src_rect.position.y

			if brush_x >= 0 and brush_x < brush_width and brush_y >= 0 and brush_y < brush_height:
				var brush_pixel = brush.get_pixel(brush_x, brush_y)

				# If brush pixel is white, erase the terrain (set to black)
				if brush_pixel.r == 1.0 and brush_pixel.g == 1.0 and brush_pixel.b == 1.0 and brush_pixel.a == 1.0:
					src.set_pixel(x, y, Color(0, 0, 0, 1))  # Erase terrain
					
func create_static_objects(grid_cells: Dictionary):
	var static_objects = []  # Array to store created StaticBody2D instances

	for quadrant in grid_cells.keys():
		var rect = grid_cells[quadrant]
		var sprite_size =  island.texture.get_size() * scale
		var sprite_top_left = island.to_local(position - (sprite_size / 2))  

		# Convert grid cell position to local coordinates relative to the sprite
		var local_position = rect.position * scale  # Apply scale correctly
		var world_position = sprite_top_left + local_position  # Convert to world

		# Scale rect size
		var world_size = rect.size * scale

		# Create a world-space rectangle
		rect = Rect2(world_position, world_size)
		# Create StaticBody2D
		var static_body = StaticBody2D.new()
		static_body.position = rect.position  # Set position to match grid cell

		# Create CollisionShape2D
		var collision_shape = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = rect.size  # Set collision size
		collision_shape.shape = shape

		# Add CollisionShape2D to StaticBody2D
		static_body.add_child(collision_shape)
		collision_shape.position = rect.size / 2  # Center the collision shape

		

		# Add StaticBody2D to the scene
		add_child(static_body)
		static_objects.append(static_body)  # Store in array

	return static_objects

func update_grid_cells_with_brush(
	normalized_pos: Vector2, 
	cell_count: Vector2i, 
	brush_image: Image, 
	terrain_mask: Image,
	cells_data: Dictionary
):
	var image_size = Vector2(terrain_mask.get_width(), terrain_mask.get_height())  # Keep as Vector2
	var cell_size = calculate_cell_size(cell_count, image_size)

	# Convert normalized position to actual pixel position (center of brush)
	var pixel_pos = normalized_pos * image_size  # This is now the center
	
	# Get brush radius in pixels (half of brush width and height)
	var brush_radius = Vector2(brush_image.get_width(), brush_image.get_height()) / 2.0

	# Convert brush bounds into min/max pixel positions
	var brush_min = pixel_pos - brush_radius
	var brush_max = pixel_pos + brush_radius

	# Convert to grid indices
	var start_grid_x = clamp(int(brush_min.x / cell_size.x), 0, cell_count.x - 1)
	var start_grid_y = clamp(int(brush_min.y / cell_size.y), 0, cell_count.y - 1)
	var end_grid_x = clamp(int(brush_max.x / cell_size.x), 0, cell_count.x - 1)
	var end_grid_y = clamp(int(brush_max.y / cell_size.y), 0, cell_count.y - 1)

	# Iterate through affected grid positions
	for y in range(start_grid_y, end_grid_y + 1):
		for x in range(start_grid_x, end_grid_x + 1):
			var grid_pos = Vector2i(x, y)

			# Check if the grid cell exists in `cells_data`
			if not cells_data.has(grid_pos):
				continue

			var cell_data = cells_data[grid_pos]
			var bitmap: BitMap = cell_data["bitmap"]
			var rect = Rect2(x * cell_size.x, y * cell_size.y, cell_size.x, cell_size.y)

			# Modify the bitmap where brush and terrain intersect
			var bitmap_size = bitmap.get_size()
			var brush_size = brush_image.get_size()
			var modified = false  # Track if we changed anything

			for brush_y in range(brush_size.y):
				for brush_x in range(brush_size.x):
					# Convert brush pixel position to global pixel position
					var global_x = brush_min.x + brush_x
					var global_y = brush_min.y + brush_y

					# Check if this falls within the grid cell
					if global_x >= rect.position.x and global_x < rect.end.x and \
					   global_y >= rect.position.y and global_y < rect.end.y:

						# Convert to local bitmap coordinates
						var local_x = int(global_x - rect.position.x)
						var local_y = int(global_y - rect.position.y)

						# Ensure inside bitmap bounds
						if local_x < bitmap_size.x and local_y < bitmap_size.y:
							var brush_pixel = brush_image.get_pixel(brush_x, brush_y)
							if brush_pixel.r > 0.9:  # White brush pixel
								var terrain_pixel = bitmap.get_bit(local_x, local_y)
								if terrain_pixel == true:  # Already white
									bitmap.set_bit(local_x, local_y, false)  # Remove white
									modified = true  # Mark modification

			# Update the dictionary if modified
			if modified:
				cells_data[grid_pos]["is_dirty"] = true


func get_grid_position(normalized_pos: Vector2, cell_count: Vector2i) -> Vector2i:
	# Get the cell size
	var src_width = terrain_mask_image.get_width()
	var src_height = terrain_mask_image.get_height()
	var image_size: Vector2i = Vector2(src_width,src_height)
	var cell_size = calculate_cell_size(cell_count, image_size)
	
	# Convert normalized coordinates to actual pixel positions
	var pixel_pos = Vector2(normalized_pos.x * image_size.x, normalized_pos.y * image_size.y)
	
	# Get the quadrant based on pixel position
	var grid_x = int(pixel_pos.x / cell_size.x)
	var grid_y = int(pixel_pos.y / cell_size.y)
	
	# Ensure it doesn't exceed the max cell count
	grid_x = clamp(grid_x, 0, cell_count.x - 1)
	grid_y = clamp(grid_y, 0, cell_count.y - 1)
	
	return Vector2i(grid_x, grid_y)

func create_grid_from_image(image: Image, cell_count: Vector2, min_white_coverage: float) -> Dictionary:
	var grid_cells = {}  # Array to store Rect2 locations
	var width = image.get_width()
	var height = image.get_height()
	
	
	# Adjust cell_size to ensure it perfectly divides the image width and height
	var cell_size = calculate_cell_size(cell_count,Vector2(width,height))
	#print("Adjusted cell_size: ", cell_size)
	
	# Loop through the image in steps of cell_size
	for y in range(0, height, cell_size.y):
		for x in range(0, width, cell_size.x):
			# Define the Rect2 for the current cell
			var cell_rect = Rect2(x, y, cell_size.x, cell_size.y)
			# Check if the cell meets the white percentage threshold
			if check_white_threshold(image, cell_rect, min_white_coverage):
				var quadrant = Vector2i(x / cell_size.x, y / cell_size.y)
				#print("quadrant ", quadrant)
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
		var white_pixels = 0
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				if x < bitmap_size.x and y < bitmap_size.y:
					var bit = mask.get_bit(x, y)
					# Convert pixel to a byte (1 for white, 0 for black)
					if bit == true : white_pixels += 1
					packed_data.append(1 if bit == true else 0)

		# Create a new BitMap and store extracted data
		var bitmap = BitMap.new()
		var rect_size : Vector2 = Vector2(rect.size.x,rect.size.y)
		#print(rect_size)
		bitmap.create(rect_size)
		bitmap.data["data"] = packed_data  # Assign pixel data
		data[key] = {
			 "bitmap" : bitmap,
			 "count_pixels" : white_pixels,
			"is_dirty" : false,
		}
		
		

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
	var total_pixels = int(rect.size.x * rect.size.y)  # Correct total pixels for the given rect
	var min_white_pixels = int(total_pixels * min_white_coverage)  # Minimum required white pixels
	
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			# Ensure we don't go out of bounds
			if x < image.get_width() and y < image.get_height():
				var pixel = image.get_pixel(x, y)
				# Check if the pixel is white (assuming white is RGB(1, 1, 1))
				if pixel == Color(1, 1, 1):
					white_pixel_count += 1
					
					# Early return if the minimum required white pixels are already reached
					if white_pixel_count >= min_white_pixels:
						return true
	
	# If the loop completes, check if the white percentage meets the threshold
	return white_pixel_count >= min_white_pixels  # Final check
