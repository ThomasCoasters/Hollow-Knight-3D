//spacial shader so it is for 3D worlds / games
shader_type spatial;

//changes settings sort off
//unshaded means that lights does nothing
//cull_front makes only the inside rendered (not the outside)
//blend_mix enables transparancy
render_mode unshaded, cull_front, blend_mix;

//1D shader for the following alpha
uniform sampler2D tex_frg_11;

//2D shader for the away fasing alpha
uniform sampler2D tex_frg_12;

//how far on the slider 1D you are
uniform float gradient_1_slider;

//how far on the slider 2D you are
uniform float gradient_2_slider;

//color of the outline
uniform vec4 color : source_color = vec4(0.0);
//thickness of the outline
uniform float outline_thickness = 0.01;


//vertex means for every verticy of the object
void vertex() {
	//moves every vertext slightly outwards
	VERTEX += NORMAL * outline_thickness;
}

//runs for every pixel on screen
void fragment() {
	//make a uv var that is a UV
	vec2 uv = UV;
	
	// do some math for how far on the shader we are
	vec2 uv1 = (uv - vec2(gradient_1_slider)) * vec2(0.25, 0.0) + vec2(gradient_1_slider);
	
	// do some more math for how far on the other shader we are
	vec2 uv2 = (uv - vec2(gradient_2_slider)) * vec2(0.0, 0.25) + vec2(gradient_2_slider);
	
	// make vars for what the red value is and use that for the alpha
	float a1 = texture(tex_frg_11, uv1).r;
	float a2 = texture(tex_frg_12, uv2).r;
	
	// the final alpha is both multiplied
	float final_alpha = a1 * a2;
	
	// set the color to the color chosen
	ALBEDO = color.rgb;
	// set the alpga to the alpha we got from all of the math before
	ALPHA  = final_alpha;
	
	if (final_alpha <= 0.01) {
		//discards removes it
		discard;
	}
}