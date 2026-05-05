shader_type canvas_item;

uniform sampler2D t0 : hint_screen_texture, filter_linear_mipmap;
uniform float bloom_spread : hint_range(0.0, 5.0) = 2.0;
uniform float bloom_intensity : hint_range(0.0, 5.0) = 1.5;

void fragment() {
    vec2 ps = SCREEN_PIXEL_SIZE * bloom_spread;
    vec3 bloom_sum = vec3(0.0);
    
    // We sample in a 5x5 grid but with "staggered" offsets.
    // Because we use 'filter_linear', sampling between pixels
    // effectively gives us the average of 4 pixels at once.
    for (float x = -2.0; x <= 2.0; x += 1.0) {
        for (float y = -2.0; y <= 2.0; y += 1.0) {
            // Sample the texture
            vec3 col = texture(t0, SCREEN_UV + vec2(x, y) * ps).rgb;
            
            // "Better" Bloom: Squaring the color makes the glow 
            // much more vibrant and prevents it from looking like "fog".
            // It makes brights glow more than darks.
            bloom_sum += col * col;
        }
    }
    
    // Average the samples (25 instead of 81)
    bloom_sum /= 25.0;
    
    vec3 base_color = texture(t0, SCREEN_UV).rgb;
    
    // Additive blend with intensity
    // We use a simple tone-map curve (1.0 - exp) to keep it from "clipping" too harshly
    vec3 combined = base_color + (bloom_sum * bloom_intensity);
    
    COLOR = vec4(combined, 1.0);
}