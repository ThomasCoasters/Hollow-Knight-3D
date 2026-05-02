shader_type canvas_item;

uniform float blur_strength : hint_range(0, 10) = 2.0;

void fragment() {
    vec2 uv = UV;
    // Multiply by pixel size to get "per-pixel" movement
    vec2 texel = TEXTURE_PIXEL_SIZE * blur_strength;
    
    vec4 col = vec4(0.0);
    
    // We use whole numbers (1.0, 2.0) to represent pixel offsets
    col += texture(TEXTURE, uv) * 0.227;
    col += texture(TEXTURE, uv + texel * 1.0) * 0.316;
    col += texture(TEXTURE, uv - texel * 1.0) * 0.316;
    col += texture(TEXTURE, uv + texel * 2.0) * 0.070;
    col += texture(TEXTURE, uv - texel * 2.0) * 0.070;
    
    COLOR = col;
}