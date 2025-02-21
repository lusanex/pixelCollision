shader_type canvas_item;

uniform sampler2D mask_texture; // Black-and-white mask

void fragment() {
    vec4 sprite_color = texture(TEXTURE, UV); 
    vec4 mask_color = texture(mask_texture, UV); // Get the mask color at the same UV

    // If the mask pixel is black, discard the fragment (make it transparent)
    if (mask_color.r < 0.5) {
        discard;
    }

    // Otherwise, apply the sprite color
    COLOR = sprite_color;
}
