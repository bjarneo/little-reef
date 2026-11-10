// Algae on the glass. The grid holds one growth value per 8x8 cell.
shader_type canvas_item;
render_mode unshaded;

#include "res://shaders/common.gdshaderinc"

uniform sampler2D grid : filter_nearest;
uniform int AW = 32;
uniform int AH = 19;
uniform float W = 256.0;
uniform float H = 160.0;
uniform float TOP = 12.0;

float cell(int x, int y) {
	return texelFetch(grid, ivec2(x, y), 0).r;
}

void fragment() {
	float x = floor(UV.x * W);
	float y = floor(UV.y * H);
	COLOR = vec4(0.0);
	if (y >= TOP) {
		float gy = (y - TOP) / 8.0 - 0.5;
		float gx = x / 8.0 - 0.5;
		int x0 = clamp(int(floor(gx)), 0, AW - 1);
		int y0 = clamp(int(floor(gy)), 0, AH - 1);
		int x1 = min(AW - 1, x0 + 1);
		int y1 = min(AH - 1, y0 + 1);
		float fx = clamp(gx - float(x0), 0.0, 1.0);
		float fy = clamp(gy - float(y0), 0.0, 1.0);
		float v = mix(mix(cell(x0, y0), cell(x1, y0), fx), mix(cell(x0, y1), cell(x1, y1), fx), fy);
		float h = hash2(int(x), int(y), 5);
		if (v >= 0.04 && h <= v * 0.7) {
			vec3 c = h < v * 0.2 ? rgb8(58, 110, 46) : h < v * 0.45 ? rgb8(79, 138, 58) : rgb8(106, 168, 74);
			COLOR = vec4(c, floor(150.0 + v * 80.0 + 0.5) / 255.0);
		}
	}
}
