shader_type spatial;
render_mode cull_disabled;

#include "res://environment/desert_base.gdshaderinc"

uniform sampler2D biomes;
uniform vec2 terrain_offset;
uniform float terrain_size;

varying vec2 vert_world_uv;

void vertex() {
	vert_world_uv = ((MODEL_MATRIX * vec4(VERTEX, 1.0)).xz - terrain_offset) / terrain_size;
}

void fragment() {
	ALBEDO = desert_base(biomes, vert_world_uv).rgb;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
