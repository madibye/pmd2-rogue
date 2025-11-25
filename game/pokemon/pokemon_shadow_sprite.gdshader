shader_type canvas_item;

uniform int shadow_size: hint_range(-1, 3, 1);
uniform vec4 outline_color: source_color;
uniform vec4 inner_color: source_color;

vec2 get_relative_pixel(vec2 uv, vec2 pixel_size, vec2 relative_coords) {
	return uv + (pixel_size * relative_coords);
}

vec4 get_pixel_color(vec2 pixel_coord, sampler2D tex) {
	return texture(tex, pixel_coord);
}

bool should_discard_by_color(vec4 color) {
	if (color.a < 0.1) return true;
	int s = 0;
	if ((color.g == 1.0 && color.b == 1.0 && color.r == 1.0) || (color.g > 0.9 && color.b < 0.1 && color.r < 0.1)) {
		s = 1;
	} else if (color.r > 0.9 && color.b < 0.1 && color.g < 0.1) {
		s = 2;
	} else if (color.b > 0.9 && color.r < 0.1 && color.g < 0.1) {
		s = 3;
	}
	return shadow_size < s - 1;
}

bool should_discard(vec2 pixel_coord, sampler2D tex) {
	return should_discard_by_color(get_pixel_color(pixel_coord, tex));
}

vec4 get_final_rgb(vec2 uv, vec2 pixel_size, sampler2D tex) {
	vec2 cardinal_neighbor_coords[4] = { vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(1.0, 0.0), vec2(0.0, -1.0) };
	vec2 corner_neighbor_coords[4] = { vec2(-1.0, 1.0), vec2(1.0, 1.0), vec2(-1.0, -1.0), vec2(1.0, -1.0) };
	int discard_cardinal_neighbors = 0;
	int discard_corner_neighbors = 0;
	
	for (int i = 0; i < cardinal_neighbor_coords.length(); i++)
		if (should_discard(get_relative_pixel(uv, pixel_size, cardinal_neighbor_coords[i]), tex))
			discard_cardinal_neighbors += 1;
	for (int i = 0; i < corner_neighbor_coords.length(); i++) 
		if (should_discard(get_relative_pixel(uv, pixel_size, corner_neighbor_coords[i]), tex))
			discard_corner_neighbors += 1;
	if (should_discard(uv, tex) && discard_cardinal_neighbors >= 4) return vec4(0.0);
	else if (should_discard(uv, tex) && (discard_cardinal_neighbors >= 0 || discard_corner_neighbors >= 0)) return outline_color;
	else {
		if (discard_cardinal_neighbors >= 2) return vec4(mix(outline_color.rgb, inner_color.rgb, 0.5), 1.0);
		return inner_color;
	}
}

void fragment() {
	vec4 color = get_final_rgb(UV, TEXTURE_PIXEL_SIZE, TEXTURE);
	if (color.a < 0.1) discard;
	COLOR = color;
}