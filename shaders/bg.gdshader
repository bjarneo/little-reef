// Tank background: air, water bands, two dark hills and the sand floor.
shader_type canvas_item;
render_mode unshaded, blend_disabled;

#include "res://shaders/common.gdshaderinc"

uniform float W = 256.0;
uniform float H = 160.0;
uniform float TOP = 12.0;
uniform float SAND = 134.0;
// When true, only the sand floor is drawn. This pass covers the keeper's chin.
uniform bool sand_only = false;

vec3 band(int i) {
	if (i <= 0) return rgb8(90, 167, 200);
	if (i == 1) return rgb8(76, 153, 191);
	if (i == 2) return rgb8(63, 138, 179);
	if (i == 3) return rgb8(53, 124, 167);
	if (i == 4) return rgb8(45, 110, 153);
	if (i == 5) return rgb8(38, 95, 138);
	if (i == 6) return rgb8(32, 82, 123);
	return rgb8(27, 70, 108);
}

vec3 band_at(float y) {
	float bh = (SAND + 6.0 - TOP) / 8.0;
	return band(clamp(int(floor((y - TOP) / bh)), 0, 7));
}

vec3 mix8(vec3 a, vec3 b, float t) {
	return floor((a + (b - a) * t) * 255.0 + 0.5) / 255.0;
}

float sand_y(float x) {
	return SAND + jround(sin(x * 0.06) * 1.5 + sin(x * 0.17 + 2.0) * 0.8);
}

float hill_top(float x, float seed, float base, float amp) {
	float n = 0.5 + 0.3 * sin(x * 0.031 + seed) + 0.2 * sin(x * 0.083 + seed * 2.0) + 0.1 * sin(x * 0.21 + seed * 3.0);
	return jround(SAND - (base + amp * n));
}

void fragment() {
	float x = floor(UV.x * W);
	float y = floor(UV.y * H);
	int xi = int(x);
	int yi = int(y);
	if (sand_only && y < sand_y(x)) {
		discard;
	}
	vec3 col;
	if (y < TOP) {
		col = rgb8(134, 174, 194);
	} else {
		float bh = (SAND + 6.0 - TOP) / 8.0;
		float bi = floor((y - TOP) / bh);
		bool near = (y - TOP) - bi * bh > bh - 2.0;
		col = (near && (xi + yi) % 2 == 0) ? band(min(int(bi) + 1, 7)) : band_at(y);
		vec3 deep = rgb8(10, 34, 56);
		float t1 = hill_top(x, 1.7, 20.0, 22.0);
		if (y >= t1 && y < SAND + 4.0) col = mix8(band_at(y), deep, 0.22 * (y == t1 ? 0.7 : 1.0));
		float t2 = hill_top(x, 4.1, 6.0, 16.0);
		if (y >= t2 && y < SAND + 4.0) col = mix8(band_at(y), deep, 0.42 * (y == t2 ? 0.7 : 1.0));
		float top = sand_y(x);
		if (y >= top) {
			float d = y - top;
			float h = hash2(xi, yi, 3);
			col = d == 0.0 ? rgb8(233, 207, 148) : d < 3.0 ? rgb8(214, 183, 120) : d < 9.0 ? rgb8(196, 162, 102) : rgb8(176, 143, 87);
			if (d > 0.0 && h < 0.08) col = rgb8(156, 124, 72);
			else if (d > 0.0 && h > 0.965) col = rgb8(240, 220, 174);
			else if (d > 1.0 && h > 0.5 && h < 0.512) {
				float p = hash2(xi, yi, 11);
				col = p < 0.333 ? rgb8(138, 143, 160) : p < 0.666 ? rgb8(160, 122, 106) : rgb8(125, 143, 122);
			}
		}
	}
	COLOR = vec4(col, 1.0);
}
