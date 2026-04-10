//spacial shader so it is for 3D worlds / games
shader_type spatial;

//changes settings sort off
//unshaded means that lights does nothing
//cull_front makes only the inside rendered (not the outside)
//blend_mix enables transparancy
render_mode unshaded, cull_front, blend_mix;



//changes the visibility
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
//changes how thick the outline is
uniform float outline_thickness = 0.01;
//the color of the outline
uniform vec4 color : source_color = vec4(0.0);

//vertex means for every verticy of the object
void vertex() {
	//moves every vertext slightly outwards
	VERTEX += NORMAL * outline_thickness;
}

//runs for every pixel on screen
void fragment() {
	//sets the visible color
	ALBEDO = color.rgb;
	//sets the transparancy (alpha)
	ALPHA = alpha;
	
	
	if (alpha <= 0.01) {
		//discards removes it
		discard;
	}
}