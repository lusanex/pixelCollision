
extends Sprite2D
# Array of Rect2 objects representing the grid cells
var grid_cells: Dictionary = {}
var size : Vector2

var brush_rects = {}  # Stores quadrant -> normalized brush rects
var terrain_size = Vector2.ZERO
var cell_count = Vector2i.ZERO
# Colors for alternating squares
var color1 = Color(1, 0, 0, 0.1)  # Red with 50% opacity
var color2 = Color(0, 0, 1, 0.1)  # Blue with 50% opacity

func _draw():
	# Convert sprite global center position to local top-left
	var sprite_size = size
	var sprite_top_left = to_local(position - (sprite_size / 2))  
	#print(grid_cells)
	for key in grid_cells.keys():
		var rect = grid_cells[key]
		#print(rect.size)

		# Convert grid cell position to local coordinates relative to the sprite
		var local_position = Vector2(rect.position) * scale  # Apply scale correctly
		var world_position = sprite_top_left + local_position  # Convert to world

		# Scale rect size
		var world_size = Vector2(rect.size) * scale

		# Create a world-space rectangle
		var world_rect = Rect2(world_position, world_size)

		# Alternate colors for checkerboard effect
		if (int(rect.position.x / rect.size.x) + int(rect.position.y / rect.size.y)) % 2 == 0:
			draw_rect(world_rect, color1, true)  # Fill with color1
		else:
			draw_rect(world_rect, color2, true)  # Fill with color2

		# Draw black border around each cell
		draw_rect(world_rect, Color(0, 0, 0, 1), false)  # Black outline
		
		
	
	var scale_factor = scale  # Scale of terrain

	for quadrant in brush_rects.keys():
		if not grid_cells.has(quadrant):
			continue

		# ✅ Get quadrant rect from grid_cells (now Rect2i)
		var quadrant_rect: Rect2i = grid_cells[quadrant]
		var region_size: Vector2 = Vector2(quadrant_rect.size)  # Convert to Vector2
		var region_top_left: Vector2 = Vector2(quadrant_rect.position)  # Convert to Vector2

		# ✅ Convert to world space
		var local_position: Vector2 = region_top_left * scale  
		var world_position: Vector2 = sprite_top_left + local_position  

		# ✅ Get the normalized rect inside the quadrant
		var normalized_rect: Rect2 = brush_rects[quadrant].rect

		# ✅ Convert normalized rect to actual pixel coordinates inside the quadrant
		var rect_top_left: Vector2 = region_top_left + (normalized_rect.position * region_size)
		var rect_size: Vector2 = normalized_rect.size * region_size

		# ✅ Convert to world space
		var world_rect_top_left: Vector2 = sprite_top_left + (rect_top_left * scale)
		var world_rect_size: Vector2 = rect_size * scale

		# ✅ Create the final rect to draw
		var world_brush_rect: Rect2 = Rect2(world_rect_top_left, world_rect_size)

		# ✅ Draw the quadrant outline in GREEN
		var rect_container: Rect2 = Rect2(world_position, region_size * scale)
		draw_rect(rect_container, Color(0, 1, 0, 0.3), true)

		# ✅ Draw the brush area inside the quadrant in BLUE
		draw_rect(world_brush_rect, Color(0, 0, 1, 0.6), true)

		
func draw_brush_rects(new_brush_rects: Dictionary, new_terrain_size: Vector2, new_cell_count: Vector2i):
	brush_rects = new_brush_rects
	terrain_size = new_terrain_size
	cell_count = new_cell_count
	queue_redraw()  # Request re-drawin
		
func debug_cells(cells : Dictionary, _size : Vector2) -> void:
	grid_cells = cells
	#print(grid_cells)
	size = _size
	queue_redraw()
