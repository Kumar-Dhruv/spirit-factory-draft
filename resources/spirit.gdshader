shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D sprite_texture : source_color, filter_nearest;
uniform float framerate = 12.0;
uniform float max_dist = 2.0; 
// 1.0 means 100% of pixels shift. 0.1 means only 10% shift.
uniform float jitter_probability : hint_range(0.0, 1.0) = 0.5; 

// Returns a single random float for the dice roll
float random1(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Returns two random floats for angle and distance
vec2 random2(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

void vertex() {
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
    MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
    MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
    vec2 tex_size = vec2(textureSize(sprite_texture, 0));
    vec2 pixel_coord = floor(UV * tex_size);
    
    float time_step = floor(TIME * framerate);
    time_step = mod(time_step, 1000.0);
    vec2 time_offset = vec2(time_step * 3.141, time_step * 1.618);
    
    // Default shift is zero (pixel stays still)
    vec2 pixel_shift = vec2(0.0);
    
    // Roll the dice for this specific pixel at this specific time step
    // We add an arbitrary offset (vec2(100.0, 50.0)) so the dice roll uses a different seed than the movement math
    float chance = random1(pixel_coord + time_offset + vec2(100.0, 50.0));
    
    // If the dice roll is less than your parameter, calculate the shift
    if (chance < jitter_probability) {
        vec2 rand_val = random2(pixel_coord + time_offset);
        float angle = rand_val.x * 6.28318;
        float dist = rand_val.y * max_dist;
        pixel_shift = round(vec2(cos(angle), sin(angle)) * dist);
    }
    
    vec2 shifted_coord = pixel_coord + pixel_shift;
    vec2 final_uv = (shifted_coord + vec2(0.5)) / tex_size;
    
    vec4 color = texture(sprite_texture, final_uv);
    
    if (color.a < 0.1) {
        discard;
    }
    
    ALBEDO = color.rgb;
    ALPHA = color.a;
}