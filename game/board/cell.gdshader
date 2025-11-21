shader_type canvas_item;

uniform float grid_border = 0.1;
uniform float border_blur = 2.0;
uniform float alpha = 1.0;
uniform vec3 min_color_mod = vec3(0.0);
uniform vec3 max_color_mod = vec3(1.0);

// Pans a value back and forth between _min and _max
float smooth_pan(float n, float _min, float _max) {
	if (_max <= _min) return _max;
	return _min + ((_max - _min) - abs(mod(n, (_max - _min) * 2.0) - (_max - _min)));
}

void fragment() {
	vec3 d = max_color_mod - min_color_mod;
	vec2 suv = SCREEN_UV * 3.0;
	COLOR = vec4(
		smooth_pan(((suv.x + TIME) * d.x), min_color_mod.x, max_color_mod.x), 
		smooth_pan(((suv.y + TIME) * d.y), min_color_mod.y, max_color_mod.y), 
		smooth_pan(TIME * d.z, min_color_mod.z, max_color_mod.z), 
		(1.0 - (abs(grid_border / 2.0 - min(min(UV.x, UV.y), 1.0 - max(UV.x, UV.y))) * (1.0 / grid_border) * border_blur)) * alpha
	);
}
