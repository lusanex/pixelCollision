extends Node2D
@onready var island: Sprite2D = $Island
@onready var debug_sprite: Sprite2D = $DebugRects
@onready var brush_pointer: Sprite2D = $BrushPointer
#const ISLAND = preload("res://Assets/island.png")
const BRUSH_1 = preload("res://Assets/brush_1.png")
var brush_image : Image
var brush_bitmask: BitMap
var terrain_image : Image
var terrain_mask_image: Image
var mask_texture: ImageTexture
var terrain_bitmask: BitMap 
var chunks_size : Vector2 = Vector2(6,6)
var per_terrain: float = 0.10
var is_mouse_in : bool = false
var cells_bitmap : Dictionary 
var grid_cells : Dictionary

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
	brush_bitmask = BitMap.new()
	brush_bitmask.create_from_image_alpha(brush_image)
	terrain_image = island.texture.get_image()
	terrain_bitmask = BitMap.new()
	terrain_bitmask.create_from_image_alpha(terrain_image)
	terrain_mask_image = terrain_bitmask.convert_to_image()
	mask_texture = ImageTexture.create_from_image(terrain_mask_image)
	var terrain_size = terrain_bitmask.get_size()
	#print("terrain size: " ,terrain_size)
	grid_cells = create_grid_from_image(terrain_size,chunks_size,per_terrain)
	cells_bitmap = extract_regions_from_bitmask(grid_cells,terrain_bitmask)
	#print(cells_bitmap)
	#cells_data = extract_bitmaps_from_cells(terrain_bitmask,grid_cells)
	debug_sprite.debug_cells(grid_cells,island.texture.get_size())
	#create_static_objects(grid_cells)
	#print(cells_data)
	
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
	
#func get_cell_size_at_position(
	#normalized_pos: Vector2,  # Normalized mouse position (0 to 1)
	#cell_count: Vector2i,  # Grid size (NxM)
	#terrain_size: Vector2  # Terrain size in pixels
#) -> Vector2i:
	#var base_cell_size = Vector2i(terrain_size.x / cell_count.x, terrain_size.y / cell_count.y)
	#
	## Calculate which grid position the mouse is in
	#var grid_x = int(normalized_pos.x * cell_count.x)
	#var grid_y = int(normalized_pos.y * cell_count.y)
	##print(base_cell_size)
	## Calculate the size for this specific region
	#var final_width = base_cell_size.x
	#var final_height = base_cell_size.y
#
	## Adjust last column to add remain pixels
	#if grid_x == cell_count.x - 1:
		#final_width = int(terrain_size.x) - (base_cell_size.x * (cell_count.x - 1))
#
	## Adjust last row to add remain pixels
	#if grid_y == cell_count.y - 1:
		#final_height = int(terrain_size.y) - (base_cell_size.y * (cell_count.y - 1))
#
	#return Vector2i(final_width, final_height)

func calculate_normalized_brush_rects(
	normalized_pos: Vector2,  
	cell_count: Vector2i,  
	terrain_size: Vector2,  
	brush_radius: Vector2,  
	affected_quadrants: Array  
) -> Dictionary:
	var brush_size = brush_bitmask.get_size()
	var brush_center = normalized_pos * terrain_size  
	var brush_rect = Rect2i(brush_center - brush_radius, brush_radius * 2)  
	var quadrant_brush_data = {}  
	print("new affected")
	for quadrant in affected_quadrants:
		if not grid_cells.has(quadrant): 
			continue
		var quadrant_rect = grid_cells[quadrant]
		var quadrant_size = quadrant_rect.size  

		# Find the intersection between brush and quadrant
		var intersection_rect = brush_rect.intersection(quadrant_rect)  
		var snapped_width = min(intersection_rect.size.x, quadrant_rect.size.x)
		var snapped_height = min(intersection_rect.size.y, quadrant_rect.size.y)

		# ✅ Create a new snapped intersection rect
		intersection_rect = Rect2i(intersection_rect.position, Vector2(snapped_width, snapped_height))
		#print(intersection_rect)
		# Ensure valid size before creating BitMap
		if intersection_rect.size.x >= 1 and intersection_rect.size.y >= 1:  
			# Convert intersection to quadrant-local space
			var local_brush_rect = Rect2(
				floor(intersection_rect.position - quadrant_rect.position),  
				ceil(intersection_rect.size)  
			)
			print(local_brush_rect)
			# Convert to brush space
			var brush_clip_top_left = intersection_rect.position - brush_rect.position
			brush_clip_top_left.x = round(brush_clip_top_left.x)
			brush_clip_top_left.y = round(brush_clip_top_left.y)

			var clipped_brush = BitMap.new()

			# Calculate valid clip size
			var brush_clip_size_x = min(floor(local_brush_rect.size.x), max(1, floor(brush_size.x - brush_clip_top_left.x)))
			var brush_clip_size_y = min(floor(local_brush_rect.size.y), max(1, floor(brush_size.y - brush_clip_top_left.y)))

			#print("brush_pos ", [brush_clip_top_left.x,brush_clip_top_left.y])
			#print("brush_size " ,[ brush_clip_size_x,brush_clip_size_y])
			if brush_clip_size_x >= 1 and brush_clip_size_y >= 1:
				clipped_brush.create(Vector2(brush_clip_size_x, brush_clip_size_y))

				for y in range(brush_clip_size_y):
					for x in range(brush_clip_size_x):
						var brush_x = brush_clip_top_left.x + x
						var brush_y = brush_clip_top_left.y + y

						if brush_x < brush_size.x and brush_y < brush_size.y:
							clipped_brush.set_bit(x, y, brush_bitmask.get_bit(brush_x, brush_y))

				# Normalize brush rect inside quadrant
				var normalized_brush_rect = Rect2(
					local_brush_rect.position / Vector2(quadrant_size),  
					local_brush_rect.size / Vector2(quadrant_size)  
				)

				quadrant_brush_data[quadrant] = { 
					"rect": normalized_brush_rect,
					"clipped_brush": clipped_brush,
				}

	return quadrant_brush_data



#func get_correct_clipped_brush(
	#intersection_rect: Rect2,  # The exact overlapping region in terrain space
	#brush_rect_in_terrain: Rect2,  # The full brush rect in terrain space
	#brush_bitmask: BitMap  # The full brush bitmask
#) -> BitMap:
	#var brush_size = brush_bitmask.get_size()
	#
	#var brush_start_x = max(0, int(((intersection_rect.position.x - brush_rect_in_terrain.position.x) / brush_rect_in_terrain.size.x) * brush_size.x))
	#var brush_start_y = max(0, int(((intersection_rect.position.y - brush_rect_in_terrain.position.y) / brush_rect_in_terrain.size.y) * brush_size.y))
	#var brush_w = min(brush_size.x - brush_start_x, int((intersection_rect.size.x / brush_rect_in_terrain.size.x) * brush_size.x))
	#var brush_h = min(brush_size.y - brush_start_y, int((intersection_rect.size.y / brush_rect_in_terrain.size.y) * brush_size.y))
#
	#if brush_w < 1 or brush_h < 1:
		#return BitMap.new()  # Return empty if nothing is extracted
#
	#var clipped_brush = BitMap.new()
	#clipped_brush.create(Vector2(brush_w, brush_h))
#
	#for y in range(brush_h):
		#for x in range(brush_w):
			#var brush_x = brush_start_x + x
			#var brush_y = brush_start_y + y
#
			#if brush_x < brush_size.x and brush_y < brush_size.y:
				#clipped_brush.set_bit(x, y, brush_bitmask.get_bit(brush_x, brush_y))
#
	#return clipped_brush


func _process(delta: float) -> void:
	if is_mouse_in and Input.is_action_pressed("mouse_left"):
		 # Check if left mouse is clicked
		var normalized_mouse_pos = get_mouse_pos_as_control()
		var src_width = terrain_mask_image.get_width()
		var src_height = terrain_mask_image.get_height()
		var image_size: Vector2i = Vector2(src_width,src_height)
		var brush_radius = Vector2(brush_bitmask.get_size()) / 2.0
		var q = get_affected_quadrants(normalized_mouse_pos,chunks_size,image_size,brush_radius)
		#print(q)
		var affected_regions = update_brush(normalized_mouse_pos,chunks_size,image_size,brush_radius,q)
		#print(r)
		debug_sprite.draw_brush_rects(affected_regions,image_size,chunks_size)
		blit_brush_to_cells(affected_regions,cells_bitmap)
		
		update_terrain_bitmask_from_cells(cells_bitmap,terrain_bitmask,terrain_mask_image)
		mask_texture.update(terrain_mask_image)
		island.texture = mask_texture
		#var rb = get_brush_rect_in_region(image_size,chunks_size,normalized_mouse_pos,brush_radius)
		#print(rb)
		##var grid_pos = get_grid_position(normalized_mouse_pos,chunks_size)
		#var grid_pos = get_clipped_brush_bitmaps(terrain_bitmask,normalized_mouse_pos,chunks_size,brush_bitmask)
		##print(affected_cells)
		##for k in cells_data.keys():
			##if cells_data[k].is_dirty:
				##print(cells_data[k].bitmap.data)
		#print(grid_pos)
		##print("Normalized Mouse Position:", normalized_mouse_pos)
#
		## Apply the brush mask dynamically
		#blit_with_mask(terrain_mask_image, brush_image, normalized_mouse_pos)
		#mask_texture.update(terrain_mask_image)
		#island.material.set_shader_parameter("mask_texture",mask_texture)

		#island.texture = mask_texture
		#debug_sprite.texture = mask_texture

		#Update texture in real-time
		#texture = ImageTexture.create_from_image(terrain_image)
### teh region is pok for the affecte region in but we need to get teh actua region form teh brush
### so we need to calcaute the sie fo teh rect to calcaulte this into teh brush 
## so will ge t a new rect nromalized to get that bit form teh brush or a region.

func blit_brush_to_cells(
	affected_regions: Dictionary,  # Dict with grid_pos -> stored brush clip
	cells_bitmap: Dictionary  # The grid bitmaps
):
	#print(affected_regions)
	for grid_pos in affected_regions.keys():
		if not cells_bitmap.has(grid_pos):
			continue

		var cell_data = cells_bitmap[grid_pos]
		var region_bitmap: BitMap = cell_data["region"]
		var clipped_brush: BitMap = affected_regions[grid_pos]["clipped_brush"]
		var normalized_brush_rect: Rect2 = affected_regions[grid_pos]["rect"]
		
		# Convert to local pixel space inside the region
		var local_brush_x = int(normalized_brush_rect.position.x * cell_data["rect"].size.x)
		var local_brush_y = int(normalized_brush_rect.position.y * cell_data["rect"].size.y)

		var modified: bool = false
		var count_white_modified: int = 0

		for y in range(clipped_brush.get_size().y):
			for x in range(clipped_brush.get_size().x):
				var region_x = local_brush_x + x
				var region_y = local_brush_y + y

				if clipped_brush.get_bit(x, y):  # Only apply where brush bitmask is true
					if region_x < region_bitmap.get_size().x and region_y < region_bitmap.get_size().y:
						if region_bitmap.get_bit(region_x, region_y):
							region_bitmap.set_bit(region_x, region_y, false)
							modified = true
							count_white_modified += 1

		if modified:
			cell_data.is_dirty = true
			cell_data.count_pixels = max(0, cell_data.count_pixels - count_white_modified)


var last_brush_rects = {}  # Store previous brush rects

func has_significant_change(new_brush_rects: Dictionary, epsilon: float = 0.001) -> bool:
	for key in new_brush_rects.keys():
		if not last_brush_rects.has(key):
			return true  # New quadrant detected, update required

		var new_rect = new_brush_rects[key].rect
		var old_rect = last_brush_rects[key].rect

		# Compare each component with a small tolerance to handle floating-point errors
		if abs(new_rect.position.x - old_rect.position.x) > epsilon or \
		   abs(new_rect.position.y - old_rect.position.y) > epsilon or \
		   abs(new_rect.size.x - old_rect.size.x) > epsilon or \
		   abs(new_rect.size.y - old_rect.size.y) > epsilon:
			return true  # Significant change detected, update required

	return false  # No significant change, skip update

func update_brush(normalized_mouse_pos: Vector2, chunk_size: Vector2i,image_size: Vector2, brush_radius: Vector2,quadrants: Array ):
	var r = calculate_normalized_brush_rects(normalized_mouse_pos, chunks_size, image_size, brush_radius, quadrants)

	# Only update if there's a significant change
	if has_significant_change(r):
		#print(r)  # Debugging: Show only when rects actually change
		last_brush_rects = r.duplicate(true)  # Store new rects as reference
	return r
	

func extract_clipped_region(
	terrain_bitmap: BitMap,  # The full terrain mask
	region_pos: Vector2i,  # The region's position in grid coordinates
	cell_count: Vector2i,  # Grid size (NxM)
	terrain_size: Vector2,  # Terrain size in pixels
	clip_rect: Rect2  # The clipping rectangle inside this region
) -> Dictionary:
	var cell_size = calculate_cell_size(cell_count, terrain_size)  # Region size in pixels
	var region_pixel_pos = Vector2(region_pos.x * cell_size.x, region_pos.y * cell_size.y)  # Top-left of region
	var full_region_rect = Rect2(region_pixel_pos, cell_size)  # The entire region bounds

	# Check if the clipping rect is completely outside the region
	if not full_region_rect.intersects(clip_rect):
		return { "bitmap": null, "rect": full_region_rect }  # Return a null bitmap

	# Create a new empty bitmap the same size as the full region
	var clipped_bitmap = BitMap.new()
	clipped_bitmap.create(cell_size)  # Initialize to all `false`

	# Iterate through the clipping rectangle
	for y in range(clip_rect.position.y, clip_rect.end.y):
		for x in range(clip_rect.position.x, clip_rect.end.x):
			var global_x = int(region_pixel_pos.x + x)
			var global_y = int(region_pixel_pos.y + y)

			# Ensure it's inside the terrain bounds
			if global_x < terrain_bitmap.get_size().x and global_y < terrain_bitmap.get_size().y:
				var bit_value = terrain_bitmap.get_bit(global_x, global_y)

				# Copy only the clipped data into the new full region bitmap
				clipped_bitmap.set_bit(x, y, bit_value)

	return { "bitmap": clipped_bitmap, "rect": full_region_rect }


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


func get_clipped_brush_bitmaps(
	terrain_bitmap: BitMap,  # The full terrain mask
	normalized_pos: Vector2,  # Normalized mouse position (0 to 1)
	cell_count: Vector2,  # Number of grid cells in X, Y
	brush_bitmap: BitMap  # The brush mask
) -> Dictionary:
	var image_size = Vector2(terrain_bitmap.get_size())  # Terrain size in pixels
	var cell_size = image_size / cell_count  # Each grid cell's size in pixels

	# Convert normalized position to actual pixel position
	var pixel_pos = normalized_pos * image_size  # This is the center of the brush

	# Get brush radius in pixels
	var brush_radius = Vector2(brush_bitmap.get_size()) / 2.0

	# Get brush min/max bounds in pixel coordinates
	var brush_min = pixel_pos - brush_radius
	var brush_max = pixel_pos + brush_radius

	# Find affected quadrants
	var start_grid_x = clamp(int(floor(brush_min.x / cell_size.x)), 0, cell_count.x - 1)
	var start_grid_y = clamp(int(floor(brush_min.y / cell_size.y)), 0, cell_count.y - 1)
	var end_grid_x = clamp(int(ceil(brush_max.x / cell_size.x)), 0, cell_count.x - 1)
	var end_grid_y = clamp(int(ceil(brush_max.y / cell_size.y)), 0, cell_count.y - 1)

	var clipped_brush_dict = {}  # Store clipped brush bitmaps per quadrant

	# Iterate over all affected quadrants
	for grid_y in range(start_grid_y, end_grid_y + 1):
		for grid_x in range(start_grid_x, end_grid_x + 1):
			var quadrant_pos = Vector2i(grid_x, grid_y)
			var quadrant_rect = Rect2(grid_x * cell_size.x, grid_y * cell_size.y, cell_size.x, cell_size.y)

			# Create a blank bitmap matching the quadrant size
			var clipped_brush = BitMap.new()
			clipped_brush.create(cell_size)

			var modified = false  # Track if we set any `true` values in the clipped brush

			# Iterate over the brush pixels
			for brush_y in range(brush_bitmap.get_size().y):
				for brush_x in range(brush_bitmap.get_size().x):
					var global_x = brush_min.x + brush_x
					var global_y = brush_min.y + brush_y

					# Check if this pixel falls inside the quadrant
					if quadrant_rect.has_point(Vector2(global_x, global_y)):
						var local_x = int(global_x - quadrant_rect.position.x)
						var local_y = int(global_y - quadrant_rect.position.y)

						# Ensure we are inside the quadrant's bounds
						if local_x < cell_size.x and local_y < cell_size.y:
							var brush_pixel = brush_bitmap.get_bit(brush_x, brush_y)
							var terrain_pixel = terrain_bitmap.get_bit(global_x, global_y)  

							# Only modify the brush if both the terrain & brush have `true` pixels
							if brush_pixel and terrain_pixel:
								clipped_brush.set_bit(local_x, local_y, true)
								modified = true  # At least one pixel was modified

			# Only store quadrants where the brush actually modified terrain
			if modified:
				clipped_brush_dict[quadrant_pos] = clipped_brush

	return clipped_brush_dict  # Dictionary of { quadrant_position: clipped_brush }

func get_affected_quadrants(
	normalized_pos: Vector2,  # Normalized mouse position (0-1)
	cell_count: Vector2i,  # Grid size (NxM)
	terrain_size: Vector2,  # Terrain size in pixels
	brush_radius: Vector2  # Brush mask image
) -> Array:
	var affected_quadrants = []

	# Calculate brush radius in pixels
	#var brush_radius = Vector2(brush_bitmask.get_size()) / 2.0

	# Normalize brush radius (convert to 0-1 range)
	var normalized_brush_radius = brush_radius / terrain_size

	# Check all four directions (left, right, up, down)
	var offsets = [
		Vector2(0, 0),  # Center
		Vector2(-normalized_brush_radius.x, 0),  # Left
		Vector2(normalized_brush_radius.x, 0),   # Right
		Vector2(0, -normalized_brush_radius.y),  # Up
		Vector2(0, normalized_brush_radius.y), # Down
		Vector2(-normalized_brush_radius.x, -normalized_brush_radius.y),  # Top-left (diagonal)
		Vector2(normalized_brush_radius.x, -normalized_brush_radius.y),   # Top-right (diagonal)
		Vector2(-normalized_brush_radius.x, normalized_brush_radius.y),   # Bottom-left (diagonal)
		Vector2(normalized_brush_radius.x, normalized_brush_radius.y)      
	]

	for offset in offsets:
		var check_pos = normalized_pos + offset
		var quadrant = get_grid_position(check_pos, cell_count)

		if not affected_quadrants.has(quadrant):  # Avoid duplicates
			affected_quadrants.append(quadrant)

	return affected_quadrants



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

#returns grid cells that have greater tha white treshold 
#dic with key teh grid cell and teh rect2, that varies from size 

func create_grid_from_image(terrain_size : Vector2, cell_count: Vector2, min_white_coverage: float) -> Dictionary:
	var grid_cells = {}  # Store { quadrant: Rect2 }

	# Calculate base cell size (ignoring remainder)
	var base_size = Vector2i(terrain_size / cell_count)

	# Calculate remaining pixels (extra to be added to last row/column)
	var remainder_x = int(terrain_size.x) % int(cell_count.x)
	var remainder_y = int(terrain_size.y) % int(cell_count.y)
	
	#print("Base Size:", base_size)
	#print("Remainder (extra for last row/col): ", [remainder_x, remainder_y])

	# Loop through the grid
	for y in range(cell_count.y):
		for x in range(cell_count.x):
			
			#top left position Rect
			var cell_x = base_size.x * x
			var cell_y = base_size.y * y
			
			#end position rect
			var cell_w = base_size.x
			var cell_h = base_size.y
			
			#add remain pixel at the last row/col
			if x == cell_count.x - 1:
				cell_w += remainder_x  
			if y == cell_count.y - 1:
				cell_h += remainder_y  

			var cell_rect = Rect2i(cell_x, cell_y, cell_w, cell_h)
			# we just add quadrants with min white percentage
			if check_white_threshold(terrain_bitmask, cell_rect, min_white_coverage):
				var quadrant = Vector2i(x, y)
				grid_cells[quadrant] = cell_rect

	return grid_cells

func extract_regions_from_bitmask(grid_cells: Dictionary, terrain_bitmask: BitMap) -> Dictionary:
	var regions = {}  # Dictionary to store extracted bitmask regions

	for grid_pos in grid_cells.keys():
		var rect: Rect2i = grid_cells[grid_pos]  # Get the region rectangle

		# Create a new bitmap for this specific region
		var region_bitmap = BitMap.new()
		region_bitmap.create(rect.size)  # Same size as region

		var white_pixel_count = 0  # Counter for white pixels

		# Copy data from terrain_bitmask into region_bitmap
		for y in range(rect.size.y):
			for x in range(rect.size.x):
				var global_x = int(rect.position.x) + x
				var global_y = int(rect.position.y) + y

				# Ensure we don't go out of bounds
				if global_x < terrain_bitmask.get_size().x and global_y < terrain_bitmask.get_size().y:
					var bit_value = terrain_bitmask.get_bit(global_x, global_y)
					region_bitmap.set_bit(x, y, bit_value)  # Set in the new region bitmap
					
					if bit_value:  # If true (white pixel), increase count
						white_pixel_count += 1

		# Store extracted bitmask in dictionary with metadata
		regions[grid_pos] = {
			"region": region_bitmap,  # Extracted bitmask
			"count_pixels": white_pixel_count,  # Number of white pixels
			"is_dirty": false,  # Initially clean, will change if modified
			"rect" : rect,
		}

	return regions  # Return dictionary of extracted regions

#remove this 
func extract_bitmaps_from_cells(mask: BitMap, grid_cells: Dictionary) -> Dictionary:
	var data = {}

	for key in grid_cells.keys():
		var rect: Rect2 = grid_cells[key]
		var bitmap_size = mask.get_size()

		# Create a new BitMap for this region
		var bitmap = BitMap.new()
		bitmap.create(Vector2(rect.size.x, rect.size.y))

		var white_pixels = 0  # Count of white pixels in the region

		# Extract pixel data from the terrain mask and directly set values in the new BitMap
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				if x < bitmap_size.x and y < bitmap_size.y:
					var bit_value = mask.get_bit(x, y)  # Get actual value from terrain
					
					# Set the exact pixel value into the new extracted BitMap
					bitmap.set_bit(x - int(rect.position.x), y - int(rect.position.y), bit_value)

					# Count white pixels (fully white = 1 in BitMap)
					if bit_value:
						white_pixels += 1
		#print(bitmap.data)
		# Store extracted data
		data[key] = {
			"bitmap": bitmap,  # Correctly extracted bitmap with actual pixel values
			"count_pixels": white_pixels,  # Number of white pixels
			"is_dirty": false  # Initially not dirty
		}

	return data

		
		

		#bitmaps.append(bitmap)

		# Debug: Print data for validation
		#print("Extracted Bitmap Data:", packed_data)

	return data  # Return the array of bitmaps

func calculate_cell_size(cell_count: Vector2i, terrain_size: Vector2) -> Vector2i:
	#print("terrain size ", terrain_size)
	var cell_width = terrain_size.x / cell_count.x
	var cell_height = terrain_size.y / cell_count.y
	return Vector2i(cell_width, cell_height)




# Helper function to check if a Rect2 area meets the white percentage threshold
func check_white_threshold(map: BitMap, rect: Rect2, min_white_coverage: float) -> bool:
	var white_pixel_count = 0
	var total_pixels = int(rect.size.x * rect.size.y)  # Correct total pixels for the given rect
	var min_white_pixels = int(total_pixels * min_white_coverage)  # Minimum required white pixels
	var w = map.get_size().x
	var h = map.get_size().y
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			# Ensure we don't go out of bounds
			if x < w and y < h:
				var pixel = map.get_bit(x,y)
				# Check if the pixel is white (assuming white is RGB(1, 1, 1))
				if pixel:
					white_pixel_count += 1
					
					# Early return if the minimum required white pixels are already reached
					if white_pixel_count >= min_white_pixels:
						return true
	
	# If the loop completes, check if the white percentage meets the threshold
	return white_pixel_count >= min_white_pixels  # Final check
	
	
func update_terrain_bitmask_from_cells(cells_bitmap: Dictionary, terrain_bitmask: BitMap, terrain_image: Image):
	for grid_pos in cells_bitmap.keys():
		var cell_data = cells_bitmap[grid_pos]
		
		# Only process dirty cells
		if not cell_data["is_dirty"]:
			continue
		
		var region_bitmap: BitMap = cell_data["region"]
		var region_rect: Rect2 = cell_data["rect"]  

		# Loop through the region and update terrain_bitmask
		for y in range(region_bitmap.get_size().y):
			for x in range(region_bitmap.get_size().x):
				var global_x = int(region_rect.position.x) + x
				var global_y = int(region_rect.position.y) + y

				# Ensure we don't go out of bounds
				if global_x < terrain_bitmask.get_size().x and global_y < terrain_bitmask.get_size().y:
					var bit_value = region_bitmap.get_bit(x, y)
					terrain_bitmask.set_bit(global_x, global_y, bit_value)
					var color = Color.WHITE if bit_value else Color.BLACK
					terrain_image.set_pixel(global_x,global_y,color)

		# Reset the dirty flag after updating
		cell_data["is_dirty"] = false
