shader_type canvas_item;

// --- Your Original Code (Preserved) ---
uniform vec4 center_color : source_color = vec4(0.15, 0.25, 0.45, 1.0);
uniform vec4 edge_color   : source_color = vec4(0.02, 0.05, 0.12, 1.0);

uniform float radius = 0.7;
uniform float softness = 1.5;

// ellipse + rotation controls
uniform vec2 stretch = vec2(1.4, 0.8); // ellipse shape
uniform float rotation = 0.35; // rotation in radians

uniform vec2 offset = vec2(0.55, 0.45);

// --- New Texture and Animation Controls ---
// Set this texture uniform in the inspector with the provided beam image.
uniform sampler2D ray_texture : source_color, filter_linear_mipmap_anisotropic;

uniform vec4 ray_color     : source_color = vec4(1.0, 0.85, 0.6, 0.2); 
uniform float ray_intensity : hint_range(0.0, 5.0) = 1.2;

// Controls the subtle 10% breathing animation
uniform float ray_pulse_speed : hint_range(0.0, 2.0) = 0.4; 
// Reduces the pulse range to be 10% (0.9 to 1.0)
uniform float ray_pulse_range : hint_range(0.0, 1.0) = 0.1; 

// Pushed to spawn zone
uniform float bottom_extent : hint_range(0.0, 1.0) = 0.2;
uniform float bottom_softness : hint_range(0.0, 1.0) = 0.3;
uniform vec4 bottom_color : source_color = vec4(0.01, 0.02, 0.05, 1.0);

void fragment() {
	vec2 uv = UV;
	
	// --- 1. Base Ellipse Vignette ---
	vec2 p = uv - offset;
	float c = cos(rotation);
	float s = sin(rotation);
	mat2 rot = mat2(vec2(c, -s), vec2(s, c));
	p = rot * p;
	p *= stretch;
	float dist = length(p);
	float t = smoothstep(radius, radius * softness, dist);
	vec4 base = mix(center_color, edge_color, t);
	
	// --- 2. Bottom Floor Gradient (Calculated BEFORE the rays) ---
	float bottom_factor = smoothstep(1.0 - bottom_extent - bottom_softness, 1.0 - bottom_extent, uv.y);
	vec4 full_background = mix(base, bottom_color, bottom_factor);
	
	// --- 3. Textured Rays ---
	vec4 tex_lookup = texture(ray_texture, uv);
	
	// 3a. Mask to cut off rays
	float spawn_mask = smoothstep(0.018, 0.28, uv.x) * smoothstep(0.982, 0.72, uv.x);
	
	// 3b. Breathing pulse
	float base_pulse = mix(1.0 - ray_pulse_range, 1.0, sin(TIME * ray_pulse_speed) * 0.5 + 0.5);
	
	// 3c. Vertical fade-out toward the bottom
	float vertical_fade = pow(1.0 - uv.y, 1.4);
	
	// Combine the texture data with masks and animation
	float final_ray_intensity = tex_lookup.r * ray_intensity * vertical_fade * spawn_mask * base_pulse;
	
	// --- 4. Final Output ---
	// Add the volumetric textured rays ON TOP of the complete background
	vec3 final_rgb = full_background.rgb + ray_color.rgb * final_ray_intensity * ray_color.a;
	
	COLOR = vec4(final_rgb, 1.0);
}