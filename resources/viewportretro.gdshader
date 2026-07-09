shader_type canvas_item;

// No hint_screen_texture needed! The container passes the viewport texture automatically.
uniform float pixel_size = 1.0; // Keep at 1.0 if SubViewport size is already low-res
uniform float color_depth = 8.0;
uniform bool enable_dithering = true;
uniform float dither_intensity = 0.3;

void fragment() {
    // 1. Pixelize coordinates relative to the texture
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 size = pixel_size / tex_size;
    vec2 uv = floor(UV / size) * size;
    
    // 2. Sample the viewport frame color
    vec3 color = texture(TEXTURE, uv).rgb;
    
    // 3. Apply Dither Matrix math manually
    if (enable_dithering) {
        int x = int(FRAGCOORD.x / pixel_size) % 4;
        int y = int(FRAGCOORD.y / pixel_size) % 4;
        
        float threshold = 0.0;
        if (y == 0) {
            if (x == 0) threshold = 0.0000; else if (x == 1) threshold = 0.5000; else if (x == 2) threshold = 0.1250; else threshold = 0.6250;
        } else if (y == 1) {
            if (x == 0) threshold = 0.7500; else if (x == 1) threshold = 0.2500; else if (x == 2) threshold = 0.8750; else threshold = 0.3750;
        } else if (y == 2) {
            if (x == 0) threshold = 0.1875; else if (x == 1) threshold = 0.6875; else if (x == 2) threshold = 0.0625; else threshold = 0.5625;
        } else {
            if (x == 0) threshold = 0.9375; else if (x == 1) threshold = 0.4375; else if (x == 2) threshold = 0.8125; else threshold = 0.3125;
        }
        
        threshold -= 0.5;
        color += threshold * (1.0 / color_depth) * dither_intensity;
    }
    
    // 4. Quantize (Color Banding)
    color = floor(color * color_depth) / color_depth;
    
    COLOR = vec4(color, 1.0);
}