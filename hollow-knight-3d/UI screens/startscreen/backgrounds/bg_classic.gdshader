shader_type canvas_item;

uniform vec4 center_color : source_color = vec4(0.15, 0.25, 0.45, 1.0);
uniform vec4 edge_color   : source_color = vec4(0.02, 0.05, 0.12, 1.0);

uniform float radius = 0.7;
uniform float softness = 1.5;

// ellipse + rotation controls
uniform vec2 stretch = vec2(1.4, 0.8); // ellipse shape
uniform float rotation = 0.35; // rotation in radians

uniform vec2 offset = vec2(0.55, 0.45);

void fragment() {
	vec2 uv = UV;
	
	// center with offset
	vec2 p = uv - offset;
	
	// rotate
	float c = cos(rotation);
	float s = sin(rotation);
	mat2 rot = mat2(vec2(c, -s), vec2(s, c));
	p = rot * p;
	
	// stretch to make the eclipse
	p *= stretch;
	
	// distance
	float dist = length(p);
	
	float t = smoothstep(radius, radius * softness, dist);
	
	// make the midle a bit brighter
	float center_boost = smoothstep(0.2, 0.0, dist);
	center_boost = pow(center_boost, 1.0);
	
	
	
	//aply the color
	vec4 base = mix(center_color, edge_color, t);
	
	// add brightness only in center
	base.rgb += center_boost * 0.05; // intensity control
	
	COLOR = base;
}