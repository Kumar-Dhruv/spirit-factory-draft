shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

uniform float pixel_size = 4.0;
uniform float color_depth = 8.0;
uniform bool enable_dithering = true;
uniform float dither_intensity = 0.3;

void fragment() {
    // 1. Pixelize coordinates
    vec2 screen_size = vec2(textureSize(screen_texture, 0));
    vec2 size = pixel_size / screen_size;
    vec2 uv = floor(SCREEN_UV / size) * size;
    
    // 2. Sample original color
    vec3 color = texture(screen_texture, uv).rgb;
    
    // 3. Apply Dither Matrix math manually to avoid array/matrix lookup bugs
    if (enable_dithering) {
        int x = int(FRAGCOORD.x / pixel_size) % 4;
        int y = int(FRAGCOORD.y / pixel_size) % 4;
        
        // Flattened 4x4 Bayer matrix values
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