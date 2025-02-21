
extends Sprite2D
# Array of Rect2 objects representing the grid cells
var grid_cells: Array = []
var size : Vector2

# Colors for alternating squares
var color1 = Color(1, 0, 0, 0.1)  # Red with 50% opacity
var color2 = Color(0, 0, 1, 0.1)  # Blue with 50% opacity

func _draw():
	# Convert sprite global center position to local top-left
	var sprite_size = size
	var sprite_top_left = to_local(position - (sprite_size / 2))  

	for i in range(grid_cells.size()):
		var rect = grid_cells[i]

		# Convert grid cell position to local coordinates relative to the sprite
		var local_position = rect.position * scale  # Apply scale correctly
		var world_position = sprite_top_left + local_position  # Convert to world

		# Scale rect size
		var world_size = rect.size * scale

		# Create a world-space rectangle
		var world_rect = Rect2(world_position, world_size)

		# Alternate colors for checkerboard effect
		if (int(rect.position.x / rect.size.x) + int(rect.position.y / rect.size.y)) % 2 == 0:
			draw_rect(world_rect, color1, true)  # Fill with color1
		else:
			draw_rect(world_rect, color2, true)  # Fill with color2

		# Draw black border around each cell
		draw_rect(world_rect, Color(0, 0, 0, 1), false)  # Black outline



func debug_cells(cells : Array, _size : Vector2) -> void:
	grid_cells = cells
	size = _size
	queue_redraw()
