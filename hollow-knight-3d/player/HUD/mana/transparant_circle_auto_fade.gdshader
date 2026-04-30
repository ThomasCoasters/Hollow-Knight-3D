shader_type canvas_item;

// alpha control
uniform float start_alpha = 0.1;

// fade timing (5 frames at 30 FPS ≈ 0.1667 sec)
uniform float fade_time = 0.1667;

// edge softness for circle
uniform float edge_softness = 0.01;

uniform float lifetime = 0.0;

void fragment() {
	// UV to -1 → 1
	vec2 uv = UV * 2.0 - 1.0;
	
	// circle mask
	float dist = length(uv);
	float circle = smoothstep(1.0, 1.0 - edge_softness, dist);
	
	// time-based fade
	float t = clamp(lifetime / fade_time, 0.0, 1.0);
	
	// alpha goes from start_alpha → 0
	float alpha = mix(start_alpha, 0.0, t);
	
	// final color (white circle, change if needed)
	COLOR = vec4(1.0, 1.0, 1.0, alpha * circle);
}