shader_type canvas_item;

uniform vec4 center_color : source_color = vec4(0.15, 0.25, 0.45, 1.0);
uniform vec4 edge_color   : source_color = vec4(0.02, 0.05, 0.12, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.01, 0.02, 0.05, 1.0);

uniform float radius = 0.7;
uniform float softness = 1.5;

uniform vec2 stretch = vec2(1.4, 0.8);
uniform float rotation = 0.35;

uniform vec2 offset = vec2(0.55, 0.45);


uniform float bottom_extent : hint_range(0.0, 1.0) = 0.2;
uniform float bottom_softness : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec2 uv = UV;
	
	vec2 p = uv - offset;
	
	float c = cos(rotation);
	float s = sin(rotation);
	mat2 rot = mat2(vec2(c, -s), vec2(s, c));
	p = rot * p;
	
	p *= stretch;
	
	float dist = length(p);
	
	float t = smoothstep(radius, radius * softness, dist);
	
	vec4 base = mix(center_color, edge_color, t);
	
	float bottom_factor = smoothstep(1.0 - bottom_extent - bottom_softness, 1.0 - bottom_extent, uv.y);
	
	COLOR = mix(base, bottom_color, bottom_factor);
}