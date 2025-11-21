shader_type canvas_item;

uniform int shadow_size: hint_range(-1, 3, 1);

void fragment() {
	if (COLOR.g == 1.0 && COLOR.b == 1.0 && COLOR.r == 1.0) {
		if (shadow_size < 1) COLOR.a = 0.0;
	} else if (COLOR.g > 0.9 && COLOR.b < 0.1 && COLOR.r < 0.1) {
		if (shadow_size < 1) COLOR.a = 0.0;
	} else if (COLOR.r > 0.9 && COLOR.b < 0.1 && COLOR.g < 0.1) {
		if (shadow_size < 2) COLOR.a = 0.0;
	} else if (COLOR.b > 0.9 && COLOR.r < 0.1 && COLOR.g < 0.1) {
		if (shadow_size < 3) COLOR.a = 0.0;
	}
	COLOR.rgb = vec3(0.0);
}