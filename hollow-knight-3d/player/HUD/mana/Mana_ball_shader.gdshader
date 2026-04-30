// shader type fr 2D objects
shader_type canvas_item;

// fill //

// editable var that goes from 0 to 1 for what the fill ratio is
uniform float fill_ratio : hint_range(0, 1.0) = 0.5;

// colors //

// editable vars that are colors that have R G B and A
// source_color makes colors work correctly
uniform vec4 fill_color: source_color = vec4(0.8, 0.9, 1.0, 1.0);
uniform vec4 bg_color: source_color = vec4(0.05, 0.05, 0.07, 1.0);

// light //
uniform bool dissable_lights;

// editable var that is a Vector2
uniform vec2 light_dir = vec2(-0.6, -0.8); // direction light comes from
// just fill in yourself float editable vars
uniform float light_strength = 0.6;
uniform float ambient = 0.4;

// pulsing //
uniform bool pulsing_lights;

// the pulsing speed
uniform float pulse_speed = 2.0;

uniform vec2 pulse_range = vec2(0.0, 1.0); // x = min, y = max




// waves //

uniform float wave_amp = 0.03;
uniform float wave_freq = 8.0;
uniform float wave_speed = 2.0;

// edges //

uniform float edge_softness = 0.01;

void fragment() {
	// get the uv //
	
	// gets the texture cords
	vec2 uv = UV;
	// changes the uv to be -1 to 1 instead of 0 to 1
	vec2 location_uv = uv * 2.0 - 1.0;
	
	
	// make the circle //
	
	// get the distance of the point on the sphere (center = 0, edge = -1 or 1)
	float dist = length(location_uv);
	// returns 0 if x < a and 1 if x > b (smoothly between those 2) 
	float circle = smoothstep(1.0, 1.0 - edge_softness, dist);
	
	
	
	// lights //
	
	float lighting;
	
	if (dissable_lights) {
		lighting = 1.0;
	
	} else if (pulsing_lights) {
		// 0 → 1 sine wave
		float t = (sin(TIME * pulse_speed) + 1.0) * 0.5;
		
		// map to custom range
		lighting = mix(pulse_range.x, pulse_range.y, t);
	
	} else {
		// step 1: get the left / right (location_uv) and make a fake 3D point
		// step 2: do sphere calculations (z = sqrt(1 - x² - y²))
		// step 3: clamp it
		// step 4: normalize it
		vec3 normal = normalize(vec3(location_uv.x, location_uv.y, sqrt(max(0.0, 1.0 - dist * dist))));
		
		// normalize the light with a small forward tilt 
		vec3 light = normalize(vec3(light_dir, 0.5));
		
		// dot product (if facing the light) make it bright
		float diff = max(dot(normal, light), 0.0);
		
		// make the final lights
		lighting = ambient + diff * light_strength;
	}
	
	
	
	
	
	// liquid feeling //
	//the flat level of off the liquid
	float height = 1.0 - fill_ratio * 2.0;
	
	// smoothly fade the edge
	float edge_fade = smoothstep(0.0, 0.05, fill_ratio) * smoothstep(0.0, 0.05, 1.0 - fill_ratio);
	
	// first sine wave
	float wave = sin(location_uv.x * wave_freq + TIME * wave_speed) * wave_amp * edge_fade;
	// second sine wave with some slower and minder high movements in the opposite direction
	float wave2 = sin(location_uv.x * (wave_freq * 0.5) - TIME * wave_speed * 0.7) * (wave_amp * 0.5) * edge_fade;
	
	//makes the surface
	float surface = height + wave + wave2;
	
	//fill everything below the surface
	float fill_mask = smoothstep(surface + 0.04, surface - 0.04, location_uv.y);
	
	
	
	vec4 lit_bg   = vec4(bg_color.rgb * lighting, bg_color.a);
	vec4 lit_fill = vec4(fill_color.rgb * lighting, fill_color.a);
	
	
	
	// final stuff //
	
	// choose the color
	vec4 col = mix(lit_fill, lit_bg, fill_mask);
	
	// set the alpha in the outside circle lower
	col.a *= circle;
	
	// set the final output
	COLOR = col;
}